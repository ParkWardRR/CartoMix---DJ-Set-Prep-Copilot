// Dardania - Serato Exporter
// Port of internal/exporter/serato.go

import Foundation

/// Serato .crate binary format exporter
public struct SeratoExporter {

    // MARK: - Binary Format Constants

    private static let crateHeader: [UInt8] = [
        0x76, 0x72, 0x73, 0x6e, // "vrsn"
        0x00, 0x00, 0x00, 0x38, // version header size (56 bytes)
    ]

    private static let versionString = "1.0/Serato ScratchLive Crate"

    // MARK: - Cue Marker Colors

    nonisolated(unsafe) static let cueColors: [CuePoint.CueType: (r: UInt8, g: UInt8, b: UInt8)] = [
        .intro: (0x28, 0xE2, 0x14),      // Green
        .drop: (0xE6, 0x14, 0x14),       // Red
        .breakdown: (0x14, 0x82, 0xE6),  // Blue
        .build: (0xE6, 0x96, 0x14),      // Orange
        .outro: (0xC8, 0x14, 0xC8),      // Purple
        .custom: (0xFF, 0xFF, 0xFF),     // White
    ]

    // MARK: - Export

    /// Export tracks to Serato .crate format
    public static func export(
        tracks: [Track],
        crateName: String,
        to directory: URL
    ) throws -> (crateURL: URL, cuesURL: URL) {
        // Create crate file
        var crateData = Data()

        // Write header
        crateData.append(contentsOf: crateHeader)

        // Write version string (UTF-16BE)
        let versionUTF16 = encodeUTF16BE(versionString)
        crateData.append(contentsOf: versionUTF16)

        // Pad to 56 bytes
        let paddingNeeded = 56 - 8 - versionUTF16.count
        if paddingNeeded > 0 {
            crateData.append(contentsOf: [UInt8](repeating: 0, count: paddingNeeded))
        }

        // Write tracks
        for track in tracks {
            // Track chunk header "otrk"
            crateData.append(contentsOf: [0x6f, 0x74, 0x72, 0x6b]) // "otrk"

            // Track data
            var trackChunk = Data()

            // "ptrk" - path tag
            trackChunk.append(contentsOf: [0x70, 0x74, 0x72, 0x6b]) // "ptrk"
            let pathUTF16 = encodeUTF16BE(track.path)
            trackChunk.append(bigEndian: UInt32(pathUTF16.count))
            trackChunk.append(contentsOf: pathUTF16)

            // Track chunk size
            crateData.append(bigEndian: UInt32(trackChunk.count))
            crateData.append(trackChunk)
        }

        // Write crate file
        let crateFilename = "\(crateName).crate"
        let crateURL = directory.appendingPathComponent(crateFilename)
        try crateData.write(to: crateURL)

        // Write supplementary cues CSV
        let cuesURL = try exportCuesCSV(tracks: tracks, crateName: crateName, to: directory)

        return (crateURL, cuesURL)
    }

    /// Export cue markers to CSV (supplementary file)
    private static func exportCuesCSV(
        tracks: [Track],
        crateName: String,
        to directory: URL
    ) throws -> URL {
        var csv = "Path,Cue Index,Name,Type,Position (ms),Color R,Color G,Color B\n"

        for track in tracks {
            guard let analysis = track.analysis else { continue }

            for (index, cue) in analysis.cuePoints.enumerated() {
                let color = cueColors[cue.type] ?? (0xFF, 0xFF, 0xFF)
                let positionMs = Int(cue.timeSeconds * 1000)

                csv += "\"\(escapeCSV(track.path))\","
                csv += "\(index),"
                csv += "\"\(escapeCSV(cue.label))\","
                csv += "\"\(cue.type.rawValue)\","
                csv += "\(positionMs),"
                csv += "\(color.r),\(color.g),\(color.b)\n"
            }
        }

        let cuesFilename = "\(crateName)_cues.csv"
        let cuesURL = directory.appendingPathComponent(cuesFilename)
        try csv.write(to: cuesURL, atomically: true, encoding: .utf8)

        return cuesURL
    }

    /// Export cue markers as Serato binary markers
    /// (This would go in the file's ID3 tags or a sidecar file)
    public static func encodeSeratoMarkers(cues: [CuePoint]) -> Data {
        var data = Data()

        // Marker header
        data.append(0x02) // Version

        // Number of cues (max 8 for Serato)
        let cueCount = min(cues.count, 8)
        data.append(UInt8(cueCount))

        for (index, cue) in cues.prefix(8).enumerated() {
            // Cue index
            data.append(UInt8(index))

            // Position in milliseconds (big-endian 4 bytes)
            let positionMs = UInt32(cue.timeSeconds * 1000)
            data.append(bigEndian: positionMs)

            // Color (RGB)
            let color = cueColors[cue.type] ?? (0xFF, 0xFF, 0xFF)
            data.append(color.r)
            data.append(color.g)
            data.append(color.b)

            // Label (variable length, null-terminated)
            let labelBytes = cue.label.utf8
            data.append(UInt8(labelBytes.count))
            data.append(contentsOf: labelBytes)
        }

        return data
    }

    // MARK: - Helpers

    /// Encode string as UTF-16 Big Endian
    private static func encodeUTF16BE(_ string: String) -> [UInt8] {
        let utf16 = Array(string.utf16)
        var bytes: [UInt8] = []
        bytes.reserveCapacity(utf16.count * 2)

        for codeUnit in utf16 {
            bytes.append(UInt8(codeUnit >> 8))    // High byte first
            bytes.append(UInt8(codeUnit & 0xFF))  // Low byte
        }

        return bytes
    }

    /// Escape string for CSV
    private static func escapeCSV(_ string: String) -> String {
        string.replacingOccurrences(of: "\"", with: "\"\"")
    }
}

// MARK: - Data Extensions

private extension Data {
    mutating func append(bigEndian value: UInt32) {
        var bigEndian = value.bigEndian
        append(contentsOf: Swift.withUnsafeBytes(of: &bigEndian) { Array($0) })
    }
}
