// Dardania - Set Builder View

import SwiftUI
import DardaniaCore

struct SetBuilderView: View {
    @EnvironmentObject var appState: AppState
    @State private var setMode: SetMode = .peakTime
    @State private var selectedExportFormat: ExportFormat = .rekordbox
    @State private var isExporting = false

    var body: some View {
        HSplitView {
            // Set list
            VStack(spacing: 0) {
                SetToolbar(
                    setMode: $setMode,
                    trackCount: appState.setTracks.count,
                    onOptimize: optimizeSet,
                    onClear: clearSet
                )

                Divider()

                if appState.setTracks.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.stack",
                        title: "Empty Set",
                        subtitle: "Drag tracks here or use the + button in Library"
                    )
                } else {
                    List {
                        ForEach(Array(appState.setTracks.enumerated()), id: \.element.id) { index, track in
                            SetTrackRow(
                                track: track,
                                index: index,
                                previousTrack: index > 0 ? appState.setTracks[index - 1] : nil
                            )
                            .onTapGesture {
                                appState.selectedTrack = track
                            }
                        }
                        .onMove { from, to in
                            appState.reorderSet(from: from, to: to)
                        }
                        .onDelete { indices in
                            for index in indices {
                                appState.removeFromSet(appState.setTracks[index])
                            }
                        }
                    }
                    .listStyle(.inset)
                }

                Divider()

                // Export panel
                ExportPanel(
                    selectedFormat: $selectedExportFormat,
                    isExporting: $isExporting,
                    trackCount: appState.setTracks.count,
                    onExport: exportSet
                )
            }
            .frame(minWidth: 400)

            // Energy Arc visualization
            VStack {
                Text("Set Energy Flow")
                    .font(.headline)
                    .padding()

                if appState.setTracks.isEmpty {
                    EmptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "No Data",
                        subtitle: "Add tracks to see energy flow"
                    )
                } else {
                    EnergyArcView(tracks: appState.setTracks)
                        .padding()
                }

                Spacer()

                // Set stats
                SetStatsView(tracks: appState.setTracks)
                    .padding()
            }
            .frame(minWidth: 300)
        }
        .navigationTitle("Set Builder")
    }

    private func optimizeSet() {
        // TODO: Implement set optimization using planner
    }

    private func clearSet() {
        appState.setTracks.removeAll()
    }

    private func exportSet() {
        isExporting = true
        Task {
            defer { isExporting = false }
            // TODO: Implement export
        }
    }
}

// MARK: - Set Toolbar

struct SetToolbar: View {
    @Binding var setMode: SetMode
    let trackCount: Int
    let onOptimize: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Set mode picker
            Picker("Mode", selection: $setMode) {
                ForEach(SetMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)

            Spacer()

            Text("\(trackCount) tracks")
                .foregroundStyle(.secondary)

            if let duration = totalDuration {
                Text(formatDuration(duration))
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 20)

            Button("Optimize", action: onOptimize)
                .disabled(trackCount < 2)

            Button("Clear", role: .destructive, action: onClear)
                .disabled(trackCount == 0)
        }
        .padding()
    }

    private var totalDuration: Double? {
        // Would calculate from tracks
        nil
    }

    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        return hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
    }
}

enum SetMode: String, CaseIterable {
    case warmUp = "Warm-up"
    case peakTime = "Peak Time"
    case openFormat = "Open Format"
}

// MARK: - Set Track Row

struct SetTrackRow: View {
    let track: Track
    let index: Int
    let previousTrack: Track?

    var body: some View {
        HStack(spacing: 12) {
            // Index
            Text("\(index + 1)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 30)

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(track.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Analysis badges
            if let analysis = track.analysis {
                HStack(spacing: 8) {
                    AnalysisBadge(
                        icon: "metronome",
                        value: String(format: "%.0f", analysis.bpm),
                        color: .blue
                    )

                    AnalysisBadge(
                        icon: "music.note",
                        value: analysis.keyValue,
                        color: .purple
                    )
                }
            }

            // Transition indicator
            if let prev = previousTrack, let prevAnalysis = prev.analysis, let currAnalysis = track.analysis {
                TransitionIndicator(
                    fromBPM: prevAnalysis.bpm,
                    toBPM: currAnalysis.bpm,
                    fromKey: prevAnalysis.keyValue,
                    toKey: currAnalysis.keyValue
                )
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Transition Indicator

struct TransitionIndicator: View {
    let fromBPM: Double
    let toBPM: Double
    let fromKey: String
    let toKey: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // BPM delta
            let bpmDelta = toBPM - fromBPM
            HStack(spacing: 2) {
                Image(systemName: bpmDelta >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption2)
                Text(String(format: "%.1f", abs(bpmDelta)))
                    .font(.caption.monospacedDigit())
            }
            .foregroundStyle(abs(bpmDelta) <= 3 ? .green : (abs(bpmDelta) <= 6 ? .yellow : .red))

            // Key compatibility
            Text(keyRelation)
                .font(.caption2)
                .foregroundStyle(keyColor)
        }
        .frame(width: 60)
    }

    private var keyRelation: String {
        if fromKey == toKey { return "same" }
        // Simplified - would use full Camelot logic
        return "compatible"
    }

    private var keyColor: Color {
        if fromKey == toKey { return .green }
        return .yellow
    }
}

// MARK: - Energy Arc View

struct EnergyArcView: View {
    let tracks: [Track]

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let padding: CGFloat = 40

                // Draw grid
                for i in 1...10 {
                    let y = height - padding - (CGFloat(i) / 10 * (height - 2 * padding))
                    var gridPath = Path()
                    gridPath.move(to: CGPoint(x: padding, y: y))
                    gridPath.addLine(to: CGPoint(x: width - padding, y: y))
                    context.stroke(gridPath, with: .color(.gray.opacity(0.2)), lineWidth: 1)
                }

                // Draw energy curve
                let energyLevels = tracks.compactMap { $0.analysis?.energyGlobal }
                guard energyLevels.count >= 2 else { return }

                let stepX = (width - 2 * padding) / CGFloat(energyLevels.count - 1)

                var path = Path()
                for (index, energy) in energyLevels.enumerated() {
                    let x = padding + CGFloat(index) * stepX
                    let normalizedEnergy = CGFloat(energy) / 10
                    let y = height - padding - (normalizedEnergy * (height - 2 * padding))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        // Use curve for smoother line
                        let prevX = padding + CGFloat(index - 1) * stepX
                        let prevEnergy = CGFloat(energyLevels[index - 1]) / 10
                        let prevY = height - padding - (prevEnergy * (height - 2 * padding))
                        let controlX = (prevX + x) / 2
                        path.addCurve(
                            to: CGPoint(x: x, y: y),
                            control1: CGPoint(x: controlX, y: prevY),
                            control2: CGPoint(x: controlX, y: y)
                        )
                    }
                }

                // Draw gradient fill
                var fillPath = path
                fillPath.addLine(to: CGPoint(x: width - padding, y: height - padding))
                fillPath.addLine(to: CGPoint(x: padding, y: height - padding))
                fillPath.closeSubpath()

                let gradient = Gradient(colors: [
                    .orange.opacity(0.5),
                    .red.opacity(0.3),
                    .purple.opacity(0.1)
                ])
                context.fill(
                    fillPath,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: 0, y: height)
                    )
                )

                // Draw line
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [.orange, .red, .purple]),
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: width, y: 0)
                    ),
                    lineWidth: 3
                )

                // Draw points
                for (index, energy) in energyLevels.enumerated() {
                    let x = padding + CGFloat(index) * stepX
                    let normalizedEnergy = CGFloat(energy) / 10
                    let y = height - padding - (normalizedEnergy * (height - 2 * padding))

                    let circle = Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
                    context.fill(circle, with: .color(.white))
                    context.stroke(circle, with: .color(.orange), lineWidth: 2)
                }
            }
        }
    }
}

// MARK: - Set Stats View

struct SetStatsView: View {
    let tracks: [Track]

    var body: some View {
        HStack(spacing: 24) {
            StatBox(
                title: "Avg BPM",
                value: String(format: "%.1f", averageBPM),
                icon: "metronome"
            )

            StatBox(
                title: "BPM Range",
                value: bpmRange,
                icon: "arrow.left.arrow.right"
            )

            StatBox(
                title: "Avg Energy",
                value: String(format: "%.1f", averageEnergy),
                icon: "bolt.fill"
            )

            StatBox(
                title: "Keys Used",
                value: "\(uniqueKeys)",
                icon: "music.note"
            )
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var averageBPM: Double {
        let bpms = tracks.compactMap { $0.analysis?.bpm }
        guard !bpms.isEmpty else { return 0 }
        return bpms.reduce(0, +) / Double(bpms.count)
    }

    private var bpmRange: String {
        let bpms = tracks.compactMap { $0.analysis?.bpm }
        guard let min = bpms.min(), let max = bpms.max() else { return "-" }
        return "\(Int(min))-\(Int(max))"
    }

    private var averageEnergy: Double {
        let energies = tracks.compactMap { $0.analysis?.energyGlobal }
        guard !energies.isEmpty else { return 0 }
        return Double(energies.reduce(0, +)) / Double(energies.count)
    }

    private var uniqueKeys: Int {
        Set(tracks.compactMap { $0.analysis?.keyValue }).count
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.bold().monospacedDigit())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Export Panel

struct ExportPanel: View {
    @Binding var selectedFormat: ExportFormat
    @Binding var isExporting: Bool
    let trackCount: Int
    let onExport: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Picker("Format", selection: $selectedFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Label(format.rawValue, systemImage: format.icon).tag(format)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)

            Spacer()

            Button(action: onExport) {
                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Export Set", systemImage: "square.and.arrow.up")
                }
            }
            .disabled(trackCount == 0 || isExporting)
        }
        .padding()
    }
}

enum ExportFormat: String, CaseIterable {
    case rekordbox = "Rekordbox"
    case serato = "Serato"
    case traktor = "Traktor"
    case json = "JSON"
    case m3u = "M3U"

    var icon: String {
        switch self {
        case .rekordbox: return "r.circle"
        case .serato: return "s.circle"
        case .traktor: return "t.circle"
        case .json: return "curlybraces"
        case .m3u: return "list.bullet"
        }
    }
}

// Preview commented out for SPM compatibility
// #Preview {
//     SetBuilderView()
//         .environmentObject(AppState())
//         .frame(width: 1000, height: 700)
// }
