import Foundation
import AVFoundation
import Accelerate

/// Native audio player using AVAudioEngine for high-quality playback
public class AudioPlayer: NSObject {

    // MARK: - Singleton

    public static let shared = AudioPlayer()

    // MARK: - Properties

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    private var audioBuffer: AVAudioPCMBuffer?

    private var currentTrackId: Int64?
    private var currentPath: String?

    // Playback state
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var volume: Float = 1.0
    private(set) var rate: Float = 1.0

    // Waveform data for visualization
    private(set) var waveformData: [Float] = []

    // Timer for position updates
    private var positionTimer: Timer?

    // Callback for state changes
    var onStateChange: (([String: Any]) -> Void)?

    // MARK: - Initialization

    private override init() {
        super.init()
        setupEngine()
    }

    private func setupEngine() {
        // Attach player node to engine
        engine.attach(playerNode)

        // Connect player to main mixer
        let mainMixer = engine.mainMixerNode
        engine.connect(playerNode, to: mainMixer, format: nil)

        // Prepare engine
        engine.prepare()
    }

    // MARK: - Public Methods

    /// Load an audio file for playback
    public func load(path: String, trackId: Int64) throws {
        // Stop current playback
        stop()

        let url = URL(fileURLWithPath: path)

        // Load audio file
        audioFile = try AVAudioFile(forReading: url)

        guard let file = audioFile else {
            throw AudioPlayerError.failedToLoad
        }

        // Get format and duration
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        duration = Double(file.length) / file.processingFormat.sampleRate

        // Create buffer for entire file
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw AudioPlayerError.failedToCreateBuffer
        }

        try file.read(into: buffer)
        audioBuffer = buffer

        // Generate waveform data
        generateWaveform(from: buffer)

        // Update state
        currentTrackId = trackId
        currentPath = path
        currentTime = 0

        // Start engine if needed
        if !engine.isRunning {
            try engine.start()
        }

        // Notify state change
        notifyStateChange()
    }

    /// Start or resume playback
    public func play() {
        guard let buffer = audioBuffer, let file = audioFile else { return }

        if !engine.isRunning {
            try? engine.start()
        }

        // Schedule buffer from current position
        let startFrame = AVAudioFramePosition(currentTime * file.processingFormat.sampleRate)
        let remainingFrames = AVAudioFrameCount(file.length - startFrame)

        if remainingFrames > 0 {
            // Create segment buffer
            if let segmentBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: remainingFrames) {
                segmentBuffer.frameLength = remainingFrames

                // Copy data from main buffer
                if let srcData = buffer.floatChannelData, let dstData = segmentBuffer.floatChannelData {
                    for channel in 0..<Int(file.processingFormat.channelCount) {
                        let src = srcData[channel].advanced(by: Int(startFrame))
                        let dst = dstData[channel]
                        memcpy(dst, src, Int(remainingFrames) * MemoryLayout<Float>.size)
                    }
                }

                playerNode.scheduleBuffer(segmentBuffer, completionHandler: { [weak self] in
                    DispatchQueue.main.async {
                        self?.handlePlaybackComplete()
                    }
                })
            }
        }

        playerNode.play()
        isPlaying = true

        // Start position timer
        startPositionTimer()

        notifyStateChange()
    }

    /// Pause playback
    public func pause() {
        playerNode.pause()
        isPlaying = false
        stopPositionTimer()
        notifyStateChange()
    }

    /// Stop playback and reset position
    public func stop() {
        playerNode.stop()
        isPlaying = false
        currentTime = 0
        stopPositionTimer()
        notifyStateChange()
    }

    /// Seek to a specific time
    public func seek(to time: Double) {
        let wasPlaying = isPlaying

        // Stop current playback
        playerNode.stop()
        isPlaying = false

        // Update position
        currentTime = max(0, min(time, duration))

        // Resume if was playing
        if wasPlaying {
            play()
        } else {
            notifyStateChange()
        }
    }

    /// Set playback volume (0.0 - 1.0)
    public func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
        playerNode.volume = volume
        notifyStateChange()
    }

    /// Set playback rate (0.5 - 2.0)
    public func setRate(_ newRate: Float) {
        rate = max(0.5, min(2.0, newRate))
        playerNode.rate = rate
        notifyStateChange()
    }

    /// Get current state as dictionary
    public func getState() -> [String: Any] {
        return [
            "isPlaying": isPlaying,
            "currentTime": currentTime,
            "duration": duration,
            "volume": Double(volume),
            "rate": Double(rate),
            "trackId": currentTrackId as Any,
            "path": currentPath as Any,
            "waveformSamples": waveformData.count
        ]
    }

    /// Get waveform data for visualization
    public func getWaveformData() -> [Float] {
        return waveformData
    }

    // MARK: - Private Methods

    private func startPositionTimer() {
        stopPositionTimer()

        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
    }

    private func stopPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
    }

    private func updatePosition() {
        guard isPlaying, let file = audioFile else { return }

        if let nodeTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            currentTime = Double(playerTime.sampleTime) / file.processingFormat.sampleRate

            // Check if we've reached the end
            if currentTime >= duration {
                handlePlaybackComplete()
            } else {
                notifyStateChange()
            }
        }
    }

    private func handlePlaybackComplete() {
        isPlaying = false
        currentTime = duration
        stopPositionTimer()
        notifyStateChange()
    }

    private func notifyStateChange() {
        onStateChange?(getState())
    }

    /// Generate waveform visualization data
    private func generateWaveform(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else {
            waveformData = []
            return
        }

        let frameCount = Int(buffer.frameLength)
        let samplesPerPixel = max(1, frameCount / 1000) // ~1000 points
        let outputCount = frameCount / samplesPerPixel

        var waveform = [Float](repeating: 0, count: outputCount)

        // Process first channel (mono or left)
        let samples = channelData[0]

        for i in 0..<outputCount {
            let start = i * samplesPerPixel
            let end = min(start + samplesPerPixel, frameCount)

            // Find peak amplitude in this segment
            var maxAmp: Float = 0
            for j in start..<end {
                let amp = abs(samples[j])
                if amp > maxAmp {
                    maxAmp = amp
                }
            }
            waveform[i] = maxAmp
        }

        // Normalize to 0-1 range
        var maxVal: Float = 0
        vDSP_maxv(waveform, 1, &maxVal, vDSP_Length(outputCount))

        if maxVal > 0 {
            var scale = 1.0 / maxVal
            vDSP_vsmul(waveform, 1, &scale, &waveform, 1, vDSP_Length(outputCount))
        }

        waveformData = waveform
    }
}

// MARK: - Errors

enum AudioPlayerError: Error, LocalizedError {
    case failedToLoad
    case failedToCreateBuffer
    case noAudioFile

    var errorDescription: String? {
        switch self {
        case .failedToLoad:
            return "Failed to load audio file"
        case .failedToCreateBuffer:
            return "Failed to create audio buffer"
        case .noAudioFile:
            return "No audio file loaded"
        }
    }
}
