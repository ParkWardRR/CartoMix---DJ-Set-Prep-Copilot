// TransitionPreviewView - Dual waveform display showing mix point

import SwiftUI

struct TransitionPreviewView: View {
    let trackA: TransitionTrackData
    let trackB: TransitionTrackData
    var mixZoneStart: Double = 0.8  // Normalized position (0-1)
    var mixZoneEnd: Double = 0.2    // Normalized position on track B

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Transition")
                .font(CartoMixTypography.headline)
                .foregroundStyle(CartoMixColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, CartoMixSpacing.sm)

            // Track A (outgoing)
            TransitionTrackRow(
                track: trackA,
                isOutgoing: true,
                mixZonePosition: mixZoneStart
            )

            // Connector
            TransitionConnector(
                bpmDelta: trackB.bpm - trackA.bpm,
                keyFrom: trackA.key,
                keyTo: trackB.key
            )

            // Track B (incoming)
            TransitionTrackRow(
                track: trackB,
                isOutgoing: false,
                mixZonePosition: mixZoneEnd
            )
        }
        .padding(CartoMixSpacing.md)
        .background(CartoMixColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.lg))
    }
}

// MARK: - Transition Track Row

struct TransitionTrackRow: View {
    let track: TransitionTrackData
    let isOutgoing: Bool
    let mixZonePosition: Double

    var body: some View {
        VStack(alignment: .leading, spacing: CartoMixSpacing.xs) {
            // Track info
            HStack {
                // Section indicator
                Circle()
                    .fill(isOutgoing ? CartoMixColors.sectionOutro : CartoMixColors.sectionIntro)
                    .frame(width: 8, height: 8)

                Text(track.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CartoMixColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                BadgeRow(
                    bpm: track.bpm,
                    key: track.key,
                    energy: track.energy,
                    size: .small,
                    spacing: 6
                )
            }

            // Waveform with mix zone highlight
            ZStack {
                CompactWaveformView(
                    samples: track.waveform,
                    sections: track.sections
                )

                // Mix zone overlay
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let zoneWidth = width * 0.2
                    let xPosition = isOutgoing ?
                        width * CGFloat(mixZonePosition) :
                        width * CGFloat(mixZonePosition) - zoneWidth

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: isOutgoing ?
                                    [.clear, CartoMixColors.accentPurple.opacity(0.4)] :
                                    [CartoMixColors.accentCyan.opacity(0.4), .clear],
                                startPoint: isOutgoing ? .leading : .trailing,
                                endPoint: isOutgoing ? .trailing : .leading
                            )
                        )
                        .frame(width: zoneWidth)
                        .position(x: xPosition + zoneWidth / 2, y: geometry.size.height / 2)
                }
            }
            .frame(height: 40)
            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.sm))
        }
        .padding(CartoMixSpacing.sm)
        .background(CartoMixColors.backgroundTertiary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }
}

// MARK: - Transition Connector

struct TransitionConnector: View {
    let bpmDelta: Double
    let keyFrom: String
    let keyTo: String

    var keyCompatibility: KeyCompatibility {
        if keyFrom == keyTo { return .same }

        let fromNum = Int(keyFrom.dropLast()) ?? 0
        let toNum = Int(keyTo.dropLast()) ?? 0
        let fromMode = keyFrom.last
        let toMode = keyTo.last

        let diff = abs(fromNum - toNum)

        if fromMode == toMode {
            if diff == 1 || diff == 11 { return .compatible }
            if diff == 2 || diff == 10 { return .harmonic }
        } else {
            if diff == 0 { return .relative }
            if diff == 3 || diff == 9 { return .harmonic }
        }

        return .clash
    }

    enum KeyCompatibility {
        case same, relative, compatible, harmonic, clash

        var color: Color {
            switch self {
            case .same: return CartoMixColors.accentGreen
            case .relative: return CartoMixColors.accentCyan
            case .compatible: return CartoMixColors.accentCyan
            case .harmonic: return CartoMixColors.accentYellow
            case .clash: return CartoMixColors.accentRed
            }
        }

        var icon: String {
            switch self {
            case .same: return "checkmark.circle.fill"
            case .relative, .compatible: return "arrow.triangle.merge"
            case .harmonic: return "waveform.path"
            case .clash: return "exclamationmark.triangle.fill"
            }
        }

        var label: String {
            switch self {
            case .same: return "Same Key"
            case .relative: return "Relative"
            case .compatible: return "Compatible"
            case .harmonic: return "Harmonic"
            case .clash: return "Key Clash"
            }
        }
    }

    var body: some View {
        HStack(spacing: CartoMixSpacing.lg) {
            // Connecting line
            VStack(spacing: 0) {
                Rectangle()
                    .fill(CartoMixColors.textTertiary)
                    .frame(width: 2, height: 16)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CartoMixColors.textTertiary)

                Rectangle()
                    .fill(CartoMixColors.textTertiary)
                    .frame(width: 2, height: 16)
            }

            // Transition info
            HStack(spacing: CartoMixSpacing.md) {
                // BPM delta
                HStack(spacing: 4) {
                    Image(systemName: "metronome")
                        .font(.caption2)
                    Text(bpmDelta >= 0 ? "+\(String(format: "%.1f", bpmDelta))" : String(format: "%.1f", bpmDelta))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(abs(bpmDelta) <= 3 ? CartoMixColors.accentGreen : CartoMixColors.accentYellow)

                // Key compatibility
                HStack(spacing: 4) {
                    Image(systemName: keyCompatibility.icon)
                        .font(.caption2)
                    Text("\(keyFrom) → \(keyTo)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(keyCompatibility.color)
            }
            .padding(.horizontal, CartoMixSpacing.md)
            .padding(.vertical, CartoMixSpacing.xs)
            .background(CartoMixColors.backgroundTertiary)
            .clipShape(Capsule())

            Spacer()
        }
        .padding(.vertical, CartoMixSpacing.xs)
    }
}

// MARK: - Supporting Types

struct TransitionTrackData: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let bpm: Double
    let key: String
    let energy: Int
    let waveform: [Float]
    var sections: [WaveformSection] = []
}

// MARK: - Preview

#Preview {
    let mockWaveform: [Float] = (0..<200).map { i in
        let t = Float(i) / 200
        return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
    }

    VStack(spacing: 20) {
        Text("Transition Preview")
            .font(.headline)
            .foregroundStyle(.white)

        TransitionPreviewView(
            trackA: TransitionTrackData(
                title: "Twilight Zone",
                artist: "Artist A",
                bpm: 126,
                key: "8A",
                energy: 7,
                waveform: mockWaveform,
                sections: [
                    WaveformSection(type: "drop", startTime: 0, endTime: 150),
                    WaveformSection(type: "outro", startTime: 150, endTime: 200)
                ]
            ),
            trackB: TransitionTrackData(
                title: "Berghain Sunrise",
                artist: "Artist B",
                bpm: 128,
                key: "9A",
                energy: 8,
                waveform: mockWaveform,
                sections: [
                    WaveformSection(type: "intro", startTime: 0, endTime: 50),
                    WaveformSection(type: "build", startTime: 50, endTime: 100)
                ]
            )
        )
    }
    .padding()
    .background(CartoMixColors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
