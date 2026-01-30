// CartoMix - Programmatic Screenshot Generator
// Renders SwiftUI views to images for documentation

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
        // Default to docs/assets/screens in the current working directory
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
        // Create output directory
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        print("Generating screenshots to: \(outputDirectory.path)")

        // Generate mock data for screenshots
        let mockTracks = createMockTracks()
        let mockAnalysis = createMockAnalysis()

        // 1. Library View
        print("  Generating: library-view")
        try await renderView(
            LibraryViewPreview(tracks: mockTracks),
            filename: "library-view"
        )

        // 2. Set Builder View
        print("  Generating: set-builder")
        try await renderView(
            SetBuilderPreview(tracks: Array(mockTracks.prefix(5))),
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
            EnergyMatchingPreview(analysis: mockAnalysis),
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

    /// Render a SwiftUI view to an image file
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

        // Save as PNG
        let pngURL = outputDirectory.appendingPathComponent("\(filename).png")
        try pngData.write(to: pngURL)

        // Convert to WebP if cwebp is available
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
            Track(
                id: 1,
                contentHash: "abc123",
                path: "/Music/Daft Punk/Random Access Memories/Get Lucky.mp3",
                title: "Get Lucky",
                artist: "Daft Punk",
                album: "Random Access Memories",
                fileSize: 12_500_000,
                fileModifiedAt: Date(),
                createdAt: Date(),
                updatedAt: Date()
            ),
            Track(
                id: 2,
                contentHash: "def456",
                path: "/Music/Daft Punk/Random Access Memories/Instant Crush.mp3",
                title: "Instant Crush",
                artist: "Daft Punk",
                album: "Random Access Memories",
                fileSize: 11_200_000,
                fileModifiedAt: Date(),
                createdAt: Date(),
                updatedAt: Date()
            ),
            Track(
                id: 3,
                contentHash: "ghi789",
                path: "/Music/ZHU/ERUM/In The Morning.mp3",
                title: "In The Morning",
                artist: "ZHU",
                album: "ERUM",
                fileSize: 9_800_000,
                fileModifiedAt: Date(),
                createdAt: Date(),
                updatedAt: Date()
            ),
            Track(
                id: 4,
                contentHash: "jkl012",
                path: "/Music/Disclosure/Settle/Latch.mp3",
                title: "Latch",
                artist: "Disclosure",
                album: "Settle",
                fileSize: 10_500_000,
                fileModifiedAt: Date(),
                createdAt: Date(),
                updatedAt: Date()
            ),
            Track(
                id: 5,
                contentHash: "mno345",
                path: "/Music/ODESZA/A Moment Apart/Line of Sight.mp3",
                title: "Line of Sight",
                artist: "ODESZA",
                album: "A Moment Apart",
                fileSize: 11_800_000,
                fileModifiedAt: Date(),
                createdAt: Date(),
                updatedAt: Date()
            ),
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

        // Generate mock waveform data
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
            id: 1,
            trackId: 1,
            version: 1,
            status: .complete,
            durationSeconds: 285,
            bpm: 116,
            bpmConfidence: 0.95,
            keyValue: "4A",
            keyFormat: "camelot",
            keyConfidence: 0.88,
            energyGlobal: 75,
            integratedLUFS: -8.5,
            truePeakDB: -0.3,
            loudnessRange: 6.2,
            waveformPreview: waveform,
            sections: sections,
            cuePoints: cuePoints,
            soundContext: "Electronic / Dance",
            soundContextConfidence: 0.92,
            qaFlags: [],
            hasOpenL3Embedding: true,
            trainingLabels: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Preview Views for Screenshots

struct LibraryViewPreview: View {
    let tracks: [Track]

    var body: some View {
        VStack(spacing: 0) {
            // Mock toolbar
            HStack {
                Text("CartoMix")
                    .font(.title2.bold())
                Spacer()
                HStack(spacing: 16) {
                    Label("Library", systemImage: "music.note.list")
                    Label("Set Builder", systemImage: "list.bullet.rectangle")
                    Label("Graph", systemImage: "point.3.connected.trianglepath.dotted")
                }
                Spacer()
                TextField("Search...", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            .padding()
            .background(.bar)

            // Track list
            List {
                ForEach(tracks, id: \.id) { track in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(track.title)
                                .font(.headline)
                            Text(track.artist)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("116 BPM")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.2), in: Capsule())
                            Text("4A")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.2), in: Capsule())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct SetBuilderPreview: View {
    let tracks: [Track]

    var body: some View {
        VStack(spacing: 0) {
            Text("Set Builder")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.bar)

            HStack(spacing: 20) {
                // Set list
                VStack(alignment: .leading, spacing: 8) {
                    Text("My Set")
                        .font(.headline)
                    ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .frame(width: 24)
                            Text(track.title)
                            Spacer()
                            Text("→")
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(maxWidth: 300)

                // Transition info
                VStack(alignment: .leading) {
                    Text("Transition: Track 2 → Track 3")
                        .font(.headline)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("BPM: 116 → 118")
                            Text("Key: 4A → 5A ✓")
                            Text("Energy: +5%")
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct GraphViewPreview: View {
    let tracks: [Track]

    var body: some View {
        VStack(spacing: 0) {
            Text("Similarity Graph")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.bar)

            ZStack {
                // Mock graph visualization
                ForEach(0..<5, id: \.self) { i in
                    let angle = Double(i) * (2 * .pi / 5)
                    let x = cos(angle) * 150 + 300
                    let y = sin(angle) * 150 + 200

                    Circle()
                        .fill(.blue)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Text(tracks[i].title.prefix(3))
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .position(x: x, y: y)
                }

                // Connection lines
                Path { path in
                    for i in 0..<5 {
                        let angle1 = Double(i) * (2 * .pi / 5)
                        let angle2 = Double((i + 1) % 5) * (2 * .pi / 5)
                        path.move(to: CGPoint(x: cos(angle1) * 150 + 300, y: sin(angle1) * 150 + 200))
                        path.addLine(to: CGPoint(x: cos(angle2) * 150 + 300, y: sin(angle2) * 150 + 200))
                    }
                }
                .stroke(.gray.opacity(0.3), lineWidth: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.background)
    }
}

struct TrackAnalysisPreview: View {
    let track: Track
    let analysis: TrackAnalysis

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(track.title)
                        .font(.title2.bold())
                    Text(track.artist)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 12) {
                    ScreenshotBadge(label: "\(Int(analysis.bpm)) BPM", color: .blue)
                    ScreenshotBadge(label: analysis.keyValue, color: .green)
                    ScreenshotBadge(label: "Energy: \(analysis.energyGlobal)", color: .orange)
                }
            }
            .padding()
            .background(.bar)

            // Content
            ScrollView {
                VStack(spacing: 16) {
                    // Waveform
                    MockWaveformView(waveform: analysis.waveformPreview)
                        .frame(height: 120)

                    // Sections
                    VStack(alignment: .leading) {
                        Text("Sections")
                            .font(.headline)
                        HStack(spacing: 4) {
                            ForEach(analysis.sections, id: \.startTime) { section in
                                Rectangle()
                                    .fill(section.color)
                                    .frame(width: CGFloat(section.duration) * 2)
                                    .overlay {
                                        Text(section.type.rawValue.prefix(3))
                                            .font(.caption2)
                                            .foregroundStyle(.white)
                                    }
                            }
                        }
                        .frame(height: 30)
                    }
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                    // Cue Points
                    VStack(alignment: .leading) {
                        Text("Cue Points")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(analysis.cuePoints, id: \.index) { cue in
                                HStack {
                                    Circle()
                                        .fill(cue.color)
                                        .frame(width: 8, height: 8)
                                    Text(cue.label)
                                        .font(.caption)
                                }
                                .padding(6)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct WaveformPaintingPreview: View {
    let analysis: TrackAnalysis

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Waveform Label Painting")
                    .font(.title2.bold())
                Spacer()
                Toggle("Paint Mode", isOn: .constant(true))
                    .toggleStyle(.button)
                    .tint(.blue)
                Picker("Section", selection: .constant(TrackSection.SectionType.drop)) {
                    ForEach(TrackSection.SectionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .frame(width: 120)
            }
            .padding()
            .background(.bar)

            VStack(spacing: 16) {
                // Waveform with painted sections
                ZStack(alignment: .bottom) {
                    // Section backgrounds
                    HStack(spacing: 0) {
                        ForEach(analysis.sections, id: \.startTime) { section in
                            Rectangle()
                                .fill(section.color.opacity(0.3))
                                .frame(width: CGFloat(section.duration) * 3)
                        }
                    }

                    // Waveform
                    MockWaveformView(waveform: analysis.waveformPreview)
                }
                .frame(height: 200)
                .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))

                // Legend
                HStack(spacing: 12) {
                    ForEach(TrackSection.SectionType.allCases, id: \.self) { type in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(type.color)
                                .frame(width: 8, height: 8)
                            Text(type.displayName)
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct AudioPlaybackPreview: View {
    let analysis: TrackAnalysis

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Audio Playback")
                    .font(.title2.bold())
                Spacer()
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                    }
                    Button(action: {}) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                    }
                }
                Spacer()
                Text("1:45 / 4:45")
                    .font(.caption.monospacedDigit())
            }
            .padding()
            .background(.bar)

            VStack(spacing: 16) {
                // Waveform with playhead
                ZStack(alignment: .leading) {
                    MockWaveformView(waveform: analysis.waveformPreview)

                    // Playhead
                    Rectangle()
                        .fill(.white)
                        .frame(width: 2)
                        .offset(x: 350)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                }
                .frame(height: 200)
                .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))

                // Transport controls
                HStack {
                    Text("Space: Play/Pause")
                    Text("←/→: Skip 5s")
                    Text("Click: Seek")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct UserOverridesPreview: View {
    let analysis: TrackAnalysis

    var body: some View {
        VStack(spacing: 0) {
            Text("User Overrides")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.bar)

            HStack(alignment: .top, spacing: 20) {
                // BPM Override
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("BPM")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.orange)
                    }
                    HStack {
                        Text("Auto: 116.2")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    HStack {
                        TextField("Override", text: .constant("116"))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Toggle("Lock", isOn: .constant(true))
                            .toggleStyle(.button)
                    }
                }
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                // Key Override
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key")
                        .font(.headline)
                    HStack {
                        Text("Auto: 4A")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    Picker("Key", selection: .constant("4A")) {
                        Text("4A").tag("4A")
                        Text("5A").tag("5A")
                    }
                    .pickerStyle(.menu)
                }
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                // Custom Cue Points
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Cue Points")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(.red).frame(width: 8, height: 8)
                            Text("My Drop Marker - 1:30")
                                .font(.caption)
                        }
                        HStack {
                            Circle().fill(.green).frame(width: 8, height: 8)
                            Text("Mix In Point - 0:45")
                                .font(.caption)
                        }
                    }
                    Button("Add Cue Point") {}
                        .buttonStyle(.bordered)
                }
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct TransitionDetectionPreview: View {
    let analysis: TrackAnalysis

    var body: some View {
        VStack(spacing: 0) {
            Text("Transition Detection")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.bar)

            HStack(spacing: 20) {
                // Track A waveform
                VStack(alignment: .leading) {
                    Text("Track A: Get Lucky")
                        .font(.headline)
                    ZStack(alignment: .bottom) {
                        MockWaveformView(waveform: analysis.waveformPreview)
                        // Mix-out points
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(.red)
                                .frame(width: 2, height: 80)
                                .overlay(alignment: .top) {
                                    Text("Out")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                        .offset(y: -15)
                                }
                        }
                        .padding(.trailing, 100)
                    }
                    .frame(height: 100)
                    .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }

                // Track B waveform
                VStack(alignment: .leading) {
                    Text("Track B: Instant Crush")
                        .font(.headline)
                    ZStack(alignment: .bottom) {
                        MockWaveformView(waveform: analysis.waveformPreview.reversed())
                        // Mix-in points
                        HStack {
                            Rectangle()
                                .fill(.green)
                                .frame(width: 2, height: 80)
                                .overlay(alignment: .top) {
                                    Text("In")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                        .offset(y: -15)
                                }
                            Spacer()
                        }
                        .padding(.leading, 50)
                    }
                    .frame(height: 100)
                    .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()

            // Transition recommendation
            VStack(alignment: .leading) {
                Text("Recommended Transition")
                    .font(.headline)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Mix-out: 3:45 (breakdown before drop)")
                        Text("Mix-in: 0:30 (after intro)")
                        Text("Transition length: 16 bars")
                    }
                    .font(.subheadline)
                    Spacer()
                    Text("95%")
                        .font(.title)
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct EnergyMatchingPreview: View {
    let analysis: TrackAnalysis

    var body: some View {
        VStack(spacing: 0) {
            Text("Energy Curve Matching")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.bar)

            HStack(spacing: 20) {
                // Energy curve visualization
                VStack(alignment: .leading) {
                    Text("Energy Curves")
                        .font(.headline)
                    ZStack {
                        // Track A curve (blue)
                        MockEnergyCurve(color: .blue, label: "Track A")
                        // Track B curve (orange)
                        MockEnergyCurve(color: .orange, label: "Track B", offset: 0.2)
                    }
                    .frame(height: 150)
                    .background(.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxWidth: .infinity)

                // Match results
                VStack(alignment: .leading, spacing: 12) {
                    Text("Match Results")
                        .font(.headline)

                    MatchResult(type: "Parallel", score: 85, color: .blue)
                    MatchResult(type: "Complementary", score: 72, color: .purple)
                    MatchResult(type: "Continuation", score: 91, color: .green)
                }
                .frame(width: 200)
            }
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct SectionEmbeddingsPreview: View {
    let analysis: TrackAnalysis

    var body: some View {
        VStack(spacing: 0) {
            Text("Section-Level Embeddings")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.bar)

            HStack(alignment: .top, spacing: 20) {
                // Section list
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sections")
                        .font(.headline)
                    ForEach(analysis.sections, id: \.startTime) { section in
                        HStack {
                            Circle()
                                .fill(section.color)
                                .frame(width: 12, height: 12)
                            Text(section.type.displayName)
                            Spacer()
                            Text("512-dim")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(width: 250)

                // Similar sections
                VStack(alignment: .leading, spacing: 8) {
                    Text("Similar Drops in Library")
                        .font(.headline)
                    ForEach(0..<4, id: \.self) { i in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Track \(i + 1) - Drop")
                                    .font(.subheadline)
                                Text("95% match")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                            Spacer()
                            Button("Preview") {}
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

// MARK: - Helper Views

struct ScreenshotBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.2), in: Capsule())
            .foregroundStyle(color)
    }
}

struct MockWaveformView: View {
    let waveform: [Float]

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let midY = size.height / 2
                let step = max(1, waveform.count / Int(size.width))

                var path = Path()
                path.move(to: CGPoint(x: 0, y: midY))

                for x in stride(from: 0, to: Int(size.width), by: 1) {
                    let idx = min(x * step, waveform.count - 1)
                    let sample = CGFloat(waveform[idx])
                    path.addLine(to: CGPoint(x: CGFloat(x), y: midY - sample * midY * 0.8))
                }

                for x in stride(from: Int(size.width) - 1, through: 0, by: -1) {
                    let idx = min(x * step, waveform.count - 1)
                    let sample = CGFloat(waveform[idx])
                    path.addLine(to: CGPoint(x: CGFloat(x), y: midY + sample * midY * 0.8))
                }

                path.closeSubpath()

                context.fill(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [.cyan.opacity(0.8), .blue.opacity(0.6), .purple.opacity(0.4)]),
                        startPoint: CGPoint(x: 0, y: size.height / 2),
                        endPoint: CGPoint(x: size.width, y: size.height / 2)
                    )
                )
            }
        }
    }
}

struct MockEnergyCurve: View {
    let color: Color
    let label: String
    var offset: Double = 0

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height

                path.move(to: CGPoint(x: 0, y: height * 0.8))

                for x in stride(from: 0, to: width, by: 2) {
                    let progress = x / width
                    let energy = sin((progress + offset) * .pi * 2) * 0.3 + 0.5
                    let y = height * (1 - energy)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 2)

            Text(label)
                .font(.caption)
                .foregroundStyle(color)
                .position(x: 50, y: 20 + offset * 30)
        }
    }
}

struct MatchResult: View {
    let type: String
    let score: Int
    let color: Color

    var body: some View {
        HStack {
            Text(type)
            Spacer()
            Text("\(score)%")
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding(8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}
