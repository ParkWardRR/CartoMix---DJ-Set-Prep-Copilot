// Dardania - XPC Analyzer Service Entry Point

import Foundation
import AnalyzerSwift
import Logging

/// XPC Service for audio analysis
/// This runs as a separate process for crash isolation
@main
struct AnalyzerXPCService {
    static func main() {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .info
            return handler
        }

        let logger = Logger(label: "com.dardania.analyzer-xpc")
        logger.info("AnalyzerXPC service starting")

        // Create XPC listener
        let listener = NSXPCListener.service()
        let delegate = AnalyzerXPCDelegate()
        listener.delegate = delegate

        // Resume the listener (this never returns)
        listener.resume()

        // Keep the service running
        RunLoop.main.run()
    }
}

// MARK: - XPC Delegate

final class AnalyzerXPCDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Configure the connection
        newConnection.exportedInterface = NSXPCInterface(with: AnalyzerXPCProtocol.self)
        newConnection.exportedObject = AnalyzerXPCHandler()

        // Handle connection errors
        newConnection.invalidationHandler = {
            Logger(label: "com.dardania.analyzer-xpc").info("XPC connection invalidated")
        }

        newConnection.interruptionHandler = {
            Logger(label: "com.dardania.analyzer-xpc").warning("XPC connection interrupted")
        }

        newConnection.resume()
        return true
    }
}

// MARK: - XPC Protocol

@objc public protocol AnalyzerXPCProtocol {
    /// Analyze a track at the given path
    func analyzeTrack(
        path: String,
        progressHandler: @escaping (String, Double) -> Void,
        completion: @escaping (Data?, Error?) -> Void
    )

    /// Check if the service is healthy
    func healthCheck(completion: @escaping (Bool) -> Void)

    /// Get hardware capabilities
    func getHardwareInfo(completion: @escaping (Data?) -> Void)
}

// MARK: - XPC Handler

final class AnalyzerXPCHandler: NSObject, AnalyzerXPCProtocol {
    private let logger = Logger(label: "com.dardania.analyzer-xpc.handler")
    private let analyzer: Analyzer

    override init() {
        self.analyzer = Analyzer()
        super.init()
    }

    func analyzeTrack(
        path: String,
        progressHandler: @escaping (String, Double) -> Void,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        let analysisLogger = Logger(label: "com.dardania.analyzer-xpc.handler")
        analysisLogger.info("Analyzing: \(path)")

        // Wrap callbacks for Sendable compliance
        let safeProgressHandler = UnsafeSendable(value: progressHandler)
        let safeCompletion = UnsafeSendable(value: completion)
        let analyzerRef = self.analyzer

        Task.detached {
            do {
                let result = try await analyzerRef.analyze(
                    path: path,
                    progress: { @Sendable stage in
                        let stageName: String
                        let progress: Double

                        switch stage {
                        case .decoding:
                            stageName = "Decoding"
                            progress = 0.1
                        case .beatgrid:
                            stageName = "Beatgrid"
                            progress = 0.25
                        case .key:
                            stageName = "Key Detection"
                            progress = 0.35
                        case .energy:
                            stageName = "Energy"
                            progress = 0.45
                        case .loudness:
                            stageName = "Loudness"
                            progress = 0.55
                        case .sections:
                            stageName = "Sections"
                            progress = 0.65
                        case .waveform:
                            stageName = "Waveform"
                            progress = 0.70
                        case .embedding, .openL3Embedding:
                            stageName = "ML Embedding"
                            progress = 0.80
                        case .soundClassification:
                            stageName = "Classification"
                            progress = 0.85
                        case .cues:
                            stageName = "Cue Points"
                            progress = 0.90
                        case .complete:
                            stageName = "Complete"
                            progress = 1.0
                        }

                        safeProgressHandler.value(stageName, progress)
                    }
                )

                // Encode result as JSON
                let encoder = JSONEncoder()
                let wrapper = AnalysisResultWrapper(result: result)
                let data = try encoder.encode(wrapper)

                safeCompletion.value(data, nil)
            } catch {
                Logger(label: "com.dardania.analyzer-xpc.handler").error("Analysis failed: \(error)")
                safeCompletion.value(nil, error)
            }
        }
    }

    func healthCheck(completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    func getHardwareInfo(completion: @escaping (Data?) -> Void) {
        let info = HardwareInfo(
            hasNeuralEngine: true, // Apple Silicon default
            hasMetal: true,
            chipName: ProcessInfo.processInfo.machineHardwareName ?? "Unknown"
        )

        let encoder = JSONEncoder()
        let data = try? encoder.encode(info)
        completion(data)
    }
}

// MARK: - Wrapper Types

struct AnalysisResultWrapper: Codable {
    let durationSeconds: Double
    let bpm: Double
    let bpmConfidence: Double
    let keyValue: String
    let keyConfidence: Double
    let energyGlobal: Int
    let integratedLUFS: Double
    let truePeakDB: Double
    let loudnessRange: Double
    let soundContext: String?
    let soundContextConfidence: Double?
    let hasOpenL3Embedding: Bool
    let waveformPreview: [Float]
    let sections: [SectionWrapper]
    let cuePoints: [CueWrapper]
    let openL3Embedding: [Float]?

    init(result: TrackAnalysisResult) {
        self.durationSeconds = result.duration
        self.bpm = result.bpm
        self.bpmConfidence = result.beatgridConfidence
        self.keyValue = result.key.camelot
        self.keyConfidence = result.key.confidence
        self.energyGlobal = result.globalEnergy
        self.integratedLUFS = Double(result.loudness.integratedLoudness)
        self.truePeakDB = Double(result.loudness.truePeak)
        self.loudnessRange = Double(result.loudness.loudnessRange)
        self.soundContext = result.soundClassification?.primaryContext
        self.soundContextConfidence = result.soundClassification?.confidence
        self.hasOpenL3Embedding = result.openL3Embedding != nil
        self.waveformPreview = result.waveformSummary
        self.sections = result.sections.map { SectionWrapper(from: $0) }
        self.cuePoints = result.cues.map { CueWrapper(from: $0) }
        self.openL3Embedding = result.openL3Embedding?.vector
    }
}

struct SectionWrapper: Codable {
    let type: String
    let startTime: Double
    let endTime: Double
    let confidence: Double

    init(from section: Section) {
        self.type = section.type.rawValue
        self.startTime = section.startTime
        self.endTime = section.endTime
        self.confidence = section.confidence
    }
}

struct CueWrapper: Codable {
    let label: String
    let type: String
    let timeSeconds: Double
    let beatIndex: Int?

    init(from cue: CuePoint) {
        self.label = cue.label
        self.type = cue.type.rawValue
        self.timeSeconds = cue.time
        self.beatIndex = cue.beatIndex
    }
}

struct HardwareInfo: Codable {
    let hasNeuralEngine: Bool
    let hasMetal: Bool
    let chipName: String
}

// MARK: - ProcessInfo Extension

extension ProcessInfo {
    var machineHardwareName: String? {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

// MARK: - Unsafe Sendable Wrapper

/// Wrapper to bypass Sendable checking for XPC callbacks
/// This is safe because XPC ensures serial execution
struct UnsafeSendable<T>: @unchecked Sendable {
    let value: T
}
