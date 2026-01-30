// CartoMix - Energy Curve Matching
// Find tracks with compatible energy progressions for smooth transitions

import Foundation
import Accelerate
import Logging

/// Energy curve match result
public struct EnergyCurveMatch: Sendable, Identifiable {
    public let id: UUID
    public let trackId: Int64
    public let overallScore: Float
    public let correlationScore: Float
    public let complementScore: Float
    public let shapeScore: Float
    public let matchType: MatchType
    public let bestTransitionPoint: Int  // Normalized position (0-100)
    public let explanation: String

    public enum MatchType: String, Sendable {
        case parallel      // Similar energy curve (good for maintaining energy)
        case complementary // Opposite curves (good for building/dropping)
        case continuation  // One ends where other begins (seamless)
        case contrast      // Different shapes (creative transitions)
    }

    public init(
        id: UUID = UUID(),
        trackId: Int64,
        overallScore: Float,
        correlationScore: Float,
        complementScore: Float,
        shapeScore: Float,
        matchType: MatchType,
        bestTransitionPoint: Int,
        explanation: String
    ) {
        self.id = id
        self.trackId = trackId
        self.overallScore = overallScore
        self.correlationScore = correlationScore
        self.complementScore = complementScore
        self.shapeScore = shapeScore
        self.matchType = matchType
        self.bestTransitionPoint = bestTransitionPoint
        self.explanation = explanation
    }
}

/// Energy curve shape descriptor
public struct EnergyCurveShape: Codable, Sendable {
    public let curve: [Float]           // Normalized 0-1, typically 100 points
    public let peakPosition: Float      // 0-1, where main peak occurs
    public let peakValue: Float         // 0-1
    public let avgEnergy: Float
    public let variance: Float
    public let trend: Trend             // Overall direction
    public let pattern: Pattern         // Shape pattern

    public enum Trend: String, Codable, Sendable {
        case rising      // Energy generally increases
        case falling     // Energy generally decreases
        case flat        // Relatively constant
        case peaked      // Rise then fall
        case valley      // Fall then rise
    }

    public enum Pattern: String, Codable, Sendable {
        case steady      // Minimal variation
        case building    // Gradual increase
        case dropping    // Gradual decrease
        case dynamic     // Lots of variation
        case doubleClimb // Two main peaks
    }

    public init(curve: [Float]) {
        self.curve = curve

        // Calculate peak
        var maxVal: Float = 0
        var maxIdx: vDSP_Length = 0
        vDSP_maxvi(curve, 1, &maxVal, &maxIdx, vDSP_Length(curve.count))

        self.peakPosition = Float(maxIdx) / Float(curve.count)
        self.peakValue = maxVal

        // Calculate average
        var mean: Float = 0
        vDSP_meanv(curve, 1, &mean, vDSP_Length(curve.count))
        self.avgEnergy = mean

        // Calculate variance
        var tempVariance: Float = 0
        for value in curve {
            tempVariance += (value - mean) * (value - mean)
        }
        self.variance = tempVariance / Float(curve.count)

        // Determine trend
        let firstQuarter = Array(curve.prefix(curve.count / 4))
        let lastQuarter = Array(curve.suffix(curve.count / 4))

        var firstMean: Float = 0
        var lastMean: Float = 0
        vDSP_meanv(firstQuarter, 1, &firstMean, vDSP_Length(firstQuarter.count))
        vDSP_meanv(lastQuarter, 1, &lastMean, vDSP_Length(lastQuarter.count))

        let diff = lastMean - firstMean

        if abs(diff) < 0.1 {
            if peakPosition > 0.3 && peakPosition < 0.7 && peakValue > avgEnergy + 0.2 {
                self.trend = .peaked
            } else {
                self.trend = .flat
            }
        } else if diff > 0.2 {
            self.trend = .rising
        } else if diff < -0.2 {
            self.trend = .falling
        } else {
            // Check for valley (low in middle)
            let middleMean = curve[curve.count/3..<curve.count*2/3].reduce(0, +) / Float(curve.count/3)
            if middleMean < firstMean - 0.15 && middleMean < lastMean - 0.15 {
                self.trend = .valley
            } else {
                self.trend = diff > 0 ? .rising : .falling
            }
        }

        // Determine pattern
        if variance < 0.02 {
            self.pattern = .steady
        } else if trend == .rising {
            self.pattern = .building
        } else if trend == .falling {
            self.pattern = .dropping
        } else if variance > 0.1 {
            self.pattern = .dynamic
        } else {
            // Check for double peak
            let peaks = EnergyCurveShape.findPeaks(in: curve)
            if peaks.count >= 2 {
                self.pattern = .doubleClimb
            } else {
                self.pattern = .dynamic
            }
        }
    }

    private static func findPeaks(in curve: [Float], threshold: Float = 0.6) -> [Int] {
        var peaks: [Int] = []

        for i in 2..<(curve.count - 2) {
            if curve[i] > threshold &&
               curve[i] > curve[i-1] && curve[i] > curve[i-2] &&
               curve[i] > curve[i+1] && curve[i] > curve[i+2] {
                peaks.append(i)
            }
        }

        return peaks
    }
}

/// Energy curve matcher for finding compatible tracks
public actor EnergyCurveMatcher {
    private let logger = Logger(label: "com.cartomix.energy-matcher")

    // Standard curve resolution
    private let curveResolution = 100

    public init() {}

    // MARK: - Public API

    /// Find tracks with matching energy curves
    public func findMatches(
        sourceCurve: [Float],
        candidateCurves: [(trackId: Int64, curve: [Float])],
        limit: Int = 20,
        preferredMatchType: EnergyCurveMatch.MatchType? = nil
    ) -> [EnergyCurveMatch] {
        let normalizedSource = normalizeCurve(sourceCurve)
        let sourceShape = EnergyCurveShape(curve: normalizedSource)

        var matches: [EnergyCurveMatch] = []

        for (trackId, curve) in candidateCurves {
            let normalizedCandidate = normalizeCurve(curve)
            let candidateShape = EnergyCurveShape(curve: normalizedCandidate)

            let match = computeMatch(
                source: normalizedSource,
                sourceShape: sourceShape,
                candidate: normalizedCandidate,
                candidateShape: candidateShape,
                trackId: trackId
            )

            matches.append(match)
        }

        // Sort by score
        matches.sort { $0.overallScore > $1.overallScore }

        // Filter by preferred match type if specified
        if let preferred = preferredMatchType {
            let filtered = matches.filter { $0.matchType == preferred }
            if !filtered.isEmpty {
                return Array(filtered.prefix(limit))
            }
        }

        return Array(matches.prefix(limit))
    }

    /// Analyze how well two curves transition at a specific point
    public func analyzeTransition(
        outgoingCurve: [Float],
        incomingCurve: [Float],
        transitionPoint: Float  // 0-1, where in outgoing to start incoming
    ) -> TransitionAnalysisResult {
        let normOut = normalizeCurve(outgoingCurve)
        let normIn = normalizeCurve(incomingCurve)

        let outIdx = Int(transitionPoint * Float(normOut.count))
        let outEnergy = normOut[safe: outIdx] ?? 0.5
        let inEnergy = normIn.first ?? 0.5

        let energyDiff = abs(outEnergy - inEnergy)
        let smoothness = 1.0 - min(energyDiff * 2, 1.0)

        // Check if energy curves align well at transition
        let overlapSize = min(20, normOut.count - outIdx, normIn.count)
        var overlapCorrelation: Float = 0

        if overlapSize > 5 {
            let outSlice = Array(normOut[outIdx..<(outIdx + overlapSize)])
            let inSlice = Array(normIn.prefix(overlapSize))
            overlapCorrelation = computeCorrelation(outSlice, inSlice)
        }

        let overallScore = smoothness * 0.6 + max(0, overlapCorrelation) * 0.4

        var recommendation: String
        if overallScore > 0.8 {
            recommendation = "Excellent transition point - energies align smoothly"
        } else if overallScore > 0.6 {
            recommendation = "Good transition - minor energy adjustment needed"
        } else if overallScore > 0.4 {
            recommendation = "Moderate transition - consider EQ adjustments"
        } else {
            recommendation = "Challenging transition - significant energy difference"
        }

        return TransitionAnalysisResult(
            transitionPoint: transitionPoint,
            outgoingEnergy: outEnergy,
            incomingEnergy: inEnergy,
            energyDifference: energyDiff,
            smoothnessScore: smoothness,
            overlapCorrelation: overlapCorrelation,
            overallScore: overallScore,
            recommendation: recommendation
        )
    }

    /// Find optimal transition point between two curves
    public func findOptimalTransition(
        outgoingCurve: [Float],
        incomingCurve: [Float]
    ) -> (point: Float, score: Float) {
        let normOut = normalizeCurve(outgoingCurve)
        let normIn = normalizeCurve(incomingCurve)

        var bestPoint: Float = 0.7
        var bestScore: Float = 0

        // Test transition points from 50% to 90% of outgoing track
        for percentage in stride(from: 50, through: 90, by: 5) {
            let point = Float(percentage) / 100.0
            let result = analyzeTransitionInternal(
                normOut: normOut,
                normIn: normIn,
                point: point
            )

            if result.score > bestScore {
                bestScore = result.score
                bestPoint = point
            }
        }

        return (bestPoint, bestScore)
    }

    // MARK: - Private Methods

    private func normalizeCurve(_ curve: [Float]) -> [Float] {
        guard !curve.isEmpty else {
            return [Float](repeating: 0.5, count: curveResolution)
        }

        // Resample to standard resolution
        var resampled = [Float](repeating: 0, count: curveResolution)
        let step = Float(curve.count) / Float(curveResolution)

        for i in 0..<curveResolution {
            let srcIdx = Int(Float(i) * step)
            resampled[i] = curve[min(srcIdx, curve.count - 1)]
        }

        // Normalize to 0-1
        var minVal: Float = 0
        var maxVal: Float = 0
        vDSP_minv(resampled, 1, &minVal, vDSP_Length(resampled.count))
        vDSP_maxv(resampled, 1, &maxVal, vDSP_Length(resampled.count))

        let range = maxVal - minVal
        if range > 0.01 {
            resampled = resampled.map { ($0 - minVal) / range }
        }

        return resampled
    }

    private func computeMatch(
        source: [Float],
        sourceShape: EnergyCurveShape,
        candidate: [Float],
        candidateShape: EnergyCurveShape,
        trackId: Int64
    ) -> EnergyCurveMatch {
        // Correlation (parallel match)
        let correlation = computeCorrelation(source, candidate)

        // Complement score (inverse correlation for complementary matches)
        let inverted = candidate.map { 1.0 - $0 }
        let complementCorrelation = computeCorrelation(source, inverted)

        // Shape similarity
        let shapeScore = computeShapeScore(sourceShape, candidateShape)

        // Continuation score (end of source matches start of candidate)
        let continuationScore = computeContinuationScore(source, candidate)

        // Determine match type and score
        let (matchType, overallScore) = determineMatchType(
            correlation: correlation,
            complement: complementCorrelation,
            shape: shapeScore,
            continuation: continuationScore
        )

        // Find best transition point
        let (transitionPoint, _) = findBestTransitionPointInternal(source, candidate)

        // Generate explanation
        let explanation = generateExplanation(
            matchType: matchType,
            sourceShape: sourceShape,
            candidateShape: candidateShape,
            score: overallScore
        )

        return EnergyCurveMatch(
            trackId: trackId,
            overallScore: overallScore,
            correlationScore: max(0, correlation),
            complementScore: max(0, complementCorrelation),
            shapeScore: shapeScore,
            matchType: matchType,
            bestTransitionPoint: Int(transitionPoint * 100),
            explanation: explanation
        )
    }

    private func computeCorrelation(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var meanA: Float = 0
        var meanB: Float = 0
        vDSP_meanv(a, 1, &meanA, vDSP_Length(a.count))
        vDSP_meanv(b, 1, &meanB, vDSP_Length(b.count))

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

        let denom = sqrt(varA) * sqrt(varB)
        return denom > 0 ? covariance / denom : 0
    }

    private func computeShapeScore(
        _ shape1: EnergyCurveShape,
        _ shape2: EnergyCurveShape
    ) -> Float {
        var score: Float = 0

        // Trend similarity
        if shape1.trend == shape2.trend {
            score += 0.3
        } else if (shape1.trend == .rising && shape2.trend == .building) ||
                  (shape1.trend == .falling && shape2.trend == .dropping) {
            score += 0.2
        }

        // Pattern similarity
        if shape1.pattern == shape2.pattern {
            score += 0.3
        }

        // Average energy similarity
        let energyDiff = abs(shape1.avgEnergy - shape2.avgEnergy)
        score += (1.0 - min(energyDiff * 2, 1.0)) * 0.2

        // Peak position similarity
        let peakDiff = abs(shape1.peakPosition - shape2.peakPosition)
        score += (1.0 - peakDiff) * 0.2

        return score
    }

    private func computeContinuationScore(_ source: [Float], _ candidate: [Float]) -> Float {
        // Compare last 10% of source with first 10% of candidate
        let windowSize = max(1, source.count / 10)

        let sourceEnd = Array(source.suffix(windowSize))
        let candidateStart = Array(candidate.prefix(windowSize))

        // Energy level match
        var sourceMean: Float = 0
        var candidateMean: Float = 0
        vDSP_meanv(sourceEnd, 1, &sourceMean, vDSP_Length(sourceEnd.count))
        vDSP_meanv(candidateStart, 1, &candidateMean, vDSP_Length(candidateStart.count))

        let energyMatch = 1.0 - abs(sourceMean - candidateMean)

        // Slope match
        let sourceSlope = (sourceEnd.last ?? 0) - (sourceEnd.first ?? 0)
        let candidateSlope = (candidateStart.last ?? 0) - (candidateStart.first ?? 0)
        let slopeMatch: Float = sourceSlope * candidateSlope > 0 ? 0.8 : 0.4

        return energyMatch * 0.6 + slopeMatch * 0.4
    }

    private func determineMatchType(
        correlation: Float,
        complement: Float,
        shape: Float,
        continuation: Float
    ) -> (EnergyCurveMatch.MatchType, Float) {
        var scores: [(EnergyCurveMatch.MatchType, Float)] = [
            (.parallel, correlation * 0.4 + shape * 0.6),
            (.complementary, complement * 0.5 + (1 - shape) * 0.3 + 0.2),
            (.continuation, continuation),
            (.contrast, (1 - abs(correlation)) * 0.3 + (1 - shape) * 0.4 + 0.3)
        ]

        scores.sort { $0.1 > $1.1 }

        return (scores[0].0, max(0, min(1, scores[0].1)))
    }

    private func findBestTransitionPointInternal(
        _ source: [Float],
        _ candidate: [Float]
    ) -> (Float, Float) {
        var bestPoint: Float = 0.75
        var bestScore: Float = 0

        for i in stride(from: 50, through: 90, by: 5) {
            let point = Float(i) / 100.0
            let idx = Int(point * Float(source.count))

            let sourceEnergy = source[safe: idx] ?? 0.5
            let candidateEnergy = candidate.first ?? 0.5

            let score = 1.0 - abs(sourceEnergy - candidateEnergy)

            if score > bestScore {
                bestScore = score
                bestPoint = point
            }
        }

        return (bestPoint, bestScore)
    }

    private func analyzeTransitionInternal(
        normOut: [Float],
        normIn: [Float],
        point: Float
    ) -> (score: Float, energyDiff: Float) {
        let idx = Int(point * Float(normOut.count))
        let outEnergy = normOut[safe: idx] ?? 0.5
        let inEnergy = normIn.first ?? 0.5

        let energyDiff = abs(outEnergy - inEnergy)
        let score = 1.0 - min(energyDiff * 2, 1.0)

        return (score, energyDiff)
    }

    private func generateExplanation(
        matchType: EnergyCurveMatch.MatchType,
        sourceShape: EnergyCurveShape,
        candidateShape: EnergyCurveShape,
        score: Float
    ) -> String {
        let quality = score > 0.8 ? "Excellent" : (score > 0.6 ? "Good" : "Moderate")

        switch matchType {
        case .parallel:
            return "\(quality) parallel energy - both tracks \(sourceShape.pattern.rawValue)"
        case .complementary:
            return "\(quality) complement - \(sourceShape.trend.rawValue) meets \(candidateShape.trend.rawValue)"
        case .continuation:
            return "\(quality) continuation - seamless energy flow"
        case .contrast:
            return "\(quality) contrast - creative transition opportunity"
        }
    }
}

// MARK: - Supporting Types

public struct TransitionAnalysisResult: Sendable {
    public let transitionPoint: Float
    public let outgoingEnergy: Float
    public let incomingEnergy: Float
    public let energyDifference: Float
    public let smoothnessScore: Float
    public let overlapCorrelation: Float
    public let overallScore: Float
    public let recommendation: String
}
