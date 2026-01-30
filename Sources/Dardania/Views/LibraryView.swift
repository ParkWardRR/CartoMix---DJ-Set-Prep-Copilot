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
        HStack(spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search tracks...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 300)

            Spacer()

            // Track count
            Text("\(trackCount) tracks")
                .foregroundStyle(.secondary)
                .font(.subheadline)

            Divider()
                .frame(height: 20)

            // Sort
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
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }

            // BPM Range
            Menu {
                Button("60-90 BPM") { bpmRange = 60...90 }
                Button("90-120 BPM") { bpmRange = 90...120 }
                Button("120-140 BPM") { bpmRange = 120...140 }
                Button("140-180 BPM") { bpmRange = 140...180 }
                Divider()
                Button("All BPMs") { bpmRange = 60...200 }
            } label: {
                Label("BPM", systemImage: "metronome")
            }

            // Analyze All
            Button(action: onAnalyzeAll) {
                Label("Analyze All", systemImage: "waveform.badge.plus")
            }
        }
        .padding()
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
            // Waveform preview
            ZStack {
                if let waveform = track.analysis?.waveformPreview {
                    WaveformPreviewView(samples: waveform)
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "waveform")
                                .font(.title)
                                .foregroundStyle(.tertiary)
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
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task {
                                await appState.analyzeTrack(track)
                            }
                        } label: {
                            Image(systemName: "waveform.badge.plus")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

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

            // Analysis badges
            if let analysis = track.analysis {
                HStack(spacing: 8) {
                    AnalysisBadge(
                        icon: "metronome",
                        value: String(format: "%.1f", analysis.bpm),
                        color: .blue
                    )

                    AnalysisBadge(
                        icon: "music.note",
                        value: analysis.keyValue,
                        color: .purple
                    )

                    AnalysisBadge(
                        icon: "bolt.fill",
                        value: "\(analysis.energyGlobal)",
                        color: .orange
                    )

                    Spacer()

                    Text(formatDuration(analysis.durationSeconds))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(.yellow)
                    Text("Not analyzed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(appState.selectedTrack?.id == track.id ? Color.accentColor : .clear, lineWidth: 2)
        }
        .onHover { isHovered = $0 }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Analysis Badge

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

                let gradient = Gradient(colors: [
                    .cyan.opacity(0.8),
                    .blue.opacity(0.6),
                    .purple.opacity(0.4)
                ])

                context.fill(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: 0, y: 0),
                        endPoint: CGPoint(x: width, y: 0)
                    )
                )
            }
        }
    }
}

// Preview commented out for SPM compatibility
// #Preview {
//     LibraryView()
//         .environmentObject(AppState())
//         .frame(width: 800, height: 600)
// }
