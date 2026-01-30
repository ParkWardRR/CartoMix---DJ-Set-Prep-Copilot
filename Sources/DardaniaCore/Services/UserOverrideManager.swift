// CartoMix - User Override Manager
// Allows users to edit and override auto-detected analysis values

import Foundation
import GRDB
import Logging

/// Manages user overrides for track analysis
/// Overrides are stored separately and merged with auto-analysis at runtime
public actor UserOverrideManager {
    public static let shared = UserOverrideManager()

    private let logger = Logger(label: "com.cartomix.overrides")

    // MARK: - Override Types

    public struct TrackOverrides: Codable, Sendable {
        public var bpm: Double?
        public var bpmLocked: Bool
        public var key: String?
        public var keyLocked: Bool
        public var energy: Int?
        public var cuePoints: [CuePointOverride]?
        public var sections: [SectionOverride]?
        public var gridOffset: Double?
        public var notes: String?
        public var rating: Int?
        public var tags: [String]?
        public var updatedAt: Date

        public init(
            bpm: Double? = nil,
            bpmLocked: Bool = false,
            key: String? = nil,
            keyLocked: Bool = false,
            energy: Int? = nil,
            cuePoints: [CuePointOverride]? = nil,
            sections: [SectionOverride]? = nil,
            gridOffset: Double? = nil,
            notes: String? = nil,
            rating: Int? = nil,
            tags: [String]? = nil
        ) {
            self.bpm = bpm
            self.bpmLocked = bpmLocked
            self.key = key
            self.keyLocked = keyLocked
            self.energy = energy
            self.cuePoints = cuePoints
            self.sections = sections
            self.gridOffset = gridOffset
            self.notes = notes
            self.rating = rating
            self.tags = tags
            self.updatedAt = Date()
        }
    }

    public struct CuePointOverride: Codable, Sendable, Identifiable {
        public var id: UUID
        public var timeSeconds: Double
        public var beatIndex: Int?
        public var type: String
        public var label: String
        public var color: CueColor?
        public var isUserCreated: Bool

        public init(
            id: UUID = UUID(),
            timeSeconds: Double,
            beatIndex: Int? = nil,
            type: String,
            label: String,
            color: CueColor? = nil,
            isUserCreated: Bool = true
        ) {
            self.id = id
            self.timeSeconds = timeSeconds
            self.beatIndex = beatIndex
            self.type = type
            self.label = label
            self.color = color
            self.isUserCreated = isUserCreated
        }
    }

    public struct CueColor: Codable, Sendable {
        public var red: Int
        public var green: Int
        public var blue: Int

        public init(red: Int, green: Int, blue: Int) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        public static let hotCueColors: [CueColor] = [
            CueColor(red: 40, green: 226, blue: 20),   // Green
            CueColor(red: 230, green: 20, blue: 20),   // Red
            CueColor(red: 20, green: 130, blue: 230),  // Blue
            CueColor(red: 230, green: 150, blue: 20),  // Orange
            CueColor(red: 200, green: 20, blue: 200),  // Purple
            CueColor(red: 230, green: 230, blue: 20),  // Yellow
            CueColor(red: 20, green: 230, blue: 230),  // Cyan
            CueColor(red: 230, green: 100, blue: 150), // Pink
        ]
    }

    public struct SectionOverride: Codable, Sendable, Identifiable {
        public var id: UUID
        public var type: String
        public var startTime: Double
        public var endTime: Double
        public var label: String?
        public var isUserCreated: Bool

        public init(
            id: UUID = UUID(),
            type: String,
            startTime: Double,
            endTime: Double,
            label: String? = nil,
            isUserCreated: Bool = true
        ) {
            self.id = id
            self.type = type
            self.startTime = startTime
            self.endTime = endTime
            self.label = label
            self.isUserCreated = isUserCreated
        }
    }

    // MARK: - Storage

    private var cache: [Int64: TrackOverrides] = [:]

    // MARK: - Public API

    /// Get overrides for a track
    public func getOverrides(trackId: Int64) async throws -> TrackOverrides? {
        // Check cache first
        if let cached = cache[trackId] {
            return cached
        }

        // Load from database
        let overrides = try await loadFromDatabase(trackId: trackId)
        if let overrides = overrides {
            cache[trackId] = overrides
        }
        return overrides
    }

    /// Save overrides for a track
    public func saveOverrides(trackId: Int64, overrides: TrackOverrides) async throws {
        var updatedOverrides = overrides
        updatedOverrides.updatedAt = Date()

        cache[trackId] = updatedOverrides
        try await saveToDatabase(trackId: trackId, overrides: updatedOverrides)

        logger.info("Saved overrides for track \(trackId)")
    }

    /// Update BPM override
    public func setBPM(trackId: Int64, bpm: Double, locked: Bool = true) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        overrides.bpm = bpm
        overrides.bpmLocked = locked
        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Update key override
    public func setKey(trackId: Int64, key: String, locked: Bool = true) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        overrides.key = key
        overrides.keyLocked = locked
        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Add or update a cue point
    public func setCuePoint(trackId: Int64, cue: CuePointOverride) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        var cues = overrides.cuePoints ?? []

        // Replace existing or add new
        if let index = cues.firstIndex(where: { $0.id == cue.id }) {
            cues[index] = cue
        } else {
            cues.append(cue)
        }

        // Sort by time
        cues.sort { $0.timeSeconds < $1.timeSeconds }
        overrides.cuePoints = cues

        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Remove a cue point
    public func removeCuePoint(trackId: Int64, cueId: UUID) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        overrides.cuePoints?.removeAll { $0.id == cueId }
        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Add or update a section
    public func setSection(trackId: Int64, section: SectionOverride) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        var sections = overrides.sections ?? []

        // Replace existing or add new
        if let index = sections.firstIndex(where: { $0.id == section.id }) {
            sections[index] = section
        } else {
            sections.append(section)
        }

        // Sort by start time
        sections.sort { $0.startTime < $1.startTime }
        overrides.sections = sections

        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Remove a section
    public func removeSection(trackId: Int64, sectionId: UUID) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        overrides.sections?.removeAll { $0.id == sectionId }
        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Set beat grid offset
    public func setGridOffset(trackId: Int64, offset: Double) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        overrides.gridOffset = offset
        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Set user notes
    public func setNotes(trackId: Int64, notes: String) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        overrides.notes = notes.isEmpty ? nil : notes
        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Set rating (1-5 stars)
    public func setRating(trackId: Int64, rating: Int) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        overrides.rating = max(0, min(5, rating))
        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Set tags
    public func setTags(trackId: Int64, tags: [String]) async throws {
        var overrides = try await getOverrides(trackId: trackId) ?? TrackOverrides()
        overrides.tags = tags.isEmpty ? nil : tags
        try await saveOverrides(trackId: trackId, overrides: overrides)
    }

    /// Clear all overrides for a track
    public func clearOverrides(trackId: Int64) async throws {
        cache.removeValue(forKey: trackId)
        try await deleteFromDatabase(trackId: trackId)
        logger.info("Cleared overrides for track \(trackId)")
    }

    /// Merge overrides with auto-analysis
    public func mergeWithAnalysis(trackId: Int64, analysis: TrackAnalysis) async throws -> TrackAnalysis {
        guard let overrides = try await getOverrides(trackId: trackId) else {
            return analysis
        }

        var merged = analysis

        // Apply BPM override
        if let bpm = overrides.bpm {
            merged.bpm = bpm
            merged.bpmConfidence = 1.0 // User override is 100% confident
        }

        // Apply key override
        if let key = overrides.key {
            merged.keyValue = key
            merged.keyConfidence = 1.0
        }

        // Apply energy override
        if let energy = overrides.energy {
            merged.energyGlobal = energy
        }

        // Merge cue points (user cues take precedence)
        if let userCues = overrides.cuePoints, !userCues.isEmpty {
            var allCues = merged.cuePoints ?? []

            for userCue in userCues {
                // Remove auto-cues at similar positions
                allCues.removeAll { abs($0.timeSeconds - userCue.timeSeconds) < 0.5 }

                // Add user cue
                allCues.append(CuePoint(
                    index: allCues.count,
                    label: userCue.label,
                    type: CuePoint.CueType(rawValue: userCue.type) ?? .custom,
                    timeSeconds: userCue.timeSeconds,
                    beatIndex: userCue.beatIndex
                ))
            }

            allCues.sort { $0.timeSeconds < $1.timeSeconds }
            merged.cuePoints = allCues
        }

        return merged
    }

    // MARK: - Database Operations

    private func loadFromDatabase(trackId: Int64) async throws -> TrackOverrides? {
        try await DatabaseManager.shared.dbQueue.read { db in
            guard let row = try Row.fetchOne(
                db,
                sql: "SELECT overrides_json FROM user_overrides WHERE track_id = ?",
                arguments: [trackId]
            ) else {
                return nil
            }

            guard let jsonData = row["overrides_json"] as? Data else {
                return nil
            }

            return try JSONDecoder().decode(TrackOverrides.self, from: jsonData)
        }
    }

    private func saveToDatabase(trackId: Int64, overrides: TrackOverrides) async throws {
        let jsonData = try JSONEncoder().encode(overrides)

        try await DatabaseManager.shared.dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO user_overrides (track_id, overrides_json, updated_at)
                    VALUES (?, ?, ?)
                    ON CONFLICT(track_id) DO UPDATE SET
                        overrides_json = excluded.overrides_json,
                        updated_at = excluded.updated_at
                    """,
                arguments: [trackId, jsonData, overrides.updatedAt]
            )
        }
    }

    private func deleteFromDatabase(trackId: Int64) async throws {
        try await DatabaseManager.shared.dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM user_overrides WHERE track_id = ?",
                arguments: [trackId]
            )
        }
    }
}

