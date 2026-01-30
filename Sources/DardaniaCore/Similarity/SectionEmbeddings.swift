// CartoMix - Section-Level Embeddings
// Generate and compare embeddings for individual track sections

import Foundation
import Accelerate
import Logging

/// Section-level embedding for granular similarity matching
public struct SectionEmbedding: Codable, Sendable {
    public let sectionId: UUID
    public let sectionType: String
    public let startTime: Double
    public let endTime: Double
    public let embedding: [Float]  // 512-dim OpenL3 embedding
    public let energy: Float
    public let spectralCentroid: Float
    public let zeroCrossingRate: Float

    public init(
        sectionId: UUID,
        sectionType: String,
        startTime: Double,
        endTime: Double,
        embedding: [Float],
        energy: Float,
        spectralCentroid: Float,
        zeroCrossingRate: Float
    ) {
        self.sectionId = sectionId
        self.sectionType = sectionType
        self.startTime = startTime
        self.endTime = endTime
        self.embedding = embedding
        self.energy = energy
        self.spectralCentroid = spectralCentroid
        self.zeroCrossingRate = zeroCrossingRate
    }

    public var duration: Double {
        endTime - startTime
    }
}

/// Track's complete section embedding profile
public struct TrackSectionProfile: Codable, Sendable {
    public let trackId: Int64
    public let sections: [SectionEmbedding]
    public let globalEmbedding: [Float]
    public let energyCurve: [Float]
    public let createdAt: Date

    public init(
        trackId: Int64,
        sections: [SectionEmbedding],
        globalEmbedding: [Float],
        energyCurve: [Float]
    ) {
        self.trackId = trackId
        self.sections = sections
        self.globalEmbedding = globalEmbedding
        self.energyCurve = energyCurve
        self.createdAt = Date()
    }
}

/// Section embedding analyzer
public actor SectionEmbeddingAnalyzer {
    private let logger = Logger(label: "com.cartomix.section-embeddings")

    // Standard section window for embedding (8 seconds)
    private let sectionWindowSeconds: Double = 8.0

    // Overlap between windows (2 seconds)
    private let windowOverlapSeconds: Double = 2.0

    public init() {}

    // MARK: - Analysis

    /// Generate section embeddings for a track
    public func analyzeTrack(
        audioData: [Float],
        sampleRate: Double,
        sections: [TrackSection]
    ) async throws -> TrackSectionProfile {
        let trackDuration = Double(audioData.count) / sampleRate

        var sectionEmbeddings: [SectionEmbedding] = []

        // Generate embeddings for each section
        for section in sections {
            let embedding = try await analyzeSectionEmbedding(
                audioData: audioData,
                sampleRate: sampleRate,
                startTime: section.startTime,
                endTime: section.endTime,
                sectionType: section.type.rawValue
            )
            sectionEmbeddings.append(embedding)
        }

        // If no sections provided, use sliding window
        if sections.isEmpty {
            sectionEmbeddings = try await analyzeWithSlidingWindow(
                audioData: audioData,
                sampleRate: sampleRate
            )
        }

        // Compute global embedding (average of all sections)
        let globalEmbedding = computeGlobalEmbedding(from: sectionEmbeddings)

        // Compute energy curve
        let energyCurve = computeEnergyCurve(
            audioData: audioData,
            sampleRate: sampleRate,
            windowCount: 100
        )

        logger.info("Generated \(sectionEmbeddings.count) section embeddings for track")

        return TrackSectionProfile(
            trackId: 0, // Will be set by caller
            sections: sectionEmbeddings,
            globalEmbedding: globalEmbedding,
            energyCurve: energyCurve
        )
    }

    /// Analyze a single section
    private func analyzeSectionEmbedding(
        audioData: [Float],
        sampleRate: Double,
        startTime: Double,
        endTime: Double,
        sectionType: String
    ) async throws -> SectionEmbedding {
        let startSample = Int(startTime * sampleRate)
        let endSample = min(Int(endTime * sampleRate), audioData.count)

        guard endSample > startSample else {
            throw SectionAnalysisError.invalidRange
        }

        let sectionData = Array(audioData[startSample..<endSample])

        // Compute features
        let energy = computeRMSEnergy(sectionData)
        let spectralCentroid = computeSpectralCentroid(sectionData, sampleRate: sampleRate)
        let zcr = computeZeroCrossingRate(sectionData)

        // Generate embedding (placeholder - would use Core ML model)
        let embedding = generateEmbedding(from: sectionData, sampleRate: sampleRate)

        return SectionEmbedding(
            sectionId: UUID(),
            sectionType: sectionType,
            startTime: startTime,
            endTime: endTime,
            embedding: embedding,
            energy: energy,
            spectralCentroid: spectralCentroid,
            zeroCrossingRate: zcr
        )
    }

    /// Sliding window analysis for tracks without predefined sections
    private func analyzeWithSlidingWindow(
        audioData: [Float],
        sampleRate: Double
    ) async throws -> [SectionEmbedding] {
        let duration = Double(audioData.count) / sampleRate
        let windowStep = sectionWindowSeconds - windowOverlapSeconds
        var embeddings: [SectionEmbedding] = []

        var currentTime: Double = 0
        var windowIndex = 0

        while currentTime < duration - 1.0 {
            let endTime = min(currentTime + sectionWindowSeconds, duration)

            let embedding = try await analyzeSectionEmbedding(
                audioData: audioData,
                sampleRate: sampleRate,
                startTime: currentTime,
                endTime: endTime,
                sectionType: "window_\(windowIndex)"
            )
            embeddings.append(embedding)

            currentTime += windowStep
            windowIndex += 1
        }

        return embeddings
    }

    // MARK: - Feature Computation

    private func computeRMSEnergy(_ samples: [Float]) -> Float {
        var sumSquared: Float = 0
        vDSP_measqv(samples, 1, &sumSquared, vDSP_Length(samples.count))
        return sqrt(sumSquared / Float(samples.count))
    }

    private func computeSpectralCentroid(_ samples: [Float], sampleRate: Double) -> Float {
        // Simplified spectral centroid using FFT
        let fftSize = 2048
        guard samples.count >= fftSize else { return 0 }

        // Apply Hanning window
        var windowedSamples = [Float](repeating: 0, count: fftSize)
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul(samples, 1, window, 1, &windowedSamples, 1, vDSP_Length(fftSize))

        // Compute magnitude spectrum (simplified)
        var magnitudes = [Float](repeating: 0, count: fftSize / 2)
        for i in 0..<(fftSize / 2) {
            magnitudes[i] = abs(windowedSamples[i])
        }

        // Compute weighted average frequency
        var weightedSum: Float = 0
        var totalMagnitude: Float = 0

        for i in 0..<magnitudes.count {
            let frequency = Float(i) * Float(sampleRate) / Float(fftSize)
            weightedSum += frequency * magnitudes[i]
            totalMagnitude += magnitudes[i]
        }

        return totalMagnitude > 0 ? weightedSum / totalMagnitude : 0
    }

    private func computeZeroCrossingRate(_ samples: [Float]) -> Float {
        guard samples.count > 1 else { return 0 }

        var crossings = 0
        for i in 1..<samples.count {
            if (samples[i] >= 0) != (samples[i - 1] >= 0) {
                crossings += 1
            }
        }

        return Float(crossings) / Float(samples.count - 1)
    }

    private func generateEmbedding(from samples: [Float], sampleRate: Double) -> [Float] {
        // Placeholder embedding generation
        // In production, this would use the OpenL3 Core ML model

        var embedding = [Float](repeating: 0, count: 512)

        // Generate pseudo-embedding based on audio features
        let energy = computeRMSEnergy(samples)
        let zcr = computeZeroCrossingRate(samples)

        // Fill embedding with feature-derived values
        for i in 0..<512 {
            let phase = Float(i) / 512.0 * Float.pi * 2
            embedding[i] = sin(phase * energy * 10) * 0.5 + cos(phase * zcr * 100) * 0.5
        }

        // Normalize
        var norm: Float = 0
        vDSP_svesq(embedding, 1, &norm, vDSP_Length(embedding.count))
        norm = sqrt(norm)

        if norm > 0 {
            var normValue = 1.0 / norm
            vDSP_vsmul(embedding, 1, &normValue, &embedding, 1, vDSP_Length(embedding.count))
        }

        return embedding
    }

    private func computeGlobalEmbedding(from sections: [SectionEmbedding]) -> [Float] {
        guard !sections.isEmpty else {
            return [Float](repeating: 0, count: 512)
        }

        var globalEmbedding = [Float](repeating: 0, count: 512)

        // Weight by section duration
        var totalDuration: Double = 0
        for section in sections {
            totalDuration += section.duration
        }

        for section in sections {
            let weight = Float(section.duration / totalDuration)
            for i in 0..<512 {
                globalEmbedding[i] += section.embedding[i] * weight
            }
        }

        // Normalize
        var norm: Float = 0
        vDSP_svesq(globalEmbedding, 1, &norm, vDSP_Length(globalEmbedding.count))
        norm = sqrt(norm)

        if norm > 0 {
            var normValue = 1.0 / norm
            vDSP_vsmul(globalEmbedding, 1, &normValue, &globalEmbedding, 1, vDSP_Length(globalEmbedding.count))
        }

        return globalEmbedding
    }

    private func computeEnergyCurve(
        audioData: [Float],
        sampleRate: Double,
        windowCount: Int
    ) -> [Float] {
        let samplesPerWindow = audioData.count / windowCount
        var curve = [Float](repeating: 0, count: windowCount)

        for i in 0..<windowCount {
            let start = i * samplesPerWindow
            let end = min(start + samplesPerWindow, audioData.count)
            let windowData = Array(audioData[start..<end])
            curve[i] = computeRMSEnergy(windowData)
        }

        // Normalize to 0-1
        let maxEnergy = curve.max() ?? 1.0
        if maxEnergy > 0 {
            curve = curve.map { $0 / maxEnergy }
        }

        return curve
    }

    // MARK: - Similarity

    /// Compare two section profiles
    public func compareSections(
        profile1: TrackSectionProfile,
        profile2: TrackSectionProfile
    ) -> SectionSimilarityResult {
        // Global embedding similarity
        let globalSimilarity = cosineSimilarity(
            profile1.globalEmbedding,
            profile2.globalEmbedding
        )

        // Energy curve correlation
        let energyCorrelation = computeCorrelation(
            profile1.energyCurve,
            profile2.energyCurve
        )

        // Find best section matches
        var sectionMatches: [(Int, Int, Float)] = []

        for (i, section1) in profile1.sections.enumerated() {
            var bestMatch = -1
            var bestScore: Float = -1

            for (j, section2) in profile2.sections.enumerated() {
                let score = cosineSimilarity(section1.embedding, section2.embedding)
                if score > bestScore {
                    bestScore = score
                    bestMatch = j
                }
            }

            if bestMatch >= 0 && bestScore > 0.5 {
                sectionMatches.append((i, bestMatch, bestScore))
            }
        }

        return SectionSimilarityResult(
            globalSimilarity: globalSimilarity,
            energyCorrelation: energyCorrelation,
            sectionMatches: sectionMatches,
            overallScore: (globalSimilarity + energyCorrelation) / 2
        )
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0

        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
        vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))

        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? dotProduct / denominator : 0
    }

    private func computeCorrelation(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        // Compute means
        var meanA: Float = 0
        var meanB: Float = 0
        vDSP_meanv(a, 1, &meanA, vDSP_Length(a.count))
        vDSP_meanv(b, 1, &meanB, vDSP_Length(b.count))

        // Compute correlation
        var covariance: Float = 0
        var varA: Float = 0
        var varB: Float = 0

        for i in 0..<a.count {
            let diffA = a[i] - meanA
            let diffB = b[i] - meanB
            covariance += diffA * diffB
            varA += diffA * diffA
            varB += diffB * diffB
        }

        let denominator = sqrt(varA) * sqrt(varB)
        return denominator > 0 ? covariance / denominator : 0
    }
}

// MARK: - Supporting Types

public struct SectionSimilarityResult: Sendable {
    public let globalSimilarity: Float
    public let energyCorrelation: Float
    public let sectionMatches: [(Int, Int, Float)]  // (section1Index, section2Index, score)
    public let overallScore: Float
}

public enum SectionAnalysisError: Error {
    case invalidRange
    case insufficientData
    case modelLoadFailed
}

// MARK: - TrackSection Extension for Compatibility

extension TrackSection {
    init(from sectionEmbedding: SectionEmbedding) {
        self.id = sectionEmbedding.sectionId
        self.type = SectionType(rawValue: sectionEmbedding.sectionType) ?? .verse
        self.startTime = sectionEmbedding.startTime
        self.endTime = sectionEmbedding.endTime
        self.confidence = 1.0
    }
}
