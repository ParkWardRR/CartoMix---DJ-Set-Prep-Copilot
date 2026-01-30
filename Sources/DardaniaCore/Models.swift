// Dardania - Core Models

import Foundation
import SwiftUI
import GRDB

// MARK: - Track

public struct Track: Identifiable, Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: Int64
    public var contentHash: String
    public var path: String
    public var title: String
    public var artist: String
    public var album: String?
    public var fileSize: Int64
    public var fileModifiedAt: Date
    public var createdAt: Date
    public var updatedAt: Date

    // Joined analysis (optional)
    public var analysis: TrackAnalysis?

    public static let databaseTableName = "tracks"

    public init(
        id: Int64 = 0,
        contentHash: String,
        path: String,
        title: String,
        artist: String,
        album: String? = nil,
        fileSize: Int64,
        fileModifiedAt: Date,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.contentHash = contentHash
        self.path = path
        self.title = title
        self.artist = artist
        self.album = album
        self.fileSize = fileSize
        self.fileModifiedAt = fileModifiedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, contentHash = "content_hash", path, title, artist, album
        case fileSize = "file_size", fileModifiedAt = "file_modified_at"
        case createdAt = "created_at", updatedAt = "updated_at"
    }

    public static var preview: Track {
        Track(
            id: 1,
            contentHash: "abc123",
            path: "/Music/track.mp3",
            title: "Sample Track",
            artist: "Test Artist",
            album: "Test Album",
            fileSize: 10_000_000,
            fileModifiedAt: Date()
        )
    }
}

// MARK: - Track Analysis

public struct TrackAnalysis: Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: Int64
    public var trackId: Int64
    public var version: Int
    public var status: AnalysisStatus
    public var durationSeconds: Double
    public var bpm: Double
    public var bpmConfidence: Double
    public var keyValue: String
    public var keyFormat: String
    public var keyConfidence: Double
    public var energyGlobal: Int
    public var integratedLUFS: Double
    public var truePeakDB: Double
    public var loudnessRange: Double
    public var waveformPreview: [Float]
    public var sections: [TrackSection]
    public var cuePoints: [CuePoint]
    public var soundContext: String?
    public var soundContextConfidence: Double?
    public var qaFlags: [QAFlag]
    public var hasOpenL3Embedding: Bool
    public var trainingLabels: [TrainingLabel]
    public var createdAt: Date
    public var updatedAt: Date

    public static let databaseTableName = "analyses"

    enum CodingKeys: String, CodingKey {
        case id, trackId = "track_id", version, status
        case durationSeconds = "duration_seconds"
        case bpm, bpmConfidence = "bpm_confidence"
        case keyValue = "key_value", keyFormat = "key_format", keyConfidence = "key_confidence"
        case energyGlobal = "energy_global"
        case integratedLUFS = "integrated_lufs", truePeakDB = "true_peak_db", loudnessRange = "loudness_range"
        case waveformPreview = "waveform_preview"
        case sections = "sections_json", cuePoints = "cue_points_json"
        case soundContext = "sound_context", soundContextConfidence = "sound_context_confidence"
        case qaFlags = "qa_flags", hasOpenL3Embedding = "has_openl3_embedding"
        case trainingLabels = "training_labels"
        case createdAt = "created_at", updatedAt = "updated_at"
    }

    public init(
        id: Int64,
        trackId: Int64,
        version: Int,
        status: AnalysisStatus,
        durationSeconds: Double,
        bpm: Double,
        bpmConfidence: Double,
        keyValue: String,
        keyFormat: String,
        keyConfidence: Double,
        energyGlobal: Int,
        integratedLUFS: Double,
        truePeakDB: Double,
        loudnessRange: Double,
        waveformPreview: [Float],
        sections: [TrackSection],
        cuePoints: [CuePoint],
        soundContext: String?,
        soundContextConfidence: Double?,
        qaFlags: [QAFlag],
        hasOpenL3Embedding: Bool,
        trainingLabels: [TrainingLabel],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.trackId = trackId
        self.version = version
        self.status = status
        self.durationSeconds = durationSeconds
        self.bpm = bpm
        self.bpmConfidence = bpmConfidence
        self.keyValue = keyValue
        self.keyFormat = keyFormat
        self.keyConfidence = keyConfidence
        self.energyGlobal = energyGlobal
        self.integratedLUFS = integratedLUFS
        self.truePeakDB = truePeakDB
        self.loudnessRange = loudnessRange
        self.waveformPreview = waveformPreview
        self.sections = sections
        self.cuePoints = cuePoints
        self.soundContext = soundContext
        self.soundContextConfidence = soundContextConfidence
        self.qaFlags = qaFlags
        self.hasOpenL3Embedding = hasOpenL3Embedding
        self.trainingLabels = trainingLabels
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        trackId = try container.decode(Int64.self, forKey: .trackId)
        version = try container.decode(Int.self, forKey: .version)
        status = try container.decode(AnalysisStatus.self, forKey: .status)
        durationSeconds = try container.decode(Double.self, forKey: .durationSeconds)
        bpm = try container.decode(Double.self, forKey: .bpm)
        bpmConfidence = try container.decode(Double.self, forKey: .bpmConfidence)
        keyValue = try container.decode(String.self, forKey: .keyValue)
        keyFormat = try container.decode(String.self, forKey: .keyFormat)
        keyConfidence = try container.decode(Double.self, forKey: .keyConfidence)
        energyGlobal = try container.decode(Int.self, forKey: .energyGlobal)
        integratedLUFS = try container.decode(Double.self, forKey: .integratedLUFS)
        truePeakDB = try container.decode(Double.self, forKey: .truePeakDB)
        loudnessRange = try container.decode(Double.self, forKey: .loudnessRange)

        // Decode JSON strings
        let waveformData = try container.decodeIfPresent(Data.self, forKey: .waveformPreview)
        waveformPreview = waveformData.flatMap { try? JSONDecoder().decode([Float].self, from: $0) } ?? []

        let sectionsData = try container.decodeIfPresent(Data.self, forKey: .sections)
        sections = sectionsData.flatMap { try? JSONDecoder().decode([TrackSection].self, from: $0) } ?? []

        let cuesData = try container.decodeIfPresent(Data.self, forKey: .cuePoints)
        cuePoints = cuesData.flatMap { try? JSONDecoder().decode([CuePoint].self, from: $0) } ?? []

        soundContext = try container.decodeIfPresent(String.self, forKey: .soundContext)
        soundContextConfidence = try container.decodeIfPresent(Double.self, forKey: .soundContextConfidence)

        let qaFlagsData = try container.decodeIfPresent(Data.self, forKey: .qaFlags)
        qaFlags = qaFlagsData.flatMap { try? JSONDecoder().decode([QAFlag].self, from: $0) } ?? []

        hasOpenL3Embedding = try container.decode(Bool.self, forKey: .hasOpenL3Embedding)

        let labelsData = try container.decodeIfPresent(Data.self, forKey: .trainingLabels)
        trainingLabels = labelsData.flatMap { try? JSONDecoder().decode([TrainingLabel].self, from: $0) } ?? []

        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

public enum AnalysisStatus: String, Codable, Sendable {
    case pending
    case analyzing
    case complete
    case failed
}

// MARK: - Track Section

public struct TrackSection: Codable, Equatable, Sendable {
    public var type: SectionType
    public var startTime: Double
    public var endTime: Double
    public var confidence: Double

    public enum SectionType: String, Codable, Sendable {
        case intro, verse, build, drop, breakdown, chorus, outro

        public var color: Color {
            switch self {
            case .intro: return .green
            case .verse: return .gray
            case .build: return .yellow
            case .drop: return .red
            case .breakdown: return .purple
            case .chorus: return .pink
            case .outro: return .blue
            }
        }
    }

    public var color: Color { type.color }
}

// MARK: - Cue Point

public struct CuePoint: Codable, Equatable, Sendable {
    public var index: Int
    public var label: String
    public var type: CueType
    public var timeSeconds: Double
    public var beatIndex: Int?

    public enum CueType: String, Codable, Sendable {
        case intro, drop, build, breakdown, outro, custom

        public var defaultColor: Color {
            switch self {
            case .intro: return .green
            case .drop: return .red
            case .build: return .orange
            case .breakdown: return .blue
            case .outro: return .purple
            case .custom: return .gray
            }
        }
    }

    public var color: Color { type.defaultColor }
}

// MARK: - QA Flag

public struct QAFlag: Codable, Equatable, Sendable {
    public var type: FlagType
    public var reason: String
    public var dismissed: Bool

    public enum FlagType: String, Codable, Sendable {
        case needsReview = "needs_review"
        case mixedContent = "mixed_content"
        case speechDetected = "speech_detected"
        case lowConfidence = "low_confidence"
    }

    public var icon: String {
        switch type {
        case .needsReview: return "exclamationmark.triangle"
        case .mixedContent: return "waveform.badge.exclamationmark"
        case .speechDetected: return "person.wave.2"
        case .lowConfidence: return "questionmark.circle"
        }
    }

    public var color: Color {
        switch type {
        case .needsReview: return .yellow
        case .mixedContent: return .orange
        case .speechDetected: return .blue
        case .lowConfidence: return .gray
        }
    }
}

// MARK: - Training Label

public struct TrainingLabel: Codable, Equatable, Sendable {
    public var label: SectionLabel
    public var startTime: Double
    public var endTime: Double
    public var startBeat: Int?
    public var endBeat: Int?

    public enum SectionLabel: String, Codable, CaseIterable, Sendable {
        case intro, build, drop, breakdown = "break", outro, verse, chorus

        public var color: Color {
            switch self {
            case .intro: return .green
            case .build: return .yellow
            case .drop: return .red
            case .breakdown: return .purple
            case .outro: return .blue
            case .verse: return .gray
            case .chorus: return .pink
            }
        }
    }
}

// MARK: - Music Location

public struct MusicLocation: Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var id: Int64
    public var url: URL
    public var bookmarkData: Data
    public var createdAt: Date

    public static let databaseTableName = "music_locations"

    enum CodingKeys: String, CodingKey {
        case id, url, bookmarkData = "bookmark_data", createdAt = "created_at"
    }
}

// MARK: - OpenL3 Embedding

public struct OpenL3Embedding: Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var trackId: Int64
    public var analysisVersion: Int
    public var embedding: [Float] // 512-dimensional
    public var createdAt: Date

    public static let databaseTableName = "openl3_embeddings"

    enum CodingKeys: String, CodingKey {
        case trackId = "track_id", analysisVersion = "analysis_version"
        case embedding, createdAt = "created_at"
    }

    /// Compute cosine similarity with another embedding
    public func similarity(to other: OpenL3Embedding) -> Float {
        guard embedding.count == other.embedding.count else { return 0 }

        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0

        for i in 0..<embedding.count {
            dotProduct += embedding[i] * other.embedding[i]
            normA += embedding[i] * embedding[i]
            normB += other.embedding[i] * other.embedding[i]
        }

        guard normA > 0 && normB > 0 else { return 0 }

        let similarity = dotProduct / (sqrt(normA) * sqrt(normB))
        // Normalize from [-1, 1] to [0, 1]
        return (similarity + 1) / 2
    }
}

// MARK: - Embedding Similarity

public struct EmbeddingSimilarity: Codable, Equatable, Sendable, FetchableRecord, PersistableRecord {
    public var trackAId: Int64
    public var trackBId: Int64
    public var openl3Similarity: Double
    public var combinedScore: Double
    public var tempoSimilarity: Double
    public var keySimilarity: Double
    public var energySimilarity: Double
    public var explanation: String

    public static let databaseTableName = "embedding_similarity"

    enum CodingKeys: String, CodingKey {
        case trackAId = "track_a_id", trackBId = "track_b_id"
        case openl3Similarity = "openl3_similarity", combinedScore = "combined_score"
        case tempoSimilarity = "tempo_similarity", keySimilarity = "key_similarity"
        case energySimilarity = "energy_similarity", explanation
    }
}

// MARK: - Analysis Progress

public struct AnalysisProgress: Sendable {
    public var stage: Stage
    public var progress: Double
    public var message: String?

    public enum Stage: String, Sendable {
        case decoding
        case beatgrid
        case key
        case energy
        case loudness
        case sections
        case embedding
        case cues
        case complete
        case failed
    }

    public init(stage: Stage, progress: Double = 0, message: String? = nil) {
        self.stage = stage
        self.progress = progress
        self.message = message
    }
}
