// CartoMix - Apple SoundAnalysis Integration
// Context detection and QA flag generation using Apple's built-in classifier

import Foundation
import SoundAnalysis
import AVFoundation
import Logging

/// Sound context classification result
public struct SoundContextResult: Sendable {
    public let primaryContext: String
    public let confidence: Double
    public let allClassifications: [String: Double]
    public let qaFlags: [QAFlag]

    public init(
        primaryContext: String,
        confidence: Double,
        allClassifications: [String: Double],
        qaFlags: [QAFlag]
    ) {
        self.primaryContext = primaryContext
        self.confidence = confidence
        self.allClassifications = allClassifications
        self.qaFlags = qaFlags
    }
}

/// DJ-relevant sound categories mapped from Apple's 300+ labels
public enum DJSoundCategory: String, CaseIterable, Sendable {
    case music
    case speech
    case noise
    case silence
    case crowd
    case applause
    case unknown

    /// Map Apple's classifier labels to DJ categories
    public static func fromAppleLabel(_ label: String) -> DJSoundCategory {
        let lower = label.lowercased()

        // Music categories
        if lower.contains("music") ||
           lower.contains("instrument") ||
           lower.contains("drum") ||
           lower.contains("guitar") ||
           lower.contains("bass") ||
           lower.contains("piano") ||
           lower.contains("synth") ||
           lower.contains("electronic") ||
           lower.contains("hip_hop") ||
           lower.contains("house") ||
           lower.contains("techno") ||
           lower.contains("dance") ||
           lower.contains("beat") {
            return .music
        }

        // Speech categories
        if lower.contains("speech") ||
           lower.contains("voice") ||
           lower.contains("talking") ||
           lower.contains("conversation") ||
           lower.contains("narration") {
            return .speech
        }

        // Singing (could be music or speech - we'll classify as music)
        if lower.contains("singing") ||
           lower.contains("vocal") ||
           lower.contains("choir") {
            return .music
        }

        // Crowd/audience
        if lower.contains("crowd") ||
           lower.contains("audience") ||
           lower.contains("cheer") {
            return .crowd
        }

        // Applause
        if lower.contains("applause") ||
           lower.contains("clapping") {
            return .applause
        }

        // Noise categories
        if lower.contains("noise") ||
           lower.contains("static") ||
           lower.contains("hum") ||
           lower.contains("buzz") ||
           lower.contains("click") ||
           lower.contains("pop") ||
           lower.contains("distortion") {
            return .noise
        }

        // Silence
        if lower.contains("silence") ||
           lower.contains("quiet") {
            return .silence
        }

        return .unknown
    }
}

/// Sound Analysis Service using Apple's SoundAnalysis framework
public actor SoundAnalysisService {
    private let logger = Logger(label: "com.cartomix.soundanalysis")

    /// Minimum confidence threshold for primary classification
    private let confidenceThreshold: Double = 0.5

    public init() {}

    // MARK: - Analysis

    /// Analyze audio file for sound context and generate QA flags
    public func analyzeAudioFile(at url: URL) async throws -> SoundContextResult {
        logger.info("Analyzing sound context for: \(url.lastPathComponent)")

        // Load audio file
        let audioFile = try AVAudioFile(forReading: url)
        let format = audioFile.processingFormat

        // Create analyzer and observer
        let analyzer = SNAudioStreamAnalyzer(format: format)
        let observer = SoundObserver()

        // Create classification request with Apple's built-in classifier
        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        try analyzer.add(request, withObserver: observer)

        // Process audio in chunks
        let bufferSize: AVAudioFrameCount = 8192
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else {
            throw SoundAnalysisError.invalidAudioFormat
        }

        // Read and analyze audio
        while audioFile.framePosition < audioFile.length {
            try audioFile.read(into: buffer)
            analyzer.analyze(buffer, atAudioFramePosition: audioFile.framePosition - AVAudioFramePosition(buffer.frameLength))
        }

        // Signal completion
        analyzer.completeAnalysis()

        // Wait for processing
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Get results
        let results = observer.getResults()

        // Process results
        return processResults(results)
    }

    /// Analyze audio samples directly
    public func analyzeAudioSamples(_ samples: [Float], sampleRate: Double) async throws -> SoundContextResult {
        logger.info("Analyzing \(samples.count) samples for sound context")

        // Create audio format
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            throw SoundAnalysisError.invalidAudioFormat
        }

        let analyzer = SNAudioStreamAnalyzer(format: format)
        let observer = SoundObserver()

        // Create classification request
        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        try analyzer.add(request, withObserver: observer)

        // Process audio in chunks
        let bufferSize = 8192
        var position = 0

        while position < samples.count {
            let chunkEnd = min(position + bufferSize, samples.count)
            let chunk = Array(samples[position..<chunkEnd])

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(chunk.count)) else {
                break
            }

            buffer.frameLength = AVAudioFrameCount(chunk.count)
            if let channelData = buffer.floatChannelData?[0] {
                for i in 0..<chunk.count {
                    channelData[i] = chunk[i]
                }
            }

            analyzer.analyze(buffer, atAudioFramePosition: AVAudioFramePosition(position))
            position += bufferSize
        }

        analyzer.completeAnalysis()

        try await Task.sleep(nanoseconds: 200_000_000)

        return processResults(observer.getResults())
    }

    // MARK: - Result Processing

    private func processResults(_ results: [(time: Double, classifications: [String: Double])]) -> SoundContextResult {
        guard !results.isEmpty else {
            return SoundContextResult(
                primaryContext: "unknown",
                confidence: 0,
                allClassifications: [:],
                qaFlags: [QAFlag(type: .lowConfidence, reason: "No classification results", dismissed: false)]
            )
        }

        // Aggregate classifications across all time windows
        var categoryScores: [DJSoundCategory: Double] = [:]
        var categoryCount: [DJSoundCategory: Int] = [:]

        for (_, classifications) in results {
            for (label, confidence) in classifications where confidence > 0.3 {
                let category = DJSoundCategory.fromAppleLabel(label)
                categoryScores[category, default: 0] += confidence
                categoryCount[category, default: 0] += 1
            }
        }

        // Normalize scores
        for category in categoryScores.keys {
            if let count = categoryCount[category], count > 0 {
                categoryScores[category]! /= Double(count)
            }
        }

        // Find primary context
        let sortedCategories = categoryScores.sorted { $0.value > $1.value }
        let primaryCategory = sortedCategories.first?.key ?? .unknown
        let primaryConfidence = sortedCategories.first?.value ?? 0

        // Build all classifications dict
        var allClassifications: [String: Double] = [:]
        for (category, score) in categoryScores {
            allClassifications[category.rawValue] = score
        }

        // Generate QA flags
        var qaFlags: [QAFlag] = []

        // Low confidence flag
        if primaryConfidence < confidenceThreshold {
            qaFlags.append(QAFlag(
                type: .lowConfidence,
                reason: "Primary classification confidence below \(Int(confidenceThreshold * 100))%",
                dismissed: false
            ))
        }

        // Mixed content flag
        let hasMusic = (categoryScores[.music] ?? 0) > 0.3
        let hasSpeech = (categoryScores[.speech] ?? 0) > 0.3
        if hasMusic && hasSpeech {
            qaFlags.append(QAFlag(
                type: .mixedContent,
                reason: "Track contains both music and speech content",
                dismissed: false
            ))
        }

        // Needs review flag
        if primaryCategory == .noise || primaryCategory == .unknown {
            qaFlags.append(QAFlag(
                type: .needsReview,
                reason: "Audio content requires manual review",
                dismissed: false
            ))
        }

        logger.info("Sound context: \(primaryCategory.rawValue) (confidence: \(String(format: "%.1f%%", primaryConfidence * 100)))")

        return SoundContextResult(
            primaryContext: primaryCategory.rawValue,
            confidence: primaryConfidence,
            allClassifications: allClassifications,
            qaFlags: qaFlags
        )
    }
}

// MARK: - Observer

/// Thread-safe observer for collecting classification results
private final class SoundObserver: NSObject, SNResultsObserving, @unchecked Sendable {
    private let lock = NSLock()
    private var _results: [(time: Double, classifications: [String: Double])] = []

    func getResults() -> [(time: Double, classifications: [String: Double])] {
        lock.lock()
        defer { lock.unlock() }
        return _results
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classificationResult = result as? SNClassificationResult else { return }

        var resultDict: [String: Double] = [:]
        for classification in classificationResult.classifications {
            resultDict[classification.identifier] = classification.confidence
        }

        let time = classificationResult.timeRange.start.seconds

        lock.lock()
        _results.append((time: time, classifications: resultDict))
        lock.unlock()
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        // Log error if needed
    }

    func requestDidComplete(_ request: SNRequest) {
        // Analysis complete
    }
}

// MARK: - Errors

public enum SoundAnalysisError: Error, LocalizedError {
    case invalidAudioFormat
    case analysisFailedWithError(Error)
    case noResults

    public var errorDescription: String? {
        switch self {
        case .invalidAudioFormat:
            return "Invalid audio format for SoundAnalysis"
        case .analysisFailedWithError(let error):
            return "SoundAnalysis failed: \(error.localizedDescription)"
        case .noResults:
            return "No classification results returned"
        }
    }
}
