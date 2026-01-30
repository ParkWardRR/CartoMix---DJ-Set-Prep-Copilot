// CartoMix - Audio Player Service
// Real-time audio playback with waveform synchronization

import Foundation
import AVFoundation
import Logging
import Combine

/// Audio player service for track preview and playback
@MainActor
public final class AudioPlayerService: ObservableObject {
    public static let shared = AudioPlayerService()

    // MARK: - Published State

    @Published public private(set) var isPlaying = false
    @Published public private(set) var currentTime: Double = 0
    @Published public private(set) var duration: Double = 0
    @Published public private(set) var playbackRate: Float = 1.0
    @Published public private(set) var volume: Float = 1.0
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: PlayerError?
    @Published public private(set) var currentTrackId: Int64?
    @Published public private(set) var waveformData: [Float] = []

    // MARK: - Audio Engine

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private var displayLink: CVDisplayLink?
    private var timeObserver: Any?

    private let logger = Logger(label: "com.cartomix.player")
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Player Error

    public enum PlayerError: Error, LocalizedError {
        case fileNotFound(String)
        case decodingFailed(String)
        case engineSetupFailed(String)
        case playbackFailed(String)

        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "Audio file not found: \(path)"
            case .decodingFailed(let reason):
                return "Failed to decode audio: \(reason)"
            case .engineSetupFailed(let reason):
                return "Audio engine setup failed: \(reason)"
            case .playbackFailed(let reason):
                return "Playback failed: \(reason)"
            }
        }
    }

    // MARK: - Initialization

    private init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let engine = audioEngine, let player = playerNode else {
            logger.error("Failed to create audio engine components")
            return
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)

        do {
            try engine.start()
            logger.info("Audio engine started")
        } catch {
            logger.error("Failed to start audio engine: \(error)")
            self.error = .engineSetupFailed(error.localizedDescription)
        }
    }

    // MARK: - Public API

    /// Load a track for playback
    public func load(url: URL, trackId: Int64) async throws {
        isLoading = true
        error = nil

        defer { isLoading = false }

        // Stop current playback
        stop()

        do {
            // Load audio file
            audioFile = try AVAudioFile(forReading: url)

            guard let file = audioFile else {
                throw PlayerError.fileNotFound(url.path)
            }

            duration = Double(file.length) / file.fileFormat.sampleRate
            currentTrackId = trackId
            currentTime = 0

            // Generate waveform data
            waveformData = try await generateWaveform(from: file)

            logger.info("Loaded track: \(url.lastPathComponent), duration: \(duration)s")

        } catch let playerError as PlayerError {
            self.error = playerError
            throw playerError
        } catch {
            let playerError = PlayerError.decodingFailed(error.localizedDescription)
            self.error = playerError
            throw playerError
        }
    }

    /// Start or resume playback
    public func play() {
        guard let player = playerNode,
              let file = audioFile,
              let engine = audioEngine else {
            return
        }

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                logger.error("Failed to start engine: \(error)")
                return
            }
        }

        if !isPlaying {
            // Schedule file from current position
            let startFrame = AVAudioFramePosition(currentTime * file.fileFormat.sampleRate)
            let frameCount = AVAudioFrameCount(file.length - startFrame)

            if frameCount > 0 {
                player.scheduleSegment(
                    file,
                    startingFrame: startFrame,
                    frameCount: frameCount,
                    at: nil
                )
            }

            player.play()
            isPlaying = true
            startTimeUpdates()

            logger.info("Playback started at \(currentTime)s")
        }
    }

    /// Pause playback
    public func pause() {
        playerNode?.pause()
        isPlaying = false
        stopTimeUpdates()
        logger.info("Playback paused at \(currentTime)s")
    }

    /// Stop playback and reset position
    public func stop() {
        playerNode?.stop()
        isPlaying = false
        currentTime = 0
        stopTimeUpdates()
        logger.info("Playback stopped")
    }

    /// Seek to a specific time
    public func seek(to time: Double) {
        let wasPlaying = isPlaying

        if isPlaying {
            playerNode?.stop()
        }

        currentTime = max(0, min(time, duration))

        if wasPlaying {
            play()
        }
    }

    /// Seek by relative amount
    public func skip(by seconds: Double) {
        seek(to: currentTime + seconds)
    }

    /// Set playback rate (0.5 - 2.0)
    public func setRate(_ rate: Float) {
        playbackRate = max(0.5, min(2.0, rate))
        playerNode?.rate = playbackRate
    }

    /// Set volume (0.0 - 1.0)
    public func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        playerNode?.volume = volume
    }

    /// Toggle play/pause
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    // MARK: - Waveform Generation

    private func generateWaveform(from file: AVAudioFile) async throws -> [Float] {
        let targetSampleCount = 1000 // Number of waveform points
        let channelCount = Int(file.fileFormat.channelCount)
        let frameCount = Int(file.length)

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(frameCount)
        ) else {
            throw PlayerError.decodingFailed("Failed to create buffer")
        }

        try file.read(into: buffer)

        guard let channelData = buffer.floatChannelData else {
            throw PlayerError.decodingFailed("No channel data available")
        }

        let samplesPerPoint = max(1, frameCount / targetSampleCount)
        var waveform: [Float] = []
        waveform.reserveCapacity(targetSampleCount)

        for i in 0..<targetSampleCount {
            let startSample = i * samplesPerPoint
            let endSample = min(startSample + samplesPerPoint, frameCount)

            var maxAmplitude: Float = 0

            for sampleIndex in startSample..<endSample {
                for channel in 0..<channelCount {
                    let amplitude = abs(channelData[channel][sampleIndex])
                    maxAmplitude = max(maxAmplitude, amplitude)
                }
            }

            waveform.append(maxAmplitude)
        }

        // Normalize
        let maxValue = waveform.max() ?? 1.0
        if maxValue > 0 {
            waveform = waveform.map { $0 / maxValue }
        }

        return waveform
    }

    // MARK: - Time Updates

    private func startTimeUpdates() {
        // Use a timer for time updates (simpler than DisplayLink for this use case)
        Timer.publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCurrentTime()
            }
            .store(in: &cancellables)
    }

    private func stopTimeUpdates() {
        cancellables.removeAll()
    }

    private func updateCurrentTime() {
        guard let player = playerNode,
              let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime) else {
            return
        }

        let newTime = Double(playerTime.sampleTime) / playerTime.sampleRate
        currentTime = newTime

        // Check for end of track
        if currentTime >= duration {
            stop()
        }
    }

    // MARK: - Cue Point Playback

    /// Jump to a cue point
    public func jumpToCue(at time: Double) {
        seek(to: time)
        if !isPlaying {
            play()
        }
    }

    /// Preview from a specific time (play for a few seconds then stop)
    public func preview(from time: Double, duration previewDuration: Double = 5.0) {
        seek(to: time)
        play()

        Task {
            try? await Task.sleep(nanoseconds: UInt64(previewDuration * 1_000_000_000))
            await MainActor.run {
                if self.currentTime >= time + previewDuration - 0.5 {
                    self.pause()
                }
            }
        }
    }
}

// MARK: - Keyboard Shortcuts Support

extension AudioPlayerService {
    public func handleKeyPress(_ key: KeyEquivalent) {
        switch key {
        case .space:
            togglePlayPause()
        case .leftArrow:
            skip(by: -5)
        case .rightArrow:
            skip(by: 5)
        default:
            break
        }
    }
}
