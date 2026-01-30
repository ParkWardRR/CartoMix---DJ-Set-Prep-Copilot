// CuePointsTable - Table view of cue points with beat numbers

import SwiftUI

struct CuePointsTable: View {
    let cuePoints: [CuePointData]
    var onSelect: ((CuePointData) -> Void)? = nil
    var selectedId: UUID? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 0) {
                Text("#")
                    .frame(width: 30, alignment: .center)
                Text("Label")
                    .frame(minWidth: 80, alignment: .leading)
                Spacer()
                Text("Beat")
                    .frame(width: 60, alignment: .trailing)
                Text("Time")
                    .frame(width: 60, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(CartoMixColors.textSecondary)
            .padding(.horizontal, CartoMixSpacing.sm)
            .padding(.vertical, CartoMixSpacing.xs)
            .background(CartoMixColors.backgroundTertiary)

            // Rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(cuePoints.enumerated()), id: \.element.id) { index, cue in
                        CuePointRow(
                            index: index + 1,
                            cue: cue,
                            isSelected: cue.id == selectedId,
                            onTap: {
                                onSelect?(cue)
                            }
                        )

                        if index < cuePoints.count - 1 {
                            Divider()
                                .background(CartoMixColors.backgroundTertiary)
                        }
                    }
                }
            }
        }
        .background(CartoMixColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }
}

// MARK: - Cue Point Row

struct CuePointRow: View {
    let index: Int
    let cue: CuePointData
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Index with color indicator
                ZStack {
                    Circle()
                        .fill(cue.color)
                        .frame(width: 20, height: 20)
                    Text("\(index)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 30)

                // Label
                Text(cue.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(CartoMixColors.textPrimary)
                    .lineLimit(1)
                    .frame(minWidth: 80, alignment: .leading)

                Spacer()

                // Beat number
                if let beat = cue.beatIndex {
                    Text("\(beat)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(CartoMixColors.textSecondary)
                        .frame(width: 60, alignment: .trailing)
                } else {
                    Text("—")
                        .font(.system(size: 11))
                        .foregroundStyle(CartoMixColors.textTertiary)
                        .frame(width: 60, alignment: .trailing)
                }

                // Time
                Text(formatTime(cue.timeSeconds))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(CartoMixColors.textSecondary)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, CartoMixSpacing.sm)
            .padding(.vertical, CartoMixSpacing.sm)
            .background(isSelected ? cue.color.opacity(0.15) : .clear)
        }
        .buttonStyle(.plain)
        .hoverHighlight()
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let ms = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", mins, secs, ms)
    }
}

// MARK: - Supporting Types

struct CuePointData: Identifiable {
    let id = UUID()
    let label: String
    let type: CueType
    let timeSeconds: Double
    let beatIndex: Int?

    enum CueType: String, CaseIterable {
        case hotcue = "hotcue"
        case loop = "loop"
        case fadeIn = "fade_in"
        case fadeOut = "fade_out"
        case load = "load"
        case grid = "grid"

        var color: Color {
            switch self {
            case .hotcue: return CartoMixColors.accentGreen
            case .loop: return CartoMixColors.accentOrange
            case .fadeIn: return CartoMixColors.accentCyan
            case .fadeOut: return CartoMixColors.accentPurple
            case .load: return CartoMixColors.accentBlue
            case .grid: return CartoMixColors.accentYellow
            }
        }

        var icon: String {
            switch self {
            case .hotcue: return "flame.fill"
            case .loop: return "repeat"
            case .fadeIn: return "arrow.up.right"
            case .fadeOut: return "arrow.down.right"
            case .load: return "arrow.down.circle.fill"
            case .grid: return "square.grid.3x3"
            }
        }
    }

    var color: Color { type.color }
}

// MARK: - Compact Cue List (for smaller spaces)

struct CompactCueList: View {
    let cuePoints: [CuePointData]
    var maxDisplay: Int = 4

    var body: some View {
        VStack(alignment: .leading, spacing: CartoMixSpacing.xs) {
            ForEach(Array(cuePoints.prefix(maxDisplay).enumerated()), id: \.element.id) { index, cue in
                HStack(spacing: CartoMixSpacing.sm) {
                    // Color indicator
                    Circle()
                        .fill(cue.color)
                        .frame(width: 6, height: 6)

                    // Label
                    Text(cue.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CartoMixColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    // Time
                    Text(formatTime(cue.timeSeconds))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(CartoMixColors.textSecondary)
                }
            }

            if cuePoints.count > maxDisplay {
                Text("+\(cuePoints.count - maxDisplay) more")
                    .font(.system(size: 10))
                    .foregroundStyle(CartoMixColors.textTertiary)
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Preview

#Preview {
    let mockCues: [CuePointData] = [
        CuePointData(label: "Intro", type: .hotcue, timeSeconds: 0.0, beatIndex: 1),
        CuePointData(label: "Build Start", type: .hotcue, timeSeconds: 32.5, beatIndex: 65),
        CuePointData(label: "DROP", type: .hotcue, timeSeconds: 64.0, beatIndex: 129),
        CuePointData(label: "Breakdown", type: .hotcue, timeSeconds: 128.0, beatIndex: 257),
        CuePointData(label: "Drop 2", type: .hotcue, timeSeconds: 192.0, beatIndex: 385),
        CuePointData(label: "Mix Out", type: .fadeOut, timeSeconds: 240.0, beatIndex: 481),
        CuePointData(label: "Loop A", type: .loop, timeSeconds: 96.0, beatIndex: 193),
        CuePointData(label: "End", type: .load, timeSeconds: 270.0, beatIndex: nil)
    ]

    VStack(spacing: 20) {
        Text("Cue Points Table")
            .font(.headline)
            .foregroundStyle(.white)

        CuePointsTable(cuePoints: mockCues)
            .frame(height: 250)

        Divider()

        Text("Compact Cue List")
            .font(.headline)
            .foregroundStyle(.white)

        CompactCueList(cuePoints: mockCues)
            .frame(width: 200)
            .padding()
            .background(CartoMixColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }
    .padding()
    .background(CartoMixColors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
