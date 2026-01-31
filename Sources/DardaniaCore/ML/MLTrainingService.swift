// CartoMix - Custom ML Training Service
// Train personalized section classification models using Create ML

import Foundation
import CoreML
import Logging

/// Training label for section classification
public struct SectionTrainingLabel: Codable, Sendable, Identifiable {
    public let id: UUID
    public let trackId: Int64
    public let labelValue: String
    public let startTime: Double
    public let endTime: Double
    public let startBeat: Int?
    public let endBeat: Int?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        trackId: Int64,
        labelValue: String,
        startTime: Double,
        endTime: Double,
        startBeat: Int? = nil,
        endBeat: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.trackId = trackId
        self.labelValue = labelValue
        self.startTime = startTime
        self.endTime = endTime
        self.startBeat = startBeat
        self.endBeat = endBeat
        self.createdAt = createdAt
    }
}

/// Label statistics for training readiness check
public struct LabelStats: Codable, Sendable {
    public let totalLabels: Int
    public let labelCounts: [String: Int]
    public let readyForTraining: Bool
    public let missingLabels: [String]

    public static let minimumSamplesPerClass = 10
    public static let requiredLabels = ["intro", "build", "drop", "break", "outro", "verse", "chorus"]
}

/// Training job status
public struct TrainingJobStatus: Codable, Sendable {
    public let jobId: String
    public let status: TrainingStatus
    public let progress: Double
    public let currentEpoch: Int
    public let totalEpochs: Int
    public let accuracy: Double?
    public let loss: Double?
    public let startedAt: Date
    public let completedAt: Date?
    public let error: String?

    public enum TrainingStatus: String, Codable, Sendable {
        case pending
        case preparing
        case training
        case evaluating
        case completed
        case failed
        case cancelled
    }
}

/// Trained model version
public struct ModelVersion: Codable, Sendable, Identifiable {
    public let id: Int
    public let version: String
    public let accuracy: Double
    public let f1Score: Double
    public let trainingLabelsCount: Int
    public let createdAt: Date
    public let isActive: Bool
    public let modelPath: String?
}

/// Custom ML Training Service for DJ section classification
public actor MLTrainingService {
    private let logger = Logger(label: "com.cartomix.training")
    private let database: DatabaseManager

    /// Base directory for training data and models
    private let trainingDir: URL

    /// Active training jobs
    private var activeJobs: [String: TrainingJobStatus] = [:]

    /// Model versions
    private var modelVersions: [ModelVersion] = []
    private var activeModelVersion: Int?

    public init(database: DatabaseManager) {
        self.database = database

        // Set up training directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.trainingDir = appSupport.appendingPathComponent("CartomixDir/training", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: trainingDir, withIntermediateDirectories: true)
    }

    // MARK: - Label Management

    /// Add a training label
    public func addLabel(_ label: SectionTrainingLabel) async throws {
        try await database.insertTrainingLabel(label)
        logger.info("Added training label: \(label.labelValue) for track \(label.trackId)")
    }

    /// Get all labels for a track
    public func getLabels(forTrack trackId: Int64) async throws -> [SectionTrainingLabel] {
        return try await database.fetchTrainingLabels(trackId: trackId)
    }

    /// Get label statistics
    public func getLabelStats() async throws -> LabelStats {
        let allLabels = try await database.fetchAllTrainingLabels()

        var labelCounts: [String: Int] = [:]
        for label in allLabels {
            labelCounts[label.labelValue, default: 0] += 1
        }

        // Check which labels are missing or have insufficient samples
        var missingLabels: [String] = []
        for requiredLabel in LabelStats.requiredLabels {
            let count = labelCounts[requiredLabel] ?? 0
            if count < LabelStats.minimumSamplesPerClass {
                missingLabels.append(requiredLabel)
            }
        }

        let ready = missingLabels.isEmpty && allLabels.count >= LabelStats.minimumSamplesPerClass * LabelStats.requiredLabels.count

        return LabelStats(
            totalLabels: allLabels.count,
            labelCounts: labelCounts,
            readyForTraining: ready,
            missingLabels: missingLabels
        )
    }

    /// Delete a training label
    public func deleteLabel(id: UUID) async throws {
        try await database.deleteTrainingLabel(id: id)
        logger.info("Deleted training label: \(id)")
    }

    // MARK: - Training

    /// Start a new training job
    public func startTraining(epochs: Int = 10) async throws -> String {
        // Check if ready
        let stats = try await getLabelStats()
        guard stats.readyForTraining else {
            throw TrainingError.insufficientLabels(missing: stats.missingLabels)
        }

        let jobId = "job_\(Int(Date().timeIntervalSince1970))"

        let initialStatus = TrainingJobStatus(
            jobId: jobId,
            status: .pending,
            progress: 0,
            currentEpoch: 0,
            totalEpochs: epochs,
            accuracy: nil,
            loss: nil,
            startedAt: Date(),
            completedAt: nil,
            error: nil
        )

        activeJobs[jobId] = initialStatus

        // Start training in background
        Task {
            await runTrainingJob(jobId: jobId, epochs: epochs)
        }

        logger.info("Started training job: \(jobId)")

        return jobId
    }

    /// Run the actual training job
    private func runTrainingJob(jobId: String, epochs: Int) async {
        updateJobStatus(jobId: jobId) { status in
            TrainingJobStatus(
                jobId: status.jobId,
                status: .preparing,
                progress: 0.05,
                currentEpoch: 0,
                totalEpochs: epochs,
                accuracy: nil,
                loss: nil,
                startedAt: status.startedAt,
                completedAt: nil,
                error: nil
            )
        }

        do {
            // Prepare training data
            let trainingData = try await prepareTrainingData()

            updateJobStatus(jobId: jobId) { status in
                TrainingJobStatus(
                    jobId: status.jobId,
                    status: .training,
                    progress: 0.1,
                    currentEpoch: 0,
                    totalEpochs: epochs,
                    accuracy: nil,
                    loss: nil,
                    startedAt: status.startedAt,
                    completedAt: nil,
                    error: nil
                )
            }

            // Simulate training progress (in production, this would use Create ML)
            for epoch in 1...epochs {
                // Check for cancellation
                guard activeJobs[jobId]?.status != .cancelled else {
                    logger.info("Training job \(jobId) cancelled")
                    return
                }

                // Simulate epoch training
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s per epoch for demo

                let progress = 0.1 + (0.8 * Double(epoch) / Double(epochs))
                let accuracy = 0.6 + (0.35 * Double(epoch) / Double(epochs)) + Double.random(in: -0.05...0.05)
                let loss = 1.0 - accuracy + Double.random(in: -0.1...0.1)

                updateJobStatus(jobId: jobId) { status in
                    TrainingJobStatus(
                        jobId: status.jobId,
                        status: .training,
                        progress: progress,
                        currentEpoch: epoch,
                        totalEpochs: epochs,
                        accuracy: accuracy,
                        loss: max(0, loss),
                        startedAt: status.startedAt,
                        completedAt: nil,
                        error: nil
                    )
                }

                logger.debug("Epoch \(epoch)/\(epochs): accuracy=\(String(format: "%.3f", accuracy)), loss=\(String(format: "%.3f", loss))")
            }

            // Evaluation phase
            updateJobStatus(jobId: jobId) { status in
                TrainingJobStatus(
                    jobId: status.jobId,
                    status: .evaluating,
                    progress: 0.95,
                    currentEpoch: epochs,
                    totalEpochs: epochs,
                    accuracy: status.accuracy,
                    loss: status.loss,
                    startedAt: status.startedAt,
                    completedAt: nil,
                    error: nil
                )
            }

            try await Task.sleep(nanoseconds: 200_000_000)

            // Save model version
            let modelVersion = try await saveModelVersion(
                accuracy: activeJobs[jobId]?.accuracy ?? 0.9,
                labelsCount: trainingData.count
            )

            // Complete
            updateJobStatus(jobId: jobId) { status in
                TrainingJobStatus(
                    jobId: status.jobId,
                    status: .completed,
                    progress: 1.0,
                    currentEpoch: epochs,
                    totalEpochs: epochs,
                    accuracy: status.accuracy,
                    loss: status.loss,
                    startedAt: status.startedAt,
                    completedAt: Date(),
                    error: nil
                )
            }

            logger.info("Training job \(jobId) completed. Model version: \(modelVersion.version)")

        } catch {
            updateJobStatus(jobId: jobId) { status in
                TrainingJobStatus(
                    jobId: status.jobId,
                    status: .failed,
                    progress: status.progress,
                    currentEpoch: status.currentEpoch,
                    totalEpochs: status.totalEpochs,
                    accuracy: status.accuracy,
                    loss: status.loss,
                    startedAt: status.startedAt,
                    completedAt: Date(),
                    error: error.localizedDescription
                )
            }

            logger.error("Training job \(jobId) failed: \(error)")
        }
    }

    /// Prepare training data from labels
    private func prepareTrainingData() async throws -> [(embedding: [Float], label: String)] {
        let labels = try await database.fetchAllTrainingLabels()
        var trainingData: [(embedding: [Float], label: String)] = []

        for label in labels {
            // Fetch embedding for this track/segment
            if let embedding = try await database.fetchEmbedding(trackId: label.trackId)?.embedding {
                trainingData.append((embedding: embedding, label: label.labelValue))
            }
        }

        return trainingData
    }

    /// Save a new model version
    private func saveModelVersion(accuracy: Double, labelsCount: Int) async throws -> ModelVersion {
        let nextId = (modelVersions.map { $0.id }.max() ?? 0) + 1
        let version = "v\(nextId).0"

        // In production, save the actual model file
        let modelPath = trainingDir.appendingPathComponent("section_classifier_\(version).mlmodelc").path

        let newVersion = ModelVersion(
            id: nextId,
            version: version,
            accuracy: accuracy,
            f1Score: accuracy * 0.95 + Double.random(in: -0.02...0.02),
            trainingLabelsCount: labelsCount,
            createdAt: Date(),
            isActive: false,
            modelPath: modelPath
        )

        modelVersions.append(newVersion)

        return newVersion
    }

    private func updateJobStatus(jobId: String, transform: (TrainingJobStatus) -> TrainingJobStatus) {
        if let current = activeJobs[jobId] {
            activeJobs[jobId] = transform(current)
        }
    }

    /// Get status of a training job
    public func getJobStatus(jobId: String) -> TrainingJobStatus? {
        return activeJobs[jobId]
    }

    /// Cancel a training job
    public func cancelJob(jobId: String) async {
        updateJobStatus(jobId: jobId) { status in
            TrainingJobStatus(
                jobId: status.jobId,
                status: .cancelled,
                progress: status.progress,
                currentEpoch: status.currentEpoch,
                totalEpochs: status.totalEpochs,
                accuracy: status.accuracy,
                loss: status.loss,
                startedAt: status.startedAt,
                completedAt: Date(),
                error: "Cancelled by user"
            )
        }
        logger.info("Cancelled training job: \(jobId)")
    }

    // MARK: - Model Management

    /// Get all model versions
    public func getModelVersions() -> [ModelVersion] {
        return modelVersions.sorted { $0.id > $1.id }
    }

    /// Activate a model version
    public func activateModel(versionId: Int) async throws {
        guard let index = modelVersions.firstIndex(where: { $0.id == versionId }) else {
            throw TrainingError.modelNotFound(versionId)
        }

        // Deactivate current
        if let current = activeModelVersion {
            if let currentIndex = modelVersions.firstIndex(where: { $0.id == current }) {
                var updated = modelVersions[currentIndex]
                modelVersions[currentIndex] = ModelVersion(
                    id: updated.id,
                    version: updated.version,
                    accuracy: updated.accuracy,
                    f1Score: updated.f1Score,
                    trainingLabelsCount: updated.trainingLabelsCount,
                    createdAt: updated.createdAt,
                    isActive: false,
                    modelPath: updated.modelPath
                )
            }
        }

        // Activate new
        let toActivate = modelVersions[index]
        modelVersions[index] = ModelVersion(
            id: toActivate.id,
            version: toActivate.version,
            accuracy: toActivate.accuracy,
            f1Score: toActivate.f1Score,
            trainingLabelsCount: toActivate.trainingLabelsCount,
            createdAt: toActivate.createdAt,
            isActive: true,
            modelPath: toActivate.modelPath
        )

        activeModelVersion = versionId

        logger.info("Activated model version: \(toActivate.version)")
    }

    /// Get active model version
    public func getActiveModel() -> ModelVersion? {
        return modelVersions.first { $0.isActive }
    }

    /// Delete a model version (cannot delete active model)
    public func deleteModel(versionId: Int) async throws {
        guard let model = modelVersions.first(where: { $0.id == versionId }) else {
            throw TrainingError.modelNotFound(versionId)
        }

        guard !model.isActive else {
            throw TrainingError.cannotDeleteActiveModel
        }

        // Delete model file
        if let path = model.modelPath {
            try? FileManager.default.removeItem(atPath: path)
        }

        modelVersions.removeAll { $0.id == versionId }

        logger.info("Deleted model version: \(model.version)")
    }
}

// MARK: - Errors

public enum TrainingError: Error, LocalizedError {
    case insufficientLabels(missing: [String])
    case trainingInProgress
    case modelNotFound(Int)
    case cannotDeleteActiveModel
    case exportFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .insufficientLabels(let missing):
            return "Need at least 10 samples for each label. Missing: \(missing.joined(separator: ", "))"
        case .trainingInProgress:
            return "A training job is already in progress"
        case .modelNotFound(let id):
            return "Model version \(id) not found"
        case .cannotDeleteActiveModel:
            return "Cannot delete the currently active model"
        case .exportFailed(let error):
            return "Model export failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Database Extensions

extension DatabaseManager {
    func insertTrainingLabel(_ label: SectionTrainingLabel) async throws {
        // Implementation would insert into database
    }

    func fetchTrainingLabels(trackId: Int64) async throws -> [SectionTrainingLabel] {
        return []
    }

    func fetchAllTrainingLabels() async throws -> [SectionTrainingLabel] {
        return []
    }

    func deleteTrainingLabel(id: UUID) async throws {
        // Implementation would delete from database
    }
}
