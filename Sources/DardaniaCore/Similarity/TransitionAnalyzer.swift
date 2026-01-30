// CartoMix - Transition Window Detection
// Detect optimal mix-in and mix-out points for DJ transitions

import Foundation
import Accelerate
import Logging

/// Transition point recommendation
public struct TransitionPoint: Codable, Sendable, Identifiable {
    public let id: UUID
    public let timeSeconds: Double
    public let beatIndex: Int
    public let type: TransitionType
    public let score: Float  // 0-1, higher is better
    public let reason: String
    public let energyLevel: Float
    public let isOnPhrase: Bool

    public enum TransitionType: String, Codable, Sendable {
        case mixIn       // Good point to start mixing in this track
        case mixOut      // Good point to mix out of this track
        case dropEntry   // Entry point for a drop
        case breakdown   // Breakdown section (good for long blends)
    }

    public init(
        id: UUID = UUID(),
        timeSeconds: Double,
        beatIndex: Int,
        type: TransitionType,
        score: Float,
        reason: String,
        energyLevel: Float,
        isOnPhrase: Bool
    ) {
        self.id = id
        self.timeSeconds = timeSeconds
        self.beatIndex = beatIndex
        self.type = type
        self.score = score
        self.reason = reason
        self.energyLevel = energyLevel
        self.isOnPhrase = isOnPhrase
    }
}

/// Transition window representing a good range for mixing
public struct TransitionWindow: Codable, Sendable, Identifiable {
    public let id: UUID
    public let startTime: Double
    public let endTime: Double
    public let startBeat: Int
    public let endBeat: Int
    public let type: TransitionWindowType
    public let score: Float
    public let characteristics: WindowCharacteristics

    public enum TransitionWindowType: String, Codable, Sendable {
        case intro          // Track intro (good for mixing in)
        case outro          // Track outro (good for mixing out)
        case breakdown      // Energy dip (good for long transitions)
        case buildUp        // Energy rise (can mix during build)
        case sustain        // Steady energy (safe mixing zone)
    }

    public struct WindowCharacteristics: Codable, Sendable {
        public let avgEnergy: Float
        public let energyVariance: Float
        public let hasVocals: Bool
        public let instrumentalRatio: Float
        public let phraseAlignment: Bool  // Starts/ends on phrase boundary

        public init(
            avgEnergy: Float,
            energyVariance: Float,
            hasVocals: Bool,
            instrumentalRatio: Float,
            phraseAlignment: Bool
        ) {
            self.avgEnergy = avgEnergy
            self.energyVariance = energyVariance
            self.hasVocals = hasVocals
            self.instrumentalRatio = instrumentalRatio
            self.phraseAlignment = phraseAlignment
        }
    }

    public var duration: Double {
        endTime - startTime
    }

    public init(
        id: UUID = UUID(),
        startTime: Double,
        endTime: Double,
        startBeat: Int,
        endBeat: Int,
        type: TransitionWindowType,
        score: Float,
        characteristics: WindowCharacteristics
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.startBeat = startBeat
        self.endBeat = endBeat
        self.type = type
        self.score = score
        self.characteristics = characteristics
    }
}

/// Complete transition analysis for a track
public struct TransitionAnalysis: Codable, Sendable {
    public let trackId: Int64
    public let mixInPoints: [TransitionPoint]
    public let mixOutPoints: [TransitionPoint]
    public let transitionWindows: [TransitionWindow]
    public let energyCurve: [Float]
    public let phraseBoundaries: [Int]  // Beat indices
    public let recommendedMixInBeat: Int
    public let recommendedMixOutBeat: Int
    public let analysisVersion: Int

    public init(
        trackId: Int64,
        mixInPoints: [TransitionPoint],
        mixOutPoints: [TransitionPoint],
        transitionWindows: [TransitionWindow],
        energyCurve: [Float],
        phraseBoundaries: [Int],
        recommendedMixInBeat: Int,
        recommendedMixOutBeat: Int
    ) {
        self.trackId = trackId
        self.mixInPoints = mixInPoints
        self.mixOutPoints = mixOutPoints
        self.transitionWindows = transitionWindows
        self.energyCurve = energyCurve
        self.phraseBoundaries = phraseBoundaries
        self.recommendedMixInBeat = recommendedMixInBeat
        self.recommendedMixOutBeat = recommendedMixOutBeat
        self.analysisVersion = 1
    }
}

/// Analyzer for detecting transition points and windows
public actor TransitionAnalyzer {
    private let logger = Logger(label: "com.cartomix.transitions")

    // Analysis parameters
    private let phraseLength = 16  // Beats per phrase (typical for electronic music)
    private let minTransitionWindow = 8.0  // Minimum window duration in seconds
    private let energyWindowSize = 0.5  // Energy calculation window in seconds

    public init() {}

    // MARK: - Main Analysis

    /// Analyze a track for transition opportunities
    public func analyzeTransitions(
        audioData: [Float],
        sampleRate: Double,
        bpm: Double,
        sections: [TrackSection]
    ) async -> TransitionAnalysis {
        let duration = Double(audioData.count) / sampleRate
        let beatsPerSecond = bpm / 60.0
        let totalBeats = Int(duration * beatsPerSecond)

        // Compute energy curve
        let energyCurve = computeEnergyCurve(
            audioData: audioData,
            sampleRate: sampleRate,
            windowCount: totalBeats
        )

        // Detect phrase boundaries
        let phraseBoundaries = detectPhraseBoundaries(
            energyCurve: energyCurve,
            totalBeats: totalBeats
        )

        // Find transition windows
        let windows = findTransitionWindows(
            energyCurve: energyCurve,
            sections: sections,
            bpm: bpm,
            phraseBoundaries: phraseBoundaries
        )

        // Find specific transition points
        let mixInPoints = findMixInPoints(
            energyCurve: energyCurve,
            windows: windows,
            bpm: bpm,
            phraseBoundaries: phraseBoundaries
        )

        let mixOutPoints = findMixOutPoints(
            energyCurve: energyCurve,
            windows: windows,
            bpm: bpm,
            phraseBoundaries: phraseBoundaries,
            duration: duration
        )

        // Determine best overall recommendations
        let recommendedMixIn = mixInPoints.first?.beatIndex ?? 0
        let recommendedMixOut = mixOutPoints.last?.beatIndex ?? totalBeats

        logger.info("Transition analysis complete: \(mixInPoints.count) mix-in points, \(mixOutPoints.count) mix-out points")

        return TransitionAnalysis(
            trackId: 0,
            mixInPoints: mixInPoints,
            mixOutPoints: mixOutPoints,
            transitionWindows: windows,
            energyCurve: energyCurve,
            phraseBoundaries: phraseBoundaries,
            recommendedMixInBeat: recommendedMixIn,
            recommendedMixOutBeat: recommendedMixOut
        )
    }

    // MARK: - Energy Analysis

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

            var rms: Float = 0
            vDSP_measqv(windowData, 1, &rms, vDSP_Length(windowData.count))
            curve[i] = sqrt(rms)
        }

        // Normalize
        let maxEnergy = curve.max() ?? 1.0
        if maxEnergy > 0 {
            curve = curve.map { $0 / maxEnergy }
        }

        return curve
    }

    // MARK: - Phrase Detection

    private func detectPhraseBoundaries(
        energyCurve: [Float],
        totalBeats: Int
    ) -> [Int] {
        var boundaries: [Int] = [0]

        // Add phrase boundaries at regular intervals
        var beat = phraseLength
        while beat < totalBeats {
            boundaries.append(beat)
            beat += phraseLength
        }

        // Also detect energy-based phrase boundaries
        let threshold: Float = 0.15

        for i in 1..<(energyCurve.count - 1) {
            let diff = abs(energyCurve[i] - energyCurve[i - 1])

            // Check if this is a significant energy change near a phrase boundary
            if diff > threshold {
                let nearestPhrase = (i / phraseLength) * phraseLength
                if !boundaries.contains(nearestPhrase) && nearestPhrase > 0 {
                    boundaries.append(nearestPhrase)
                }
            }
        }

        return boundaries.sorted()
    }

    // MARK: - Transition Windows

    private func findTransitionWindows(
        energyCurve: [Float],
        sections: [TrackSection],
        bpm: Double,
        phraseBoundaries: [Int]
    ) -> [TransitionWindow] {
        var windows: [TransitionWindow] = []
        let secondsPerBeat = 60.0 / bpm

        // Use sections if available
        for section in sections {
            let windowType: TransitionWindow.TransitionWindowType

            switch section.type {
            case .intro:
                windowType = .intro
            case .outro:
                windowType = .outro
            case .breakdown:
                windowType = .breakdown
            case .build:
                windowType = .buildUp
            default:
                windowType = .sustain
            }

            let startBeat = Int(section.startTime / secondsPerBeat)
            let endBeat = Int(section.endTime / secondsPerBeat)

            // Calculate characteristics
            let avgEnergy = calculateAverageEnergy(
                energyCurve: energyCurve,
                startBeat: startBeat,
                endBeat: endBeat
            )

            let variance = calculateEnergyVariance(
                energyCurve: energyCurve,
                startBeat: startBeat,
                endBeat: endBeat
            )

            let isOnPhrase = phraseBoundaries.contains(startBeat) ||
                            phraseBoundaries.contains { abs($0 - startBeat) <= 2 }

            let score = calculateWindowScore(
                type: windowType,
                avgEnergy: avgEnergy,
                variance: variance,
                duration: section.duration,
                isOnPhrase: isOnPhrase
            )

            let window = TransitionWindow(
                startTime: section.startTime,
                endTime: section.endTime,
                startBeat: startBeat,
                endBeat: endBeat,
                type: windowType,
                score: score,
                characteristics: TransitionWindow.WindowCharacteristics(
                    avgEnergy: avgEnergy,
                    energyVariance: variance,
                    hasVocals: false,  // Would need vocal detection
                    instrumentalRatio: 0.8,
                    phraseAlignment: isOnPhrase
                )
            )

            windows.append(window)
        }

        // If no sections, create windows based on energy analysis
        if windows.isEmpty {
            windows = createEnergyBasedWindows(
                energyCurve: energyCurve,
                bpm: bpm,
                phraseBoundaries: phraseBoundaries
            )
        }

        return windows.sorted { $0.score > $1.score }
    }

    private func createEnergyBasedWindows(
        energyCurve: [Float],
        bpm: Double,
        phraseBoundaries: [Int]
    ) -> [TransitionWindow] {
        var windows: [TransitionWindow] = []
        let secondsPerBeat = 60.0 / bpm

        // Find low-energy regions (good for mixing)
        var inLowRegion = false
        var regionStart = 0

        for i in 0..<energyCurve.count {
            let isLow = energyCurve[i] < 0.4

            if isLow && !inLowRegion {
                regionStart = i
                inLowRegion = true
            } else if !isLow && inLowRegion {
                let duration = Double(i - regionStart) * secondsPerBeat

                if duration >= minTransitionWindow {
                    let window = TransitionWindow(
                        startTime: Double(regionStart) * secondsPerBeat,
                        endTime: Double(i) * secondsPerBeat,
                        startBeat: regionStart,
                        endBeat: i,
                        type: .breakdown,
                        score: 0.7,
                        characteristics: TransitionWindow.WindowCharacteristics(
                            avgEnergy: 0.3,
                            energyVariance: 0.1,
                            hasVocals: false,
                            instrumentalRatio: 0.9,
                            phraseAlignment: true
                        )
                    )
                    windows.append(window)
                }
                inLowRegion = false
            }
        }

        return windows
    }

    // MARK: - Mix Points

    private func findMixInPoints(
        energyCurve: [Float],
        windows: [TransitionWindow],
        bpm: Double,
        phraseBoundaries: [Int]
    ) -> [TransitionPoint] {
        var points: [TransitionPoint] = []
        let secondsPerBeat = 60.0 / bpm

        // First phrase boundary is always a good mix-in point
        if let firstPhrase = phraseBoundaries.first(where: { $0 > 0 }) {
            points.append(TransitionPoint(
                timeSeconds: Double(firstPhrase) * secondsPerBeat,
                beatIndex: firstPhrase,
                type: .mixIn,
                score: 0.9,
                reason: "Track intro on phrase boundary",
                energyLevel: energyCurve[safe: firstPhrase] ?? 0.5,
                isOnPhrase: true
            ))
        }

        // Add points at intro/breakdown windows
        for window in windows where window.type == .intro || window.type == .breakdown {
            let beatIndex = window.startBeat
            let nearestPhrase = findNearestPhraseBoundary(beat: beatIndex, boundaries: phraseBoundaries)

            points.append(TransitionPoint(
                timeSeconds: window.startTime,
                beatIndex: beatIndex,
                type: .mixIn,
                score: window.score,
                reason: window.type == .intro ? "Track intro" : "Breakdown section",
                energyLevel: window.characteristics.avgEnergy,
                isOnPhrase: beatIndex == nearestPhrase
            ))
        }

        // Sort by score and time
        return points.sorted { $0.score > $1.score }
    }

    private func findMixOutPoints(
        energyCurve: [Float],
        windows: [TransitionWindow],
        bpm: Double,
        phraseBoundaries: [Int],
        duration: Double
    ) -> [TransitionPoint] {
        var points: [TransitionPoint] = []
        let secondsPerBeat = 60.0 / bpm
        let totalBeats = Int(duration / secondsPerBeat)

        // Last phrase boundary before outro is a good mix-out point
        if let lastPhrase = phraseBoundaries.last(where: { $0 < totalBeats - phraseLength }) {
            points.append(TransitionPoint(
                timeSeconds: Double(lastPhrase) * secondsPerBeat,
                beatIndex: lastPhrase,
                type: .mixOut,
                score: 0.9,
                reason: "Phrase boundary before outro",
                energyLevel: energyCurve[safe: lastPhrase] ?? 0.5,
                isOnPhrase: true
            ))
        }

        // Add points at outro/breakdown windows
        for window in windows where window.type == .outro || window.type == .breakdown {
            let beatIndex = window.startBeat
            let nearestPhrase = findNearestPhraseBoundary(beat: beatIndex, boundaries: phraseBoundaries)

            points.append(TransitionPoint(
                timeSeconds: window.startTime,
                beatIndex: beatIndex,
                type: .mixOut,
                score: window.score,
                reason: window.type == .outro ? "Track outro" : "Breakdown section",
                energyLevel: window.characteristics.avgEnergy,
                isOnPhrase: beatIndex == nearestPhrase
            ))
        }

        // Sort by time (later points first for mix-out)
        return points.sorted { $0.timeSeconds > $1.timeSeconds }
    }

    // MARK: - Helpers

    private func calculateAverageEnergy(
        energyCurve: [Float],
        startBeat: Int,
        endBeat: Int
    ) -> Float {
        let start = max(0, startBeat)
        let end = min(energyCurve.count, endBeat)

        guard end > start else { return 0 }

        let slice = Array(energyCurve[start..<end])
        var mean: Float = 0
        vDSP_meanv(slice, 1, &mean, vDSP_Length(slice.count))

        return mean
    }

    private func calculateEnergyVariance(
        energyCurve: [Float],
        startBeat: Int,
        endBeat: Int
    ) -> Float {
        let start = max(0, startBeat)
        let end = min(energyCurve.count, endBeat)

        guard end > start else { return 0 }

        let slice = Array(energyCurve[start..<end])
        var mean: Float = 0
        var variance: Float = 0

        vDSP_meanv(slice, 1, &mean, vDSP_Length(slice.count))

        for value in slice {
            variance += (value - mean) * (value - mean)
        }

        return variance / Float(slice.count)
    }

    private func calculateWindowScore(
        type: TransitionWindow.TransitionWindowType,
        avgEnergy: Float,
        variance: Float,
        duration: Double,
        isOnPhrase: Bool
    ) -> Float {
        var score: Float = 0.5

        // Prefer low-energy regions for mixing
        if type == .breakdown || type == .intro || type == .outro {
            score += (1.0 - avgEnergy) * 0.2
        }

        // Prefer low variance (consistent energy)
        score += (1.0 - min(variance * 10, 1.0)) * 0.15

        // Prefer longer windows
        let durationBonus = Float(min(duration / 32.0, 1.0)) * 0.15
        score += durationBonus

        // Phrase alignment bonus
        if isOnPhrase {
            score += 0.1
        }

        return min(score, 1.0)
    }

    private func findNearestPhraseBoundary(beat: Int, boundaries: [Int]) -> Int {
        return boundaries.min(by: { abs($0 - beat) < abs($1 - beat) }) ?? beat
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
