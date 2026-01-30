// Dardania - Unified Exporter

import Foundation

/// Export format options
public enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case rekordbox
    case serato
    case traktor
    case json
    case m3u
    case csv

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .rekordbox: return "Rekordbox"
        case .serato: return "Serato"
        case .traktor: return "Traktor"
        case .json: return "JSON"
        case .m3u: return "M3U8"
        case .csv: return "CSV"
        }
    }

    public var fileExtension: String {
        switch self {
        case .rekordbox: return "xml"
        case .serato: return "crate"
        case .traktor: return "nml"
        case .json: return "json"
        case .m3u: return "m3u8"
        case .csv: return "csv"
        }
    }
}

/// Export result
public struct ExportResult: Sendable {
    public let format: ExportFormat
    public let primaryFile: URL
    public let supplementaryFiles: [URL]
    public let checksum: String

    public init(format: ExportFormat, primaryFile: URL, supplementaryFiles: [URL] = [], checksum: String = "") {
        self.format = format
        self.primaryFile = primaryFile
        self.supplementaryFiles = supplementaryFiles
        self.checksum = checksum
    }
}

/// Unified exporter interface
public actor Exporter {
    private let database: DatabaseManager

    public init(database: DatabaseManager) {
        self.database = database
    }

    /// Export tracks to specified format
    public func export(
        tracks: [Track],
        format: ExportFormat,
        name: String,
        to directory: URL
    ) async throws -> ExportResult {
        // Ensure directory exists
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        switch format {
        case .rekordbox:
            let url = try RekordboxExporter.export(tracks: tracks, playlistName: name, to: directory)
            let checksum = try computeChecksum(url: url)
            return ExportResult(format: format, primaryFile: url, checksum: checksum)

        case .serato:
            let (crateURL, cuesURL) = try SeratoExporter.export(tracks: tracks, crateName: name, to: directory)
            let checksum = try computeChecksum(url: crateURL)
            return ExportResult(format: format, primaryFile: crateURL, supplementaryFiles: [cuesURL], checksum: checksum)

        case .traktor:
            let url = try TraktorExporter.export(tracks: tracks, playlistName: name, to: directory)
            let checksum = try computeChecksum(url: url)
            return ExportResult(format: format, primaryFile: url, checksum: checksum)

        case .json:
            let url = try exportJSON(tracks: tracks, name: name, to: directory)
            let checksum = try computeChecksum(url: url)
            return ExportResult(format: format, primaryFile: url, checksum: checksum)

        case .m3u:
            let url = try exportM3U(tracks: tracks, name: name, to: directory)
            let checksum = try computeChecksum(url: url)
            return ExportResult(format: format, primaryFile: url, checksum: checksum)

        case .csv:
            let url = try exportCSV(tracks: tracks, name: name, to: directory)
            let checksum = try computeChecksum(url: url)
            return ExportResult(format: format, primaryFile: url, checksum: checksum)
        }
    }

    // MARK: - JSON Export

    private func exportJSON(tracks: [Track], name: String, to directory: URL) throws -> URL {
        let exportData = JSONExportData(
            name: name,
            exportedAt: Date(),
            tracks: tracks.map { JSONExportTrack(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(exportData)
        let url = directory.appendingPathComponent("\(name).json")
        try data.write(to: url)

        return url
    }

    // MARK: - M3U Export

    private func exportM3U(tracks: [Track], name: String, to directory: URL) throws -> URL {
        var m3u = "#EXTM3U\n"
        m3u += "#PLAYLIST:\(name)\n\n"

        for track in tracks {
            let duration = Int(track.analysis?.durationSeconds ?? 0)
            m3u += "#EXTINF:\(duration),\(track.artist) - \(track.title)\n"
            m3u += "\(track.path)\n"
        }

        let url = directory.appendingPathComponent("\(name).m3u8")
        try m3u.write(to: url, atomically: true, encoding: .utf8)

        return url
    }

    // MARK: - CSV Export

    private func exportCSV(tracks: [Track], name: String, to directory: URL) throws -> URL {
        var csv = "Title,Artist,Album,BPM,Key,Energy,Duration,Loudness (LUFS),Path\n"

        for track in tracks {
            let analysis = track.analysis
            csv += "\"\(escapeCSV(track.title))\","
            csv += "\"\(escapeCSV(track.artist))\","
            csv += "\"\(escapeCSV(track.album ?? ""))\","
            csv += "\(String(format: "%.2f", analysis?.bpm ?? 0)),"
            csv += "\(analysis?.keyValue ?? ""),"
            csv += "\(analysis?.energyGlobal ?? 0),"
            csv += "\(String(format: "%.1f", analysis?.durationSeconds ?? 0)),"
            csv += "\(String(format: "%.1f", analysis?.integratedLUFS ?? 0)),"
            csv += "\"\(escapeCSV(track.path))\"\n"
        }

        let url = directory.appendingPathComponent("\(name).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)

        return url
    }

    // MARK: - Helpers

    private func escapeCSV(_ string: String) -> String {
        string.replacingOccurrences(of: "\"", with: "\"\"")
    }

    private func computeChecksum(url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        return data.sha256().hexString
    }
}

// MARK: - JSON Export Types

struct JSONExportData: Codable {
    let name: String
    let exportedAt: Date
    let tracks: [JSONExportTrack]
}

struct JSONExportTrack: Codable {
    let title: String
    let artist: String
    let album: String?
    let path: String
    let bpm: Double?
    let key: String?
    let energy: Int?
    let duration: Double?
    let loudness: Double?
    let cuePoints: [JSONExportCue]?

    init(from track: Track) {
        self.title = track.title
        self.artist = track.artist
        self.album = track.album
        self.path = track.path
        self.bpm = track.analysis?.bpm
        self.key = track.analysis?.keyValue
        self.energy = track.analysis?.energyGlobal
        self.duration = track.analysis?.durationSeconds
        self.loudness = track.analysis?.integratedLUFS
        self.cuePoints = track.analysis?.cuePoints.map { JSONExportCue(from: $0) }
    }
}

struct JSONExportCue: Codable {
    let label: String
    let type: String
    let time: Double

    init(from cue: CuePoint) {
        self.label = cue.label
        self.type = cue.type.rawValue
        self.time = cue.timeSeconds
    }
}

// MARK: - Data Extensions

extension Data {
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        return Data(hash)
    }

    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto
