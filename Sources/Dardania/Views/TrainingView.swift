// Dardania - Training View

import SwiftUI
import DardaniaCore

struct TrainingView: View {
    @EnvironmentObject var appState: AppState
    @State private var labelStats: LabelStats?
    @State private var trainingJob: TrainingJob?
    @State private var modelVersions: [ModelVersion] = []
    @State private var selectedLabel: SectionLabel = .drop

    var body: some View {
        HSplitView {
            // Left: Dataset and labeling
            VStack(spacing: 0) {
                TrainingToolbar(
                    labelStats: labelStats,
                    isReadyToTrain: labelStats?.readyForTraining ?? false,
                    onStartTraining: startTraining
                )

                Divider()

                // Label distribution
                if let stats = labelStats {
                    LabelDistributionChart(stats: stats)
                        .frame(height: 200)
                        .padding()
                }

                Divider()

                // Track list for labeling
                List(appState.tracks) { track in
                    TrainingTrackRow(
                        track: track,
                        selectedLabel: $selectedLabel,
                        onAddLabel: { label, start, end in
                            addLabel(to: track, label: label, start: start, end: end)
                        }
                    )
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 500)

            // Right: Training progress and models
            VStack(spacing: 0) {
                // Training progress
                if let job = trainingJob {
                    TrainingProgressCard(job: job)
                        .padding()
                }

                Divider()

                // Model versions
                ModelVersionsList(
                    versions: modelVersions,
                    onActivate: activateModel,
                    onDelete: deleteModel
                )
            }
            .frame(minWidth: 300)
        }
        .navigationTitle("ML Training")
        .task {
            await loadLabelStats()
            await loadModelVersions()
        }
    }

    private func loadLabelStats() async {
        // Load from database
    }

    private func loadModelVersions() async {
        // Load from database
    }

    private func startTraining() {
        // Start training job
    }

    private func addLabel(to track: Track, label: SectionLabel, start: Double, end: Double) {
        // Add label to database
    }

    private func activateModel(_ version: ModelVersion) {
        // Activate model version
    }

    private func deleteModel(_ version: ModelVersion) {
        // Delete model version
    }
}

// MARK: - Training Toolbar

struct TrainingToolbar: View {
    let labelStats: LabelStats?
    let isReadyToTrain: Bool
    let onStartTraining: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if let stats = labelStats {
                Text("\(stats.totalLabels) labels")
                    .foregroundStyle(.secondary)

                if isReadyToTrain {
                    Label("Ready to train", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Need more labels", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.yellow)
                }
            }

            Spacer()

            Button("Start Training", action: onStartTraining)
                .disabled(!isReadyToTrain)
        }
        .padding()
    }
}

// MARK: - Label Distribution Chart

struct LabelDistributionChart: View {
    let stats: LabelStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Label Distribution")
                .font(.headline)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(SectionLabel.allCases, id: \.self) { label in
                    let count = stats.labelCounts[label] ?? 0
                    let maxCount = stats.labelCounts.values.max() ?? 1

                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.caption.monospacedDigit())

                        RoundedRectangle(cornerRadius: 4)
                            .fill(label.color)
                            .frame(width: 40, height: max(20, CGFloat(count) / CGFloat(maxCount) * 100))

                        Text(label.rawValue)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Minimum requirement indicator
            HStack {
                Image(systemName: "info.circle")
                Text("Minimum 10 samples per label required")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Training Track Row

struct TrainingTrackRow: View {
    let track: Track
    @Binding var selectedLabel: SectionLabel
    let onAddLabel: (SectionLabel, Double, Double) -> Void

    @State private var showLabelSheet = false
    @State private var labelStart: Double = 0
    @State private var labelEnd: Double = 30

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(track.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Label badges
            if let analysis = track.analysis {
                ForEach(analysis.trainingLabels, id: \.startTime) { label in
                    Text(label.label.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(label.label.color.opacity(0.2), in: Capsule())
                        .foregroundStyle(label.label.color)
                }
            }

            Button {
                showLabelSheet = true
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showLabelSheet) {
            LabelEditorSheet(
                track: track,
                selectedLabel: $selectedLabel,
                labelStart: $labelStart,
                labelEnd: $labelEnd,
                onSave: {
                    onAddLabel(selectedLabel, labelStart, labelEnd)
                    showLabelSheet = false
                },
                onCancel: {
                    showLabelSheet = false
                }
            )
        }
    }
}

// MARK: - Label Editor Sheet

struct LabelEditorSheet: View {
    let track: Track
    @Binding var selectedLabel: SectionLabel
    @Binding var labelStart: Double
    @Binding var labelEnd: Double
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Label")
                .font(.headline)

            // Track info
            VStack(spacing: 4) {
                Text(track.title)
                    .font(.subheadline)
                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Label picker
            Picker("Label", selection: $selectedLabel) {
                ForEach(SectionLabel.allCases, id: \.self) { label in
                    HStack {
                        Circle()
                            .fill(label.color)
                            .frame(width: 12, height: 12)
                        Text(label.rawValue)
                    }
                    .tag(label)
                }
            }
            .pickerStyle(.radioGroup)

            Divider()

            // Time range
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    Text("Start:")
                    TextField("0", value: $labelStart, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("seconds")
                        .foregroundStyle(.secondary)
                }

                GridRow {
                    Text("End:")
                    TextField("30", value: $labelEnd, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("seconds")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.escape)

                Spacer()

                Button("Save", action: onSave)
                    .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

// MARK: - Training Progress Card

struct TrainingProgressCard: View {
    let job: TrainingJob

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Training", systemImage: "brain")
                    .font(.headline)

                Spacer()

                Text(job.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(job.status.color.opacity(0.2), in: Capsule())
                    .foregroundStyle(job.status.color)
            }

            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Epoch \(job.currentEpoch)/\(job.totalEpochs)")
                    Spacer()
                    Text(String(format: "%.0f%%", job.progress * 100))
                }
                .font(.subheadline)

                ProgressView(value: job.progress)
            }

            // Metrics
            if job.status == .training || job.status == .completed {
                HStack(spacing: 24) {
                    MetricView(label: "Loss", value: String(format: "%.4f", job.validationLoss))
                    MetricView(label: "Accuracy", value: String(format: "%.1f%%", job.validationAccuracy * 100))
                    MetricView(label: "Samples", value: "\(job.samplesProcessed)")
                }
            }

            // Elapsed time
            Text("Elapsed: \(formatDuration(job.elapsedSeconds))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

struct MetricView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Model Versions List

struct ModelVersionsList: View {
    let versions: [ModelVersion]
    let onActivate: (ModelVersion) -> Void
    let onDelete: (ModelVersion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Versions")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            if versions.isEmpty {
                EmptyStateView(
                    icon: "cube.box",
                    title: "No Models",
                    subtitle: "Train a model to see versions here"
                )
            } else {
                List(versions) { version in
                    ModelVersionRow(
                        version: version,
                        onActivate: { onActivate(version) },
                        onDelete: { onDelete(version) }
                    )
                }
                .listStyle(.inset)
            }
        }
    }
}

struct ModelVersionRow: View {
    let version: ModelVersion
    let onActivate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("v\(version.version)")
                        .font(.headline)

                    if version.isActive {
                        Text("Active")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }

                Text(version.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Text(String(format: "%.1f%%", version.accuracy * 100))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if !version.isActive {
                Button("Activate", action: onActivate)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Models

struct LabelStats {
    let totalLabels: Int
    let labelCounts: [SectionLabel: Int]
    let readyForTraining: Bool
}

enum SectionLabel: String, CaseIterable {
    case intro = "Intro"
    case build = "Build"
    case drop = "Drop"
    case breakdown = "Break"
    case outro = "Outro"
    case verse = "Verse"
    case chorus = "Chorus"

    var color: Color {
        switch self {
        case .intro: return .green
        case .build: return .yellow
        case .drop: return .red
        case .breakdown: return .purple
        case .outro: return .blue
        case .verse: return .gray
        case .chorus: return .pink
        }
    }
}

struct TrainingJob: Identifiable {
    let id: String
    let status: TrainingStatus
    let progress: Double
    let currentEpoch: Int
    let totalEpochs: Int
    let validationLoss: Double
    let validationAccuracy: Double
    let samplesProcessed: Int
    let elapsedSeconds: Int
}

enum TrainingStatus: String {
    case pending = "Pending"
    case preparing = "Preparing"
    case training = "Training"
    case evaluating = "Evaluating"
    case completed = "Completed"
    case failed = "Failed"

    var color: Color {
        switch self {
        case .pending: return .gray
        case .preparing: return .yellow
        case .training: return .blue
        case .evaluating: return .purple
        case .completed: return .green
        case .failed: return .red
        }
    }
}

struct ModelVersion: Identifiable {
    let id: Int
    let version: Int
    let accuracy: Double
    let isActive: Bool
    let createdAt: Date
}

// Preview commented out for SPM compatibility
// #Preview {
//     TrainingView()
//         .environmentObject(AppState())
//         .frame(width: 1000, height: 700)
// }
