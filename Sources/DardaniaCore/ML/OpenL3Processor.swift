// CartoMix - OpenL3 Audio Embedding Processor
// Generates 512-dimensional embeddings using Core ML on Apple Neural Engine

import Foundation
import CoreML
import Accelerate
import AVFoundation
import Logging

/// Configuration for OpenL3 embedding generation
public struct OpenL3Config: Sendable {
    /// Sample rate expected by the model (48kHz)
    public static let sampleRate: Double = 48000

    /// Window size in seconds (1 second)
    public static let windowSeconds: Double = 1.0

    /// Hop size in seconds (0.5 seconds for 50% overlap)
    public static let hopSeconds: Double = 0.5

    /// Number of mel bands
    public static let melBands: Int = 128

    /// Number of frames per window
    public static let framesPerWindow: Int = 199

    /// Embedding dimension
    public static let embeddingDim: Int = 512

    /// Samples per window
    public static var samplesPerWindow: Int {
        Int(windowSeconds * sampleRate)
    }

    /// Samples per hop
    public static var samplesPerHop: Int {
        Int(hopSeconds * sampleRate)
    }
}

/// OpenL3 Audio Embedding Processor using Core ML
public actor OpenL3Processor {
    private let logger = Logger(label: "com.cartomix.openl3")
    private var modelWrapper: ModelWrapper?
    private var isLoaded = false

    /// Thread-safe wrapper for MLModel
    private final class ModelWrapper: @unchecked Sendable {
        let model: MLModel

        init(_ model: MLModel) {
            self.model = model
        }
    }

    /// Errors that can occur during OpenL3 processing
    public enum OpenL3Error: Error, LocalizedError {
        case modelNotFound
        case modelLoadFailed(underlying: Error)
        case invalidAudioFormat
        case insufficientAudio
        case predictionFailed(underlying: Error)
        case invalidModelOutput

        public var errorDescription: String? {
            switch self {
            case .modelNotFound:
                return "OpenL3 model not found in app bundle"
            case .modelLoadFailed(let error):
                return "Failed to load OpenL3 model: \(error.localizedDescription)"
            case .invalidAudioFormat:
                return "Invalid audio format for embedding generation"
            case .insufficientAudio:
                return "Audio too short for embedding generation (minimum 1 second)"
            case .predictionFailed(let error):
                return "OpenL3 prediction failed: \(error.localizedDescription)"
            case .invalidModelOutput:
                return "Invalid model output format"
            }
        }
    }

    public init() {}

    // MARK: - Model Loading

    /// Load the OpenL3 Core ML model
    public func loadModel() async throws {
        guard !isLoaded else { return }

        logger.info("Loading OpenL3 Core ML model...")

        // Find the model in the bundle
        guard let modelURL = Bundle.main.url(forResource: "OpenL3Music", withExtension: "mlmodelc") ??
                            Bundle.main.url(forResource: "OpenL3Music", withExtension: "mlpackage") else {
            logger.error("OpenL3 model not found in bundle")
            throw OpenL3Error.modelNotFound
        }

        do {
            // Configure for Neural Engine
            let config = MLModelConfiguration()
            config.computeUnits = .all // Prefer ANE, fall back to GPU/CPU

            let loadedModel = try MLModel(contentsOf: modelURL, configuration: config)
            self.modelWrapper = ModelWrapper(loadedModel)
            self.isLoaded = true

            logger.info("OpenL3 model loaded successfully (compute units: all)")
        } catch {
            logger.error("Failed to load OpenL3 model: \(error)")
            throw OpenL3Error.modelLoadFailed(underlying: error)
        }
    }

    /// Check if model is loaded and ready
    public var ready: Bool {
        isLoaded && modelWrapper != nil
    }

    // MARK: - Embedding Generation

    /// Generate a single 512-dimensional embedding for an audio segment
    public func generateEmbedding(audioData: [Float], sampleRate: Double) async throws -> [Float] {
        guard let wrapper = modelWrapper else {
            try await loadModel()
            guard let loadedWrapper = self.modelWrapper else {
                throw OpenL3Error.modelNotFound
            }
            return try generateEmbeddingSync(model: loadedWrapper.model, audioData: audioData, sampleRate: sampleRate)
        }

        return try generateEmbeddingSync(model: wrapper.model, audioData: audioData, sampleRate: sampleRate)
    }

    /// Synchronous embedding generation (runs on actor's executor)
    private func generateEmbeddingSync(model: MLModel, audioData: [Float], sampleRate: Double) throws -> [Float] {
        // Resample if necessary
        let resampledAudio: [Float]
        if abs(sampleRate - OpenL3Config.sampleRate) > 1 {
            resampledAudio = resampleAudio(audioData, fromRate: sampleRate, toRate: OpenL3Config.sampleRate)
        } else {
            resampledAudio = audioData
        }

        guard resampledAudio.count >= OpenL3Config.samplesPerWindow else {
            throw OpenL3Error.insufficientAudio
        }

        // Compute mel spectrogram
        let melSpec = computeMelSpectrogram(resampledAudio)

        // Create model input
        guard let inputArray = try? MLMultiArray(shape: [1, NSNumber(value: OpenL3Config.melBands), NSNumber(value: OpenL3Config.framesPerWindow)], dataType: .float32) else {
            throw OpenL3Error.predictionFailed(underlying: NSError(domain: "OpenL3", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create input array"]))
        }

        // Copy mel spectrogram to input array
        for i in 0..<min(melSpec.count, OpenL3Config.melBands * OpenL3Config.framesPerWindow) {
            inputArray[i] = NSNumber(value: melSpec[i])
        }

        // Run synchronous prediction (faster for small inputs, avoids concurrency issues)
        do {
            let inputFeatures = try MLDictionaryFeatureProvider(dictionary: ["input": inputArray])
            let output = try model.prediction(from: inputFeatures)

            // Extract embedding from output
            guard let embeddingArray = output.featureValue(for: "embedding")?.multiArrayValue else {
                throw OpenL3Error.invalidModelOutput
            }

            // Convert to Float array
            var embedding = [Float](repeating: 0, count: OpenL3Config.embeddingDim)
            for i in 0..<OpenL3Config.embeddingDim {
                embedding[i] = Float(truncating: embeddingArray[i])
            }

            // L2 normalize the embedding
            return normalizeEmbedding(embedding)
        } catch let error as OpenL3Error {
            throw error
        } catch {
            throw OpenL3Error.predictionFailed(underlying: error)
        }
    }

    /// Generate track-level embedding by processing windows and mean-pooling
    public func generateTrackEmbedding(audioData: [Float], sampleRate: Double) async throws -> [Float] {
        // Resample if necessary
        let resampledAudio: [Float]
        if abs(sampleRate - OpenL3Config.sampleRate) > 1 {
            resampledAudio = resampleAudio(audioData, fromRate: sampleRate, toRate: OpenL3Config.sampleRate)
        } else {
            resampledAudio = audioData
        }

        guard resampledAudio.count >= OpenL3Config.samplesPerWindow else {
            throw OpenL3Error.insufficientAudio
        }

        // Process windows
        var windowEmbeddings: [[Float]] = []
        var position = 0

        while position + OpenL3Config.samplesPerWindow <= resampledAudio.count {
            let windowStart = position
            let windowEnd = position + OpenL3Config.samplesPerWindow
            let windowData = Array(resampledAudio[windowStart..<windowEnd])

            do {
                let embedding = try await generateEmbedding(audioData: windowData, sampleRate: OpenL3Config.sampleRate)
                windowEmbeddings.append(embedding)
            } catch {
                logger.warning("Failed to generate embedding for window at \(position): \(error)")
            }

            position += OpenL3Config.samplesPerHop
        }

        guard !windowEmbeddings.isEmpty else {
            throw OpenL3Error.insufficientAudio
        }

        // Mean pool all window embeddings
        var meanEmbedding = [Float](repeating: 0, count: OpenL3Config.embeddingDim)
        for embedding in windowEmbeddings {
            for i in 0..<OpenL3Config.embeddingDim {
                meanEmbedding[i] += embedding[i]
            }
        }

        let count = Float(windowEmbeddings.count)
        for i in 0..<OpenL3Config.embeddingDim {
            meanEmbedding[i] /= count
        }

        logger.info("Generated track embedding from \(windowEmbeddings.count) windows")

        return normalizeEmbedding(meanEmbedding)
    }

    // MARK: - Audio Processing

    /// Resample audio using Accelerate
    private func resampleAudio(_ audio: [Float], fromRate: Double, toRate: Double) -> [Float] {
        let ratio = toRate / fromRate
        let outputLength = Int(Double(audio.count) * ratio)
        var output = [Float](repeating: 0, count: outputLength)

        // Linear interpolation for resampling
        for i in 0..<outputLength {
            let srcPos = Double(i) / ratio
            let srcIndex = Int(srcPos)
            let frac = Float(srcPos - Double(srcIndex))

            if srcIndex + 1 < audio.count {
                output[i] = audio[srcIndex] * (1 - frac) + audio[srcIndex + 1] * frac
            } else if srcIndex < audio.count {
                output[i] = audio[srcIndex]
            }
        }

        return output
    }

    /// Compute mel spectrogram using Accelerate FFT
    private func computeMelSpectrogram(_ audio: [Float]) -> [Float] {
        let fftSize = 2048
        let hopSize = Int(OpenL3Config.sampleRate * OpenL3Config.windowSeconds) / OpenL3Config.framesPerWindow

        // Ensure we have enough audio
        let paddedAudio: [Float]
        if audio.count < fftSize {
            paddedAudio = audio + [Float](repeating: 0, count: fftSize - audio.count)
        } else {
            paddedAudio = audio
        }

        var melSpec = [Float](repeating: 0, count: OpenL3Config.melBands * OpenL3Config.framesPerWindow)

        // Create Hanning window
        var window = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))

        // Create FFT setup
        guard let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(fftSize))), FFTRadix(kFFTRadix2)) else {
            return melSpec
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        // Mel filterbank (simplified - using triangular filters)
        let melFilters = createMelFilterbank(
            numFilters: OpenL3Config.melBands,
            fftSize: fftSize,
            sampleRate: OpenL3Config.sampleRate
        )

        // Process each frame
        for frame in 0..<OpenL3Config.framesPerWindow {
            let frameStart = frame * hopSize

            guard frameStart + fftSize <= paddedAudio.count else { break }

            // Extract and window frame
            var windowedFrame = [Float](repeating: 0, count: fftSize)
            vDSP_vmul(Array(paddedAudio[frameStart..<(frameStart + fftSize)]), 1, window, 1, &windowedFrame, 1, vDSP_Length(fftSize))

            // Compute FFT with proper pointer management
            var realPart = [Float](repeating: 0, count: fftSize / 2)
            var imagPart = [Float](repeating: 0, count: fftSize / 2)
            var powerSpectrum = [Float](repeating: 0, count: fftSize / 2)

            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)

                    windowedFrame.withUnsafeBufferPointer { ptr in
                        ptr.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: fftSize / 2) { complexPtr in
                            vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(fftSize / 2))
                        }
                    }

                    vDSP_fft_zrip(fftSetup, &splitComplex, 1, vDSP_Length(log2(Float(fftSize))), FFTDirection(FFT_FORWARD))

                    // Compute power spectrum
                    powerSpectrum.withUnsafeMutableBufferPointer { powerPtr in
                        vDSP_zvmags(&splitComplex, 1, powerPtr.baseAddress!, 1, vDSP_Length(fftSize / 2))
                    }
                }
            }

            // Apply mel filterbank
            for mel in 0..<OpenL3Config.melBands {
                var melEnergy: Float = 0
                for bin in 0..<(fftSize / 2) {
                    melEnergy += powerSpectrum[bin] * melFilters[mel * (fftSize / 2) + bin]
                }
                // Log-mel (with floor to avoid log(0))
                melSpec[mel * OpenL3Config.framesPerWindow + frame] = log10(max(melEnergy, 1e-10))
            }
        }

        // Normalize mel spectrogram
        var minVal: Float = 0
        var maxVal: Float = 0
        vDSP_minv(melSpec, 1, &minVal, vDSP_Length(melSpec.count))
        vDSP_maxv(melSpec, 1, &maxVal, vDSP_Length(melSpec.count))

        if maxVal > minVal {
            var range = maxVal - minVal
            var negMin = -minVal
            vDSP_vsadd(melSpec, 1, &negMin, &melSpec, 1, vDSP_Length(melSpec.count))
            vDSP_vsdiv(melSpec, 1, &range, &melSpec, 1, vDSP_Length(melSpec.count))
        }

        return melSpec
    }

    /// Create mel filterbank matrix
    private func createMelFilterbank(numFilters: Int, fftSize: Int, sampleRate: Double) -> [Float] {
        let numBins = fftSize / 2

        func hzToMel(_ hz: Double) -> Double {
            2595 * log10(1 + hz / 700)
        }

        func melToHz(_ mel: Double) -> Double {
            700 * (pow(10, mel / 2595) - 1)
        }

        let lowFreq: Double = 0
        let highFreq = sampleRate / 2
        let lowMel = hzToMel(lowFreq)
        let highMel = hzToMel(highFreq)

        // Mel points
        var melPoints = [Double](repeating: 0, count: numFilters + 2)
        for i in 0...(numFilters + 1) {
            melPoints[i] = lowMel + Double(i) * (highMel - lowMel) / Double(numFilters + 1)
        }

        // Convert to Hz and then to bin indices
        var binPoints = [Int](repeating: 0, count: numFilters + 2)
        for i in 0...(numFilters + 1) {
            let hz = melToHz(melPoints[i])
            binPoints[i] = Int(hz * Double(fftSize) / sampleRate)
        }

        // Create filterbank
        var filterbank = [Float](repeating: 0, count: numFilters * numBins)

        for m in 0..<numFilters {
            let filterStart = binPoints[m]
            let filterCenter = binPoints[m + 1]
            let filterEnd = binPoints[m + 2]

            // Rising edge
            for k in filterStart..<filterCenter {
                if k < numBins {
                    let weight = Float(k - filterStart) / Float(filterCenter - filterStart)
                    filterbank[m * numBins + k] = weight
                }
            }

            // Falling edge
            for k in filterCenter..<filterEnd {
                if k < numBins {
                    let weight = Float(filterEnd - k) / Float(filterEnd - filterCenter)
                    filterbank[m * numBins + k] = weight
                }
            }
        }

        return filterbank
    }

    /// L2 normalize embedding
    private func normalizeEmbedding(_ embedding: [Float]) -> [Float] {
        var norm: Float = 0
        vDSP_svesq(embedding, 1, &norm, vDSP_Length(embedding.count))
        norm = sqrt(norm)

        guard norm > 0 else { return embedding }

        var normalized = embedding
        var normValue = 1.0 / norm
        vDSP_vsmul(embedding, 1, &normValue, &normalized, 1, vDSP_Length(embedding.count))

        return normalized
    }
}
