// ColoredBadge - Vibrant pill badges for track metadata

import SwiftUI

struct ColoredBadge: View {
    let icon: String?
    let value: String
    let color: Color
    var size: Size = .regular

    enum Size {
        case small, regular, large

        var iconFont: Font {
            switch self {
            case .small: return .system(size: 9, weight: .semibold)
            case .regular: return .system(size: 10, weight: .semibold)
            case .large: return .system(size: 12, weight: .semibold)
            }
        }

        var textFont: Font {
            switch self {
            case .small: return .system(size: 10, weight: .semibold, design: .monospaced)
            case .regular: return .system(size: 11, weight: .semibold, design: .monospaced)
            case .large: return .system(size: 13, weight: .semibold, design: .monospaced)
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .regular: return 10
            case .large: return 14
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .small: return 3
            case .regular: return 5
            case .large: return 7
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 3
            case .regular: return 4
            case .large: return 5
            }
        }
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            if let icon {
                Image(systemName: icon)
                    .font(size.iconFont)
            }
            Text(value)
                .font(size.textFont)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(color.opacity(0.2))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Convenience Initializers

extension ColoredBadge {
    /// BPM badge (blue)
    static func bpm(_ value: Double, size: Size = .regular) -> ColoredBadge {
        ColoredBadge(
            icon: "metronome",
            value: "\(Int(value))",
            color: CartoMixColors.badgeBPM,
            size: size
        )
    }

    /// Key badge (green)
    static func key(_ value: String, size: Size = .regular) -> ColoredBadge {
        ColoredBadge(
            icon: "music.note",
            value: value,
            color: CartoMixColors.colorForKey(value),
            size: size
        )
    }

    /// Energy badge (orange)
    static func energy(_ value: Int, size: Size = .regular) -> ColoredBadge {
        ColoredBadge(
            icon: "bolt.fill",
            value: "\(value)",
            color: CartoMixColors.badgeEnergy,
            size: size
        )
    }

    /// Duration badge (purple)
    static func duration(_ seconds: Double, size: Size = .regular) -> ColoredBadge {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return ColoredBadge(
            icon: "clock",
            value: String(format: "%d:%02d", minutes, secs),
            color: CartoMixColors.badgeDuration,
            size: size
        )
    }

    /// LUFS badge (cyan)
    static func lufs(_ value: Double, size: Size = .regular) -> ColoredBadge {
        ColoredBadge(
            icon: "speaker.wave.2",
            value: String(format: "%.1f", value),
            color: CartoMixColors.accentCyan,
            size: size
        )
    }

    /// Compatibility badge (color varies by score)
    static func compatibility(_ score: Int, size: Size = .regular) -> ColoredBadge {
        let color: Color
        if score >= 80 {
            color = CartoMixColors.accentGreen
        } else if score >= 60 {
            color = CartoMixColors.accentYellow
        } else {
            color = CartoMixColors.accentRed
        }
        return ColoredBadge(
            icon: "arrow.triangle.merge",
            value: "\(score)%",
            color: color,
            size: size
        )
    }
}

// MARK: - Badge Row

struct BadgeRow: View {
    let bpm: Double?
    let key: String?
    let energy: Int?
    var size: ColoredBadge.Size = .regular
    var spacing: CGFloat = 8

    var body: some View {
        HStack(spacing: spacing) {
            if let bpm {
                ColoredBadge.bpm(bpm, size: size)
            }
            if let key {
                ColoredBadge.key(key, size: size)
            }
            if let energy {
                ColoredBadge.energy(energy, size: size)
            }
        }
    }
}

// MARK: - Transition Info Badge

struct TransitionInfoBadge: View {
    let bpmDelta: Double
    let keyFrom: String
    let keyTo: String
    let energyDelta: Int

    var keyCompatibility: String {
        if keyFrom == keyTo { return "same" }
        // Simplified compatibility check
        let fromNum = Int(keyFrom.dropLast()) ?? 0
        let toNum = Int(keyTo.dropLast()) ?? 0
        let diff = abs(fromNum - toNum)
        if diff <= 1 || diff == 11 { return "compatible" }
        if diff <= 2 || diff == 10 { return "harmonic" }
        return "clash"
    }

    var keyColor: Color {
        switch keyCompatibility {
        case "same": return CartoMixColors.accentGreen
        case "compatible": return CartoMixColors.accentCyan
        case "harmonic": return CartoMixColors.accentYellow
        default: return CartoMixColors.accentRed
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CartoMixSpacing.sm) {
            // BPM Delta
            HStack(spacing: 4) {
                Image(systemName: "metronome")
                    .font(.caption2)
                Text(bpmDelta >= 0 ? "+\(String(format: "%.1f", bpmDelta))" : String(format: "%.1f", bpmDelta))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                Text("BPM")
                    .font(.caption2)
                    .foregroundStyle(CartoMixColors.textSecondary)
            }
            .foregroundStyle(abs(bpmDelta) <= 3 ? CartoMixColors.accentGreen : CartoMixColors.accentYellow)

            // Key transition
            HStack(spacing: 4) {
                Image(systemName: "music.note")
                    .font(.caption2)
                Text("\(keyFrom) → \(keyTo)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                if keyCompatibility == "same" {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                }
            }
            .foregroundStyle(keyColor)

            // Energy delta
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.caption2)
                Text(energyDelta >= 0 ? "+\(energyDelta)" : "\(energyDelta)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                Text("energy")
                    .font(.caption2)
                    .foregroundStyle(CartoMixColors.textSecondary)
            }
            .foregroundStyle(CartoMixColors.badgeEnergy)
        }
        .padding(CartoMixSpacing.md)
        .background(CartoMixColors.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Colored Badges")
            .font(.headline)

        HStack(spacing: 12) {
            ColoredBadge.bpm(128)
            ColoredBadge.key("8A")
            ColoredBadge.energy(7)
            ColoredBadge.duration(245)
        }

        HStack(spacing: 12) {
            ColoredBadge.bpm(116, size: .small)
            ColoredBadge.key("4B", size: .small)
            ColoredBadge.energy(5, size: .small)
        }

        HStack(spacing: 12) {
            ColoredBadge.bpm(140, size: .large)
            ColoredBadge.key("12A", size: .large)
            ColoredBadge.energy(9, size: .large)
        }

        Divider()

        Text("Badge Row")
            .font(.headline)

        BadgeRow(bpm: 126, key: "6A", energy: 6)

        Divider()

        Text("Transition Info")
            .font(.headline)

        TransitionInfoBadge(
            bpmDelta: 2.0,
            keyFrom: "8A",
            keyTo: "9A",
            energyDelta: 1
        )
    }
    .padding()
    .background(CartoMixColors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
