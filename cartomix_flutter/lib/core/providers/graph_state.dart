import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import 'app_state.dart';

/// Node in the force-directed graph
class GraphNode {
  final Track track;
  Offset position;
  Offset velocity;
  bool isDragging;
  bool isSelected;

  GraphNode({
    required this.track,
    required this.position,
    this.velocity = Offset.zero,
    this.isDragging = false,
    this.isSelected = false,
  });

  GraphNode copyWith({
    Track? track,
    Offset? position,
    Offset? velocity,
    bool? isDragging,
    bool? isSelected,
  }) {
    return GraphNode(
      track: track ?? this.track,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      isDragging: isDragging ?? this.isDragging,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Edge in the force-directed graph
class GraphEdge {
  final int sourceId;
  final int targetId;
  final double score;

  const GraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.score,
  });
}

/// Graph state containing all nodes and edges
class GraphState {
  final Map<int, GraphNode> nodes;
  final List<GraphEdge> edges;
  final double minScoreThreshold;
  final bool showSetOnly;
  final int? selectedNodeId;
  final double zoom;
  final Offset pan;
  final bool isSimulating;

  const GraphState({
    this.nodes = const {},
    this.edges = const [],
    this.minScoreThreshold = 6.0,
    this.showSetOnly = false,
    this.selectedNodeId,
    this.zoom = 1.0,
    this.pan = Offset.zero,
    this.isSimulating = true,
  });

  GraphState copyWith({
    Map<int, GraphNode>? nodes,
    List<GraphEdge>? edges,
    double? minScoreThreshold,
    bool? showSetOnly,
    int? selectedNodeId,
    bool clearSelection = false,
    double? zoom,
    Offset? pan,
    bool? isSimulating,
  }) {
    return GraphState(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      minScoreThreshold: minScoreThreshold ?? this.minScoreThreshold,
      showSetOnly: showSetOnly ?? this.showSetOnly,
      selectedNodeId: clearSelection ? null : (selectedNodeId ?? this.selectedNodeId),
      zoom: zoom ?? this.zoom,
      pan: pan ?? this.pan,
      isSimulating: isSimulating ?? this.isSimulating,
    );
  }

  /// Get visible edges based on current threshold
  List<GraphEdge> get visibleEdges =>
      edges.where((e) => e.score >= minScoreThreshold).toList();

  /// Get visible nodes based on showSetOnly filter
  List<GraphNode> visibleNodes(List<int> setTrackIds) {
    if (!showSetOnly) return nodes.values.toList();
    return nodes.values.where((n) => setTrackIds.contains(n.track.id)).toList();
  }

  /// Calculate graph statistics
  int get nodeCount => nodes.length;
  int get edgeCount => visibleEdges.length;
  double? get avgScore {
    final visible = visibleEdges;
    if (visible.isEmpty) return null;
    return visible.map((e) => e.score).reduce((a, b) => a + b) / visible.length;
  }
}

/// Notifier for graph state
class GraphStateNotifier extends StateNotifier<GraphState> {
  final Random _random = Random();

  GraphStateNotifier() : super(const GraphState());

  /// Initialize graph with tracks and similarities
  void initializeGraph(List<Track> tracks, List<TrackSimilarity> similarities) {
    final nodes = <int, GraphNode>{};
    final edges = <GraphEdge>[];

    // Create nodes with random initial positions
    for (final track in tracks) {
      final angle = _random.nextDouble() * 2 * pi;
      final radius = 100 + _random.nextDouble() * 200;
      nodes[track.id] = GraphNode(
        track: track,
        position: Offset(
          cos(angle) * radius,
          sin(angle) * radius,
        ),
      );
    }

    // Create edges from similarities
    for (final sim in similarities) {
      if (nodes.containsKey(sim.trackIdA) && nodes.containsKey(sim.trackIdB)) {
        edges.add(GraphEdge(
          sourceId: sim.trackIdA,
          targetId: sim.trackIdB,
          score: sim.score,
        ));
      }
    }

    state = state.copyWith(
      nodes: nodes,
      edges: edges,
      isSimulating: true,
    );
  }

  /// Update node positions for physics simulation
  void simulateStep(Size canvasSize) {
    if (!state.isSimulating || state.nodes.isEmpty) return;

    final nodes = Map<int, GraphNode>.from(state.nodes);
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    // Physics constants
    const repulsionStrength = 5000.0;
    const attractionStrength = 0.01;
    const damping = 0.85;
    const centerGravity = 0.01;

    // Calculate forces for each node
    for (final nodeId in nodes.keys) {
      if (nodes[nodeId]!.isDragging) continue;

      var force = Offset.zero;
      final node = nodes[nodeId]!;

      // Repulsion from other nodes
      for (final otherId in nodes.keys) {
        if (otherId == nodeId) continue;
        final other = nodes[otherId]!;
        final delta = node.position - other.position;
        final distance = delta.distance.clamp(20.0, 500.0);
        force += delta / distance * (repulsionStrength / (distance * distance));
      }

      // Attraction along edges
      for (final edge in state.visibleEdges) {
        int? otherId;
        if (edge.sourceId == nodeId) {
          otherId = edge.targetId;
        } else if (edge.targetId == nodeId) {
          otherId = edge.sourceId;
        }
        if (otherId != null && nodes.containsKey(otherId)) {
          final other = nodes[otherId]!;
          final delta = other.position - node.position;
          // Stronger attraction for higher scores
          final strength = attractionStrength * (edge.score / 10.0);
          force += delta * strength;
        }
      }

      // Gravity toward center
      final toCenter = center - node.position;
      force += toCenter * centerGravity;

      // Apply force with damping
      final newVelocity = (node.velocity + force) * damping;
      final newPosition = node.position + newVelocity;

      nodes[nodeId] = node.copyWith(
        position: newPosition,
        velocity: newVelocity,
      );
    }

    state = state.copyWith(nodes: nodes);
  }

  /// Stop simulation
  void stopSimulation() {
    state = state.copyWith(isSimulating: false);
  }

  /// Start simulation
  void startSimulation() {
    state = state.copyWith(isSimulating: true);
  }

  /// Update minimum score threshold
  void setMinScoreThreshold(double value) {
    state = state.copyWith(minScoreThreshold: value);
  }

  /// Toggle show set only
  void setShowSetOnly(bool value) {
    state = state.copyWith(showSetOnly: value);
  }

  /// Select a node
  void selectNode(int? nodeId) {
    if (nodeId == null) {
      state = state.copyWith(clearSelection: true);
    } else {
      // Update selection state in nodes
      final nodes = Map<int, GraphNode>.from(state.nodes);
      for (final id in nodes.keys) {
        nodes[id] = nodes[id]!.copyWith(isSelected: id == nodeId);
      }
      state = state.copyWith(nodes: nodes, selectedNodeId: nodeId);
    }
  }

  /// Start dragging a node
  void startDragging(int nodeId) {
    final nodes = Map<int, GraphNode>.from(state.nodes);
    if (nodes.containsKey(nodeId)) {
      nodes[nodeId] = nodes[nodeId]!.copyWith(isDragging: true);
      state = state.copyWith(nodes: nodes);
    }
  }

  /// Update dragging position
  void updateDragPosition(int nodeId, Offset position) {
    final nodes = Map<int, GraphNode>.from(state.nodes);
    if (nodes.containsKey(nodeId)) {
      nodes[nodeId] = nodes[nodeId]!.copyWith(
        position: position,
        velocity: Offset.zero,
      );
      state = state.copyWith(nodes: nodes);
    }
  }

  /// Stop dragging a node
  void stopDragging(int nodeId) {
    final nodes = Map<int, GraphNode>.from(state.nodes);
    if (nodes.containsKey(nodeId)) {
      nodes[nodeId] = nodes[nodeId]!.copyWith(isDragging: false);
      state = state.copyWith(nodes: nodes);
    }
  }

  /// Update zoom level
  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom.clamp(0.25, 4.0));
  }

  /// Update pan offset
  void setPan(Offset pan) {
    state = state.copyWith(pan: pan);
  }

  /// Reset view to center
  void resetView() {
    state = state.copyWith(zoom: 1.0, pan: Offset.zero);
  }

  /// Clear the graph
  void clear() {
    state = const GraphState();
  }
}

/// Provider for graph state
final graphStateProvider =
    StateNotifierProvider<GraphStateNotifier, GraphState>((ref) {
  return GraphStateNotifier();
});

/// Provider for similarities (mock data for now, will be connected to native backend)
final similaritiesProvider = Provider<List<TrackSimilarity>>((ref) {
  final tracksAsync = ref.watch(tracksProvider);

  return tracksAsync.when(
    data: (tracks) {
      if (tracks.length < 2) return [];

      // Generate mock similarities based on BPM and energy proximity
      final similarities = <TrackSimilarity>[];
      final random = Random(42); // Seeded for consistency

      for (int i = 0; i < tracks.length; i++) {
        for (int j = i + 1; j < tracks.length; j++) {
          final trackA = tracks[i];
          final trackB = tracks[j];

          // Calculate similarity based on BPM and energy proximity
          double score = 5.0; // Base score

          // BPM similarity (if both have BPM)
          if (trackA.bpm != null && trackB.bpm != null) {
            final bpmDiff = (trackA.bpm! - trackB.bpm!).abs();
            if (bpmDiff < 5) {
              score += 2.5;
            } else if (bpmDiff < 10) {
              score += 1.5;
            } else if (bpmDiff < 20) {
              score += 0.5;
            }
          }

          // Energy similarity (if both have energy)
          if (trackA.energy != null && trackB.energy != null) {
            final energyDiff = (trackA.energy! - trackB.energy!).abs();
            if (energyDiff < 2) {
              score += 2.0;
            } else if (energyDiff < 4) {
              score += 1.0;
            }
          }

          // Add some randomness for demo purposes
          score += (random.nextDouble() - 0.5) * 2;
          score = score.clamp(0.0, 10.0);

          // Only include similarities above a minimum threshold
          if (score >= 4.0) {
            similarities.add(TrackSimilarity(
              trackIdA: trackA.id,
              trackIdB: trackB.id,
              score: score,
            ));
          }
        }
      }

      return similarities;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for selected track in graph
final selectedGraphTrackProvider = Provider<Track?>((ref) {
  final graphState = ref.watch(graphStateProvider);
  if (graphState.selectedNodeId == null) return null;
  final node = graphState.nodes[graphState.selectedNodeId];
  return node?.track;
});

/// Provider for connections of selected track
final selectedTrackConnectionsProvider = Provider<List<(Track, double)>>((ref) {
  final graphState = ref.watch(graphStateProvider);
  if (graphState.selectedNodeId == null) return [];

  final connections = <(Track, double)>[];
  for (final edge in graphState.visibleEdges) {
    int? otherId;
    if (edge.sourceId == graphState.selectedNodeId) {
      otherId = edge.targetId;
    } else if (edge.targetId == graphState.selectedNodeId) {
      otherId = edge.sourceId;
    }
    if (otherId != null && graphState.nodes.containsKey(otherId)) {
      connections.add((graphState.nodes[otherId]!.track, edge.score));
    }
  }

  // Sort by score descending
  connections.sort((a, b) => b.$2.compareTo(a.$2));
  return connections;
});
