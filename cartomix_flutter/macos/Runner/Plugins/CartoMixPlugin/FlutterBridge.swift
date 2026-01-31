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
}

// MARK: - Errors

enum BridgeError: Error {
    case databaseNotInitialized
    case invalidArguments
    case trackNotFound
    case analysisFailedWithError(Error)
}
