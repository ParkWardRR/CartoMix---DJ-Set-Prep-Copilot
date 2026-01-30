// Dardania - Similarity Scoring
// Port of internal/similarity/similarity.go

import Foundation
import Accelerate

/// Weights for combined similarity scoring
public struct SimilarityWeights: Sendable {
    public let openL3: Double
    public let tempo: Double
    public let key: Double
    public let energy: Double

    public static let `default` = SimilarityWeights(
        openL3: 0.50,  // Vibe match from embeddings
        tempo: 0.20,   // BPM compatibility
        key: 0.20,     // Key compatibility
        energy: 0.10   // Energy level similarity
    )
}

/// Result of similarity computation between two tracks
public struct SimilarityResult: Sendable {
    public let trackAId: Int64
    public let trackBId: Int64
    public let openL3Similarity: Double
    public let tempoSimilarity: Double
    public let keySimilarity: Double
    public let energySimilarity: Double
    public let combinedScore: Double
    public let keyRelation: String
    public let explanation: String
}

public actor SimilarityScorer {
    private let weights: SimilarityWeights
    private let database: DatabaseManager

    public init(database: DatabaseManager, weights: SimilarityWeights = .default) {
        self.database = database
        self.weights = weights
    }

    // MARK: - Cosine Similarity (using vDSP)

    /// Compute cosine similarity between two embedding vectors using Accelerate
    public nonisolated func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0

        // Use vDSP for vectorized computation
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
        vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))

        guard normA > 0 && normB > 0 else { return 0 }

        let similarity = dotProduct / (sqrt(normA) * sqrt(normB))

        // Normalize from [-1, 1] to [0, 1]
        return (similarity + 1) / 2
    }

    // MARK: - Tempo Similarity

    /// Compute tempo similarity with half/double tempo support
    public func tempoSimilarity(bpmA: Double, bpmB: Double) -> Double {
        let diff = abs(bpmA - bpmB)

        // Support half/double tempo (64 BPM ≈ 128 BPM)
        let halfDiff = min(abs(bpmA - bpmB * 2), abs(bpmA * 2 - bpmB))
        let effectiveDiff = min(diff, halfDiff)

        if effectiveDiff <= 1 { return 1.0 }
        if effectiveDiff >= 10 { return 0.0 }

        return 1.0 - (effectiveDiff / 10.0)
    }

    // MARK: - Key Similarity (Camelot Wheel)

    /// Compute key similarity using Camelot wheel rules
    public nonisolated func keySimilarity(keyA: String, keyB: String) -> (similarity: Double, relation: String) {
        // Same key = perfect match
        if keyA == keyB {
            return (1.0, "same")
        }

        guard let (numA, modeA) = parseCamelot(keyA),
              let (numB, modeB) = parseCamelot(keyB) else {
            return (0.2, "unknown")
        }

        // Relative major/minor (same number, different mode)
        if numA == numB && modeA != modeB {
            return (0.9, "relative")
        }

        // Adjacent on wheel (±1, same mode)
        let adjacent = (numA == numB + 1) || (numA == numB - 1) ||
                       (numA == 1 && numB == 12) || (numA == 12 && numB == 1)
        if adjacent && modeA == modeB {
            return (0.85, "compatible")
        }

        // +2/-2 steps (energy boost/drop)
        let twoSteps = abs(numA - numB) == 2 ||
                       (numA == 1 && numB == 11) || (numA == 11 && numB == 1) ||
                       (numA == 2 && numB == 12) || (numA == 12 && numB == 2)
        if twoSteps && modeA == modeB {
            return (0.7, "harmonic")
        }

        // Diagonal (±1 number, opposite mode)
        let diagonal = adjacent && modeA != modeB
        if diagonal {
            return (0.6, "diagonal")
        }

        // Everything else is a clash
        return (0.2, "clash")
    }

    /// Parse Camelot notation (e.g., "8A" -> (8, "A"))
    private nonisolated func parseCamelot(_ key: String) -> (number: Int, mode: String)? {
        let pattern = /^(\d{1,2})([AB])$/

        guard let match = key.wholeMatch(of: pattern) else { return nil }

        let number = Int(match.1)!
        let mode = String(match.2)

        guard number >= 1 && number <= 12 else { return nil }

        return (number, mode)
    }

    // MARK: - Energy Similarity

    /// Compute energy similarity (0-10 scale)
    public func energySimilarity(energyA: Int, energyB: Int) -> Double {
        let diff = abs(energyA - energyB)
        return max(0, 1.0 - Double(diff) / 10.0)
    }

    // MARK: - Combined Similarity

    /// Compute combined similarity score with explanation
    public func computeSimilarity(
        trackA: Track,
        trackB: Track,
        embeddingA: [Float]?,
        embeddingB: [Float]?
    ) -> SimilarityResult {
        guard let analysisA = trackA.analysis, let analysisB = trackB.analysis else {
            return SimilarityResult(
                trackAId: trackA.id,
                trackBId: trackB.id,
                openL3Similarity: 0,
                tempoSimilarity: 0,
                keySimilarity: 0,
                energySimilarity: 0,
                combinedScore: 0,
                keyRelation: "unknown",
                explanation: "Missing analysis data"
            )
        }

        // OpenL3 similarity
        var openL3Sim: Double = 0
        if let a = embeddingA, let b = embeddingB {
            openL3Sim = Double(cosineSimilarity(a, b))
        }

        // Tempo similarity
        let tempoSim = tempoSimilarity(bpmA: analysisA.bpm, bpmB: analysisB.bpm)

        // Key similarity
        let (keySim, keyRelation) = keySimilarity(keyA: analysisA.keyValue, keyB: analysisB.keyValue)

        // Energy similarity
        let energySim = energySimilarity(energyA: analysisA.energyGlobal, energyB: analysisB.energyGlobal)

        // Combined score
        let combined = weights.openL3 * openL3Sim +
                      weights.tempo * tempoSim +
                      weights.key * keySim +
                      weights.energy * energySim

        // Generate explanation
        let explanation = generateExplanation(
            openL3Sim: openL3Sim,
            tempoSim: tempoSim,
            keySim: keySim,
            energySim: energySim,
            keyRelation: keyRelation,
            bpmDelta: analysisB.bpm - analysisA.bpm,
            keyA: analysisA.keyValue,
            keyB: analysisB.keyValue,
            energyDelta: analysisB.energyGlobal - analysisA.energyGlobal
        )

        return SimilarityResult(
            trackAId: trackA.id,
            trackBId: trackB.id,
            openL3Similarity: openL3Sim,
            tempoSimilarity: tempoSim,
            keySimilarity: keySim,
            energySimilarity: energySim,
            combinedScore: combined,
            keyRelation: keyRelation,
            explanation: explanation
        )
    }

    /// Generate human-readable explanation
    private func generateExplanation(
        openL3Sim: Double,
        tempoSim: Double,
        keySim: Double,
        energySim: Double,
        keyRelation: String,
        bpmDelta: Double,
        keyA: String,
        keyB: String,
        energyDelta: Int
    ) -> String {
        var parts: [String] = []

        // Vibe match
        let vibePercent = Int(openL3Sim * 100)
        if vibePercent >= 70 {
            parts.append("similar vibe (\(vibePercent)%)")
        } else if vibePercent >= 50 {
            parts.append("moderate vibe (\(vibePercent)%)")
        }

        // Tempo
        if abs(bpmDelta) < 1 {
            parts.append("tempo match")
        } else {
            let sign = bpmDelta >= 0 ? "+" : ""
            parts.append("Δ\(sign)\(String(format: "%.1f", bpmDelta)) BPM")
        }

        // Key
        if keyA == keyB {
            parts.append("same key")
        } else {
            parts.append("key: \(keyA)→\(keyB) (\(keyRelation))")
        }

        // Energy
        if energyDelta != 0 {
            let sign = energyDelta > 0 ? "+" : ""
            parts.append("energy \(sign)\(energyDelta)")
        }

        return parts.joined(separator: "; ")
    }

    // MARK: - Batch Similarity

    /// Find similar tracks for a given track
    public func findSimilarTracks(
        for track: Track,
        allTracks: [Track],
        limit: Int = 10
    ) async throws -> [SimilarityResult] {
        guard let trackEmbedding = try await database.fetchEmbedding(trackId: track.id)?.embedding else {
            return []
        }

        var results: [SimilarityResult] = []

        for other in allTracks where other.id != track.id {
            let otherEmbedding = try await database.fetchEmbedding(trackId: other.id)?.embedding

            let result = computeSimilarity(
                trackA: track,
                trackB: other,
                embeddingA: trackEmbedding,
                embeddingB: otherEmbedding
            )

            results.append(result)
        }

        // Sort by combined score and return top N
        return results
            .sorted { $0.combinedScore > $1.combinedScore }
            .prefix(limit)
            .map { $0 }
    }

    /// Compute and cache similarity for all track pairs
    public func computeAllSimilarities(tracks: [Track]) async throws {
        let analyzedTracks = tracks.filter { $0.analysis != nil }

        for i in 0..<analyzedTracks.count {
            for j in (i + 1)..<analyzedTracks.count {
                let trackA = analyzedTracks[i]
                let trackB = analyzedTracks[j]

                let embeddingA = try await database.fetchEmbedding(trackId: trackA.id)?.embedding
                let embeddingB = try await database.fetchEmbedding(trackId: trackB.id)?.embedding

                let result = computeSimilarity(
                    trackA: trackA,
                    trackB: trackB,
                    embeddingA: embeddingA,
                    embeddingB: embeddingB
                )

                // Cache in database
                let similarity = EmbeddingSimilarity(
                    trackAId: result.trackAId,
                    trackBId: result.trackBId,
                    openl3Similarity: result.openL3Similarity,
                    combinedScore: result.combinedScore,
                    tempoSimilarity: result.tempoSimilarity,
                    keySimilarity: result.keySimilarity,
                    energySimilarity: result.energySimilarity,
                    explanation: result.explanation
                )

                try await database.insertSimilarity(similarity)
            }
        }
    }
}
