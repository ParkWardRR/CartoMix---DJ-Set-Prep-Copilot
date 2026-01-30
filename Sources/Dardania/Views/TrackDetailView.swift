// Dardania - Track Detail View

import SwiftUI
import DardaniaCore

struct TrackDetailView: View {
    let track: Track
    @EnvironmentObject var appState: AppState
    @State private var selectedCue: Int?
    @State private var playbackPosition: Double = 0
    @State private var isPlaying = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                TrackHeader(track: track)

                // Waveform with sections
                if let analysis = track.analysis {
                    WaveformDetailView(
                        waveform: analysis.waveformPreview,
                        sections: analysis.sections,
                        cues: analysis.cuePoints,
                        playbackPosition: $playbackPosition,
                        selectedCue: $selectedCue
                    )
                    .frame(height: 150)
                }

                // Analysis panels
                HStack(alignment: .top, spacing: 16) {
                    // DSP Analysis
                    DSPAnalysisPanel(track: track)

                    // ML Analysis
                    MLAnalysisPanel(track: track)
                }

                // Sections
                if let analysis = track.analysis, !analysis.sections.isEmpty {
                    SectionsPanel(sections: analysis.sections)
                }

                // Cue Points
                if let analysis = track.analysis, !analysis.cuePoints.isEmpty {
                    CuePointsPanel(
                        cuePoints: analysis.cuePoints,
                        selectedCue: $selectedCue
                    )
                }

                // Similar Tracks
                SimilarTracksPanel(track: track)
            }
            .padding()
        }
        .navigationTitle(track.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.addToSet(track)
                } label: {
                    Label("Add to Set", systemImage: "plus.rectangle.on.rectangle")
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await appState.analyzeTrack(track)
                    }
                } label: {
                    Label("Re-analyze", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}

// MARK: - Track Header

struct TrackHeader: View {
    let track: Track

    var body: some View {
        HStack(spacing: 20) {
            // Album art placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(.quaternary)
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(track.title)
                    .font(.title.bold())

                Text(track.artist)
                    .font(.title2)
                    .foregroundStyle(.secondary)

                if let album = track.album {
                    Text(album)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 16) {
                    if let analysis = track.analysis {
                        Label(formatDuration(analysis.durationSeconds), systemImage: "clock")
                        Label(formatFileSize(track.fileSize), systemImage: "doc")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Main stats
            if let analysis = track.analysis {
                VStack(spacing: 12) {
                    MainStatBadge(
                        value: String(format: "%.1f", analysis.bpm),
                        label: "BPM",
                        color: .blue
                    )
                    MainStatBadge(
                        value: analysis.keyValue,
                        label: "Key",
                        color: .purple
                    )
                    MainStatBadge(
                        value: "\(analysis.energyGlobal)",
                        label: "Energy",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_000_000
        return String(format: "%.1f MB", mb)
    }
}

struct MainStatBadge: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(color)
    }
}

// MARK: - Waveform Detail View

struct WaveformDetailView: View {
    let waveform: [Float]
    let sections: [TrackSection]
    let cues: [CuePoint]
    @Binding var playbackPosition: Double
    @Binding var selectedCue: Int?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Sections background
                HStack(spacing: 0) {
                    ForEach(sections, id: \.startTime) { section in
                        Rectangle()
                            .fill(section.color.opacity(0.2))
                    }
                }

                // Waveform
                WaveformView(samples: waveform)

                // Cue markers
                ForEach(cues.indices, id: \.self) { index in
                    let cue = cues[index]
                    let x = CGFloat(cue.timeSeconds) / CGFloat(waveform.count) * geometry.size.width

                    Rectangle()
                        .fill(cue.color)
                        .frame(width: 2)
                        .overlay(alignment: .top) {
                            Text(cue.label)
                                .font(.caption2)
                                .padding(2)
                                .background(cue.color, in: RoundedRectangle(cornerRadius: 2))
                                .foregroundStyle(.white)
                        }
                        .position(x: x, y: geometry.size.height / 2)
                        .onTapGesture {
                            selectedCue = index
                        }
                }

                // Playback position
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .position(
                        x: CGFloat(playbackPosition) * geometry.size.width,
                        y: geometry.size.height / 2
                    )
            }
        }
        .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - DSP Analysis Panel

struct DSPAnalysisPanel: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("DSP Analysis", systemImage: "waveform.path.ecg")
                .font(.headline)

            if let analysis = track.analysis {
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                    GridRow {
                        AnalysisRow(label: "Tempo", value: String(format: "%.2f BPM", analysis.bpm))
                        AnalysisRow(label: "Confidence", value: String(format: "%.0f%%", analysis.bpmConfidence * 100))
                    }

                    GridRow {
                        AnalysisRow(label: "Key", value: analysis.keyValue)
                        AnalysisRow(label: "Confidence", value: String(format: "%.0f%%", analysis.keyConfidence * 100))
                    }

                    GridRow {
                        AnalysisRow(label: "Loudness", value: String(format: "%.1f LUFS", analysis.integratedLUFS))
                        AnalysisRow(label: "True Peak", value: String(format: "%.1f dBTP", analysis.truePeakDB))
                    }

                    GridRow {
                        AnalysisRow(label: "Energy", value: "\(analysis.energyGlobal)/10")
                        AnalysisRow(label: "Duration", value: formatDuration(analysis.durationSeconds))
                    }
                }
            } else {
                Text("Not analyzed")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatDuration(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct AnalysisRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospacedDigit())
        }
    }
}

// MARK: - ML Analysis Panel

struct MLAnalysisPanel: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("ML Analysis", systemImage: "brain")
                .font(.headline)

            if let analysis = track.analysis {
                VStack(alignment: .leading, spacing: 12) {
                    // Sound context
                    HStack {
                        Text("Context:")
                            .foregroundStyle(.secondary)
                        Text(analysis.soundContext ?? "Unknown")
                        if let confidence = analysis.soundContextConfidence {
                            Text(String(format: "(%.0f%%)", confidence * 100))
                                .foregroundStyle(.secondary)
                        }
                    }

                    // OpenL3 embedding status
                    HStack {
                        Text("Embedding:")
                            .foregroundStyle(.secondary)
                        if analysis.hasOpenL3Embedding {
                            Label("512-dim OpenL3", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Not computed", systemImage: "xmark.circle")
                                .foregroundStyle(.secondary)
                        }
                    }

                    // QA Flags
                    if !analysis.qaFlags.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("QA Flags:")
                                .foregroundStyle(.secondary)
                            ForEach(analysis.qaFlags, id: \.type) { flag in
                                HStack {
                                    Image(systemName: flag.icon)
                                        .foregroundStyle(flag.color)
                                    Text(flag.reason)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("Not analyzed")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Sections Panel

struct SectionsPanel: View {
    let sections: [TrackSection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sections", systemImage: "rectangle.split.3x1")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 8) {
                ForEach(sections, id: \.startTime) { section in
                    HStack {
                        Circle()
                            .fill(section.color)
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.type.rawValue)
                                .font(.subheadline.bold())
                            Text("\(formatTime(section.startTime)) - \(formatTime(section.endTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(8)
                    .background(section.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Cue Points Panel

struct CuePointsPanel: View {
    let cuePoints: [CuePoint]
    @Binding var selectedCue: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cue Points", systemImage: "mappin.and.ellipse")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                ForEach(cuePoints.indices, id: \.self) { index in
                    let cue = cuePoints[index]
                    Button {
                        selectedCue = index
                    } label: {
                        HStack {
                            Text("\(index + 1)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(cue.color, in: Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cue.label)
                                    .font(.subheadline)
                                Text(formatTime(cue.timeSeconds))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .background(
                        selectedCue == index ? cue.color.opacity(0.2) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedCue == index ? cue.color : .clear, lineWidth: 2)
                    }
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Similar Tracks Panel

struct SimilarTracksPanel: View {
    let track: Track
    @EnvironmentObject var appState: AppState
    @State private var similarTracks: [SimilarTrack] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Similar Tracks", systemImage: "sparkles")
                .font(.headline)

            if similarTracks.isEmpty {
                Text("No similar tracks found")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(similarTracks, id: \.track.id) { similar in
                    SimilarTrackRow(similar: similar)
                        .onTapGesture {
                            appState.selectedTrack = similar.track
                        }
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .task {
            // Load similar tracks
            // similarTracks = await loadSimilarTracks()
        }
    }
}

struct SimilarTrackRow: View {
    let similar: SimilarTrack

    var body: some View {
        HStack(spacing: 12) {
            // Similarity score
            ZStack {
                Circle()
                    .stroke(scoreColor, lineWidth: 3)
                    .frame(width: 44, height: 44)

                Text(String(format: "%.0f", similar.score * 100))
                    .font(.caption.bold().monospacedDigit())
            }

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(similar.track.title)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(similar.track.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Explanation
            Text(similar.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: 200)
        }
        .padding(8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var scoreColor: Color {
        switch similar.score {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        default: return .orange
        }
    }
}

struct SimilarTrack {
    let track: Track
    let score: Double
    let explanation: String
}

// Preview commented out for SPM compatibility
// #Preview {
//     TrackDetailView(track: Track.preview)
//         .environmentObject(AppState())
//         .frame(width: 800, height: 900)
// }
