import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/providers/app_state.dart';
import '../../core/providers/graph_state.dart';
import '../../models/models.dart';
import '../widgets/graph/force_directed_graph.dart';

/// Transition Graph screen for visualizing track relationships
class GraphScreen extends ConsumerStatefulWidget {
  const GraphScreen({super.key});

  @override
  ConsumerState<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends ConsumerState<GraphScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGraph();
    });
  }

  void _initializeGraph() {
    if (_isInitialized) return;

    final tracksAsync = ref.read(tracksProvider);
    final similarities = ref.read(similaritiesProvider);

    tracksAsync.whenData((tracks) {
      if (tracks.isNotEmpty) {
        ref.read(graphStateProvider.notifier).initializeGraph(tracks, similarities);
        _isInitialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(tracksProvider);
    final graphState = ref.watch(graphStateProvider);
    final selectedTrack = ref.watch(selectedGraphTrackProvider);
    final connections = ref.watch(selectedTrackConnectionsProvider);
    final setTracks = ref.watch(setTracksProvider);

    // Re-initialize when tracks change
    tracksAsync.whenData((tracks) {
      if (!_isInitialized && tracks.isNotEmpty) {
        _initializeGraph();
      }
    });

    return Row(
      children: [
        // Graph canvas (2/3)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildToolbar(graphState),
              const Divider(height: 1),
              Expanded(
                child: tracksAsync.when(
                  data: (tracks) {
                    if (tracks.isEmpty) {
                      return const GraphEmptyState();
                    }
                    return const ForceDirectedGraph();
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error loading tracks: $e',
                      style: CartoMixTypography.body.copyWith(
                        color: CartoMixColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sidebar (1/3)
        const VerticalDivider(width: 1),
        SizedBox(
          width: 360,
          child: _buildSidebar(
            graphState,
            selectedTrack,
            connections,
            setTracks,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(GraphState graphState) {
    return Container(
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      color: CartoMixColors.bgSecondary,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Similarity threshold slider
            Text(
              'Min Score:',
              style: CartoMixTypography.caption,
            ),
            const SizedBox(width: CartoMixSpacing.sm),
            SizedBox(
              width: 120,
              child: Slider(
                value: graphState.minScoreThreshold,
                min: 0,
                max: 10,
                divisions: 20,
                label: graphState.minScoreThreshold.toStringAsFixed(1),
                onChanged: (value) {
                  ref.read(graphStateProvider.notifier).setMinScoreThreshold(value);
                },
              ),
            ),
            Container(
              width: 36,
              alignment: Alignment.center,
              child: Text(
                graphState.minScoreThreshold.toStringAsFixed(1),
                style: CartoMixTypography.badge.copyWith(
                  color: CartoMixColors.primary,
                ),
              ),
            ),
            const SizedBox(width: CartoMixSpacing.md),
            // Show set only toggle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Checkbox(
                    value: graphState.showSetOnly,
                    onChanged: (value) {
                      ref.read(graphStateProvider.notifier).setShowSetOnly(value ?? false);
                    },
                  ),
                ),
                const SizedBox(width: CartoMixSpacing.xs),
                Text(
                  'Set Only',
                  style: CartoMixTypography.caption,
                ),
              ],
            ),
            const SizedBox(width: CartoMixSpacing.lg),
            // Simulation toggle
            IconButton(
              icon: Icon(
                graphState.isSimulating ? Icons.pause : Icons.play_arrow,
                size: 18,
              ),
              onPressed: () {
                if (graphState.isSimulating) {
                  ref.read(graphStateProvider.notifier).stopSimulation();
                } else {
                  ref.read(graphStateProvider.notifier).startSimulation();
                }
              },
              tooltip: graphState.isSimulating ? 'Pause Physics' : 'Resume Physics',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: CartoMixSpacing.sm),
            // Zoom controls
            IconButton(
              icon: const Icon(Icons.zoom_out, size: 18),
              onPressed: () {
                ref.read(graphStateProvider.notifier).setZoom(graphState.zoom - 0.25);
              },
              tooltip: 'Zoom Out',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            Text(
              '${(graphState.zoom * 100).round()}%',
              style: CartoMixTypography.caption.copyWith(
                color: CartoMixColors.textMuted,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in, size: 18),
              onPressed: () {
                ref.read(graphStateProvider.notifier).setZoom(graphState.zoom + 0.25);
              },
              tooltip: 'Zoom In',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong, size: 18),
              onPressed: () {
                ref.read(graphStateProvider.notifier).resetView();
              },
              tooltip: 'Reset View',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(
    GraphState graphState,
    Track? selectedTrack,
    List<(Track, double)> connections,
    List<Track> setTracks,
  ) {
    return Container(
      color: CartoMixColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graph info
          Padding(
            padding: const EdgeInsets.all(CartoMixSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: CartoMixColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.hub_outlined,
                        size: 16,
                        color: CartoMixColors.primary,
                      ),
                    ),
                    const SizedBox(width: CartoMixSpacing.sm),
                    Text(
                      'Graph Stats',
                      style: CartoMixTypography.badge.copyWith(
                        color: CartoMixColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CartoMixSpacing.md),
                _buildInfoRow('Nodes', '${graphState.nodeCount}'),
                _buildInfoRow('Visible Edges', '${graphState.visibleEdges.length}'),
                _buildInfoRow(
                  'Avg Score',
                  graphState.avgScore?.toStringAsFixed(1) ?? '-',
                ),
                _buildInfoRow('In Set', '${setTracks.length}'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Legend
          Padding(
            padding: const EdgeInsets.all(CartoMixSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legend',
                  style: CartoMixTypography.badge.copyWith(
                    color: CartoMixColors.textSecondary,
                  ),
                ),
                const SizedBox(height: CartoMixSpacing.sm),
                _buildLegendItem(CartoMixColors.success, 'High Match (≥8)'),
                _buildLegendItem(CartoMixColors.primary, 'Good Match (≥6)'),
                _buildLegendItem(CartoMixColors.textMuted, 'Low Match (<6)'),
                const SizedBox(height: CartoMixSpacing.sm),
                _buildLegendNode(),
              ],
            ),
          ),
          const Divider(height: 1),
          // Selected track details
          Expanded(
            child: selectedTrack != null
                ? _buildTrackDetails(selectedTrack, connections)
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 32,
                          color: CartoMixColors.textMuted.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: CartoMixSpacing.sm),
                        Text(
                          'Click a node to view details',
                          style: CartoMixTypography.caption.copyWith(
                            color: CartoMixColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackDetails(Track track, List<(Track, double)> connections) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CartoMixSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: track.energyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(CartoMixSpacing.radiusMd),
                  border: Border.all(
                    color: track.energyColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${track.energy ?? 5}',
                    style: CartoMixTypography.headline.copyWith(
                      color: track.energyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CartoMixSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: CartoMixTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: CartoMixTypography.caption.copyWith(
                        color: CartoMixColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: CartoMixSpacing.md),
          // Track metadata
          Wrap(
            spacing: CartoMixSpacing.sm,
            runSpacing: CartoMixSpacing.xs,
            children: [
              if (track.bpm != null)
                _buildMetadataBadge(
                  'BPM',
                  track.bpmFormatted ?? '-',
                  CartoMixColors.primary,
                ),
              if (track.key != null)
                _buildMetadataBadge(
                  'Key',
                  track.key!,
                  track.keyColor,
                ),
              if (track.durationFormatted != null)
                _buildMetadataBadge(
                  'Duration',
                  track.durationFormatted!,
                  CartoMixColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: CartoMixSpacing.lg),
          // Connections
          Row(
            children: [
              Icon(
                Icons.link,
                size: 14,
                color: CartoMixColors.textMuted,
              ),
              const SizedBox(width: CartoMixSpacing.xs),
              Text(
                'Similar Tracks (${connections.length})',
                style: CartoMixTypography.badge.copyWith(
                  color: CartoMixColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: CartoMixSpacing.sm),
          if (connections.isEmpty)
            Text(
              'No similar tracks found above threshold',
              style: CartoMixTypography.caption.copyWith(
                color: CartoMixColors.textMuted,
              ),
            )
          else
            ...connections.take(10).map((conn) => _buildConnectionItem(conn.$1, conn.$2)),
        ],
      ),
    );
  }

  Widget _buildConnectionItem(Track track, double score) {
    final scoreColor = score >= 8.0
        ? CartoMixColors.success
        : score >= 6.0
            ? CartoMixColors.primary
            : CartoMixColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: CartoMixSpacing.sm),
      child: InkWell(
        onTap: () {
          ref.read(graphStateProvider.notifier).selectNode(track.id);
        },
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(CartoMixSpacing.sm),
          decoration: BoxDecoration(
            color: CartoMixColors.bgTertiary,
            borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: track.energyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
                ),
                child: Center(
                  child: Text(
                    '${track.energy ?? 5}',
                    style: CartoMixTypography.badge.copyWith(
                      color: track.energyColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CartoMixSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: CartoMixTypography.caption.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist,
                      style: CartoMixTypography.caption.copyWith(
                        color: CartoMixColors.textMuted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CartoMixSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  score.toStringAsFixed(1),
                  style: CartoMixTypography.badge.copyWith(
                    color: scoreColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CartoMixSpacing.sm,
        vertical: CartoMixSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(CartoMixSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textMuted,
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: CartoMixTypography.badge.copyWith(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CartoMixSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textMuted,
            ),
          ),
          Text(
            value,
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CartoMixSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: CartoMixSpacing.sm),
          Text(
            label,
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendNode() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CartoMixSpacing.xxs),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CartoMixColors.primary, width: 2),
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CartoMixColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(width: CartoMixSpacing.sm),
          Text(
            'In Set',
            style: CartoMixTypography.caption.copyWith(
              color: CartoMixColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
