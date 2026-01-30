// Dardania - Transition Graph View

import SwiftUI
import DardaniaCore

struct TransitionGraphView: View {
    @EnvironmentObject var appState: AppState
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var selectedNode: Track?
    @State private var showOnlySet = false
    @State private var minSimilarity: Double = 0.5

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            GraphToolbar(
                showOnlySet: $showOnlySet,
                minSimilarity: $minSimilarity,
                nodeCount: displayTracks.count,
                onResetView: resetView
            )

            Divider()

            // Graph canvas
            ZStack {
                if displayTracks.isEmpty {
                    EmptyStateView(
                        icon: "point.3.connected.trianglepath.dotted",
                        title: "No Tracks",
                        subtitle: "Add analyzed tracks to see the transition graph"
                    )
                } else {
                    ForceDirectedGraphView(
                        tracks: displayTracks,
                        selectedNode: $selectedNode,
                        scale: $scale,
                        offset: $offset,
                        minSimilarity: minSimilarity
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.05))
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.5, min(3.0, value))
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    }
            )

            // Info panel
            if let node = selectedNode {
                GraphInfoPanel(track: node)
            }
        }
        .navigationTitle("Transition Graph")
        .onChange(of: selectedNode) { _, newValue in
            if let track = newValue {
                appState.selectedTrack = track
            }
        }
    }

    private var displayTracks: [Track] {
        let tracks = showOnlySet ? appState.setTracks : appState.tracks
        return tracks.filter { $0.analysis != nil }
    }

    private func resetView() {
        withAnimation(.spring()) {
            scale = 1.0
            offset = .zero
        }
    }
}

// MARK: - Graph Toolbar

struct GraphToolbar: View {
    @Binding var showOnlySet: Bool
    @Binding var minSimilarity: Double
    let nodeCount: Int
    let onResetView: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Toggle("Show Set Only", isOn: $showOnlySet)
                .toggleStyle(.switch)

            Divider()
                .frame(height: 20)

            HStack {
                Text("Min Similarity:")
                Slider(value: $minSimilarity, in: 0.3...0.9, step: 0.1)
                    .frame(width: 100)
                Text(String(format: "%.0f%%", minSimilarity * 100))
                    .monospacedDigit()
            }

            Spacer()

            Text("\(nodeCount) nodes")
                .foregroundStyle(.secondary)

            Button("Reset View", action: onResetView)
        }
        .padding()
    }
}

// MARK: - Force Directed Graph

struct ForceDirectedGraphView: View {
    let tracks: [Track]
    @Binding var selectedNode: Track?
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    let minSimilarity: Double

    @State private var nodePositions: [Int64: CGPoint] = [:]
    @State private var isDraggingNode: Int64?

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Edges (connections)
                ForEach(edges, id: \.id) { edge in
                    EdgeView(edge: edge, positions: nodePositions)
                }

                // Nodes
                ForEach(tracks) { track in
                    NodeView(
                        track: track,
                        isSelected: selectedNode?.id == track.id,
                        position: nodePositions[track.id] ?? center
                    )
                    .onTapGesture {
                        selectedNode = track
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingNode = track.id
                                nodePositions[track.id] = value.location
                            }
                            .onEnded { _ in
                                isDraggingNode = nil
                            }
                    )
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .onAppear {
                initializePositions(center: center, size: geometry.size)
            }
        }
    }

    private func initializePositions(center: CGPoint, size: CGSize) {
        let radius = min(size.width, size.height) * 0.35

        for (index, track) in tracks.enumerated() {
            let angle = (Double(index) / Double(tracks.count)) * 2 * .pi
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            nodePositions[track.id] = CGPoint(x: x, y: y)
        }
    }

    private var edges: [GraphEdge] {
        var result: [GraphEdge] = []

        for i in 0..<tracks.count {
            for j in (i + 1)..<tracks.count {
                let trackA = tracks[i]
                let trackB = tracks[j]

                // Calculate similarity (simplified)
                guard let analysisA = trackA.analysis,
                      let analysisB = trackB.analysis else { continue }

                let bpmSimilarity = 1.0 - min(abs(analysisA.bpm - analysisB.bpm) / 20.0, 1.0)
                let keySimilarity = analysisA.keyValue == analysisB.keyValue ? 1.0 : 0.5
                let energySimilarity = 1.0 - abs(Double(analysisA.energyGlobal - analysisB.energyGlobal)) / 10.0

                let similarity = (bpmSimilarity * 0.4 + keySimilarity * 0.4 + energySimilarity * 0.2)

                if similarity >= minSimilarity {
                    result.append(GraphEdge(
                        id: "\(trackA.id)-\(trackB.id)",
                        fromId: trackA.id,
                        toId: trackB.id,
                        similarity: similarity
                    ))
                }
            }
        }

        return result
    }
}

struct GraphEdge: Identifiable {
    let id: String
    let fromId: Int64
    let toId: Int64
    let similarity: Double
}

// MARK: - Edge View

struct EdgeView: View {
    let edge: GraphEdge
    let positions: [Int64: CGPoint]

    var body: some View {
        if let from = positions[edge.fromId], let to = positions[edge.toId] {
            Path { path in
                path.move(to: from)
                path.addLine(to: to)
            }
            .stroke(
                edgeColor.opacity(edge.similarity),
                lineWidth: CGFloat(edge.similarity * 3)
            )
        }
    }

    private var edgeColor: Color {
        switch edge.similarity {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        default: return .orange
        }
    }
}

// MARK: - Node View

struct NodeView: View {
    let track: Track
    let isSelected: Bool
    let position: CGPoint

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(nodeColor)
                .frame(width: nodeSize, height: nodeSize)
                .overlay {
                    if let analysis = track.analysis {
                        Text("\(analysis.energyGlobal)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: isSelected ? .accentColor : .clear, radius: 8)

            Text(track.title)
                .font(.caption2)
                .lineLimit(1)
                .frame(maxWidth: 80)
        }
        .position(position)
    }

    private var nodeSize: CGFloat {
        guard let analysis = track.analysis else { return 30 }
        return 20 + CGFloat(analysis.energyGlobal) * 3
    }

    private var nodeColor: Color {
        guard let analysis = track.analysis else { return .gray }
        let energy = Double(analysis.energyGlobal) / 10.0
        return Color(
            hue: 0.1 - energy * 0.1,
            saturation: 0.8,
            brightness: 0.8 + energy * 0.2
        )
    }
}

// MARK: - Graph Info Panel

struct GraphInfoPanel: View {
    let track: Track

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if let analysis = track.analysis {
                HStack(spacing: 16) {
                    InfoItem(label: "BPM", value: String(format: "%.1f", analysis.bpm))
                    InfoItem(label: "Key", value: analysis.keyValue)
                    InfoItem(label: "Energy", value: "\(analysis.energyGlobal)/10")
                }
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }
}

struct InfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// Preview commented out for SPM compatibility
// #Preview {
//     TransitionGraphView()
//         .environmentObject(AppState())
//         .frame(width: 800, height: 600)
// }
