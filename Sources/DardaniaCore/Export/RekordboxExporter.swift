// Dardania - Rekordbox Exporter
// Port of internal/exporter/rekordbox.go

import Foundation

/// Rekordbox DJ_PLAYLISTS XML exporter
public struct RekordboxExporter {

    // MARK: - XML Types

    struct DJPlaylists: Codable {
        let version: String = "1.0.0"
        let product: Product
        let collection: Collection
        let playlists: Playlists

        enum CodingKeys: String, CodingKey {
            case version = "Version"
            case product = "PRODUCT"
            case collection = "COLLECTION"
            case playlists = "PLAYLISTS"
        }
    }

    struct Product: Codable {
        let name: String
        let version: String
        let company: String

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case version = "Version"
            case company = "Company"
        }
    }

    struct Collection: Codable {
        let entries: Int
        let tracks: [RekordboxTrack]

        enum CodingKeys: String, CodingKey {
            case entries = "Entries"
            case tracks = "TRACK"
        }
    }

    struct RekordboxTrack: Codable {
        let trackId: Int
        let name: String
        let artist: String
        let album: String?
        let genre: String?
        let totalTime: Int // seconds
        let discNumber: Int
        let trackNumber: Int
        let location: String // file:// URL
        let averageBpm: String
        let tonality: String // Key
        let dateAdded: String
        let positionMarks: [PositionMark]
        let tempos: [Tempo]

        enum CodingKeys: String, CodingKey {
            case trackId = "TrackID"
            case name = "Name"
            case artist = "Artist"
            case album = "Album"
            case genre = "Genre"
            case totalTime = "TotalTime"
            case discNumber = "DiscNumber"
            case trackNumber = "TrackNumber"
            case location = "Location"
            case averageBpm = "AverageBpm"
            case tonality = "Tonality"
            case dateAdded = "DateAdded"
            case positionMarks = "POSITION_MARK"
            case tempos = "TEMPO"
        }
    }

    struct PositionMark: Codable {
        let name: String
        let type: Int // 0=cue, 1=fade-in, 2=fade-out, 4=loop
        let start: String // seconds with 3 decimals
        let num: Int // hotcue number (-1 for none)
        let red: Int
        let green: Int
        let blue: Int

        enum CodingKeys: String, CodingKey {
            case name = "Name"
            case type = "Type"
            case start = "Start"
            case num = "Num"
            case red = "Red"
            case green = "Green"
            case blue = "Blue"
        }
    }

    struct Tempo: Codable {
        let inizio: String // Start position in seconds
        let bpm: String
        let metro: String // Time signature (e.g., "4/4")
        let battito: Int // Beat number

        enum CodingKeys: String, CodingKey {
            case inizio = "Inizio"
            case bpm = "Bpm"
            case metro = "Metro"
            case battito = "Battito"
        }
    }

    struct Playlists: Codable {
        let node: PlaylistNode

        enum CodingKeys: String, CodingKey {
            case node = "NODE"
        }
    }

    struct PlaylistNode: Codable {
        let type: Int // 0=folder, 1=playlist
        let name: String
        let count: Int
        let entries: [PlaylistEntry]?
        let children: [PlaylistNode]?

        enum CodingKeys: String, CodingKey {
            case type = "Type"
            case name = "Name"
            case count = "Count"
            case entries = "TRACK"
            case children = "NODE"
        }
    }

    struct PlaylistEntry: Codable {
        let key: Int // TrackID reference

        enum CodingKeys: String, CodingKey {
            case key = "Key"
        }
    }

    // MARK: - Color Mapping

    nonisolated(unsafe) static let cueColors: [CuePoint.CueType: (r: Int, g: Int, b: Int)] = [
        .intro: (40, 226, 20),      // Green
        .drop: (230, 20, 20),       // Red
        .breakdown: (20, 130, 230), // Blue
        .build: (230, 150, 20),     // Orange
        .outro: (200, 20, 200),     // Purple
        .custom: (255, 255, 255),   // White
    ]

    // MARK: - Export

    public static func export(
        tracks: [Track],
        playlistName: String,
        to directory: URL
    ) throws -> URL {
        let rekordboxTracks = tracks.enumerated().map { index, track in
            makeRekordboxTrack(track: track, id: index + 1)
        }

        let playlist = DJPlaylists(
            product: Product(
                name: "CartoMix",
                version: "1.0.0",
                company: "CartoMix"
            ),
            collection: Collection(
                entries: rekordboxTracks.count,
                tracks: rekordboxTracks
            ),
            playlists: Playlists(
                node: PlaylistNode(
                    type: 0, // Folder (root)
                    name: "ROOT",
                    count: 1,
                    entries: nil,
                    children: [
                        PlaylistNode(
                            type: 1, // Playlist
                            name: playlistName,
                            count: tracks.count,
                            entries: tracks.enumerated().map { index, _ in
                                PlaylistEntry(key: index + 1)
                            },
                            children: nil
                        )
                    ]
                )
            )
        )

        // Encode to XML
        let encoder = XMLEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let xmlData = try encoder.encode(playlist, withRootKey: "DJ_PLAYLISTS")

        // Add XML declaration
        var xmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xmlString += String(data: xmlData, encoding: .utf8)!

        // Write file
        let filename = "\(playlistName).xml"
        let outputURL = directory.appendingPathComponent(filename)
        try xmlString.write(to: outputURL, atomically: true, encoding: .utf8)

        return outputURL
    }

    private static func makeRekordboxTrack(track: Track, id: Int) -> RekordboxTrack {
        let analysis = track.analysis

        // Convert cue points to position marks
        let positionMarks: [PositionMark] = (analysis?.cuePoints ?? []).enumerated().map { index, cue in
            let color = cueColors[cue.type] ?? (255, 255, 255)
            return PositionMark(
                name: cue.label,
                type: 0, // Cue
                start: String(format: "%.3f", cue.timeSeconds),
                num: index,
                red: color.r,
                green: color.g,
                blue: color.b
            )
        }

        // Create tempo marker
        let tempos: [Tempo]
        if let bpm = analysis?.bpm {
            tempos = [
                Tempo(
                    inizio: "0.000",
                    bpm: String(format: "%.2f", bpm),
                    metro: "4/4",
                    battito: 1
                )
            ]
        } else {
            tempos = []
        }

        // Format date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateAdded = dateFormatter.string(from: track.createdAt)

        return RekordboxTrack(
            trackId: id,
            name: track.title,
            artist: track.artist,
            album: track.album,
            genre: nil,
            totalTime: Int(analysis?.durationSeconds ?? 0),
            discNumber: 0,
            trackNumber: 0,
            location: "file://localhost\(track.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? track.path)",
            averageBpm: String(format: "%.2f", analysis?.bpm ?? 0),
            tonality: analysis?.keyValue ?? "",
            dateAdded: dateAdded,
            positionMarks: positionMarks,
            tempos: tempos
        )
    }
}

// MARK: - Simple XML Encoder (for Rekordbox format)

private class XMLEncoder {
    var outputFormatting: OutputFormatting = []

    struct OutputFormatting: OptionSet {
        let rawValue: Int
        static let prettyPrinted = OutputFormatting(rawValue: 1)
    }

    func encode<T: Encodable>(_ value: T, withRootKey rootKey: String) throws -> Data {
        let prettyPrint = outputFormatting.contains(.prettyPrinted)
        let builder = XMLBuilder(prettyPrint: prettyPrint)
        try builder.encode(value, rootKey: rootKey)
        return Data(builder.output.utf8)
    }
}

/// XML builder that produces well-formed Rekordbox XML
private class XMLBuilder {
    var output = ""
    let prettyPrint: Bool
    var indentLevel = 0

    init(prettyPrint: Bool) {
        self.prettyPrint = prettyPrint
    }

    func encode<T: Encodable>(_ value: T, rootKey: String) throws {
        output += "<\(rootKey)"
        try encodeValue(value, elementName: rootKey)
    }

    private func encodeValue<T: Encodable>(_ value: T, elementName: String) throws {
        // Use reflection to handle the encoding
        let mirror = Mirror(reflecting: value)

        var attributes: [(String, String)] = []
        var children: [(String, Any, Bool)] = [] // (key, value, isArray)

        for child in mirror.children {
            guard let label = child.label else { continue }

            // Get the coding key name (handle CodingKeys enum)
            let key = codingKey(for: label, in: T.self) ?? label

            if let stringValue = child.value as? String {
                attributes.append((key, escapeXML(stringValue)))
            } else if let intValue = child.value as? Int {
                attributes.append((key, String(intValue)))
            } else if let int64Value = child.value as? Int64 {
                attributes.append((key, String(int64Value)))
            } else if let doubleValue = child.value as? Double {
                attributes.append((key, String(doubleValue)))
            } else if let boolValue = child.value as? Bool {
                attributes.append((key, String(boolValue)))
            } else if let optionalString = child.value as? String? {
                if let str = optionalString {
                    attributes.append((key, escapeXML(str)))
                }
            } else if let array = child.value as? [Any] {
                children.append((key, array, true))
            } else {
                // Nested object
                children.append((key, child.value, false))
            }
        }

        // Output attributes
        for (key, value) in attributes {
            output += " \(key)=\"\(value)\""
        }

        // Output children
        if children.isEmpty {
            output += "/>"
        } else {
            output += ">"
            indentLevel += 1

            for (key, value, isArray) in children {
                if isArray {
                    if let encodableArray = value as? [any Encodable] {
                        for item in encodableArray {
                            output += newline() + indent() + "<\(key)"
                            try encodeValue(item, elementName: key)
                        }
                    }
                } else if let encodable = value as? (any Encodable) {
                    output += newline() + indent() + "<\(key)"
                    try encodeValue(encodable, elementName: key)
                }
            }

            indentLevel -= 1
            output += newline() + indent() + "</\(elementName)>"
        }
    }

    private func codingKey<T>(for label: String, in type: T.Type) -> String? {
        // Handle underscore prefix from property wrappers
        let cleanLabel = label.hasPrefix("_") ? String(label.dropFirst()) : label

        // Use Mirror to look for CodingKeys enum
        // For now, we'll just use the label directly since our structs define CodingKeys
        // that match the XML attribute names
        switch cleanLabel {
        case "version": return "Version"
        case "product": return "PRODUCT"
        case "collection": return "COLLECTION"
        case "playlists": return "PLAYLISTS"
        case "name": return "Name"
        case "company": return "Company"
        case "entries": return "Entries"
        case "tracks": return "TRACK"
        case "trackId": return "TrackID"
        case "artist": return "Artist"
        case "album": return "Album"
        case "genre": return "Genre"
        case "totalTime": return "TotalTime"
        case "discNumber": return "DiscNumber"
        case "trackNumber": return "TrackNumber"
        case "location": return "Location"
        case "averageBpm": return "AverageBpm"
        case "tonality": return "Tonality"
        case "dateAdded": return "DateAdded"
        case "positionMarks": return "POSITION_MARK"
        case "tempos": return "TEMPO"
        case "type": return "Type"
        case "start": return "Start"
        case "num": return "Num"
        case "red": return "Red"
        case "green": return "Green"
        case "blue": return "Blue"
        case "inizio": return "Inizio"
        case "bpm": return "Bpm"
        case "metro": return "Metro"
        case "battito": return "Battito"
        case "node": return "NODE"
        case "count": return "Count"
        case "children": return "NODE"
        case "key": return "Key"
        default: return cleanLabel
        }
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func indent() -> String {
        prettyPrint ? String(repeating: "  ", count: indentLevel) : ""
    }

    private func newline() -> String {
        prettyPrint ? "\n" : ""
    }
}
