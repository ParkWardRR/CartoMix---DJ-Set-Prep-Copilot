// Dardania - Database Manager (GRDB)

import Foundation
import GRDB
import Logging

public actor DatabaseManager {
    public static let shared = try! DatabaseManager()

    internal let dbQueue: DatabaseQueue
    private let logger = Logger(label: "com.dardania.database")

    public init() throws {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cartomixDir = appSupport.appendingPathComponent("CartoMix")

        try FileManager.default.createDirectory(at: cartomixDir, withIntermediateDirectories: true)

        let dbPath = cartomixDir.appendingPathComponent("cartomix.db").path

        var config = Configuration()
        config.prepareDatabase { db in
            // Enable WAL mode for better concurrency
            try db.execute(sql: "PRAGMA journal_mode = WAL")
            try db.execute(sql: "PRAGMA synchronous = NORMAL")
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }

        dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

        try migrator.migrate(dbQueue)

        logger.info("Database initialized at \(dbPath)")
    }

    // MARK: - Migrations

    private nonisolated var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial") { db in
            // Tracks table
            try db.create(table: "tracks") { t in
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
            try db.create(table: "analyses") { t in
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
                t.column("integrated_lufs", .double)
                t.column("true_peak_db", .double)
                t.column("loudness_range", .double)
                t.column("waveform_preview", .blob)
                t.column("sections_json", .blob)
                t.column("cue_points_json", .blob)
                t.column("sound_context", .text)
                t.column("sound_context_confidence", .double)
                t.column("qa_flags", .blob)
                t.column("has_openl3_embedding", .boolean).notNull().defaults(to: false)
                t.column("training_labels", .blob)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")

                t.uniqueKey(["track_id", "version"])
            }

            // Music locations (security-scoped bookmarks)
            try db.create(table: "music_locations") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("url", .text).notNull().unique()
                t.column("bookmark_data", .blob).notNull()
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            // OpenL3 embeddings
            try db.create(table: "openl3_embeddings") { t in
                t.column("track_id", .integer).notNull()
                    .references("tracks", onDelete: .cascade)
                t.column("analysis_version", .integer).notNull()
                t.column("embedding", .blob).notNull() // 512 x float32 = 2KB
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")

                t.primaryKey(["track_id", "analysis_version"])
            }

            // Embedding similarity cache
            try db.create(table: "embedding_similarity") { t in
                t.column("track_a_id", .integer).notNull()
                    .references("tracks", onDelete: .cascade)
                t.column("track_b_id", .integer).notNull()
                    .references("tracks", onDelete: .cascade)
                t.column("openl3_similarity", .double).notNull()
                t.column("combined_score", .double).notNull()
                t.column("tempo_similarity", .double).notNull()
                t.column("key_similarity", .double).notNull()
                t.column("energy_similarity", .double).notNull()
                t.column("explanation", .text).notNull()

                t.primaryKey(["track_a_id", "track_b_id"])
            }

            // User cue edits (never deleted by re-analysis)
            try db.create(table: "cue_edits") { t in
                t.column("track_id", .integer).notNull()
                    .references("tracks", onDelete: .cascade)
                t.column("cue_index", .integer).notNull()
                t.column("beat_index", .integer)
                t.column("cue_type", .text).notNull()
                t.column("label", .text)

                t.primaryKey(["track_id", "cue_index"])
            }

            // Training labels
            try db.create(table: "training_labels") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("track_id", .integer).notNull()
                    .references("tracks", onDelete: .cascade)
                t.column("label_value", .text).notNull()
                t.column("start_beat", .integer)
                t.column("end_beat", .integer)
                t.column("start_time_seconds", .double).notNull()
                t.column("end_time_seconds", .double).notNull()
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            // Model versions
            try db.create(table: "model_versions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("version", .integer).notNull().unique()
                t.column("accuracy", .double).notNull()
                t.column("is_active", .boolean).notNull().defaults(to: false)
                t.column("model_data", .blob).notNull()
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            // Indexes
            try db.create(index: "idx_tracks_content_hash", on: "tracks", columns: ["content_hash"])
            try db.create(index: "idx_analyses_track_id", on: "analyses", columns: ["track_id"])
            try db.create(index: "idx_analyses_status", on: "analyses", columns: ["status"])
        }

        return migrator
    }

    // MARK: - Tracks

    public func fetchAllTracks() async throws -> [Track] {
        try await dbQueue.read { db in
            let tracks = try Track.fetchAll(db)

            // Join with latest analysis
            return try tracks.map { track in
                var track = track
                track.analysis = try TrackAnalysis
                    .filter(Column("track_id") == track.id)
                    .order(Column("version").desc)
                    .fetchOne(db)
                return track
            }
        }
    }

    public func fetchTrack(id: Int64) async throws -> Track? {
        try await dbQueue.read { db in
            guard var track = try Track.fetchOne(db, key: id) else { return nil }
            track.analysis = try TrackAnalysis
                .filter(Column("track_id") == track.id)
                .order(Column("version").desc)
                .fetchOne(db)
            return track
        }
    }

    public func insertTrack(_ track: Track) async throws -> Track {
        try await dbQueue.write { db in
            var track = track
            try track.insert(db)
            return track
        }
    }

    public func upsertTrack(_ track: Track) async throws -> Track {
        try await dbQueue.write { db in
            var track = track
            try track.upsert(db)
            return track
        }
    }

    // MARK: - Music Locations

    public func fetchMusicLocations() async throws -> [MusicLocation] {
        try await dbQueue.read { db in
            try MusicLocation.fetchAll(db)
        }
    }

    public func addMusicLocation(url: URL) async throws {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        try await dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO music_locations (url, bookmark_data)
                    VALUES (?, ?)
                    ON CONFLICT(url) DO UPDATE SET bookmark_data = excluded.bookmark_data
                    """,
                arguments: [url.path, bookmarkData]
            )
        }

        logger.info("Added music location: \(url.path)")
    }

    public func removeMusicLocation(id: Int64) async throws {
        try await dbQueue.write { db in
            try MusicLocation.deleteOne(db, key: id)
        }
    }

    // MARK: - Analysis

    public func insertAnalysis(_ analysis: TrackAnalysis) async throws -> TrackAnalysis {
        try await dbQueue.write { db in
            var analysis = analysis
            try analysis.insert(db)
            return analysis
        }
    }

    public func updateAnalysis(_ analysis: TrackAnalysis) async throws {
        try await dbQueue.write { db in
            try analysis.update(db)
        }
    }

    // MARK: - Embeddings

    public func fetchEmbedding(trackId: Int64) async throws -> OpenL3Embedding? {
        try await dbQueue.read { db in
            try OpenL3Embedding
                .filter(Column("track_id") == trackId)
                .order(Column("analysis_version").desc)
                .fetchOne(db)
        }
    }

    public func insertEmbedding(_ embedding: OpenL3Embedding) async throws {
        try await dbQueue.write { db in
            var embedding = embedding
            try embedding.insert(db)
        }
    }

    // MARK: - Similarity

    public func fetchSimilarTracks(trackId: Int64, limit: Int = 10) async throws -> [EmbeddingSimilarity] {
        try await dbQueue.read { db in
            try EmbeddingSimilarity
                .filter(Column("track_a_id") == trackId || Column("track_b_id") == trackId)
                .order(Column("combined_score").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    public func insertSimilarity(_ similarity: EmbeddingSimilarity) async throws {
        try await dbQueue.write { db in
            var similarity = similarity
            try similarity.upsert(db)
        }
    }

    // MARK: - Statistics

    public func getStorageStats() async throws -> StorageStats {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cartomixDir = appSupport.appendingPathComponent("CartoMix")

        var databaseSize: Int64 = 0
        var embeddingsSize: Int64 = 0

        let dbPath = cartomixDir.appendingPathComponent("cartomix.db")
        if let attrs = try? FileManager.default.attributesOfItem(atPath: dbPath.path) {
            databaseSize = (attrs[.size] as? Int64) ?? 0
        }

        // Count embeddings
        let embeddingCount = try await dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM openl3_embeddings") ?? 0
        }
        embeddingsSize = Int64(embeddingCount * 2048) // 512 floats * 4 bytes

        return StorageStats(
            databaseSize: databaseSize,
            embeddingsSize: embeddingsSize,
            trackCount: try await dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM tracks") ?? 0
            },
            analyzedCount: try await dbQueue.read { db in
                try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM analyses WHERE status = 'complete'") ?? 0
            }
        )
    }
}

public struct StorageStats {
    public let databaseSize: Int64
    public let embeddingsSize: Int64
    public let trackCount: Int
    public let analyzedCount: Int
}
