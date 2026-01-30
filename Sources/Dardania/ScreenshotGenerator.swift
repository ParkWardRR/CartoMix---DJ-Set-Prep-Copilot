// CartoMix - Programmatic Screenshot Generator
// Renders SwiftUI views to images for documentation
// Uses new visual components for professional appearance

import SwiftUI
import AppKit
import DardaniaCore

/// Generates screenshots of app views for documentation
@MainActor
struct ScreenshotGenerator {
    let outputDirectory: URL
    let width: CGFloat
    let height: CGFloat

    init(
        outputDirectory: URL? = nil,
        width: CGFloat = 1280,
        height: CGFloat = 800
    ) {
        if let outputDirectory = outputDirectory {
            self.outputDirectory = outputDirectory
        } else {
            let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            self.outputDirectory = cwd.appendingPathComponent("docs/assets/screens")
        }
        self.width = width
        self.height = height
    }

    /// Generate all screenshots
    func generateAll() async throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        print("Generating screenshots to: \(outputDirectory.path)")

        let mockTracks = createMockTracks()
        let mockAnalysis = createMockAnalysis()

        // 1. Library View
        print("  Generating: library-view")
        try await renderView(
            LibraryViewPreview(tracks: mockTracks, analysis: mockAnalysis),
            filename: "library-view"
        )

        // 2. Set Builder View
        print("  Generating: set-builder")
        try await renderView(
            SetBuilderPreview(tracks: Array(mockTracks.prefix(8))),
            filename: "set-builder"
        )

        // 3. Graph View
        print("  Generating: graph-view")
        try await renderView(
            GraphViewPreview(tracks: mockTracks),
            filename: "graph-view"
        )

        // 4. Track Analysis
        print("  Generating: track-analysis")
        try await renderView(
            TrackAnalysisPreview(track: mockTracks[0], analysis: mockAnalysis),
            filename: "track-analysis"
        )

        // 5. Waveform Painting
        print("  Generating: waveform-painting")
        try await renderView(
            WaveformPaintingPreview(analysis: mockAnalysis),
            filename: "waveform-painting"
        )

        // 6. Audio Playback
        print("  Generating: audio-playback")
        try await renderView(
            AudioPlaybackPreview(analysis: mockAnalysis),
            filename: "audio-playback"
        )

        // 7. User Overrides
        print("  Generating: user-overrides")
        try await renderView(
            UserOverridesPreview(analysis: mockAnalysis),
            filename: "user-overrides"
        )

        // 8. Transition Detection
        print("  Generating: transition-detection")
        try await renderView(
            TransitionDetectionPreview(analysis: mockAnalysis),
            filename: "transition-detection"
        )

        // 9. Energy Matching
        print("  Generating: energy-matching")
        try await renderView(
            EnergyMatchingPreview(tracks: mockTracks),
            filename: "energy-matching"
        )

        // 10. Section Embeddings
        print("  Generating: section-embeddings")
        try await renderView(
            SectionEmbeddingsPreview(analysis: mockAnalysis),
            filename: "section-embeddings"
        )

        print("\nScreenshot generation complete!")
    }

    private func renderView<V: View>(_ view: V, filename: String) async throws {
        let hostingView = NSHostingView(rootView: view.frame(width: width, height: height))
        hostingView.frame = CGRect(x: 0, y: 0, width: width, height: height)

        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            print("    Failed to create bitmap representation")
            return
        }

        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("    Failed to create PNG data")
            return
        }

        let pngURL = outputDirectory.appendingPathComponent("\(filename).png")
        try pngData.write(to: pngURL)

        let webpURL = outputDirectory.appendingPathComponent("\(filename).webp")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/cwebp")
        process.arguments = ["-q", "90", pngURL.path, "-o", webpURL.path]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                try? FileManager.default.removeItem(at: pngURL)
                print("    Saved: \(filename).webp")
            } else {
                print("    Saved: \(filename).png (WebP conversion failed)")
            }
        } catch {
            print("    Saved: \(filename).png (cwebp not found)")
        }
    }

    // MARK: - Mock Data Generation

    private func createMockTracks() -> [Track] {
        [
            Track(id: 1, contentHash: "abc123", path: "/Music/Get Lucky.mp3", title: "Get Lucky", artist: "Daft Punk", album: "RAM", fileSize: 12_500_000, fileModifiedAt: Date(), createdAt: Date(), updatedAt: Date()),
            Track(id: 2, contentHash: "def456", path: "/Music/Instant Crush.mp3", title: "Instant Crush", artist: "Daft Punk", album: "RAM", fileSize: 11_200_000, fileModifiedAt: Date(), createdAt: Date(), updatedAt: Date()),
            Track(id: 3, contentHash: "ghi789", path: "/Music/In The Morning.mp3", title: "In The Morning", artist: "ZHU", album: "ERUM", fileSize: 9_800_000, fileModifiedAt: Date(), createdAt: Date(), updatedAt: Date()),
            Track(id: 4, contentHash: "jkl012", path: "/Music/Latch.mp3", title: "Latch", artist: "Disclosure", album: "Settle", fileSize: 10_500_000, fileModifiedAt: Date(), createdAt: Date(), updatedAt: Date()),
            Track(id: 5, contentHash: "mno345", path: "/Music/Line of Sight.mp3", title: "Line of Sight", artist: "ODESZA", album: "A Moment Apart", fileSize: 11_800_000, fileModifiedAt: Date(), createdAt: Date(), updatedAt: Date()),
            Track(id: 6, contentHash: "pqr678", path: "/Music/Midnight City.mp3", title: "Midnight City", artist: "M83", album: "Hurry Up", fileSize: 10_200_000, fileModifiedAt: Date(), createdAt: Date(), updatedAt: Date()),
            Track(id: 7, contentHash: "stu901", path: "/Music/Opus.mp3", title: "Opus", artist: "Eric Prydz", album: "Opus", fileSize: 15_500_000, fileModifiedAt: Date(), createdAt: Date(), updatedAt: Date()),
            Track(id: 8, contentHash: "vwx234", path: "/Music/Strobe.mp3", title: "Strobe", artist: "deadmau5", album: "For Lack", fileSize: 18_200_000, fileModifiedAt: Date(), createdAt: Date(), updatedAt: Date()),
        ]
    }

    private func createMockAnalysis() -> TrackAnalysis {
        let sections = [
            TrackSection(type: .intro, startTime: 0, endTime: 30, confidence: 0.95),
            TrackSection(type: .verse, startTime: 30, endTime: 75, confidence: 0.88),
            TrackSection(type: .build, startTime: 75, endTime: 90, confidence: 0.92),
            TrackSection(type: .drop, startTime: 90, endTime: 150, confidence: 0.97),
            TrackSection(type: .breakdown, startTime: 150, endTime: 180, confidence: 0.85),
            TrackSection(type: .build, startTime: 180, endTime: 195, confidence: 0.90),
            TrackSection(type: .drop, startTime: 195, endTime: 255, confidence: 0.96),
            TrackSection(type: .outro, startTime: 255, endTime: 285, confidence: 0.93),
        ]

        let cuePoints = [
            CuePoint(index: 0, label: "Intro", type: .intro, timeSeconds: 0, beatIndex: 0),
            CuePoint(index: 1, label: "Build 1", type: .build, timeSeconds: 75, beatIndex: 144),
            CuePoint(index: 2, label: "Drop 1", type: .drop, timeSeconds: 90, beatIndex: 172),
            CuePoint(index: 3, label: "Breakdown", type: .breakdown, timeSeconds: 150, beatIndex: 288),
            CuePoint(index: 4, label: "Build 2", type: .build, timeSeconds: 180, beatIndex: 346),
            CuePoint(index: 5, label: "Drop 2", type: .drop, timeSeconds: 195, beatIndex: 374),
            CuePoint(index: 6, label: "Outro", type: .outro, timeSeconds: 255, beatIndex: 490),
        ]

        let waveform = (0..<1000).map { i -> Float in
            let position = Float(i) / 1000
            let base = sin(position * Float.pi * 20) * 0.3
            let energy = position < 0.1 ? position * 5 :
                        position < 0.3 ? 0.5 :
                        position < 0.35 ? position * 2 :
                        position < 0.55 ? 0.9 :
                        position < 0.65 ? 0.4 :
                        position < 0.7 ? position * 1.5 :
                        position < 0.9 ? 0.85 :
                        (1 - position) * 5
            return (base + Float.random(in: 0...0.2)) * energy
        }

        return TrackAnalysis(
            id: 1, trackId: 1, version: 1, status: .complete,
            durationSeconds: 285, bpm: 116, bpmConfidence: 0.95,
            keyValue: "8A", keyFormat: "camelot", keyConfidence: 0.88,
            energyGlobal: 75, integratedLUFS: -8.5, truePeakDB: -0.3, loudnessRange: 6.2,
            waveformPreview: waveform, sections: sections, cuePoints: cuePoints,
            soundContext: "Electronic / Dance", soundContextConfidence: 0.92,
            qaFlags: [], hasOpenL3Embedding: true, trainingLabels: [],
            createdAt: Date(), updatedAt: Date()
        )
    }
}

// MARK: - Preview Views Using New Components

struct LibraryViewPreview: View {
    let tracks: [Track]
    let analysis: TrackAnalysis

    var mockWaveform: [Float] {
        (0..<500).map { i in
            let t = Float(i) / 500
            return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
        }
    }

    var body: some View {
        HSplitView {
            // Left: Track list
            VStack(spacing: 0) {
                HStack {
                    Text("Library")
                        .font(CartoMixTypography.title)
                    Spacer()
                    Text("\(tracks.count) tracks")
                        .font(CartoMixTypography.caption)
                        .foregroundStyle(CartoMixColors.textSecondary)
                }
                .padding()

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(tracks, id: \.id) { track in
                            HStack(spacing: CartoMixSpacing.sm) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(CartoMixColors.colorForSection("drop"))
                                    .frame(width: 4)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.system(size: 13, weight: .medium))
                                    Text(track.artist)
                                        .font(.system(size: 11))
                                        .foregroundStyle(CartoMixColors.textSecondary)
                                }

                                Spacer()

                                BadgeRow(bpm: 126, key: "8A", energy: 7, size: .small, spacing: 4)
                            }
                            .padding(.horizontal, CartoMixSpacing.md)
                            .padding(.vertical, CartoMixSpacing.sm)
                            .background(track.id == 1 ? CartoMixColors.accentBlue.opacity(0.15) : .clear)
                        }
                    }
                }
            }
            .frame(minWidth: 300, maxWidth: 350)
            .background(CartoMixColors.backgroundSecondary)

            // Center: Waveform
            VStack(spacing: CartoMixSpacing.md) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(tracks[0].title)
                            .font(CartoMixTypography.headline)
                        Text(tracks[0].artist)
                            .font(CartoMixTypography.body)
                            .foregroundStyle(CartoMixColors.textSecondary)
                    }
                    Spacer()
                    BadgeRow(bpm: 126, key: "8A", energy: 7)
                }

                GradientWaveformView(
                    samples: mockWaveform,
                    sections: [
                        WaveformSection(type: "intro", startTime: 0, endTime: 30),
                        WaveformSection(type: "build", startTime: 30, endTime: 60),
                        WaveformSection(type: "drop", startTime: 60, endTime: 120),
                        WaveformSection(type: "breakdown", startTime: 120, endTime: 150),
                        WaveformSection(type: "drop", startTime: 150, endTime: 210),
                        WaveformSection(type: "outro", startTime: 210, endTime: 240)
                    ],
                    cuePoints: [
                        WaveformCuePoint(label: "CUE 1", time: 30, type: "hotcue"),
                        WaveformCuePoint(label: "DROP", time: 60, type: "hotcue"),
                        WaveformCuePoint(label: "MIX OUT", time: 210, type: "fade_out")
                    ],
                    duration: 240,
                    playheadPosition: 90
                )
                .frame(height: 150)

                CuePointsTable(cuePoints: [
                    CuePointData(label: "Intro", type: .hotcue, timeSeconds: 0, beatIndex: 1),
                    CuePointData(label: "Build", type: .hotcue, timeSeconds: 30, beatIndex: 65),
                    CuePointData(label: "Drop 1", type: .hotcue, timeSeconds: 60, beatIndex: 129),
                    CuePointData(label: "Breakdown", type: .hotcue, timeSeconds: 120, beatIndex: 257),
                    CuePointData(label: "Drop 2", type: .hotcue, timeSeconds: 150, beatIndex: 321),
                    CuePointData(label: "Outro", type: .fadeOut, timeSeconds: 210, beatIndex: 449)
                ])
            }
            .padding()
            .background(CartoMixColors.backgroundPrimary)

            // Right: Info panel
            VStack(alignment: .leading, spacing: CartoMixSpacing.md) {
                Text("Key Distribution")
                    .font(CartoMixTypography.headline)

                CompactKeyDistribution(distribution: [
                    "8A": 12, "9A": 8, "7A": 6, "8B": 5, "10A": 4
                ])

                Divider()

                Text("Similar Tracks")
                    .font(CartoMixTypography.headline)

                VStack(spacing: CartoMixSpacing.sm) {
                    ForEach(tracks.prefix(3), id: \.id) { track in
                        HStack {
                            Text(track.title)
                                .font(.system(size: 12))
                            Spacer()
                            Text("92%")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(CartoMixColors.accentGreen)
                        }
                        .padding(CartoMixSpacing.sm)
                        .background(CartoMixColors.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.sm))
                    }
                }
            }
            .padding()
            .frame(minWidth: 200, maxWidth: 250)
            .background(CartoMixColors.backgroundSecondary)
        }
        .preferredColorScheme(.dark)
    }
}

struct SetBuilderPreview: View {
    let tracks: [Track]

    var energyData: [EnergyTrackData] {
        tracks.enumerated().map { index, track in
            let energies = [3, 5, 6, 7, 9, 8, 6, 4]
            return EnergyTrackData(
                title: track.title,
                energy: energies[index % energies.count],
                bpm: 120 + Double(index) * 2,
                key: "\(6 + index)A"
            )
        }
    }

    var mockWaveform: [Float] {
        (0..<200).map { i in
            let t = Float(i) / 200
            return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
        }
    }

    var body: some View {
        HSplitView {
            // Left: Set list
            VStack(spacing: 0) {
                HStack {
                    Text("Set Builder")
                        .font(CartoMixTypography.title)
                    Spacer()
                    Text("\(tracks.count) tracks")
                        .font(CartoMixTypography.caption)
                        .foregroundStyle(CartoMixColors.textSecondary)
                }
                .padding()

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                            HStack(spacing: CartoMixSpacing.sm) {
                                Text("\(index + 1)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(CartoMixColors.textSecondary)
                                    .frame(width: 20)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(CartoMixColors.colorForSection(["intro", "build", "drop", "breakdown"][index % 4]))
                                    .frame(width: 4)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.system(size: 13, weight: .medium))
                                    Text(track.artist)
                                        .font(.system(size: 11))
                                        .foregroundStyle(CartoMixColors.textSecondary)
                                }

                                Spacer()

                                BadgeRow(bpm: 120 + Double(index) * 2, key: "\(6 + index)A", energy: nil, size: .small, spacing: 4)
                            }
                            .padding(.horizontal, CartoMixSpacing.md)
                            .padding(.vertical, CartoMixSpacing.sm)
                            .background(CartoMixColors.backgroundTertiary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))

                            if index < tracks.count - 1 {
                                // Transition indicator
                                HStack {
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Text("+2 BPM")
                                            .foregroundStyle(CartoMixColors.accentGreen)
                                        Text("•")
                                            .foregroundStyle(CartoMixColors.textTertiary)
                                        Text("compatible")
                                            .foregroundStyle(CartoMixColors.accentCyan)
                                    }
                                    .font(.system(size: 10))
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(minWidth: 350, maxWidth: 400)
            .background(CartoMixColors.backgroundSecondary)

            // Right: Energy Journey + Transition Preview
            VStack(spacing: CartoMixSpacing.lg) {
                VStack(alignment: .leading, spacing: CartoMixSpacing.sm) {
                    Text("Energy Journey")
                        .font(CartoMixTypography.headline)
                    EnergyJourneyView(tracks: energyData)
                        .frame(height: 150)
                }

                TransitionPreviewView(
                    trackA: TransitionTrackData(
                        title: "Latch",
                        artist: "Disclosure",
                        bpm: 126,
                        key: "8A",
                        energy: 7,
                        waveform: mockWaveform,
                        sections: [
                            WaveformSection(type: "drop", startTime: 0, endTime: 150),
                            WaveformSection(type: "outro", startTime: 150, endTime: 200)
                        ]
                    ),
                    trackB: TransitionTrackData(
                        title: "Line of Sight",
                        artist: "ODESZA",
                        bpm: 128,
                        key: "9A",
                        energy: 8,
                        waveform: mockWaveform,
                        sections: [
                            WaveformSection(type: "intro", startTime: 0, endTime: 50),
                            WaveformSection(type: "build", startTime: 50, endTime: 100)
                        ]
                    )
                )

                // Export buttons
                HStack(spacing: CartoMixSpacing.md) {
                    Button("Rekordbox") {}
                        .buttonStyle(PrimaryButtonStyle(color: CartoMixColors.accentBlue))
                    Button("Serato") {}
                        .buttonStyle(SecondaryButtonStyle())
                    Button("Traktor") {}
                        .buttonStyle(SecondaryButtonStyle())
                    Spacer()
                }
            }
            .padding()
            .background(CartoMixColors.backgroundPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

struct GraphViewPreview: View {
    let tracks: [Track]

    var mockWaveform: [Float] {
        (0..<200).map { i in
            let t = Float(i) / 200
            return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
        }
    }

    var body: some View {
        HSplitView {
            // Graph
            ZStack {
                // Connections
                ForEach(0..<5, id: \.self) { i in
                    let angle1 = Double(i) * (2 * Double.pi / 5) - Double.pi / 2
                    let angle2 = Double((i + 1) % 5) * (2 * Double.pi / 5) - Double.pi / 2

                    Path { path in
                        path.move(to: CGPoint(x: cos(angle1) * 180 + 400, y: sin(angle1) * 180 + 300))
                        path.addLine(to: CGPoint(x: cos(angle2) * 180 + 400, y: sin(angle2) * 180 + 300))
                    }
                    .stroke(CartoMixColors.accentGreen.opacity(0.4), lineWidth: 2)
                }

                // Nodes
                ForEach(Array(tracks.prefix(5).enumerated()), id: \.offset) { index, track in
                    let angle = Double(index) * (2 * Double.pi / 5) - Double.pi / 2
                    let x = cos(angle) * 180 + 400
                    let y = sin(angle) * 180 + 300
                    let key = "\(6 + index)A"

                    Circle()
                        .fill(CartoMixColors.colorForKey(key))
                        .frame(width: 60, height: 60)
                        .overlay {
                            VStack(spacing: 2) {
                                Text(track.title.prefix(6))
                                    .font(.system(size: 10, weight: .semibold))
                                Text(key)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .foregroundStyle(.white)
                        }
                        .shadow(color: CartoMixColors.colorForKey(key).opacity(0.5), radius: 10)
                        .position(x: x, y: y)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CartoMixColors.backgroundPrimary)

            // Right panel
            VStack(alignment: .leading, spacing: CartoMixSpacing.lg) {
                Text(tracks[0].title)
                    .font(CartoMixTypography.title)

                BadgeRow(bpm: 126, key: "8A", energy: 7)

                CompactWaveformView(samples: mockWaveform, height: 50)

                Divider()

                Text("Key Distribution")
                    .font(CartoMixTypography.headline)

                KeyDistributionChart(
                    distribution: ["8A": 12, "9A": 8, "7A": 6, "8B": 5, "10A": 4, "6A": 3],
                    maxHeight: 80,
                    showLabels: true
                )

                Divider()

                Text("Set Energy")
                    .font(CartoMixTypography.headline)

                EnergyJourneyView(
                    tracks: tracks.prefix(5).enumerated().map { i, t in
                        EnergyTrackData(title: t.title, energy: [4, 6, 8, 9, 7][i], bpm: 126, key: "8A")
                    },
                    showLabels: false
                )
                .frame(height: 80)
            }
            .padding()
            .frame(width: 300)
            .background(CartoMixColors.backgroundSecondary)
        }
        .preferredColorScheme(.dark)
    }
}

struct TrackAnalysisPreview: View {
    let track: Track
    let analysis: TrackAnalysis

    var mockWaveform: [Float] {
        (0..<500).map { i in
            let t = Float(i) / 500
            return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(track.title)
                        .font(CartoMixTypography.title)
                    Text(track.artist)
                        .foregroundStyle(CartoMixColors.textSecondary)
                }
                Spacer()
                HStack(spacing: CartoMixSpacing.md) {
                    ColoredBadge.bpm(analysis.bpm, size: .large)
                    ColoredBadge.key(analysis.keyValue, size: .large)
                    ColoredBadge.energy(analysis.energyGlobal / 10, size: .large)
                    ColoredBadge.duration(analysis.durationSeconds, size: .large)
                }
            }
            .padding()
            .background(CartoMixColors.backgroundSecondary)

            HSplitView {
                // Main content
                ScrollView {
                    VStack(spacing: CartoMixSpacing.lg) {
                        GradientWaveformView(
                            samples: mockWaveform,
                            sections: analysis.sections.map {
                                WaveformSection(type: $0.type.rawValue, startTime: $0.startTime, endTime: $0.endTime)
                            },
                            cuePoints: analysis.cuePoints.map {
                                WaveformCuePoint(label: $0.label, time: $0.timeSeconds, type: $0.type.rawValue)
                            },
                            duration: analysis.durationSeconds,
                            playheadPosition: 90
                        )
                        .frame(height: 160)

                        // Sections timeline
                        VStack(alignment: .leading, spacing: CartoMixSpacing.sm) {
                            Text("Sections")
                                .font(CartoMixTypography.headline)
                            HStack(spacing: 2) {
                                ForEach(analysis.sections, id: \.startTime) { section in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(section.color)
                                        .frame(width: CGFloat(section.duration) * 2.5)
                                        .overlay {
                                            Text(section.type.displayName)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundStyle(.white)
                                        }
                                }
                            }
                            .frame(height: 32)
                        }
                        .cardStyle()
                    }
                    .padding()
                }
                .background(CartoMixColors.backgroundPrimary)

                // Side panel
                VStack(alignment: .leading, spacing: CartoMixSpacing.lg) {
                    Text("Cue Points")
                        .font(CartoMixTypography.headline)

                    CuePointsTable(cuePoints: analysis.cuePoints.map {
                        CuePointData(label: $0.label, type: .hotcue, timeSeconds: $0.timeSeconds, beatIndex: $0.beatIndex)
                    })

                    Divider()

                    Text("Analysis")
                        .font(CartoMixTypography.headline)

                    VStack(alignment: .leading, spacing: CartoMixSpacing.sm) {
                        HStack {
                            Text("Loudness")
                            Spacer()
                            Text("\(String(format: "%.1f", analysis.integratedLUFS)) LUFS")
                                .foregroundStyle(CartoMixColors.accentCyan)
                        }
                        HStack {
                            Text("True Peak")
                            Spacer()
                            Text("\(String(format: "%.1f", analysis.truePeakDB)) dB")
                                .foregroundStyle(CartoMixColors.accentOrange)
                        }
                        HStack {
                            Text("Context")
                            Spacer()
                            Text(analysis.soundContext ?? "Unknown")
                                .foregroundStyle(CartoMixColors.accentPurple)
                        }
                    }
                    .font(.system(size: 12))
                }
                .padding()
                .frame(width: 280)
                .background(CartoMixColors.backgroundSecondary)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct WaveformPaintingPreview: View {
    let analysis: TrackAnalysis

    var mockWaveform: [Float] {
        (0..<500).map { i in
            let t = Float(i) / 500
            return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Waveform Label Painting")
                    .font(CartoMixTypography.title)
                Spacer()
                Toggle("Paint Mode", isOn: .constant(true))
                    .toggleStyle(.button)
                    .tint(CartoMixColors.accentBlue)
                Picker("Section", selection: .constant("drop")) {
                    ForEach(["intro", "build", "drop", "breakdown", "outro"], id: \.self) { type in
                        Text(type.capitalized).tag(type)
                    }
                }
                .frame(width: 120)
            }
            .padding()
            .background(CartoMixColors.backgroundSecondary)

            VStack(spacing: CartoMixSpacing.lg) {
                GradientWaveformView(
                    samples: mockWaveform,
                    sections: analysis.sections.map {
                        WaveformSection(type: $0.type.rawValue, startTime: $0.startTime, endTime: $0.endTime)
                    },
                    cuePoints: [],
                    duration: analysis.durationSeconds
                )
                .frame(height: 250)
                .overlay(alignment: .bottom) {
                    // Section legend
                    HStack(spacing: CartoMixSpacing.lg) {
                        ForEach(["intro", "build", "drop", "breakdown", "outro"], id: \.self) { type in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(CartoMixColors.colorForSection(type))
                                    .frame(width: 10, height: 10)
                                Text(type.capitalized)
                                    .font(CartoMixTypography.caption)
                            }
                        }
                    }
                    .padding(CartoMixSpacing.sm)
                    .background(CartoMixColors.backgroundSecondary.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
                    .padding(.bottom, CartoMixSpacing.md)
                }

                Text("Drag to paint section labels • Click sections to edit • Labels train the AI")
                    .font(CartoMixTypography.caption)
                    .foregroundStyle(CartoMixColors.textSecondary)
            }
            .padding()
            .background(CartoMixColors.backgroundPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

struct AudioPlaybackPreview: View {
    let analysis: TrackAnalysis

    var mockWaveform: [Float] {
        (0..<500).map { i in
            let t = Float(i) / 500
            return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Real-Time Playback")
                    .font(CartoMixTypography.title)
                Spacer()
                HStack(spacing: CartoMixSpacing.lg) {
                    Button(action: {}) { Image(systemName: "backward.fill") }
                    Button(action: {}) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button(action: {}) { Image(systemName: "forward.fill") }
                }
                Spacer()
                Text("1:45 / 4:45")
                    .font(CartoMixTypography.mono)
                    .foregroundStyle(CartoMixColors.textSecondary)
            }
            .padding()
            .background(CartoMixColors.backgroundSecondary)

            VStack(spacing: CartoMixSpacing.lg) {
                GradientWaveformView(
                    samples: mockWaveform,
                    sections: analysis.sections.map {
                        WaveformSection(type: $0.type.rawValue, startTime: $0.startTime, endTime: $0.endTime)
                    },
                    cuePoints: analysis.cuePoints.map {
                        WaveformCuePoint(label: $0.label, time: $0.timeSeconds, type: $0.type.rawValue)
                    },
                    duration: analysis.durationSeconds,
                    playheadPosition: 105
                )
                .frame(height: 200)

                HStack(spacing: CartoMixSpacing.xxl) {
                    VStack {
                        Image(systemName: "keyboard")
                        Text("Space: Play/Pause")
                    }
                    VStack {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("←/→: Skip 5s")
                    }
                    VStack {
                        Image(systemName: "cursorarrow.click")
                        Text("Click: Seek")
                    }
                }
                .font(CartoMixTypography.caption)
                .foregroundStyle(CartoMixColors.textSecondary)
            }
            .padding()
            .background(CartoMixColors.backgroundPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

struct UserOverridesPreview: View {
    let analysis: TrackAnalysis

    var body: some View {
        VStack(spacing: 0) {
            Text("User Overrides")
                .font(CartoMixTypography.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(CartoMixColors.backgroundSecondary)

            HStack(alignment: .top, spacing: CartoMixSpacing.lg) {
                // BPM Override
                VStack(alignment: .leading, spacing: CartoMixSpacing.md) {
                    HStack {
                        Text("BPM")
                            .font(CartoMixTypography.headline)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(CartoMixColors.accentOrange)
                    }
                    HStack {
                        Text("Detected: 116.2")
                            .foregroundStyle(CartoMixColors.textSecondary)
                        Spacer()
                    }
                    HStack {
                        TextField("Override", text: .constant("116"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Toggle("Lock", isOn: .constant(true))
                            .toggleStyle(.button)
                            .tint(CartoMixColors.accentOrange)
                    }
                }
                .cardStyle()

                // Key Override
                VStack(alignment: .leading, spacing: CartoMixSpacing.md) {
                    Text("Key")
                        .font(CartoMixTypography.headline)
                    HStack {
                        Text("Detected: 8A")
                            .foregroundStyle(CartoMixColors.textSecondary)
                        Spacer()
                    }
                    Picker("Key", selection: .constant("8A")) {
                        ForEach(["7A", "8A", "9A", "8B"], id: \.self) { key in
                            Text(key).tag(key)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .cardStyle()

                // Custom Cue Points
                VStack(alignment: .leading, spacing: CartoMixSpacing.md) {
                    Text("Custom Cue Points")
                        .font(CartoMixTypography.headline)
                    VStack(alignment: .leading, spacing: CartoMixSpacing.sm) {
                        HStack {
                            Circle().fill(CartoMixColors.accentRed).frame(width: 8, height: 8)
                            Text("My Drop Marker")
                            Spacer()
                            Text("1:30")
                                .font(CartoMixTypography.monoSmall)
                                .foregroundStyle(CartoMixColors.textSecondary)
                        }
                        HStack {
                            Circle().fill(CartoMixColors.accentGreen).frame(width: 8, height: 8)
                            Text("Mix In Point")
                            Spacer()
                            Text("0:45")
                                .font(CartoMixTypography.monoSmall)
                                .foregroundStyle(CartoMixColors.textSecondary)
                        }
                    }
                    .font(CartoMixTypography.body)
                    Button("Add Cue Point") {}
                        .buttonStyle(SecondaryButtonStyle(color: CartoMixColors.accentGreen))
                }
                .cardStyle()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CartoMixColors.backgroundPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

struct TransitionDetectionPreview: View {
    let analysis: TrackAnalysis

    var mockWaveform: [Float] {
        (0..<300).map { i in
            let t = Float(i) / 300
            return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Transition Detection")
                .font(CartoMixTypography.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(CartoMixColors.backgroundSecondary)

            VStack(spacing: CartoMixSpacing.lg) {
                TransitionPreviewView(
                    trackA: TransitionTrackData(
                        title: "Get Lucky",
                        artist: "Daft Punk",
                        bpm: 116,
                        key: "8A",
                        energy: 7,
                        waveform: mockWaveform,
                        sections: [
                            WaveformSection(type: "drop", startTime: 0, endTime: 200),
                            WaveformSection(type: "outro", startTime: 200, endTime: 285)
                        ]
                    ),
                    trackB: TransitionTrackData(
                        title: "Instant Crush",
                        artist: "Daft Punk",
                        bpm: 118,
                        key: "9A",
                        energy: 6,
                        waveform: mockWaveform.reversed(),
                        sections: [
                            WaveformSection(type: "intro", startTime: 0, endTime: 45),
                            WaveformSection(type: "build", startTime: 45, endTime: 90)
                        ]
                    )
                )

                // Recommendation
                HStack {
                    VStack(alignment: .leading, spacing: CartoMixSpacing.sm) {
                        Text("Recommended Transition")
                            .font(CartoMixTypography.headline)
                        Text("Mix-out at breakdown (3:45) • Mix-in after intro (0:30)")
                            .font(CartoMixTypography.body)
                            .foregroundStyle(CartoMixColors.textSecondary)
                        Text("16-bar transition • Beat-grid aligned")
                            .font(CartoMixTypography.caption)
                            .foregroundStyle(CartoMixColors.textTertiary)
                    }
                    Spacer()
                    VStack {
                        Text("95%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(CartoMixColors.accentGreen)
                        Text("match")
                            .font(CartoMixTypography.caption)
                            .foregroundStyle(CartoMixColors.textSecondary)
                    }
                }
                .cardStyle()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CartoMixColors.backgroundPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

struct EnergyMatchingPreview: View {
    let tracks: [Track]

    var energyData: [EnergyTrackData] {
        tracks.prefix(6).enumerated().map { i, t in
            EnergyTrackData(title: t.title, energy: [4, 6, 7, 9, 8, 5][i], bpm: 120 + Double(i) * 2, key: "\(6 + i)A")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Energy Curve Matching")
                .font(CartoMixTypography.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(CartoMixColors.backgroundSecondary)

            HStack(spacing: CartoMixSpacing.lg) {
                VStack(alignment: .leading, spacing: CartoMixSpacing.md) {
                    Text("Set Energy Journey")
                        .font(CartoMixTypography.headline)
                    EnergyJourneyView(tracks: energyData)
                        .frame(height: 200)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: CartoMixSpacing.md) {
                    Text("Match Patterns")
                        .font(CartoMixTypography.headline)

                    VStack(spacing: CartoMixSpacing.sm) {
                        MatchResultRow(type: "Continuation", description: "Smooth energy flow", score: 91, color: CartoMixColors.accentGreen)
                        MatchResultRow(type: "Parallel", description: "Matching intensity", score: 85, color: CartoMixColors.accentBlue)
                        MatchResultRow(type: "Complementary", description: "Energy contrast", score: 72, color: CartoMixColors.accentPurple)
                    }

                    Divider()

                    Text("Suggestions")
                        .font(CartoMixTypography.headline)

                    VStack(alignment: .leading, spacing: CartoMixSpacing.sm) {
                        HStack {
                            Circle().fill(CartoMixColors.accentGreen).frame(width: 8, height: 8)
                            Text("Good energy progression")
                        }
                        HStack {
                            Circle().fill(CartoMixColors.accentYellow).frame(width: 8, height: 8)
                            Text("Consider energy dip before track 5")
                        }
                    }
                    .font(CartoMixTypography.body)
                }
                .frame(width: 300)
                .cardStyle()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CartoMixColors.backgroundPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

struct MatchResultRow: View {
    let type: String
    let description: String
    let score: Int
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(type)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(CartoMixTypography.caption)
                    .foregroundStyle(CartoMixColors.textSecondary)
            }
            Spacer()
            Text("\(score)%")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(CartoMixSpacing.sm)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }
}

struct SectionEmbeddingsPreview: View {
    let analysis: TrackAnalysis

    var body: some View {
        VStack(spacing: 0) {
            Text("Section-Level Embeddings")
                .font(CartoMixTypography.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(CartoMixColors.backgroundSecondary)

            HStack(alignment: .top, spacing: CartoMixSpacing.lg) {
                // Section list
                VStack(alignment: .leading, spacing: CartoMixSpacing.md) {
                    Text("Sections")
                        .font(CartoMixTypography.headline)

                    VStack(spacing: CartoMixSpacing.sm) {
                        ForEach(analysis.sections, id: \.startTime) { section in
                            HStack {
                                Circle()
                                    .fill(section.color)
                                    .frame(width: 12, height: 12)
                                Text(section.type.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text("512-dim")
                                    .font(CartoMixTypography.monoSmall)
                                    .foregroundStyle(CartoMixColors.textSecondary)
                            }
                            .padding(CartoMixSpacing.sm)
                            .background(CartoMixColors.backgroundTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
                        }
                    }
                }
                .frame(width: 280)
                .cardStyle()

                // Similar sections
                VStack(alignment: .leading, spacing: CartoMixSpacing.md) {
                    Text("Similar Drops in Library")
                        .font(CartoMixTypography.headline)

                    VStack(spacing: CartoMixSpacing.sm) {
                        SimilarSectionRow(title: "Strobe - Drop 2", artist: "deadmau5", score: 96)
                        SimilarSectionRow(title: "Opus - Main Drop", artist: "Eric Prydz", score: 94)
                        SimilarSectionRow(title: "Midnight City - Drop", artist: "M83", score: 91)
                        SimilarSectionRow(title: "In The Morning - Drop", artist: "ZHU", score: 88)
                    }

                    Divider()

                    Text("Embedding Visualization")
                        .font(CartoMixTypography.headline)

                    // Mock t-SNE visualization
                    ZStack {
                        ForEach(0..<20, id: \.self) { i in
                            let x = CGFloat.random(in: 20...280)
                            let y = CGFloat.random(in: 20...100)
                            Circle()
                                .fill(CartoMixColors.colorForSection(["drop", "intro", "build", "breakdown", "outro"][i % 5]))
                                .frame(width: 10, height: 10)
                                .position(x: x, y: y)
                        }
                    }
                    .frame(height: 120)
                    .background(CartoMixColors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
                }
                .frame(maxWidth: .infinity)
                .cardStyle()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CartoMixColors.backgroundPrimary)
        }
        .preferredColorScheme(.dark)
    }
}

struct SimilarSectionRow: View {
    let title: String
    let artist: String
    let score: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(artist)
                    .font(CartoMixTypography.caption)
                    .foregroundStyle(CartoMixColors.textSecondary)
            }
            Spacer()
            Text("\(score)%")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CartoMixColors.accentGreen)
            Button("Preview") {}
                .buttonStyle(SecondaryButtonStyle())
                .controlSize(.small)
        }
        .padding(CartoMixSpacing.sm)
        .background(CartoMixColors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }
}
