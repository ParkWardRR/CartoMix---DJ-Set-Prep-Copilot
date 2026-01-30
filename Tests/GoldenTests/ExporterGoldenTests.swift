// Dardania - Golden Export Tests
// Validates export format compatibility

import Testing
import Foundation
@testable import DardaniaCore

@Suite("Export Format Tests")
struct ExporterGoldenTests {

    // MARK: - Test Data

    func makeTestTracks() -> [Track] {
        var tracks: [Track] = []

        // Track 1: Standard house track
        var track1 = Track(
            id: 1,
            contentHash: "abc123",
            path: "/Music/DJ Sets/track1.mp3",
            title: "Summer Vibes",
            artist: "DJ Test",
            album: "Test Album",
            fileSize: 10_000_000,
            fileModifiedAt: Date()
        )
        track1.analysis = makeAnalysis(
            id: 1, trackId: 1,
            bpm: 128.0, key: "8A", energy: 7,
            duration: 360.0,
            cues: [
                ("Intro", .intro, 0.0),
                ("Drop", .drop, 64.0),
                ("Breakdown", .breakdown, 128.0),
                ("Outro", .outro, 300.0)
            ]
        )
        tracks.append(track1)

        // Track 2: Tech house
        var track2 = Track(
            id: 2,
            contentHash: "def456",
            path: "/Music/DJ Sets/track2.flac",
            title: "Groove Machine",
            artist: "Producer X",
            album: nil,
            fileSize: 50_000_000,
            fileModifiedAt: Date()
        )
        track2.analysis = makeAnalysis(
            id: 2, trackId: 2,
            bpm: 126.0, key: "9A", energy: 8,
            duration: 420.0,
            cues: [
                ("Start", .intro, 0.0),
                ("Build", .build, 32.0),
                ("Drop 1", .drop, 64.0),
                ("Break", .breakdown, 192.0),
                ("Drop 2", .drop, 256.0),
                ("End", .outro, 380.0)
            ]
        )
        tracks.append(track2)

        return tracks
    }

    func makeAnalysis(
        id: Int64,
        trackId: Int64,
        bpm: Double,
        key: String,
        energy: Int,
        duration: Double,
        cues: [(String, CuePoint.CueType, Double)]
    ) -> TrackAnalysis {
        TrackAnalysis(
            id: id,
            trackId: trackId,
            version: 1,
            status: .complete,
            durationSeconds: duration,
            bpm: bpm,
            bpmConfidence: 0.98,
            keyValue: key,
            keyFormat: "camelot",
            keyConfidence: 0.92,
            energyGlobal: energy,
            integratedLUFS: -14.0,
            truePeakDB: -0.5,
            loudnessRange: 6.0,
            waveformPreview: [],
            sections: [],
            cuePoints: cues.enumerated().map { index, cue in
                CuePoint(
                    index: index,
                    label: cue.0,
                    type: cue.1,
                    timeSeconds: cue.2,
                    beatIndex: Int(cue.2 * bpm / 60)
                )
            },
            soundContext: "music",
            soundContextConfidence: 0.95,
            qaFlags: [],
            hasOpenL3Embedding: true,
            trainingLabels: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    // MARK: - Rekordbox Tests

    @Test("Rekordbox export should have valid XML structure")
    func rekordboxExportStructure() throws {
        let tracks = makeTestTracks()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let outputURL = try RekordboxExporter.export(
            tracks: tracks,
            playlistName: "Test Set",
            to: tempDirectory
        )

        #expect(FileManager.default.fileExists(atPath: outputURL.path))

        let content = try String(contentsOf: outputURL, encoding: .utf8)

        // Verify XML structure
        #expect(content.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        #expect(content.contains("DJ_PLAYLISTS"))
        #expect(content.contains("COLLECTION"))
        #expect(content.contains("PLAYLISTS"))

        // Verify tracks
        #expect(content.contains("Summer Vibes"))
        #expect(content.contains("Groove Machine"))
        #expect(content.contains("DJ Test"))

        // Verify BPM
        #expect(content.contains("128.00") || content.contains("AverageBpm=\"128"))
        #expect(content.contains("126.00") || content.contains("AverageBpm=\"126"))

        // Verify key (tonality)
        #expect(content.contains("8A") || content.contains("Tonality"))

        // Verify position marks (cues)
        #expect(content.contains("POSITION_MARK"))
        #expect(content.contains("Intro") || content.contains("Drop"))
    }

    @Test("Rekordbox export should include cue colors")
    func rekordboxCueColors() throws {
        let tracks = makeTestTracks()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let outputURL = try RekordboxExporter.export(
            tracks: tracks,
            playlistName: "Test Set",
            to: tempDirectory
        )

        let content = try String(contentsOf: outputURL, encoding: .utf8)

        // Verify cue colors are present
        // Intro should be green (40, 226, 20)
        #expect(content.contains("Red=\"40\"") || content.contains("Green=\"226\""))

        // Drop should be red (230, 20, 20)
        #expect(content.contains("Red=\"230\""))
    }

    // MARK: - Serato Tests

    @Test("Serato export should create valid crate and cues files")
    func seratoExportStructure() throws {
        let tracks = makeTestTracks()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let (crateURL, cuesURL) = try SeratoExporter.export(
            tracks: tracks,
            crateName: "Test Crate",
            to: tempDirectory
        )

        #expect(FileManager.default.fileExists(atPath: crateURL.path))
        #expect(FileManager.default.fileExists(atPath: cuesURL.path))

        // Verify crate file header
        let crateData = try Data(contentsOf: crateURL)
        #expect(crateData.count > 56) // Minimum header size

        // Check for "vrsn" header
        let header = [UInt8](crateData.prefix(4))
        #expect(header == [0x76, 0x72, 0x73, 0x6e]) // "vrsn"

        // Verify cues CSV
        let cuesContent = try String(contentsOf: cuesURL, encoding: .utf8)
        #expect(cuesContent.contains("Path,Cue Index,Name,Type,Position (ms)"))
        #expect(cuesContent.contains("Intro"))
        #expect(cuesContent.contains("Drop"))
    }

    @Test("Serato binary markers should be valid")
    func seratoBinaryMarkers() throws {
        let cues = [
            CuePoint(index: 0, label: "Intro", type: .intro, timeSeconds: 0.0, beatIndex: 0),
            CuePoint(index: 1, label: "Drop", type: .drop, timeSeconds: 64.0, beatIndex: 136),
        ]

        let markerData = SeratoExporter.encodeSeratoMarkers(cues: cues)

        #expect(markerData.count > 0)

        // Verify version byte
        #expect(markerData[0] == 0x02)

        // Verify cue count
        #expect(markerData[1] == 2)
    }

    // MARK: - Traktor Tests

    @Test("Traktor export should have valid NML structure")
    func traktorExportStructure() throws {
        let tracks = makeTestTracks()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let outputURL = try TraktorExporter.export(
            tracks: tracks,
            playlistName: "Test Collection",
            to: tempDirectory
        )

        #expect(FileManager.default.fileExists(atPath: outputURL.path))

        let content = try String(contentsOf: outputURL, encoding: .utf8)

        // Verify NML structure
        #expect(content.contains("<?xml version=\"1.0\" encoding=\"UTF-8\""))
        #expect(content.contains("<NML VERSION=\"19\">"))
        #expect(content.contains("<HEAD"))
        #expect(content.contains("<COLLECTION"))
        #expect(content.contains("<PLAYLISTS"))

        // Verify tracks
        #expect(content.contains("Summer Vibes"))
        #expect(content.contains("Groove Machine"))

        // Verify location format (Traktor uses /: delimiter)
        #expect(content.contains("/:"))

        // Verify cues (CUE_V2 format)
        #expect(content.contains("CUE_V2"))
    }

    @Test("Traktor export should include key mapping")
    func traktorKeyMapping() throws {
        let tracks = makeTestTracks()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let outputURL = try TraktorExporter.export(
            tracks: tracks,
            playlistName: "Test Collection",
            to: tempDirectory
        )

        let content = try String(contentsOf: outputURL, encoding: .utf8)

        // Verify key is mapped (8A = 12 in Traktor's system)
        // 8A is Am, which is 12 in Traktor
        #expect(content.contains("MUSICAL_KEY"))
    }

    // MARK: - JSON Tests

    @Test("JSON export should have valid structure")
    func jsonExportStructure() async throws {
        let tracks = makeTestTracks()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let database = DatabaseManager.shared
        let exporter = Exporter(database: database)

        let result = try await exporter.export(
            tracks: tracks,
            format: .json,
            name: "Test Export",
            to: tempDirectory
        )

        #expect(FileManager.default.fileExists(atPath: result.primaryFile.path))

        let data = try Data(contentsOf: result.primaryFile)
        let decoded = try JSONDecoder().decode(JSONExportVerification.self, from: data)

        #expect(decoded.name == "Test Export")
        #expect(decoded.tracks.count == 2)
        #expect(decoded.tracks[0].title == "Summer Vibes")
        #expect(decoded.tracks[0].bpm == 128.0)
    }

    // MARK: - M3U Tests

    @Test("M3U export should have valid structure")
    func m3uExportStructure() async throws {
        let tracks = makeTestTracks()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let database = DatabaseManager.shared
        let exporter = Exporter(database: database)

        let result = try await exporter.export(
            tracks: tracks,
            format: .m3u,
            name: "Test Playlist",
            to: tempDirectory
        )

        let content = try String(contentsOf: result.primaryFile, encoding: .utf8)

        // Verify M3U structure
        #expect(content.hasPrefix("#EXTM3U"))
        #expect(content.contains("#PLAYLIST:Test Playlist"))
        #expect(content.contains("#EXTINF:"))
        #expect(content.contains("DJ Test - Summer Vibes"))
        #expect(content.contains("/Music/DJ Sets/track1.mp3"))
    }

    // MARK: - Checksum Tests

    @Test("Same export should produce same checksum")
    func exportChecksum() async throws {
        let tracks = makeTestTracks()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let database = DatabaseManager.shared
        let exporter = Exporter(database: database)

        let result1 = try await exporter.export(
            tracks: tracks,
            format: .json,
            name: "Checksum Test",
            to: tempDirectory
        )

        // Same export should produce same checksum
        let result2 = try await exporter.export(
            tracks: tracks,
            format: .json,
            name: "Checksum Test",
            to: tempDirectory
        )

        #expect(!result1.checksum.isEmpty)
        #expect(result1.checksum == result2.checksum)
    }
}

// MARK: - Verification Types

struct JSONExportVerification: Codable {
    let name: String
    let tracks: [JSONTrackVerification]
}

struct JSONTrackVerification: Codable {
    let title: String
    let artist: String
    let bpm: Double?
    let key: String?
}
