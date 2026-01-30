// Dardania - Library View

import SwiftUI
import DardaniaCore

struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .title
    @State private var filterKey: String?
    @State private var bpmRange: ClosedRange<Double> = 60...200

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            LibraryToolbar(
                searchText: $searchText,
                sortOrder: $sortOrder,
                filterKey: $filterKey,
                bpmRange: $bpmRange,
                trackCount: filteredTracks.count,
                onAnalyzeAll: analyzeAllUnanalyzed
            )

            Divider()
                .background(CartoMixColors.backgroundTertiary)

            // Track Grid
            if filteredTracks.isEmpty {
                EmptyStateView(
                    icon: "music.note.list",
                    title: searchText.isEmpty ? "No Tracks" : "No Results",
                    subtitle: searchText.isEmpty
                        ? "Add a music folder to get started"
                        : "Try adjusting your search or filters"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(filteredTracks) { track in
                            TrackCard(track: track)
                                .onTapGesture {
                                    appState.selectedTrack = track
                                }
                                .contextMenu {
                                    TrackContextMenu(track: track)
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(CartoMixColors.backgroundPrimary)
        .navigationTitle("Library")
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 12)]
    }

    private var filteredTracks: [Track] {
        var tracks = appState.tracks

        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            tracks = tracks.filter {
                $0.title.lowercased().contains(query) ||
                $0.artist.lowercased().contains(query) ||
                ($0.analysis?.keyValue ?? "").lowercased().contains(query)
            }
        }

        // Key filter
        if let key = filterKey {
            tracks = tracks.filter { $0.analysis?.keyValue == key }
        }

        // BPM filter
        tracks = tracks.filter {
            guard let bpm = $0.analysis?.bpm else { return true }
            return bpmRange.contains(bpm)
        }

        // Sort
        switch sortOrder {
        case .title:
            tracks.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .artist:
            tracks.sort { $0.artist.localizedCompare($1.artist) == .orderedAscending }
        case .bpm:
            tracks.sort { ($0.analysis?.bpm ?? 0) < ($1.analysis?.bpm ?? 0) }
        case .key:
            tracks.sort { ($0.analysis?.keyValue ?? "") < ($1.analysis?.keyValue ?? "") }
        case .energy:
            tracks.sort { ($0.analysis?.energyGlobal ?? 0) < ($1.analysis?.energyGlobal ?? 0) }
        case .dateAdded:
            tracks.sort { $0.createdAt > $1.createdAt }
        }

        return tracks
    }

    private func analyzeAllUnanalyzed() {
        let unanalyzed = appState.tracks.filter { $0.analysis == nil }
        for track in unanalyzed {
            Task {
                await appState.analyzeTrack(track)
            }
        }
    }
}

// MARK: - Library Toolbar

struct LibraryToolbar: View {
    @Binding var searchText: String
    @Binding var sortOrder: SortOrder
    @Binding var filterKey: String?
    @Binding var bpmRange: ClosedRange<Double>
    let trackCount: Int
    let onAnalyzeAll: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Main toolbar row
            HStack(spacing: 12) {
                // Search field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(CartoMixColors.textTertiary)
                    TextField("Search tracks...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(CartoMixColors.textPrimary)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(CartoMixColors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(CartoMixColors.backgroundTertiary, in: RoundedRectangle(cornerRadius: CartoMixRadius.sm))
                .frame(minWidth: 180, maxWidth: 280)

                Spacer()

                // Track count badge
                HStack(spacing: 4) {
                    Image(systemName: "music.note.list")
                        .font(.caption)
                    Text("\(trackCount)")
                        .font(.system(.subheadline, design: .monospaced).weight(.medium))
                }
                .foregroundStyle(CartoMixColors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(CartoMixColors.backgroundTertiary, in: Capsule())

                // Sort menu
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOrder.rawValue)
                            .lineLimit(1)
                    }
                    .font(.subheadline)
                    .foregroundStyle(CartoMixColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(CartoMixColors.backgroundTertiary, in: RoundedRectangle(cornerRadius: CartoMixRadius.sm))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // BPM filter menu
                Menu {
                    Button("All BPMs") { bpmRange = 60...200 }
                    Divider()
                    Button("60-90 BPM") { bpmRange = 60...90 }
                    Button("90-120 BPM") { bpmRange = 90...120 }
                    Button("120-140 BPM") { bpmRange = 120...140 }
                    Button("140-180 BPM") { bpmRange = 140...180 }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "metronome")
                        if bpmRange != 60...200 {
                            Text("\(Int(bpmRange.lowerBound))-\(Int(bpmRange.upperBound))")
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(bpmRange != 60...200 ? CartoMixColors.accentBlue : CartoMixColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(CartoMixColors.backgroundTertiary, in: RoundedRectangle(cornerRadius: CartoMixRadius.sm))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // Analyze All button
                Button(action: onAnalyzeAll) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.badge.plus")
                        Text("Analyze")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, CartoMixSpacing.md)
            .padding(.vertical, CartoMixSpacing.sm)
        }
        .background(CartoMixColors.backgroundSecondary)
    }
}

enum SortOrder: String, CaseIterable {
    case title = "Title"
    case artist = "Artist"
    case bpm = "BPM"
    case key = "Key"
    case energy = "Energy"
    case dateAdded = "Date Added"
}

// MARK: - Track Card

struct TrackCard: View {
    let track: Track
    @EnvironmentObject var appState: AppState
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Waveform preview with gradient
            ZStack {
                if let waveform = track.analysis?.waveformPreview {
                    CompactWaveformView(samples: waveform)
                } else {
                    Rectangle()
                        .fill(CartoMixColors.backgroundTertiary)
                        .overlay {
                            Image(systemName: "waveform")
                                .font(.title)
                                .foregroundStyle(CartoMixColors.textTertiary)
                        }
                }

                // Overlay controls
                if isHovered {
                    HStack(spacing: 8) {
                        Button {
                            appState.addToSet(track)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(CartoMixColors.accentGreen)
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task {
                                await appState.analyzeTrack(track)
                            }
                        } label: {
                            Image(systemName: "waveform.badge.plus")
                                .font(.title2)
                                .foregroundStyle(CartoMixColors.accentBlue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(CartoMixColors.backgroundSecondary.opacity(0.9), in: RoundedRectangle(cornerRadius: CartoMixRadius.sm))
                }
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.sm))

            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(CartoMixTypography.headline)
                    .foregroundStyle(CartoMixColors.textPrimary)
                    .lineLimit(1)

                Text(track.artist)
                    .font(CartoMixTypography.body)
                    .foregroundStyle(CartoMixColors.textSecondary)
                    .lineLimit(1)
            }

            // Analysis badges using ColoredBadge
            if let analysis = track.analysis {
                HStack(spacing: 6) {
                    ColoredBadge.bpm(analysis.bpm, size: .small)
                    ColoredBadge.key(analysis.keyValue, size: .small)
                    ColoredBadge.energy(analysis.energyGlobal, size: .small)

                    Spacer()

                    ColoredBadge.duration(analysis.durationSeconds, size: .small)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(CartoMixColors.accentYellow)
                    Text("Not analyzed")
                        .font(CartoMixTypography.caption)
                        .foregroundStyle(CartoMixColors.textSecondary)
                }
            }
        }
        .padding(CartoMixSpacing.md)
        .background(CartoMixColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: CartoMixRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CartoMixRadius.md)
                .stroke(appState.selectedTrack?.id == track.id ? CartoMixColors.accentBlue : .clear, lineWidth: 2)
        }
        .hoverHighlight()
        .onHover { isHovered = $0 }
    }
}

// MARK: - Analysis Badge (Legacy - kept for compatibility)

struct AnalysisBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .font(.caption.monospacedDigit())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: Capsule())
        .foregroundStyle(color)
    }
}

// MARK: - Section Indicator (for track rows)

struct TrackSectionIndicator: View {
    let sectionType: String

    var body: some View {
        Rectangle()
            .fill(CartoMixColors.colorForSection(sectionType))
            .frame(width: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

// MARK: - Track Context Menu

struct TrackContextMenu: View {
    let track: Track
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button("Add to Set") {
            appState.addToSet(track)
        }

        Button("Analyze") {
            Task {
                await appState.analyzeTrack(track)
            }
        }

        Divider()

        Button("Show in Finder") {
            NSWorkspace.shared.selectFile(track.path, inFileViewerRootedAtPath: "")
        }

        Divider()

        Button("Find Similar") {
            // TODO: Implement similarity search
        }
    }
}

// MARK: - Waveform Preview (Simple inline version for library)

struct WaveformPreviewView: View {
    let samples: [Float]

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let midY = height / 2
                let step = max(1, samples.count / Int(width))

                var path = Path()
                path.move(to: CGPoint(x: 0, y: midY))

                for x in stride(from: 0, to: Int(width), by: 1) {
                    let sampleIndex = min(x * step, samples.count - 1)
                    let sample = CGFloat(samples[sampleIndex])
                    let y = midY - (sample * midY * 0.9)
                    path.addLine(to: CGPoint(x: CGFloat(x), y: y))
                }

                for x in stride(from: Int(width) - 1, through: 0, by: -1) {
                    let sampleIndex = min(x * step, samples.count - 1)
                    let sample = CGFloat(samples[sampleIndex])
                    let y = midY + (sample * midY * 0.9)
                    path.addLine(to: CGPoint(x: CGFloat(x), y: y))
                }

                path.closeSubpath()

                // Use CartoMix waveform gradient
                context.fill(
                    path,
                    with: .linearGradient(
                        CartoMixGradients.waveformGradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: width, y: 0)
                    )
                )
            }
        }
        .background(CartoMixColors.backgroundTertiary)
    }
}

// Preview commented out for SPM compatibility
// #Preview {
//     LibraryView()
//         .environmentObject(AppState())
//         .frame(width: 800, height: 600)
// }
