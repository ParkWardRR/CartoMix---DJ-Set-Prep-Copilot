// CartoMix Theme - Color system inspired by Algiers web app
// Professional DJ software aesthetics with vibrant gradients

import SwiftUI

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - CartoMix Colors

struct CartoMixColors {
    // MARK: Backgrounds
    static let backgroundPrimary = Color(hex: "#0D0D0D")
    static let backgroundSecondary = Color(hex: "#1A1A1A")
    static let backgroundTertiary = Color(hex: "#252525")
    static let backgroundElevated = Color(hex: "#2D2D2D")

    // MARK: Accent Colors (iOS system-like for consistency)
    static let accentBlue = Color(hex: "#0A84FF")
    static let accentGreen = Color(hex: "#30D158")
    static let accentOrange = Color(hex: "#FF9F0A")
    static let accentPurple = Color(hex: "#BF5AF2")
    static let accentCyan = Color(hex: "#64D2FF")
    static let accentPink = Color(hex: "#FF375F")
    static let accentYellow = Color(hex: "#FFD60A")
    static let accentRed = Color(hex: "#FF453A")

    // MARK: Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#8E8E93")
    static let textTertiary = Color(hex: "#636366")

    // MARK: Section Colors (for track sections)
    static let sectionIntro = Color(hex: "#30D158")      // Green
    static let sectionBuild = Color(hex: "#FFD60A")      // Yellow
    static let sectionDrop = Color(hex: "#FF375F")       // Red/Pink
    static let sectionBreakdown = Color(hex: "#BF5AF2")  // Purple
    static let sectionChorus = Color(hex: "#FF6482")     // Pink
    static let sectionVerse = Color(hex: "#8E8E93")      // Gray
    static let sectionOutro = Color(hex: "#0A84FF")      // Blue

    // MARK: Badge Colors
    static let badgeBPM = accentBlue
    static let badgeKey = accentGreen
    static let badgeEnergy = accentOrange
    static let badgeDuration = accentPurple

    // MARK: Camelot Key Colors (12 positions x 2 modes)
    static let camelotColors: [String: Color] = [
        "1A": Color(hex: "#FF6B6B"), "1B": Color(hex: "#FF8E6B"),
        "2A": Color(hex: "#FFB16B"), "2B": Color(hex: "#FFD46B"),
        "3A": Color(hex: "#F7FF6B"), "3B": Color(hex: "#D4FF6B"),
        "4A": Color(hex: "#B1FF6B"), "4B": Color(hex: "#6BFF6B"),
        "5A": Color(hex: "#6BFFB1"), "5B": Color(hex: "#6BFFD4"),
        "6A": Color(hex: "#6BFFF7"), "6B": Color(hex: "#6BD4FF"),
        "7A": Color(hex: "#6BB1FF"), "7B": Color(hex: "#6B8EFF"),
        "8A": Color(hex: "#6B6BFF"), "8B": Color(hex: "#8E6BFF"),
        "9A": Color(hex: "#B16BFF"), "9B": Color(hex: "#D46BFF"),
        "10A": Color(hex: "#F76BFF"), "10B": Color(hex: "#FF6BD4"),
        "11A": Color(hex: "#FF6BB1"), "11B": Color(hex: "#FF6B8E"),
        "12A": Color(hex: "#FF6B6B"), "12B": Color(hex: "#FF8E8E")
    ]

    // MARK: Get color for Camelot key
    static func colorForKey(_ key: String) -> Color {
        camelotColors[key.uppercased()] ?? accentGreen
    }

    // MARK: Get color for section type
    static func colorForSection(_ type: String) -> Color {
        switch type.lowercased() {
        case "intro": return sectionIntro
        case "build", "buildup": return sectionBuild
        case "drop": return sectionDrop
        case "breakdown", "break": return sectionBreakdown
        case "chorus": return sectionChorus
        case "verse": return sectionVerse
        case "outro": return sectionOutro
        default: return textSecondary
        }
    }
}

// MARK: - Gradients

struct CartoMixGradients {
    // Waveform colors for Canvas use
    static let waveformColors: [Color] = [
        Color(hex: "#64D2FF"),  // Cyan
        Color(hex: "#0A84FF"),  // Blue
        Color(hex: "#BF5AF2"),  // Purple
        Color(hex: "#FF375F")   // Pink
    ]

    // Waveform gradient as Gradient (for Canvas)
    static let waveformGradient = Gradient(colors: waveformColors)

    // Waveform gradient (cyan -> blue -> purple -> pink)
    static let waveform = LinearGradient(
        colors: waveformColors,
        startPoint: .leading,
        endPoint: .trailing
    )

    // Energy curve colors for Canvas use
    static let energyColors: [Color] = [
        Color(hex: "#FF9F0A"),  // Orange
        Color(hex: "#FF453A"),  // Red
        Color(hex: "#BF5AF2")   // Purple
    ]

    // Energy gradient as Gradient (for Canvas)
    static let energy = Gradient(colors: energyColors)

    // Energy curve gradient
    static let energyCurve = LinearGradient(
        colors: [
            Color(hex: "#FF9F0A"),  // Orange
            Color(hex: "#FF453A"),  // Red
            Color(hex: "#BF5AF2")   // Purple
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Energy fill gradient (for area under curve)
    static let energyFill = LinearGradient(
        colors: [
            Color(hex: "#FF9F0A").opacity(0.5),
            Color(hex: "#FF453A").opacity(0.2),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Card background gradient
    static let cardBackground = LinearGradient(
        colors: [
            CartoMixColors.backgroundSecondary,
            CartoMixColors.backgroundTertiary.opacity(0.5)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Accent glow gradient
    static func glow(for color: Color) -> RadialGradient {
        RadialGradient(
            colors: [color.opacity(0.3), color.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: 50
        )
    }
}

// MARK: - Typography

struct CartoMixTypography {
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let title = Font.system(size: 22, weight: .semibold, design: .default)
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let badge = Font.system(size: 11, weight: .semibold, design: .default)
    static let mono = Font.system(size: 13, weight: .medium, design: .monospaced)
    static let monoSmall = Font.system(size: 11, weight: .medium, design: .monospaced)
}

// MARK: - Spacing

struct CartoMixSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radii

struct CartoMixRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let pill: CGFloat = 999
}
