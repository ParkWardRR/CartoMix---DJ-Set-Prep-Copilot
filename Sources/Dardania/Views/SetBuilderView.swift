// Dardania - Set Builder View

import SwiftUI
import DardaniaCore

struct SetBuilderView: View {
    @EnvironmentObject var appState: AppState
    @State private var setMode: SetMode = .peakTime
    @State private var selectedExportFormat: ExportFormat = .rekordbox
    @State private var isExporting = false
    @State private var selectedTransitionIndex: Int?

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Set list - left panel
                VStack(spacing: 0) {
                    SetToolbar(
                        setMode: $setMode,
                        trackCount: appState.setTracks.count,
                        onOptimize: optimizeSet,
                        onClear: clearSet
                    )

                    Divider()
                        .background(CartoMixColors.backgroundTertiary)

                    if appState.setTracks.isEmpty {
                        VStack(spacing: CartoMixSpacing.md) {
                            Image(systemName: "rectangle.stack")
                                .font(.system(size: 48))
                                .foregroundStyle(CartoMixColors.textTertiary)

                            Text("Empty Set")
                                .font(CartoMixTypography.headline)
                                .foregroundStyle(CartoMixColors.textPrimary)

                            Text("Drag tracks here or use + in Library")
                                .font(CartoMixTypography.body)
                                .foregroundStyle(CartoMixColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(appState.setTracks.enumerated()), id: \.element.id) { index, track in
                                    SetTrackRow(
                                        track: track,
                                        index: index,
                                        previousTrack: index > 0 ? appState.setTracks[index - 1] : nil,
                                        isSelected: appState.selectedTrack?.id == track.id
                                    )
                                    .onTapGesture {
                                        appState.selectedTrack = track
                                        selectedTransitionIndex = index > 0 ? index - 1 : nil
                                    }

                                    if index < appState.setTracks.count - 1 {
                                        Divider()
                                            .background(CartoMixColors.backgroundTertiary)
                                    }
                                }
                            }
                        }
                        .background(CartoMixColors.backgroundSecondary)
                    }

                    Divider()
                        .background(CartoMixColors.backgroundTertiary)

                    // Export panel
                    ExportPanel(
                        selectedFormat: $selectedExportFormat,
                        isExporting: $isExporting,
                        trackCount: appState.setTracks.count,
                        onExport: exportSet
                    )
                }
                .frame(width: max(geometry.size.width * 0.55, 400))
                .background(CartoMixColors.backgroundPrimary)

                Divider()
                    .background(CartoMixColors.backgroundTertiary)

                // Energy visualization - right panel
                VStack(alignment: .leading, spacing: 0) {
                    // Energy Journey header
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(CartoMixColors.accentOrange)
                        Text("Energy Journey")
                            .font(CartoMixTypography.headline)
                            .foregroundStyle(CartoMixColors.textPrimary)
                        Spacer()
                    }
                    .padding(CartoMixSpacing.md)
                    .background(CartoMixColors.backgroundSecondary)

                    if appState.setTracks.isEmpty {
                        VStack(spacing: CartoMixSpacing.md) {
                            Image(systemName: "waveform.path.ecg")
                                .font(.system(size: 40))
                                .foregroundStyle(CartoMixColors.textTertiary)
                            Text("Add tracks to see energy flow")
                                .font(CartoMixTypography.body)
                                .foregroundStyle(CartoMixColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: CartoMixSpacing.md) {
                                // Energy chart
                                EnergyJourneyView(tracks: energyTrackData)
                                    .frame(height: 160)
                                    .padding(.horizontal, CartoMixSpacing.md)

                                // Transition preview if two adjacent tracks selected
                                if let transitionData = currentTransitionData {
                                    TransitionPreviewView(
                                        trackA: transitionData.trackA,
                                        trackB: transitionData.trackB
                                    )
                                    .padding(.horizontal, CartoMixSpacing.md)
                                }

                                // Set stats at bottom
                                SetStatsView(tracks: appState.setTracks)
                                    .padding(CartoMixSpacing.md)
                            }
                            .padding(.vertical, CartoMixSpacing.md)
                        }
                    }
                }
                .frame(minWidth: 280)
                .background(CartoMixColors.backgroundPrimary)
            }
        }
        .background(CartoMixColors.backgroundPrimary)
        .navigationTitle("Set Builder")
    }

    // Convert Track array to EnergyTrackData for the chart
    private var energyTrackData: [EnergyTrackData] {
        appState.setTracks.compactMap { track in
            guard let analysis = track.analysis else { return nil }
            return EnergyTrackData(
                title: track.title,
                energy: analysis.energyGlobal,
                bpm: analysis.bpm,
                key: analysis.keyValue
            )
        }
    }

    // Generate transition preview data
    private var currentTransitionData: (trackA: TransitionTrackData, trackB: TransitionTrackData)? {
        guard let selectedTrack = appState.selectedTrack,
              let selectedIndex = appState.setTracks.firstIndex(where: { $0.id == selectedTrack.id }),
              selectedIndex > 0 else { return nil }

        let trackA = appState.setTracks[selectedIndex - 1]
        let trackB = appState.setTracks[selectedIndex]

        guard let analysisA = trackA.analysis, let analysisB = trackB.analysis else { return nil }

        let mockWaveform: [Float] = (0..<200).map { i in
            let t = Float(i) / 200
            return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
        }

        return (
            TransitionTrackData(
                title: trackA.title,
                artist: trackA.artist,
                bpm: analysisA.bpm,
                key: analysisA.keyValue,
                energy: analysisA.energyGlobal,
                waveform: analysisA.waveformPreview ?? mockWaveform
            ),
            TransitionTrackData(
                title: trackB.title,
                artist: trackB.artist,
                bpm: analysisB.bpm,
                key: analysisB.keyValue,
                energy: analysisB.energyGlobal,
                waveform: analysisB.waveformPreview ?? mockWaveform
            )
        )
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
        HStack(spacing: 12) {
            // Set mode picker
            Picker("Mode", selection: $setMode) {
                ForEach(SetMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 260)
            .fixedSize()

            Spacer()

            // Track count badge
            HStack(spacing: 4) {
                Image(systemName: "music.note.list")
                    .font(.caption)
                Text("\(trackCount) tracks")
                    .font(.system(.subheadline, design: .monospaced).weight(.medium))
            }
            .foregroundStyle(CartoMixColors.textSecondary)
            .fixedSize()

            // Action buttons
            HStack(spacing: 8) {
                Button(action: onOptimize) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Optimize")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(trackCount < 2)

                Button(action: onClear) {
                    Image(systemName: "trash")
                        .foregroundStyle(CartoMixColors.accentRed)
                }
                .buttonStyle(.plain)
                .disabled(trackCount == 0)
                .help("Clear all tracks")
            }
        }
        .padding(.horizontal, CartoMixSpacing.md)
        .padding(.vertical, CartoMixSpacing.sm)
        .background(CartoMixColors.backgroundSecondary)
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
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Section color indicator
            if let analysis = track.analysis {
                Rectangle()
                    .fill(CartoMixColors.colorForKey(analysis.keyValue))
                    .frame(width: 4)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }

            // Index with energy-based styling
            ZStack {
                Circle()
                    .fill(indexColor)
                    .frame(width: 28, height: 28)
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(CartoMixTypography.headline)
                    .foregroundStyle(CartoMixColors.textPrimary)
                    .lineLimit(1)

                Text(track.artist)
                    .font(CartoMixTypography.body)
                    .foregroundStyle(CartoMixColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Analysis badges using ColoredBadge
            if let analysis = track.analysis {
                BadgeRow(
                    bpm: analysis.bpm,
                    key: analysis.keyValue,
                    energy: analysis.energyGlobal,
                    size: .small,
                    spacing: 6
                )
            }

            // Transition indicator
            if let prev = previousTrack, let prevAnalysis = prev.analysis, let currAnalysis = track.analysis {
                TransitionInfoBadge(
                    bpmDelta: currAnalysis.bpm - prevAnalysis.bpm,
                    keyFrom: prevAnalysis.keyValue,
                    keyTo: currAnalysis.keyValue,
                    energyDelta: currAnalysis.energyGlobal - prevAnalysis.energyGlobal
                )
            }
        }
        .padding(.horizontal, CartoMixSpacing.md)
        .padding(.vertical, CartoMixSpacing.sm)
        .background(isSelected ? CartoMixColors.accentBlue.opacity(0.1) : .clear)
        .hoverHighlight()
    }

    private var indexColor: Color {
        guard let analysis = track.analysis else { return CartoMixColors.textTertiary }
        let energy = analysis.energyGlobal
        if energy <= 3 { return CartoMixColors.accentGreen }
        if energy <= 6 { return CartoMixColors.accentYellow }
        return CartoMixColors.accentOrange
    }
}

// MARK: - Transition Indicator (Legacy - kept for compatibility)

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
            .foregroundStyle(abs(bpmDelta) <= 3 ? CartoMixColors.accentGreen : (abs(bpmDelta) <= 6 ? CartoMixColors.accentYellow : CartoMixColors.accentRed))

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
        if fromKey == toKey { return CartoMixColors.accentGreen }
        return CartoMixColors.accentYellow
    }
}

// MARK: - Energy Arc View (Legacy - kept for compatibility)

struct EnergyArcView: View {
    let tracks: [Track]

    private var energyLevels: [Int] {
        tracks.compactMap { $0.analysis?.energyGlobal }
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawEnergyChart(context: context, size: size)
            }
        }
        .background(CartoMixColors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }

    private func drawEnergyChart(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        let padding: CGFloat = 40

        // Draw grid
        drawGrid(context: context, width: width, height: height, padding: padding)

        guard energyLevels.count >= 2 else { return }

        let stepX = (width - 2 * padding) / CGFloat(energyLevels.count - 1)

        // Build path
        let path = buildCurvePath(stepX: stepX, width: width, height: height, padding: padding)

        // Draw fill
        drawFill(context: context, path: path, width: width, height: height, padding: padding)

        // Draw stroke
        drawStroke(context: context, path: path, width: width)

        // Draw points
        drawPoints(context: context, stepX: stepX, width: width, height: height, padding: padding)
    }

    private func drawGrid(context: GraphicsContext, width: CGFloat, height: CGFloat, padding: CGFloat) {
        let gridColor = Color.gray.opacity(0.2)
        for i in 1...10 {
            let y = height - padding - (CGFloat(i) / 10 * (height - 2 * padding))
            var gridPath = Path()
            gridPath.move(to: CGPoint(x: padding, y: y))
            gridPath.addLine(to: CGPoint(x: width - padding, y: y))
            context.stroke(gridPath, with: .color(gridColor), lineWidth: 0.5)
        }
    }

    private func buildCurvePath(stepX: CGFloat, width: CGFloat, height: CGFloat, padding: CGFloat) -> Path {
        var path = Path()
        for (index, energy) in energyLevels.enumerated() {
            let x = padding + CGFloat(index) * stepX
            let normalizedEnergy = CGFloat(energy) / 10
            let y = height - padding - (normalizedEnergy * (height - 2 * padding))

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
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
        return path
    }

    private func drawFill(context: GraphicsContext, path: Path, width: CGFloat, height: CGFloat, padding: CGFloat) {
        var fillPath = path
        fillPath.addLine(to: CGPoint(x: width - padding, y: height - padding))
        fillPath.addLine(to: CGPoint(x: padding, y: height - padding))
        fillPath.closeSubpath()

        let fillGradient = Gradient(colors: [
            Color.orange.opacity(0.4),
            Color.red.opacity(0.2),
            Color.clear
        ])
        context.fill(
            fillPath,
            with: .linearGradient(
                fillGradient,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: height)
            )
        )
    }

    private func drawStroke(context: GraphicsContext, path: Path, width: CGFloat) {
        let strokeGradient = Gradient(colors: [Color.orange, Color.red, Color.purple])
        context.stroke(
            path,
            with: .linearGradient(
                strokeGradient,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: width, y: 0)
            ),
            lineWidth: 3
        )
    }

    private func drawPoints(context: GraphicsContext, stepX: CGFloat, width: CGFloat, height: CGFloat, padding: CGFloat) {
        for (index, energy) in energyLevels.enumerated() {
            let x = padding + CGFloat(index) * stepX
            let normalizedEnergy = CGFloat(energy) / 10
            let y = height - padding - (normalizedEnergy * (height - 2 * padding))

            // Glow
            let glow = Path(ellipseIn: CGRect(x: x - 8, y: y - 8, width: 16, height: 16))
            context.fill(glow, with: .color(Color.orange.opacity(0.3)))

            // Point
            let circle = Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
            context.fill(circle, with: .color(Color.orange))

            // Inner highlight
            let inner = Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
            context.fill(inner, with: .color(.white))
        }
    }
}

// MARK: - Set Stats View

struct SetStatsView: View {
    let tracks: [Track]

    var body: some View {
        HStack(spacing: CartoMixSpacing.lg) {
            StatBox(
                title: "Avg BPM",
                value: String(format: "%.1f", averageBPM),
                icon: "metronome",
                color: CartoMixColors.accentBlue
            )

            StatBox(
                title: "BPM Range",
                value: bpmRange,
                icon: "arrow.left.arrow.right",
                color: CartoMixColors.accentCyan
            )

            StatBox(
                title: "Avg Energy",
                value: String(format: "%.1f", averageEnergy),
                icon: "bolt.fill",
                color: CartoMixColors.accentOrange
            )

            StatBox(
                title: "Keys Used",
                value: "\(uniqueKeys)",
                icon: "music.note",
                color: CartoMixColors.accentGreen
            )
        }
        .padding(CartoMixSpacing.md)
        .background(CartoMixColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: CartoMixRadius.md))
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
    var color: Color = CartoMixColors.accentBlue

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(CartoMixColors.textPrimary)

            Text(title)
                .font(CartoMixTypography.caption)
                .foregroundStyle(CartoMixColors.textSecondary)
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
        HStack(spacing: 12) {
            // Format picker with fixed size
            HStack(spacing: 8) {
                Text("Format")
                    .font(CartoMixTypography.caption)
                    .foregroundStyle(CartoMixColors.textTertiary)

                Menu {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button {
                            selectedFormat = format
                        } label: {
                            Label(format.rawValue, systemImage: format.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedFormat.icon)
                        Text(selectedFormat.rawValue)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(CartoMixColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(CartoMixColors.backgroundTertiary, in: RoundedRectangle(cornerRadius: CartoMixRadius.sm))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            Spacer()

            // Track count indicator
            if trackCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CartoMixColors.accentGreen)
                    Text("\(trackCount) ready")
                        .font(CartoMixTypography.caption)
                        .foregroundStyle(CartoMixColors.textSecondary)
                }
                .fixedSize()
            }

            // Export button
            Button(action: onExport) {
                if isExporting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(trackCount == 0 || isExporting)
        }
        .padding(.horizontal, CartoMixSpacing.md)
        .padding(.vertical, CartoMixSpacing.sm)
        .background(CartoMixColors.backgroundSecondary)
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
