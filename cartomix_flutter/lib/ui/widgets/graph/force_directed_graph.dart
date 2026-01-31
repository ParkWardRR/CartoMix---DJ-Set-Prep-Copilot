import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/graph_state.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/theme.dart';
import '../common/empty_state.dart';

/// Interactive force-directed graph visualization
class ForceDirectedGraph extends ConsumerStatefulWidget {
  const ForceDirectedGraph({super.key});

  @override
  ConsumerState<ForceDirectedGraph> createState() => _ForceDirectedGraphState();
}

class _ForceDirectedGraphState extends ConsumerState<ForceDirectedGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _draggingNodeId;
  Offset? _lastPanPosition;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..addListener(_onTick);
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTick() {
    if (_canvasSize != Size.zero) {
      ref.read(graphStateProvider.notifier).simulateStep(_canvasSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    final graphState = ref.watch(graphStateProvider);
    final setTracks = ref.watch(setTracksProvider);
    final setTrackIds = setTracks.map((t) => t.id).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return ClipRect(
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                final delta = event.scrollDelta.dy;
                final currentZoom = graphState.zoom;
                final newZoom = (currentZoom - delta * 0.001).clamp(0.25, 4.0);
                ref.read(graphStateProvider.notifier).setZoom(newZoom);
              }
            },
            child: GestureDetector(
              onPanStart: (details) {
                // Check if we're clicking on a node
                final clickPos = _screenToCanvas(
                  details.localPosition,
                  graphState,
                  _canvasSize,
                );

                int? clickedNodeId;
                for (final entry in graphState.nodes.entries) {
                  final nodePos = entry.value.position;
                  if ((clickPos - nodePos).distance < 25) {
                    clickedNodeId = entry.key;
                    break;
                  }
                }

                if (clickedNodeId != null) {
                  _draggingNodeId = clickedNodeId;
                  ref.read(graphStateProvider.notifier).startDragging(clickedNodeId);
                  ref.read(graphStateProvider.notifier).selectNode(clickedNodeId);
                } else {
                  _lastPanPosition = details.localPosition;
                  ref.read(graphStateProvider.notifier).selectNode(null);
                }
              },
              onPanUpdate: (details) {
                if (_draggingNodeId != null) {
                  final newPos = _screenToCanvas(
                    details.localPosition,
                    graphState,
                    _canvasSize,
                  );
                  ref.read(graphStateProvider.notifier).updateDragPosition(
                        _draggingNodeId!,
                        newPos,
                      );
                } else if (_lastPanPosition != null) {
                  final delta = details.localPosition - _lastPanPosition!;
                  ref.read(graphStateProvider.notifier).setPan(
                        graphState.pan + delta,
                      );
                  _lastPanPosition = details.localPosition;
                }
              },
              onPanEnd: (details) {
                if (_draggingNodeId != null) {
                  ref.read(graphStateProvider.notifier).stopDragging(_draggingNodeId!);
                  _draggingNodeId = null;
                }
                _lastPanPosition = null;
              },
              onTapUp: (details) {
                // Check if we're clicking on a node
                final clickPos = _screenToCanvas(
                  details.localPosition,
                  graphState,
                  _canvasSize,
                );

                int? clickedNodeId;
                for (final entry in graphState.nodes.entries) {
                  final nodePos = entry.value.position;
                  if ((clickPos - nodePos).distance < 25) {
                    clickedNodeId = entry.key;
                    break;
                  }
                }

                ref.read(graphStateProvider.notifier).selectNode(clickedNodeId);
              },
              child: Container(
                color: CartoMixColors.bgPrimary,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _GraphPainter(
                    nodes: graphState.nodes,
                    edges: graphState.visibleEdges,
                    setTrackIds: setTrackIds,
                    showSetOnly: graphState.showSetOnly,
                    zoom: graphState.zoom,
                    pan: graphState.pan,
                    selectedNodeId: graphState.selectedNodeId,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _screenToCanvas(Offset screenPos, GraphState state, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    return (screenPos - center - state.pan) / state.zoom + center;
  }
}

class _GraphPainter extends CustomPainter {
  final Map<int, GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<int> setTrackIds;
  final bool showSetOnly;
  final double zoom;
  final Offset pan;
  final int? selectedNodeId;

  _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.setTrackIds,
    required this.showSetOnly,
    required this.zoom,
    required this.pan,
    required this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx + pan.dx, center.dy + pan.dy);
    canvas.scale(zoom);
    canvas.translate(-center.dx, -center.dy);

    // Get visible nodes
    final visibleNodeIds = showSetOnly
        ? nodes.keys.where((id) => setTrackIds.contains(id)).toSet()
        : nodes.keys.toSet();

    // Draw edges first (behind nodes)
    for (final edge in edges) {
      if (!visibleNodeIds.contains(edge.sourceId) ||
          !visibleNodeIds.contains(edge.targetId)) {
        continue;
      }

      final sourceNode = nodes[edge.sourceId];
      final targetNode = nodes[edge.targetId];
      if (sourceNode == null || targetNode == null) continue;

      final edgeColor = _getEdgeColor(edge.score);
      final isHighlighted = selectedNodeId == edge.sourceId ||
          selectedNodeId == edge.targetId;

      final paint = Paint()
        ..color = isHighlighted
            ? edgeColor.withValues(alpha: 0.9)
            : edgeColor.withValues(alpha: 0.4)
        ..strokeWidth = isHighlighted ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(sourceNode.position, targetNode.position, paint);

      // Draw score label on highlighted edges
      if (isHighlighted) {
        final midpoint = Offset(
          (sourceNode.position.dx + targetNode.position.dx) / 2,
          (sourceNode.position.dy + targetNode.position.dy) / 2,
        );
        _drawScoreLabel(canvas, midpoint, edge.score, edgeColor);
      }
    }

    // Draw nodes
    for (final nodeId in visibleNodeIds) {
      final node = nodes[nodeId];
      if (node == null) continue;

      _drawNode(canvas, node, nodeId == selectedNodeId);
    }

    canvas.restore();
  }

  void _drawNode(Canvas canvas, GraphNode node, bool isSelected) {
    final track = node.track;
    final pos = node.position;
    final energyColor = track.energyColor;
    final nodeRadius = isSelected ? 22.0 : 18.0;
    final isInSet = setTrackIds.contains(track.id);

    // Glow effect for selected or in-set nodes
    if (isSelected || isInSet) {
      final glowPaint = Paint()
        ..color = (isSelected ? CartoMixColors.primary : energyColor)
            .withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(pos, nodeRadius + 8, glowPaint);
    }

    // Outer ring for in-set nodes
    if (isInSet) {
      final ringPaint = Paint()
        ..color = CartoMixColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(pos, nodeRadius + 4, ringPaint);
    }

    // Node background
    final bgPaint = Paint()
      ..color = CartoMixColors.bgElevated
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, nodeRadius, bgPaint);

    // Node border (energy colored)
    final borderPaint = Paint()
      ..color = energyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;
    canvas.drawCircle(pos, nodeRadius, borderPaint);

    // Energy indicator inside
    final energyPaint = Paint()
      ..color = energyColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, nodeRadius - 4, energyPaint);

    // Draw energy number
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${track.energy ?? 5}',
        style: TextStyle(
          color: energyColor,
          fontSize: isSelected ? 12 : 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'SF Pro Text',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    // Draw track title below node (only if selected or zoomed in enough)
    if (isSelected) {
      final titlePainter = TextPainter(
        text: TextSpan(
          text: track.title.length > 20
              ? '${track.title.substring(0, 17)}...'
              : track.title,
          style: TextStyle(
            color: CartoMixColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'SF Pro Text',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      titlePainter.layout();

      // Background for label
      final labelBg = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: pos + Offset(0, nodeRadius + 14),
          width: titlePainter.width + 12,
          height: 18,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        labelBg,
        Paint()..color = CartoMixColors.bgElevated.withValues(alpha: 0.9),
      );

      titlePainter.paint(
        canvas,
        pos + Offset(-titlePainter.width / 2, nodeRadius + 5),
      );
    }
  }

  void _drawScoreLabel(
      Canvas canvas, Offset position, double score, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: score.toStringAsFixed(1),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'SF Pro Text',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Background
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: textPainter.width + 8,
        height: 14,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = CartoMixColors.bgElevated.withValues(alpha: 0.9),
    );

    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  Color _getEdgeColor(double score) {
    if (score >= 8.0) return CartoMixColors.success;
    if (score >= 6.0) return CartoMixColors.primary;
    return CartoMixColors.textMuted;
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) {
    return nodes != oldDelegate.nodes ||
        edges != oldDelegate.edges ||
        zoom != oldDelegate.zoom ||
        pan != oldDelegate.pan ||
        selectedNodeId != oldDelegate.selectedNodeId ||
        showSetOnly != oldDelegate.showSetOnly;
  }
}

/// Empty state widget for graph using standardized EmptyState
class GraphEmptyState extends StatelessWidget {
  const GraphEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CartoMixColors.bgPrimary,
      child: const EmptyState(
        icon: Icons.hub_outlined,
        title: 'No Tracks to Visualize',
        subtitle: 'Add tracks to your library and analyze them\nto see their similarity relationships',
      ),
    );
  }
}
