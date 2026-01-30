// CartoMix - Analyzer Service

import Foundation
import Logging

/// Service for audio analysis using the Swift analyzer
public actor AnalyzerService {
    private let database: DatabaseManager
    private let analyzer: Analyzer
    private let logger = Logger(label: "com.dardania.analyzer")
    private let governor: ConcurrencyGovernor

    public init(database: DatabaseManager) {
        self.database = database
        self.analyzer = Analyzer()
        self.governor = ConcurrencyGovernor()
    }

    // MARK: - Library Scanning

    /// Scan a directory for audio files
    public func scanDirectory(
        url: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        logger.info("Scanning directory: \(url.path)")

        // Resolve security-scoped bookmark if needed
        guard url.startAccessingSecurityScopedResource() else {
            throw AnalyzerServiceError.accessDenied(url.path)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Find all audio files
        let audioExtensions = ["mp3", "wav", "aiff", "aif", "flac", "m4a", "aac", "alac"]
        let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        var audioFiles: [URL] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            if audioExtensions.contains(fileURL.pathExtension.lowercased()) {
                audioFiles.append(fileURL)
            }
        }

        logger.info("Found \(audioFiles.count) audio files")

        // Process files
        for (index, fileURL) in audioFiles.enumerated() {
            progress(Double(index) / Double(audioFiles.count))

            do {
                try await processAudioFile(url: fileURL)
            } catch {
                logger.warning("Failed to process \(fileURL.lastPathComponent): \(error)")
            }
        }

        progress(1.0)
        logger.info("Scan complete")
    }

    /// Process a single audio file
    private func processAudioFile(url: URL) async throws {
        // Get file attributes
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        let modifiedAt = attributes[.modificationDate] as? Date ?? Date()

        // Compute content hash
        let contentHash = try computeContentHash(url: url)

        // Extract metadata
        let (title, artist, album) = extractMetadata(from: url)

        // Create or update track
        let track = Track(
            contentHash: contentHash,
            path: url.path,
            title: title,
            artist: artist,
            album: album,
            fileSize: fileSize,
            fileModifiedAt: modifiedAt
        )

        _ = try await database.upsertTrack(track)
    }

    /// Compute SHA-256 hash of file content
    private func computeContentHash(url: URL) throws -> String {
        let data = try Data(contentsOf: url)

        // Use first 1MB + last 1MB + file size for fast hashing
        var hashData = Data()

        if data.count > 2_000_000 {
            hashData.append(data.prefix(1_000_000))
            hashData.append(data.suffix(1_000_000))
        } else {
            hashData = data
        }

        // Add file size
        var size = UInt64(data.count)
        hashData.append(Data(bytes: &size, count: 8))

        return hashData.sha256().hexString
    }

    /// Extract metadata from audio file
    private func extractMetadata(from url: URL) -> (title: String, artist: String, album: String?) {
        // Use filename as fallback
        let filename = url.deletingPathExtension().lastPathComponent

        // Parse "Artist - Title" format
        let parts = filename.split(separator: "-", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }

        if parts.count == 2 {
            return (parts[1], parts[0], nil)
        } else {
            return (filename, "Unknown Artist", nil)
        }
    }

    // MARK: - Track Analysis

    /// Analyze a track
    public func analyzeTrack(
        track: Track,
        progress: @escaping @Sendable (AnalysisProgress) -> Void
    ) async throws {
        logger.info("Analyzing track: \(track.title)")

        // Acquire analysis permit (concurrency control)
        try await governor.acquireAnalysisPermit()
        defer { Task { await governor.releaseAnalysisPermit() } }

        // Run analysis
        progress(AnalysisProgress(stage: .decoding))

        let result = try await analyzer.analyze(
            path: track.path,
            progress: { analyzerProgress in
                // Map analyzer stages to our progress stages
                let mappedStage: AnalysisProgress.Stage
                switch analyzerProgress {
                case .decoding:
                    mappedStage = .decoding
                case .beatgrid:
                    mappedStage = .beatgrid
                case .key:
                    mappedStage = .key
                case .energy:
                    mappedStage = .energy
                case .loudness:
                    mappedStage = .loudness
                case .sections:
                    mappedStage = .sections
                case .cues:
                    mappedStage = .cues
                case .waveform:
                    mappedStage = .cues // Map waveform to cues stage
                case .embedding, .openL3Embedding:
                    mappedStage = .embedding
                case .soundClassification:
                    mappedStage = .embedding
                case .complete:
                    mappedStage = .complete
                }
                progress(AnalysisProgress(stage: mappedStage))
            }
        )

        // Convert result to our analysis model
        let analysis = convertAnalysisResult(result, trackId: track.id)

        // Save to database
        _ = try await database.insertAnalysis(analysis)

        // Save OpenL3 embedding if available
        if let analyzerEmbedding = result.openL3Embedding {
            let openL3 = OpenL3Embedding(
                trackId: track.id,
                analysisVersion: analysis.version,
                embedding: analyzerEmbedding.vector,
                createdAt: Date()
            )
            try await database.insertEmbedding(openL3)
        }

        progress(AnalysisProgress(stage: .complete))
        logger.info("Analysis complete: \(track.title)")
    }

    /// Convert analyzer result to our model
    private func convertAnalysisResult(_ result: TrackAnalysisResult, trackId: Int64) -> TrackAnalysis {
        // Convert sections
        let sections: [TrackSection] = result.sections.map { section in
            TrackSection(
                type: mapSectionType(section.type),
                startTime: section.startTime,
                endTime: section.endTime,
                confidence: Double(section.confidence)
            )
        }

        // Convert cue points
        let cuePoints: [CuePoint] = result.cues.enumerated().map { index, cue in
            CuePoint(
                index: index,
                label: cue.label,
                type: mapCueType(cue.type),
                timeSeconds: cue.time,
                beatIndex: cue.beatIndex
            )
        }

        // Generate waveform preview (downsample to 1000 points)
        let waveformPreview: [Float]
        if result.waveformSummary.count > 1000 {
            let step = result.waveformSummary.count / 1000
            waveformPreview = stride(from: 0, to: result.waveformSummary.count, by: step).map { result.waveformSummary[$0] }
        } else {
            waveformPreview = result.waveformSummary
        }

        return TrackAnalysis(
            id: 0,
            trackId: trackId,
            version: 1,
            status: .complete,
            durationSeconds: result.duration,
            bpm: result.bpm,
            bpmConfidence: Double(result.beatgridConfidence),
            keyValue: result.key.camelot,
            keyFormat: "camelot",
            keyConfidence: Double(result.key.confidence),
            energyGlobal: Int(result.globalEnergy * 100),
            integratedLUFS: Double(result.loudness.integratedLoudness),
            truePeakDB: Double(result.loudness.truePeak),
            loudnessRange: Double(result.loudness.loudnessRange),
            waveformPreview: waveformPreview,
            sections: sections,
            cuePoints: cuePoints,
            soundContext: result.soundClassification?.primaryContext,
            soundContextConfidence: result.soundClassification.map { Double($0.confidence) },
            qaFlags: [],
            hasOpenL3Embedding: result.openL3Embedding != nil,
            trainingLabels: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Map analyzer SectionType to our SectionType
    private func mapSectionType(_ type: SectionType) -> TrackSection.SectionType {
        switch type {
        case .intro: return .intro
        case .verse: return .verse
        case .build: return .build
        case .drop: return .drop
        case .breakdown: return .breakdown
        case .outro: return .outro
        }
    }

    /// Map analyzer CueType to our CueType
    private func mapCueType(_ type: CueType) -> CuePoint.CueType {
        switch type {
        case .drop: return .drop
        case .build: return .build
        case .breakdown: return .breakdown
        case .introStart, .introEnd: return .intro
        case .outroStart, .outroEnd: return .outro
        case .load, .marker: return .custom
        }
    }

    /// Analyze all unanalyzed tracks
    public func analyzeAllPending(
        progress: @escaping @Sendable (Int, Int, AnalysisProgress?) -> Void
    ) async throws {
        let tracks = try await database.fetchAllTracks()
        let unanalyzed = tracks.filter { $0.analysis == nil }

        for (index, track) in unanalyzed.enumerated() {
            progress(index, unanalyzed.count, nil)

            do {
                try await analyzeTrack(track: track) { analysisProgress in
                    progress(index, unanalyzed.count, analysisProgress)
                }
            } catch {
                logger.error("Failed to analyze \(track.title): \(error)")
            }
        }

        progress(unanalyzed.count, unanalyzed.count, AnalysisProgress(stage: .complete))
    }
}

// MARK: - Concurrency Governor

/// Controls concurrency to prevent resource exhaustion
actor ConcurrencyGovernor {
    private let maxConcurrentAnalyses: Int
    private let maxMemoryBudgetMB: Int
    private var activeAnalyses = 0
    private var estimatedMemoryUsageMB = 0

    init(maxConcurrentAnalyses: Int = 4, maxMemoryBudgetMB: Int = 550) {
        self.maxConcurrentAnalyses = maxConcurrentAnalyses
        self.maxMemoryBudgetMB = maxMemoryBudgetMB
    }

    func acquireAnalysisPermit() async throws {
        // Wait until we have capacity
        while activeAnalyses >= maxConcurrentAnalyses ||
              estimatedMemoryUsageMB + 55 > maxMemoryBudgetMB { // ~55MB per analysis
            await Task.yield()
        }

        activeAnalyses += 1
        estimatedMemoryUsageMB += 55
    }

    func releaseAnalysisPermit() {
        activeAnalyses = max(0, activeAnalyses - 1)
        estimatedMemoryUsageMB = max(0, estimatedMemoryUsageMB - 55)
    }
}

// MARK: - Errors

public enum AnalyzerServiceError: Error, LocalizedError {
    case accessDenied(String)
    case analysisFailed(String)
    case unsupportedFormat(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied(let path):
            return "Access denied to \(path)"
        case .analysisFailed(let reason):
            return "Analysis failed: \(reason)"
        case .unsupportedFormat(let format):
            return "Unsupported audio format: \(format)"
        }
    }
}
