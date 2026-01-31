import Foundation
import GRDB

/// FlutterBridge provides the native Swift backend for CartoMix platform channels
/// Manages database, audio analysis, and ML-powered similarity scoring
public class FlutterBridge {

    // MARK: - Singleton

    public static let shared = FlutterBridge()

    // MARK: - Properties

    private var dbQueue: DatabaseQueue?
    private let fileManager = FileManager.default

    // MARK: - Initialization

    private init() {
        do {
            try setupDatabase()
        } catch {
            print("FlutterBridge: Failed to initialize database: \(error)")
        }
    }

    // MARK: - Database Setup

    private func setupDatabase() throws {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cartomixDir = appSupport.appendingPathComponent("CartoMix")

        try fileManager.createDirectory(at: cartomixDir, withIntermediateDirectories: true)

        let dbPath = cartomixDir.appendingPathComponent("cartomix.db").path

        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            try db.execute(sql: "PRAGMA synchronous = NORMAL")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
        try runMigrations()

        print("FlutterBridge: Database initialized at \(dbPath)")
    }

    private func runMigrations() throws {
        guard let db = dbQueue else { return }

        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial") { db in
            // Tracks table
            try db.create(table: "tracks", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("content_hash", .text).notNull().unique()
                t.column("path", .text).notNull()
                t.column("title", .text).notNull()
                t.column("artist", .text).notNull()
                t.column("album", .text)
                t.column("file_size", .integer).notNull()
                t.column("file_modified_at", .datetime).notNull()
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            // Analyses table
            try db.create(table: "analyses", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("track_id", .integer).notNull()
                    .references("tracks", onDelete: .cascade)
                t.column("version", .integer).notNull().defaults(to: 1)
                t.column("status", .text).notNull().defaults(to: "pending")
                t.column("duration_seconds", .double)
                t.column("bpm", .double)
                t.column("bpm_confidence", .double)
                t.column("key_value", .text)
                t.column("key_format", .text)
                t.column("key_confidence", .double)
                t.column("energy_global", .integer)
                t.column("sound_context", .text)
                t.column("has_openl3_embedding", .boolean).notNull().defaults(to: false)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            // Music locations
            try db.create(table: "music_locations", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("url", .text).notNull().unique()
                t.column("bookmark_data", .blob).notNull()
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            // OpenL3 embeddings
            try db.create(table: "openl3_embeddings", ifNotExists: true) { t in
                t.column("track_id", .integer).notNull()
                    .references("tracks", onDelete: .cascade)
                t.column("analysis_version", .integer).notNull()
                t.column("embedding", .blob).notNull()
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.primaryKey(["track_id", "analysis_version"])
            }

            // Embedding similarity cache
            try db.create(table: "embedding_similarity", ifNotExists: true) { t in
                t.column("track_a_id", .integer).notNull()
                t.column("track_b_id", .integer).notNull()
                t.column("openl3_similarity", .double).notNull()
                t.column("combined_score", .double).notNull()
                t.column("tempo_similarity", .double).notNull()
                t.column("key_similarity", .double).notNull()
                t.column("energy_similarity", .double).notNull()
                t.column("explanation", .text).notNull()
                t.primaryKey(["track_a_id", "track_b_id"])
            }
        }

        try migrator.migrate(db)
    }

    // MARK: - Track Operations

    public func fetchAllTracks() throws -> [[String: Any]] {
        guard let db = dbQueue else { return [] }

        return try db.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT t.*, a.id as analysis_id, a.status, a.duration_seconds, a.bpm,
                       a.key_value, a.energy_global, a.has_openl3_embedding
                FROM tracks t
                LEFT JOIN analyses a ON t.id = a.track_id
                ORDER BY t.title ASC
            """)

            return rows.map { row -> [String: Any] in
                var track: [String: Any] = [
                    "id": row["id"] as Int64,
                    "contentHash": row["content_hash"] as String,
                    "path": row["path"] as String,
                    "title": row["title"] as String,
                    "artist": row["artist"] as String,
                    "fileSize": row["file_size"] as Int64,
                ]

                if let album = row["album"] as? String {
                    track["album"] = album
                }

                // Add analysis if present
                if let analysisId = row["analysis_id"] as? Int64 {
                    var analysis: [String: Any] = [
                        "id": analysisId,
                        "status": row["status"] as? String ?? "pending",
                        "hasOpenL3Embedding": row["has_openl3_embedding"] as? Bool ?? false,
                    ]

                    if let duration = row["duration_seconds"] as? Double {
                        analysis["durationSeconds"] = duration
                    }
                    if let bpm = row["bpm"] as? Double {
                        analysis["bpm"] = bpm
                    }
                    if let key = row["key_value"] as? String {
                        analysis["keyValue"] = key
                    }
                    if let energy = row["energy_global"] as? Int {
                        analysis["energyGlobal"] = energy
                    }

                    track["analysis"] = analysis
                }

                return track
            }
        }
    }

    public func fetchTrack(id: Int64) throws -> [String: Any]? {
        guard let db = dbQueue else { return nil }

        return try db.read { db in
            guard let row = try Row.fetchOne(db, sql: """
                SELECT t.*, a.id as analysis_id, a.status, a.duration_seconds, a.bpm,
                       a.key_value, a.energy_global, a.has_openl3_embedding
                FROM tracks t
                LEFT JOIN analyses a ON t.id = a.track_id
                WHERE t.id = ?
            """, arguments: [id]) else {
                return nil
            }

            var track: [String: Any] = [
                "id": row["id"] as Int64,
                "contentHash": row["content_hash"] as String,
                "path": row["path"] as String,
                "title": row["title"] as String,
                "artist": row["artist"] as String,
                "fileSize": row["file_size"] as Int64,
            ]

            if let album = row["album"] as? String {
                track["album"] = album
            }

            if let analysisId = row["analysis_id"] as? Int64 {
                track["analysis"] = [
                    "id": analysisId,
                    "status": row["status"] as? String ?? "pending",
                    "durationSeconds": row["duration_seconds"] as? Double,
                    "bpm": row["bpm"] as? Double,
                    "keyValue": row["key_value"] as? String,
                    "energyGlobal": row["energy_global"] as? Int,
                    "hasOpenL3Embedding": row["has_openl3_embedding"] as? Bool ?? false,
                ]
            }

            return track
        }
    }

    public func insertTrack(_ trackData: [String: Any]) throws -> [String: Any] {
        guard let db = dbQueue else { throw BridgeError.databaseNotInitialized }

        guard let path = trackData["path"] as? String,
              let title = trackData["title"] as? String,
              let artist = trackData["artist"] as? String else {
            throw BridgeError.invalidArguments
        }

        let contentHash = trackData["contentHash"] as? String ?? UUID().uuidString
        let album = trackData["album"] as? String
        let fileSize = trackData["fileSize"] as? Int64 ?? 0
        let fileModifiedAt = trackData["fileModifiedAt"] as? Date ?? Date()

        return try db.write { db in
            try db.execute(sql: """
                INSERT INTO tracks (content_hash, path, title, artist, album, file_size, file_modified_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, arguments: [contentHash, path, title, artist, album, fileSize, fileModifiedAt])

            let id = db.lastInsertedRowID

            // Create pending analysis
            try db.execute(sql: """
                INSERT INTO analyses (track_id, status) VALUES (?, 'pending')
            """, arguments: [id])

            return [
                "id": id,
                "contentHash": contentHash,
                "path": path,
                "title": title,
                "artist": artist,
                "album": album as Any,
                "fileSize": fileSize,
            ]
        }
    }

    // MARK: - Music Locations

    public func fetchMusicLocations() throws -> [[String: Any]] {
        guard let db = dbQueue else { return [] }

        return try db.read { db in
            let rows = try Row.fetchAll(db, sql: "SELECT * FROM music_locations ORDER BY created_at DESC")
            return rows.map { row in
                [
                    "id": row["id"] as Int64,
                    "url": row["url"] as String,
                    "createdAt": (row["created_at"] as? Date)?.timeIntervalSince1970 ?? 0,
                ]
            }
        }
    }

    public func addMusicLocation(url: URL) throws {
        guard let db = dbQueue else { throw BridgeError.databaseNotInitialized }

        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        try db.write { db in
            try db.execute(sql: """
                INSERT INTO music_locations (url, bookmark_data)
                VALUES (?, ?)
                ON CONFLICT(url) DO UPDATE SET bookmark_data = excluded.bookmark_data
            """, arguments: [url.path, bookmarkData])
        }
    }

    public func removeMusicLocation(id: Int64) throws {
        guard let db = dbQueue else { throw BridgeError.databaseNotInitialized }

        try db.write { db in
            try db.execute(sql: "DELETE FROM music_locations WHERE id = ?", arguments: [id])
        }
    }

    // MARK: - Directory Scanning

    public func scanDirectory(at url: URL) throws -> [[String: Any]] {
        let supportedExtensions = ["mp3", "m4a", "aac", "wav", "flac", "aiff", "aif", "ogg"]
        var tracks: [[String: Any]] = []

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard supportedExtensions.contains(ext) else { continue }

            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey])
                guard resourceValues.isRegularFile == true else { continue }

                let fileName = fileURL.deletingPathExtension().lastPathComponent
                let parts = fileName.components(separatedBy: " - ")

                let artist: String
                let title: String

                if parts.count >= 2 {
                    artist = parts[0].trimmingCharacters(in: .whitespaces)
                    title = parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespaces)
                } else {
                    artist = "Unknown Artist"
                    title = fileName
                }

                let trackData: [String: Any] = [
                    "path": fileURL.path,
                    "title": title,
                    "artist": artist,
                    "fileSize": resourceValues.fileSize ?? 0,
                    "fileModifiedAt": resourceValues.contentModificationDate ?? Date(),
                    "contentHash": fileURL.path.hashValue.description,
                ]

                // Insert track and add to result
                let inserted = try insertTrack(trackData)
                tracks.append(inserted)
            } catch {
                print("FlutterBridge: Failed to process file \(fileURL): \(error)")
            }
        }

        print("FlutterBridge: Scanned \(tracks.count) tracks from \(url.path)")
        return tracks
    }

    // MARK: - Similarity

    public func findSimilarTracks(trackId: Int64, limit: Int = 10) throws -> [[String: Any]] {
        guard let db = dbQueue else { return [] }

        return try db.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT es.*,
                       t.id as other_id, t.title as other_title, t.artist as other_artist
                FROM embedding_similarity es
                JOIN tracks t ON (
                    CASE WHEN es.track_a_id = ? THEN es.track_b_id ELSE es.track_a_id END = t.id
                )
                WHERE es.track_a_id = ? OR es.track_b_id = ?
                ORDER BY es.combined_score DESC
                LIMIT ?
            """, arguments: [trackId, trackId, trackId, limit])

            return rows.map { row in
                [
                    "trackId": row["other_id"] as Int64,
                    "title": row["other_title"] as String,
                    "artist": row["other_artist"] as String,
                    "score": row["combined_score"] as Double,
                    "openl3Similarity": row["openl3_similarity"] as Double,
                    "tempoSimilarity": row["tempo_similarity"] as Double,
                    "keySimilarity": row["key_similarity"] as Double,
                    "energySimilarity": row["energy_similarity"] as Double,
                    "explanation": row["explanation"] as String,
                ]
            }
        }
    }

    // MARK: - Statistics

    public func getStorageStats() throws -> [String: Any] {
        guard let db = dbQueue else { return [:] }

        return try db.read { db in
            let trackCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM tracks") ?? 0
            let analyzedCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM analyses WHERE status = 'complete'") ?? 0
            let embeddingCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM openl3_embeddings") ?? 0

            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dbPath = appSupport.appendingPathComponent("CartoMix/cartomix.db")
            let dbSize = (try? FileManager.default.attributesOfItem(atPath: dbPath.path)[.size] as? Int64) ?? 0

            return [
                "trackCount": trackCount,
                "analyzedCount": analyzedCount,
                "embeddingCount": embeddingCount,
                "databaseSize": dbSize,
            ]
        }
    }

    // MARK: - Export Methods

    public func fetchTracksForExport(ids: [Int64]) throws -> [[String: Any]] {
        guard let db = dbQueue else { return [] }

        return try db.read { db in
            let placeholders = ids.map { _ in "?" }.joined(separator: ", ")
            let sql = """
                SELECT t.*, a.id as analysis_id, a.status, a.duration_seconds, a.bpm,
                       a.key_value, a.energy_global, a.has_openl3_embedding,
                       a.sound_context
                FROM tracks t
                LEFT JOIN analyses a ON t.id = a.track_id
                WHERE t.id IN (\(placeholders))
            """
            let rows = try Row.fetchAll(db, sql: sql, arguments: StatementArguments(ids))

            return rows.map { row in
                var track: [String: Any] = [
                    "id": row["id"] as Int64,
                    "contentHash": row["content_hash"] as String,
                    "path": row["path"] as String,
                    "title": row["title"] as String,
                    "artist": row["artist"] as String,
                    "fileSize": row["file_size"] as Int64,
                ]

                if let album = row["album"] as? String {
                    track["album"] = album
                }

                if row["analysis_id"] != nil {
                    var analysis: [String: Any] = [
                        "status": row["status"] as? String ?? "pending",
                    ]
                    if let duration = row["duration_seconds"] as? Double {
                        analysis["durationSeconds"] = duration
                    }
                    if let bpm = row["bpm"] as? Double {
                        analysis["bpm"] = bpm
                    }
                    if let key = row["key_value"] as? String {
                        analysis["keyValue"] = key
                    }
                    if let energy = row["energy_global"] as? Int {
                        analysis["energyGlobal"] = energy
                    }
                    track["analysis"] = analysis
                }

                return track
            }
        }
    }

    /// Export tracks to Rekordbox XML format
    public func exportRekordbox(trackIds: [Int64], playlistName: String, outputPath: String) throws -> String {
        let tracks = try fetchTracksForExport(ids: trackIds)
        let url = URL(fileURLWithPath: outputPath)

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <DJ_PLAYLISTS Version="1.0.0">
          <PRODUCT Name="CartoMix" Version="0.10.0" Company="CartoMix"/>
          <COLLECTION Entries="\(tracks.count)">

        """

        for track in tracks {
            let title = escapeXML(track["title"] as? String ?? "Unknown")
            let artist = escapeXML(track["artist"] as? String ?? "Unknown")
            let path = track["path"] as? String ?? ""
            let analysis = track["analysis"] as? [String: Any]
            let bpm = analysis?["bpm"] as? Double ?? 0
            let key = analysis?["keyValue"] as? String ?? ""
            let duration = analysis?["durationSeconds"] as? Double ?? 0

            xml += """
                <TRACK TrackID="\(track["id"] ?? 0)" Name="\(title)" Artist="\(artist)"
                       AverageBpm="\(String(format: "%.2f", bpm))" Tonality="\(key)"
                       TotalTime="\(Int(duration))"
                       Location="file://localhost\(path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path)"/>

            """
        }

        xml += """
          </COLLECTION>
          <PLAYLISTS>
            <NODE Type="0" Name="ROOT" Count="1">
              <NODE Name="\(escapeXML(playlistName))" Type="1" KeyType="0" Entries="\(tracks.count)">

        """

        for track in tracks {
            xml += """
                    <TRACK Key="\(track["id"] ?? 0)"/>

            """
        }

        xml += """
              </NODE>
            </NODE>
          </PLAYLISTS>
        </DJ_PLAYLISTS>
        """

        try xml.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    /// Export tracks to Serato crate format
    public func exportSerato(trackIds: [Int64], playlistName: String, outputPath: String) throws -> String {
        let tracks = try fetchTracksForExport(ids: trackIds)
        let url = URL(fileURLWithPath: outputPath)

        var data = Data()

        // Serato crate header
        let version = "vrsn".data(using: .ascii)!
        data.append(version)
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x38]) // Version length

        let versionString = "1.0/Serato ScratchLive Crate".data(using: .utf16BigEndian)!
        data.append(versionString)

        // Track entries
        for track in tracks {
            let path = track["path"] as? String ?? ""

            // otrk tag
            let otrkTag = "otrk".data(using: .ascii)!
            data.append(otrkTag)

            // ptrk tag with path
            let ptrkTag = "ptrk".data(using: .ascii)!
            let pathData = path.data(using: .utf16BigEndian)!

            var ptrkLength = UInt32(pathData.count).bigEndian
            var otrkLength = UInt32(4 + 4 + pathData.count).bigEndian

            data.append(Data(bytes: &otrkLength, count: 4))
            data.append(ptrkTag)
            data.append(Data(bytes: &ptrkLength, count: 4))
            data.append(pathData)
        }

        try data.write(to: url)
        return url.path
    }

    /// Export tracks to Traktor NML format
    public func exportTraktor(trackIds: [Int64], playlistName: String, outputPath: String) throws -> String {
        let tracks = try fetchTracksForExport(ids: trackIds)
        let url = URL(fileURLWithPath: outputPath)

        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <NML VERSION="19">
          <HEAD COMPANY="CartoMix" PROGRAM="CartoMix 0.10.0"/>
          <COLLECTION ENTRIES="\(tracks.count)">

        """

        for track in tracks {
            let title = escapeXML(track["title"] as? String ?? "Unknown")
            let artist = escapeXML(track["artist"] as? String ?? "Unknown")
            let path = track["path"] as? String ?? ""
            let analysis = track["analysis"] as? [String: Any]
            let bpm = analysis?["bpm"] as? Double ?? 0
            let key = analysis?["keyValue"] as? String ?? ""
            let duration = analysis?["durationSeconds"] as? Double ?? 0

            // Convert path to Traktor format (/:)
            let traktorPath = path.replacingOccurrences(of: "/", with: "/:")

            xml += """
                <ENTRY>
                  <LOCATION DIR="\(escapeXML(traktorPath))" FILE="" VOLUME=""/>
                  <ALBUM TITLE="\(escapeXML(track["album"] as? String ?? ""))"/>
                  <INFO PLAYTIME="\(Int(duration))" KEY="\(key)"/>
                  <TEMPO BPM="\(String(format: "%.6f", bpm))" BPM_QUALITY="100"/>
                </ENTRY>

            """
        }

        xml += """
          </COLLECTION>
          <PLAYLISTS>
            <NODE TYPE="FOLDER" NAME="$ROOT">
              <SUBNODES COUNT="1">
                <NODE TYPE="PLAYLIST" NAME="\(escapeXML(playlistName))">
                  <PLAYLIST ENTRIES="\(tracks.count)" TYPE="LIST">

        """

        for track in tracks {
            let path = track["path"] as? String ?? ""
            let traktorPath = path.replacingOccurrences(of: "/", with: "/:")

            xml += """
                        <ENTRY>
                          <PRIMARYKEY TYPE="TRACK" KEY="\(escapeXML(traktorPath))"/>
                        </ENTRY>

            """
        }

        xml += """
                  </PLAYLIST>
                </NODE>
              </SUBNODES>
            </NODE>
          </PLAYLISTS>
        </NML>
        """

        try xml.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    /// Export tracks to JSON format
    public func exportJSON(trackIds: [Int64], outputPath: String) throws -> String {
        let tracks = try fetchTracksForExport(ids: trackIds)
        let url = URL(fileURLWithPath: outputPath)

        let exportData: [String: Any] = [
            "exportedAt": ISO8601DateFormatter().string(from: Date()),
            "version": "0.10.0",
            "trackCount": tracks.count,
            "tracks": tracks
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys])
        try jsonData.write(to: url)
        return url.path
    }

    /// Export tracks to M3U8 playlist format
    public func exportM3U(trackIds: [Int64], outputPath: String) throws -> String {
        let tracks = try fetchTracksForExport(ids: trackIds)
        let url = URL(fileURLWithPath: outputPath)

        var m3u = "#EXTM3U\n"
        m3u += "#PLAYLIST:CartoMix Export\n\n"

        for track in tracks {
            let title = track["title"] as? String ?? "Unknown"
            let artist = track["artist"] as? String ?? "Unknown"
            let path = track["path"] as? String ?? ""
            let analysis = track["analysis"] as? [String: Any]
            let duration = Int(analysis?["durationSeconds"] as? Double ?? 0)

            m3u += "#EXTINF:\(duration),\(artist) - \(title)\n"
            m3u += "\(path)\n"
        }

        try m3u.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    /// Export tracks to CSV format
    public func exportCSV(trackIds: [Int64], outputPath: String) throws -> String {
        let tracks = try fetchTracksForExport(ids: trackIds)
        let url = URL(fileURLWithPath: outputPath)

        var csv = "Title,Artist,Album,BPM,Key,Energy,Duration,Path\n"

        for track in tracks {
            let title = escapeCSV(track["title"] as? String ?? "")
            let artist = escapeCSV(track["artist"] as? String ?? "")
            let album = escapeCSV(track["album"] as? String ?? "")
            let path = escapeCSV(track["path"] as? String ?? "")
            let analysis = track["analysis"] as? [String: Any]

            csv += "\"\(title)\","
            csv += "\"\(artist)\","
            csv += "\"\(album)\","
            csv += "\(String(format: "%.2f", analysis?["bpm"] as? Double ?? 0)),"
            csv += "\(analysis?["keyValue"] as? String ?? ""),"
            csv += "\(analysis?["energyGlobal"] as? Int ?? 0),"
            csv += "\(String(format: "%.1f", analysis?["durationSeconds"] as? Double ?? 0)),"
            csv += "\"\(path)\"\n"
        }

        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url.path
    }

    // MARK: - Import Methods

    /// Import tracks from Rekordbox XML
    public func importRekordbox(filePath: String) throws -> [[String: Any]] {
        let url = URL(fileURLWithPath: filePath)
        let xmlData = try Data(contentsOf: url)

        guard let xmlString = String(data: xmlData, encoding: .utf8) else {
            throw BridgeError.invalidArguments
        }

        var importedTracks: [[String: Any]] = []

        // Parse TRACK elements from XML
        let trackPattern = #"<TRACK[^>]*TrackID="(\d+)"[^>]*Name="([^"]*)"[^>]*Artist="([^"]*)"[^>]*(?:Album="([^"]*)")?[^>]*AverageBpm="([^"]*)"[^>]*(?:Tonality="([^"]*)")?[^>]*Location="([^"]*)"[^/>]*/?>"#

        let regex = try NSRegularExpression(pattern: trackPattern, options: [.dotMatchesLineSeparators])
        let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

        for match in matches {
            var track: [String: Any] = [:]

            if let range = Range(match.range(at: 2), in: xmlString) {
                track["title"] = unescapeXML(String(xmlString[range]))
            }
            if let range = Range(match.range(at: 3), in: xmlString) {
                track["artist"] = unescapeXML(String(xmlString[range]))
            }
            if let range = Range(match.range(at: 4), in: xmlString) {
                track["album"] = unescapeXML(String(xmlString[range]))
            }
            if let range = Range(match.range(at: 5), in: xmlString) {
                track["bpm"] = Double(String(xmlString[range])) ?? 0
            }
            if let range = Range(match.range(at: 6), in: xmlString) {
                track["key"] = String(xmlString[range])
            }
            if let range = Range(match.range(at: 7), in: xmlString) {
                var path = String(xmlString[range])
                // Convert file:// URL to path
                if path.hasPrefix("file://localhost") {
                    path = path.replacingOccurrences(of: "file://localhost", with: "")
                    path = path.removingPercentEncoding ?? path
                }
                track["path"] = path
            }

            track["source"] = "rekordbox"
            importedTracks.append(track)
        }

        return importedTracks
    }

    /// Import tracks from Serato crate
    public func importSerato(filePath: String) throws -> [[String: Any]] {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)

        var importedTracks: [[String: Any]] = []
        var offset = 0

        // Skip header (vrsn tag)
        while offset < data.count - 4 {
            let tag = String(data: data.subdata(in: offset..<offset+4), encoding: .ascii) ?? ""

            if tag == "vrsn" {
                // Read version length and skip
                let length = Int(data[offset+4]) << 24 | Int(data[offset+5]) << 16 | Int(data[offset+6]) << 8 | Int(data[offset+7])
                offset += 8 + length
            } else if tag == "otrk" {
                // Read otrk length
                let otrkLength = Int(data[offset+4]) << 24 | Int(data[offset+5]) << 16 | Int(data[offset+6]) << 8 | Int(data[offset+7])
                offset += 8

                // Look for ptrk tag
                if offset + 4 < data.count {
                    let ptrkTag = String(data: data.subdata(in: offset..<offset+4), encoding: .ascii) ?? ""
                    if ptrkTag == "ptrk" {
                        let ptrkLength = Int(data[offset+4]) << 24 | Int(data[offset+5]) << 16 | Int(data[offset+6]) << 8 | Int(data[offset+7])
                        offset += 8

                        if offset + ptrkLength <= data.count {
                            let pathData = data.subdata(in: offset..<offset+ptrkLength)
                            if let path = String(data: pathData, encoding: .utf16BigEndian) {
                                let filename = (path as NSString).lastPathComponent
                                var track: [String: Any] = [
                                    "path": path,
                                    "title": (filename as NSString).deletingPathExtension,
                                    "artist": "Unknown",
                                    "source": "serato"
                                ]
                                importedTracks.append(track)
                            }
                        }
                        offset += ptrkLength
                    } else {
                        offset += otrkLength
                    }
                }
            } else {
                offset += 1
            }
        }

        return importedTracks
    }

    /// Import tracks from Traktor NML
    public func importTraktor(filePath: String) throws -> [[String: Any]] {
        let url = URL(fileURLWithPath: filePath)
        let xmlData = try Data(contentsOf: url)

        guard let xmlString = String(data: xmlData, encoding: .utf8) else {
            throw BridgeError.invalidArguments
        }

        var importedTracks: [[String: Any]] = []

        // Parse ENTRY elements from NML
        let entryPattern = #"<ENTRY[^>]*>.*?<LOCATION[^>]*DIR="([^"]*)"[^>]*FILE="([^"]*)".*?(?:<ALBUM[^>]*TITLE="([^"]*)")?.*?(?:<INFO[^>]*KEY="([^"]*)")?.*?(?:<TEMPO[^>]*BPM="([^"]*)")?.*?</ENTRY>"#

        let regex = try NSRegularExpression(pattern: entryPattern, options: [.dotMatchesLineSeparators])
        let matches = regex.matches(in: xmlString, range: NSRange(xmlString.startIndex..., in: xmlString))

        for match in matches {
            var track: [String: Any] = [:]
            var dirPath = ""
            var fileName = ""

            if let range = Range(match.range(at: 1), in: xmlString) {
                // Convert Traktor path format (/:) back to normal path
                dirPath = String(xmlString[range]).replacingOccurrences(of: "/:", with: "/")
            }
            if let range = Range(match.range(at: 2), in: xmlString) {
                fileName = unescapeXML(String(xmlString[range]))
            }

            let fullPath = dirPath.isEmpty ? fileName : (dirPath + "/" + fileName)
            track["path"] = fullPath
            track["title"] = (fileName as NSString).deletingPathExtension
            track["artist"] = "Unknown"

            if let range = Range(match.range(at: 3), in: xmlString) {
                track["album"] = unescapeXML(String(xmlString[range]))
            }
            if let range = Range(match.range(at: 4), in: xmlString) {
                track["key"] = String(xmlString[range])
            }
            if let range = Range(match.range(at: 5), in: xmlString) {
                track["bpm"] = Double(String(xmlString[range])) ?? 0
            }

            track["source"] = "traktor"
            importedTracks.append(track)
        }

        return importedTracks
    }

    /// Import tracks from M3U/M3U8 playlist
    public func importM3U(filePath: String) throws -> [[String: Any]] {
        let url = URL(fileURLWithPath: filePath)
        let content = try String(contentsOf: url, encoding: .utf8)

        var importedTracks: [[String: Any]] = []
        let lines = content.components(separatedBy: .newlines)

        var currentTitle = ""
        var currentArtist = ""
        var currentDuration = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("#EXTINF:") {
                // Parse extended info: #EXTINF:duration,artist - title
                let info = trimmed.dropFirst(8)
                let parts = info.split(separator: ",", maxSplits: 1)

                if let durationStr = parts.first {
                    currentDuration = Int(durationStr) ?? 0
                }

                if parts.count > 1 {
                    let titlePart = String(parts[1])
                    if titlePart.contains(" - ") {
                        let artistTitle = titlePart.split(separator: " - ", maxSplits: 1)
                        currentArtist = String(artistTitle[0])
                        currentTitle = artistTitle.count > 1 ? String(artistTitle[1]) : ""
                    } else {
                        currentTitle = titlePart
                    }
                }
            } else if !trimmed.isEmpty && !trimmed.hasPrefix("#") {
                // This is a file path
                var track: [String: Any] = [
                    "path": trimmed,
                    "source": "m3u"
                ]

                if !currentTitle.isEmpty {
                    track["title"] = currentTitle
                } else {
                    track["title"] = (trimmed as NSString).lastPathComponent
                }

                if !currentArtist.isEmpty {
                    track["artist"] = currentArtist
                } else {
                    track["artist"] = "Unknown"
                }

                if currentDuration > 0 {
                    track["duration"] = currentDuration
                }

                importedTracks.append(track)

                // Reset for next track
                currentTitle = ""
                currentArtist = ""
                currentDuration = 0
            }
        }

        return importedTracks
    }

    /// Add imported tracks to database
    public func addImportedTracks(_ tracks: [[String: Any]]) throws -> Int {
        guard let db = dbQueue else { throw BridgeError.databaseNotInitialized }

        var addedCount = 0

        try db.write { database in
            for track in tracks {
                guard let path = track["path"] as? String else { continue }

                // Check if file exists
                let fileURL = URL(fileURLWithPath: path)
                guard fileManager.fileExists(atPath: path) else { continue }

                // Check if already in database
                let existingCount = try Int.fetchOne(database, sql: "SELECT COUNT(*) FROM tracks WHERE path = ?", arguments: [path]) ?? 0
                if existingCount > 0 { continue }

                // Get file info
                let attrs = try fileManager.attributesOfItem(atPath: path)
                let fileSize = attrs[.size] as? Int64 ?? 0
                let modDate = attrs[.modificationDate] as? Date ?? Date()

                // Create content hash from path
                let contentHash = path.data(using: .utf8)!.base64EncodedString()

                // Insert track
                try database.execute(sql: """
                    INSERT INTO tracks (content_hash, path, title, artist, album, file_size, file_modified_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    contentHash,
                    path,
                    track["title"] as? String ?? "Unknown",
                    track["artist"] as? String ?? "Unknown",
                    track["album"] as? String ?? "",
                    fileSize,
                    modDate
                ])

                addedCount += 1
            }
        }

        return addedCount
    }

    // MARK: - Import Helpers

    private func unescapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
    }

    // MARK: - Export Helpers

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func escapeCSV(_ string: String) -> String {
        string.replacingOccurrences(of: "\"", with: "\"\"")
    }
}

// MARK: - Errors

enum BridgeError: Error {
    case databaseNotInitialized
    case invalidArguments
    case trackNotFound
    case analysisFailedWithError(Error)
}
