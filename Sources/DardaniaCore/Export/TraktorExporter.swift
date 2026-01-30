// Dardania - Traktor Exporter
// Port of internal/exporter/traktor.go

import Foundation

/// Traktor NML (Native Instruments Markup Language) exporter
public struct TraktorExporter {

    // MARK: - Camelot to Traktor Key Mapping

    /// Traktor uses a 0-23 key system
    /// Even numbers = major, odd numbers = minor
    private static let camelotToTraktor: [String: Int] = [
        // Minor keys (A mode)
        "1A": 23,  // Abm
        "2A": 18,  // Ebm
        "3A": 13,  // Bbm
        "4A": 8,   // Fm
        "5A": 3,   // Cm
        "6A": 22,  // Gm
        "7A": 17,  // Dm
        "8A": 12,  // Am (root minor)
        "9A": 7,   // Em
        "10A": 2,  // Bm
        "11A": 21, // F#m
        "12A": 16, // C#m

        // Major keys (B mode)
        "1B": 11,  // B
        "2B": 6,   // F#/Gb
        "3B": 1,   // Db
        "4B": 20,  // Ab
        "5B": 15,  // Eb
        "6B": 10,  // Bb
        "7B": 5,   // F
        "8B": 0,   // C (root major)
        "9B": 19,  // G
        "10B": 14, // D
        "11B": 9,  // A
        "12B": 4,  // E
    ]

    // MARK: - Export

    /// Export tracks to Traktor NML v19 format
    public static func export(
        tracks: [Track],
        playlistName: String,
        to directory: URL
    ) throws -> URL {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="no"?>
        <NML VERSION="19">
        <HEAD COMPANY="Native Instruments" PROGRAM="Traktor">
        </HEAD>
        <COLLECTION ENTRIES="\(tracks.count)">

        """

        // Add tracks to collection
        for track in tracks {
            xml += makeTraktorEntry(track: track)
        }

        xml += "</COLLECTION>\n"

        // Add playlist
        xml += """
        <PLAYLISTS>
        <NODE TYPE="FOLDER" NAME="$ROOT">
        <SUBNODES COUNT="1">
        <NODE TYPE="PLAYLIST" NAME="\(escapeXML(playlistName))">
        <PLAYLIST ENTRIES="\(tracks.count)" TYPE="LIST" UUID="\(UUID().uuidString)">

        """

        for track in tracks {
            let locationKey = makeLocationKey(path: track.path)
            xml += "<ENTRY>\n"
            xml += "<PRIMARYKEY TYPE=\"TRACK\" KEY=\"\(escapeXML(locationKey))\"/>\n"
            xml += "</ENTRY>\n"
        }

        xml += """
        </PLAYLIST>
        </NODE>
        </SUBNODES>
        </NODE>
        </PLAYLISTS>
        </NML>
        """

        // Write file
        let filename = "\(playlistName).nml"
        let outputURL = directory.appendingPathComponent(filename)
        try xml.write(to: outputURL, atomically: true, encoding: .utf8)

        return outputURL
    }

    /// Create a single track entry
    private static func makeTraktorEntry(track: Track) -> String {
        let analysis = track.analysis
        let locationKey = makeLocationKey(path: track.path)

        var entry = "<ENTRY MODIFIED_DATE=\"\(formatDate(track.updatedAt))\" TITLE=\"\(escapeXML(track.title))\" ARTIST=\"\(escapeXML(track.artist))\">\n"

        // Location
        let filename = URL(fileURLWithPath: track.path).lastPathComponent
        let directory = URL(fileURLWithPath: track.path).deletingLastPathComponent().path
        entry += "<LOCATION DIR=\"\(escapeXML(makeTraktorPath(directory)))\" FILE=\"\(escapeXML(filename))\" VOLUME=\"\" VOLUMEID=\"\"/>\n"

        // Album
        if let album = track.album {
            entry += "<ALBUM TITLE=\"\(escapeXML(album))\"/>\n"
        }

        // File info
        if let duration = analysis?.durationSeconds {
            entry += "<INFO PLAYTIME=\"\(Int(duration))\" PLAYTIME_FLOAT=\"\(duration)\" IMPORT_DATE=\"\(formatDate(track.createdAt))\" FILESIZE=\"\(track.fileSize / 1024)\"/>\n"
        }

        // Tempo
        if let bpm = analysis?.bpm {
            entry += "<TEMPO BPM=\"\(String(format: "%.6f", bpm))\" BPM_QUALITY=\"100.000000\"/>\n"
        }

        // Musical key
        if let keyValue = analysis?.keyValue, let traktorKey = camelotToTraktor[keyValue] {
            entry += "<MUSICAL_KEY VALUE=\"\(traktorKey)\"/>\n"
        }

        // Loudness
        if let lufs = analysis?.integratedLUFS {
            // Convert LUFS to Traktor's gain format (dB relative to reference)
            let gain = -lufs - 14.0 // Reference is -14 LUFS
            entry += "<LOUDNESS PEAK_DB=\"\(String(format: "%.6f", analysis?.truePeakDB ?? 0))\" PERCEIVED_DB=\"\(String(format: "%.6f", gain))\" ANALYZED_DB=\"\(String(format: "%.6f", gain))\"/>\n"
        }

        // Cue points (CUE_V2 format)
        if let cues = analysis?.cuePoints, !cues.isEmpty {
            for (index, cue) in cues.enumerated() {
                let positionMs = cue.timeSeconds * 1000
                entry += "<CUE_V2 NAME=\"\(escapeXML(cue.label))\" DISPL_ORDER=\"\(index)\" TYPE=\"\(cueTypeToTraktor(cue.type))\" START=\"\(String(format: "%.1f", positionMs))\" LEN=\"0.000000\" REPEATS=\"-1\" HOTCUE=\"\(index)\"/>\n"
            }
        }

        entry += "</ENTRY>\n"

        return entry
    }

    /// Convert path to Traktor's /:delimited format
    private static func makeTraktorPath(_ path: String) -> String {
        // Traktor uses /: as delimiter instead of /
        "/:Volume/:" + path.split(separator: "/").joined(separator: "/:")
    }

    /// Create location key for playlist reference
    private static func makeLocationKey(path: String) -> String {
        "/:file://localhost" + path.split(separator: "/").map { String($0) }.joined(separator: "/:")
    }

    /// Convert cue type to Traktor type code
    private static func cueTypeToTraktor(_ type: CuePoint.CueType) -> Int {
        switch type {
        case .intro: return 0   // Cue
        case .build: return 0   // Cue
        case .drop: return 0    // Cue
        case .breakdown: return 0 // Cue
        case .outro: return 2   // Fade Out
        case .custom: return 0  // Cue
        }
    }

    /// Format date for NML
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        return formatter.string(from: date)
    }

    /// Escape string for XML
    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
