// CartoMix - AnalyzerSwift Compatibility Layer
// Provides types and interfaces for audio analysis

import Foundation
import AVFoundation
import Accelerate

// MARK: - Core Analyzer

/// Main analyzer class for audio processing
public final class Analyzer: @unchecked Sendable {
    public init() {}

    /// Analyze an audio file
    public func analyze(
        path: String,
        progress: @escaping (AnalysisStage) -> Void
    ) async throws -> TrackAnalysisResult {
        progress(.decoding)

        // Load audio file
        let url = URL(fileURLWithPath: path)
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(audioFile.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AnalyzerError.bufferCreationFailed
        }

        try audioFile.read(into: buffer)

        let duration = Double(frameCount) / sampleRate

        // Extract samples
        guard let channelData = buffer.floatChannelData else {
            throw AnalyzerError.noAudioData
        }

        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(frameCount)))

        // Analyze beatgrid
        progress(.beatgrid)
        let (bpm, beatgridConfidence) = try await analyzeBeatgrid(samples: samples, sampleRate: sampleRate)

        // Analyze key
        progress(.key)
        let keyResult = try await analyzeKey(samples: samples, sampleRate: sampleRate)

        // Analyze energy
        progress(.energy)
        let globalEnergy = computeGlobalEnergy(samples: samples)

        // Analyze loudness
        progress(.loudness)
        let loudness = computeLoudness(samples: samples)

        // Detect sections
        progress(.sections)
        let sections = try await detectSections(samples: samples, sampleRate: sampleRate, duration: duration)

        // Generate cue points
        progress(.cues)
        let cues = generateCuePoints(sections: sections, bpm: bpm)

        // Generate waveform
        progress(.waveform)
        let waveform = generateWaveformSummary(samples: samples, targetPoints: 2000)

        // Generate embedding
        progress(.embedding)
        let embedding = generateOpenL3Embedding(samples: samples, sampleRate: sampleRate)

        progress(.complete)

        return TrackAnalysisResult(
            duration: duration,
            bpm: bpm,
            beatgridConfidence: beatgridConfidence,
            key: keyResult,
            globalEnergy: globalEnergy,
            loudness: loudness,
            sections: sections,
            cues: cues,
            waveformSummary: waveform,
            openL3Embedding: embedding,
            soundClassification: nil
        )
    }

    // MARK: - Beatgrid Analysis

    private func analyzeBeatgrid(samples: [Float], sampleRate: Double) async throws -> (Double, Float) {
        // Onset detection using energy flux
        let hopSize = 512
        let windowSize = 1024

        var onsetStrengths: [Float] = []
        var previousEnergy: Float = 0

        for i in stride(from: 0, to: samples.count - windowSize, by: hopSize) {
            let window = Array(samples[i..<(i + windowSize)])
            var energy: Float = 0
            vDSP_measqv(window, 1, &energy, vDSP_Length(windowSize))

            let flux = max(0, energy - previousEnergy)
            onsetStrengths.append(flux)
            previousEnergy = energy
        }

        // Autocorrelation for tempo estimation
        let minBPM: Double = 60
        let maxBPM: Double = 200
        let framesPerSecond = sampleRate / Double(hopSize)

        let minLag = Int(60.0 / maxBPM * framesPerSecond)
        let maxLag = Int(60.0 / minBPM * framesPerSecond)

        var bestBPM: Double = 120
        var bestCorrelation: Float = 0

        for lag in minLag...min(maxLag, onsetStrengths.count / 2) {
            var correlation: Float = 0
            let count = min(onsetStrengths.count - lag, 1000)

            for i in 0..<count {
                correlation += onsetStrengths[i] * onsetStrengths[i + lag]
            }

            if correlation > bestCorrelation {
                bestCorrelation = correlation
                bestBPM = 60.0 / (Double(lag) / framesPerSecond)
            }
        }

        // Normalize confidence
        let confidence = min(1.0, bestCorrelation / (Float(onsetStrengths.count) * 0.01))

        return (bestBPM, confidence)
    }

    // MARK: - Key Analysis

    private func analyzeKey(samples: [Float], sampleRate: Double) async throws -> KeyResult {
        // Krumhansl-Schmuckler key-finding algorithm (simplified)
        let majorProfile: [Float] = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
        let minorProfile: [Float] = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]

        // Compute chroma features (simplified)
        let chroma = computeChroma(samples: samples, sampleRate: sampleRate)

        var bestKey = 0
        var bestMode = "major"
        var bestCorrelation: Float = -1

        for key in 0..<12 {
            // Rotate profiles
            var majorRotated = [Float](repeating: 0, count: 12)
            var minorRotated = [Float](repeating: 0, count: 12)

            for i in 0..<12 {
                majorRotated[i] = majorProfile[(i + key) % 12]
                minorRotated[i] = minorProfile[(i + key) % 12]
            }

            // Compute correlations
            let majorCorr = correlate(chroma, majorRotated)
            let minorCorr = correlate(chroma, minorRotated)

            if majorCorr > bestCorrelation {
                bestCorrelation = majorCorr
                bestKey = key
                bestMode = "major"
            }
            if minorCorr > bestCorrelation {
                bestCorrelation = minorCorr
                bestKey = key
                bestMode = "minor"
            }
        }

        let camelotKey = keyToCamelot(pitchClass: bestKey, isMinor: bestMode == "minor")

        return KeyResult(
            camelot: camelotKey,
            confidence: bestCorrelation
        )
    }

    private func computeChroma(samples: [Float], sampleRate: Double) -> [Float] {
        var chroma = [Float](repeating: 0, count: 12)

        // Simplified chroma computation using FFT magnitude bins
        let fftSize = 4096
        let hop = fftSize / 2
        var frameCount = 0

        for start in stride(from: 0, to: samples.count - fftSize, by: hop) {
            let frame = Array(samples[start..<(start + fftSize)])

            // Simplified: use magnitude of low frequencies
            for i in 0..<min(fftSize / 2, 500) {
                let frequency = Double(i) * sampleRate / Double(fftSize)
                if frequency > 20 && frequency < 5000 {
                    let midiNote = 12 * log2(frequency / 440.0) + 69
                    let pitchClass = Int(midiNote.rounded()) % 12
                    if pitchClass >= 0 && pitchClass < 12 {
                        chroma[pitchClass] += abs(frame[i])
                    }
                }
            }
            frameCount += 1
        }

        // Normalize
        let sum = chroma.reduce(0, +)
        if sum > 0 {
            chroma = chroma.map { $0 / sum }
        }

        return chroma
    }

    private func correlate(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        var result: Float = 0
        vDSP_dotpr(a, 1, b, 1, &result, vDSP_Length(a.count))
        return result
    }

    private func keyToCamelot(pitchClass: Int, isMinor: Bool) -> String {
        let majorCamelot = ["8B", "3B", "10B", "5B", "12B", "7B", "2B", "9B", "4B", "11B", "6B", "1B"]
        let minorCamelot = ["5A", "12A", "7A", "2A", "9A", "4A", "11A", "6A", "1A", "8A", "3A", "10A"]

        return isMinor ? minorCamelot[pitchClass] : majorCamelot[pitchClass]
    }

    // MARK: - Energy Analysis

    private func computeGlobalEnergy(samples: [Float]) -> Float {
        var energy: Float = 0
        vDSP_measqv(samples, 1, &energy, vDSP_Length(samples.count))
        return sqrt(energy / Float(samples.count))
    }

    // MARK: - Loudness Analysis

    private func computeLoudness(samples: [Float]) -> LoudnessResult {
        // EBU R128 loudness estimation (simplified)
        var sumSquared: Float = 0
        vDSP_svesq(samples, 1, &sumSquared, vDSP_Length(samples.count))

        let meanSquared = sumSquared / Float(samples.count)
        let rms = sqrt(meanSquared)

        // Convert to LUFS (approximate)
        let lufs = 20 * log10(max(rms, 1e-10)) - 10

        // Find true peak
        var truePeak: Float = 0
        vDSP_maxmgv(samples, 1, &truePeak, vDSP_Length(samples.count))
        let truePeakDB = 20 * log10(max(truePeak, 1e-10))

        return LoudnessResult(
            integratedLoudness: lufs,
            truePeak: truePeakDB,
            loudnessRange: 8.0 // Typical value
        )
    }

    // MARK: - Section Detection

    private func detectSections(samples: [Float], sampleRate: Double, duration: Double) async throws -> [SectionResult] {
        var sections: [SectionResult] = []

        // Simple energy-based section detection
        let windowSeconds: Double = 4.0
        let windowSamples = Int(windowSeconds * sampleRate)
        var energies: [Float] = []

        for start in stride(from: 0, to: samples.count, by: windowSamples) {
            let end = min(start + windowSamples, samples.count)
            let window = Array(samples[start..<end])
            var energy: Float = 0
            vDSP_measqv(window, 1, &energy, vDSP_Length(window.count))
            energies.append(sqrt(energy / Float(window.count)))
        }

        // Normalize energies
        let maxEnergy = energies.max() ?? 1.0
        let normalizedEnergies = energies.map { $0 / maxEnergy }

        // Classify sections based on energy
        let introEnd = min(4, normalizedEnergies.count)
        let outroStart = max(0, normalizedEnergies.count - 4)

        // Intro
        sections.append(SectionResult(
            type: .intro,
            startTime: 0,
            endTime: Double(introEnd) * windowSeconds,
            confidence: 0.8
        ))

        // Main sections based on energy
        var i = introEnd
        while i < outroStart {
            let energy = normalizedEnergies[i]
            let sectionType: SectionType

            if energy > 0.7 {
                sectionType = .drop
            } else if energy > 0.4 {
                sectionType = .verse
            } else {
                sectionType = .breakdown
            }

            let startTime = Double(i) * windowSeconds
            var endIndex = i + 1

            // Extend section while similar energy
            while endIndex < outroStart {
                let nextEnergy = normalizedEnergies[endIndex]
                let energyDiff = abs(nextEnergy - energy)
                if energyDiff > 0.3 {
                    break
                }
                endIndex += 1
            }

            sections.append(SectionResult(
                type: sectionType,
                startTime: startTime,
                endTime: Double(endIndex) * windowSeconds,
                confidence: 0.7
            ))

            i = endIndex
        }

        // Outro
        if outroStart < normalizedEnergies.count {
            sections.append(SectionResult(
                type: .outro,
                startTime: Double(outroStart) * windowSeconds,
                endTime: duration,
                confidence: 0.8
            ))
        }

        return sections
    }

    // MARK: - Cue Point Generation

    private func generateCuePoints(sections: [SectionResult], bpm: Double) -> [CueResult] {
        var cues: [CueResult] = []

        for (index, section) in sections.enumerated() {
            let beatIndex = Int(section.startTime * bpm / 60.0)

            let cueType: CueType
            let label: String

            switch section.type {
            case .intro:
                cueType = .introStart
                label = "Intro"
            case .drop:
                cueType = .drop
                label = "Drop \(index)"
            case .breakdown:
                cueType = .breakdown
                label = "Breakdown"
            case .build:
                cueType = .build
                label = "Build"
            case .verse:
                cueType = .marker
                label = "Verse"
            case .outro:
                cueType = .outroStart
                label = "Outro"
            }

            cues.append(CueResult(
                type: cueType,
                time: section.startTime,
                beatIndex: beatIndex,
                label: label
            ))
        }

        return cues
    }

    // MARK: - Waveform Generation

    private func generateWaveformSummary(samples: [Float], targetPoints: Int) -> [Float] {
        let samplesPerPoint = max(1, samples.count / targetPoints)
        var summary: [Float] = []

        for i in stride(from: 0, to: samples.count, by: samplesPerPoint) {
            let end = min(i + samplesPerPoint, samples.count)
            let window = Array(samples[i..<end])

            var maxVal: Float = 0
            vDSP_maxmgv(window, 1, &maxVal, vDSP_Length(window.count))
            summary.append(maxVal)
        }

        return summary
    }

    // MARK: - OpenL3 Embedding

    private func generateOpenL3Embedding(samples: [Float], sampleRate: Double) -> OpenL3EmbeddingResult {
        // Generate pseudo-embedding based on audio features
        var embedding = [Float](repeating: 0, count: 512)

        // Compute spectral features at different positions
        let positions = [0.1, 0.25, 0.5, 0.75, 0.9]

        for (posIndex, pos) in positions.enumerated() {
            let startSample = Int(pos * Double(samples.count))
            let windowSize = min(44100, samples.count - startSample)
            let window = Array(samples[startSample..<(startSample + windowSize)])

            // RMS energy
            var energy: Float = 0
            vDSP_measqv(window, 1, &energy, vDSP_Length(windowSize))

            // Zero crossing rate
            var zcr: Float = 0
            for i in 1..<windowSize {
                if (window[i] >= 0) != (window[i-1] >= 0) {
                    zcr += 1
                }
            }
            zcr /= Float(windowSize)

            // Fill embedding dimensions
            let baseIndex = posIndex * 100
            for i in 0..<100 {
                let phase = Float(i) / 100.0 * Float.pi * 2
                embedding[baseIndex + i] = sin(phase * sqrt(energy) * 10) * 0.5 + cos(phase * zcr * 100) * 0.5
            }
        }

        // Normalize embedding
        var norm: Float = 0
        vDSP_svesq(embedding, 1, &norm, vDSP_Length(512))
        norm = sqrt(norm)

        if norm > 0 {
            var scale = 1.0 / norm
            vDSP_vsmul(embedding, 1, &scale, &embedding, 1, vDSP_Length(512))
        }

        return OpenL3EmbeddingResult(vector: embedding)
    }
}

// MARK: - Analysis Stages

public enum AnalysisStage: Sendable {
    case decoding
    case beatgrid
    case key
    case energy
    case loudness
    case sections
    case cues
    case waveform
    case embedding
    case openL3Embedding
    case soundClassification
    case complete
}

// MARK: - Result Types

public struct TrackAnalysisResult: Sendable {
    public let duration: Double
    public let bpm: Double
    public let beatgridConfidence: Float
    public let key: KeyResult
    public let globalEnergy: Float
    public let loudness: LoudnessResult
    public let sections: [SectionResult]
    public let cues: [CueResult]
    public let waveformSummary: [Float]
    public let openL3Embedding: OpenL3EmbeddingResult?
    public let soundClassification: SoundClassificationResult?
}

public struct KeyResult: Sendable {
    public let camelot: String
    public let confidence: Float
}

public struct LoudnessResult: Sendable {
    public let integratedLoudness: Float
    public let truePeak: Float
    public let loudnessRange: Float
}

public struct SectionResult: Sendable {
    public let type: SectionType
    public let startTime: Double
    public let endTime: Double
    public let confidence: Float
}

public struct CueResult: Sendable {
    public let type: CueType
    public let time: Double
    public let beatIndex: Int
    public let label: String
}

public struct OpenL3EmbeddingResult: Sendable {
    public let vector: [Float]
}

public struct SoundClassificationResult: Sendable {
    public let primaryContext: String
    public let confidence: Float
}

// MARK: - Enums

public enum SectionType: String, Sendable {
    case intro
    case verse
    case build
    case drop
    case breakdown
    case outro
}

public enum CueType: String, Sendable {
    case drop
    case build
    case breakdown
    case introStart
    case introEnd
    case outroStart
    case outroEnd
    case load
    case marker
}

// MARK: - Errors

public enum AnalyzerError: Error {
    case bufferCreationFailed
    case noAudioData
    case analysisTimeout
}
