// CartoMix View Modifiers - Consistent styling across the app

import SwiftUI

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = CartoMixSpacing.md
    var cornerRadius: CGFloat = CartoMixRadius.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(CartoMixColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func cardStyle(padding: CGFloat = CartoMixSpacing.md, cornerRadius: CGFloat = CartoMixRadius.lg) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Elevated Card Style

struct ElevatedCardStyle: ViewModifier {
    var padding: CGFloat = CartoMixSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(CartoMixColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.lg))
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func elevatedCardStyle(padding: CGFloat = CartoMixSpacing.md) -> some View {
        modifier(ElevatedCardStyle(padding: padding))
    }
}

// MARK: - Badge Style Modifier

struct BadgeStyle: ViewModifier {
    let color: Color
    var size: BadgeSize = .regular

    enum BadgeSize {
        case small, regular, large

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

        var font: Font {
            switch self {
            case .small: return .system(size: 10, weight: .semibold)
            case .regular: return .system(size: 11, weight: .semibold)
            case .large: return .system(size: 13, weight: .semibold)
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .font(size.font)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

extension View {
    func badgeStyle(color: Color, size: BadgeStyle.BadgeSize = .regular) -> some View {
        modifier(BadgeStyle(color: color, size: size))
    }
}

// MARK: - Section Indicator Style

struct SectionIndicatorStyle: ViewModifier {
    let sectionType: String
    var width: CGFloat = 4

    func body(content: Content) -> some View {
        HStack(spacing: CartoMixSpacing.sm) {
            RoundedRectangle(cornerRadius: 2)
                .fill(CartoMixColors.colorForSection(sectionType))
                .frame(width: width)
            content
        }
    }
}

extension View {
    func sectionIndicator(_ type: String, width: CGFloat = 4) -> some View {
        modifier(SectionIndicatorStyle(sectionType: type, width: width))
    }
}

// MARK: - Glow Effect

struct GlowEffect: ViewModifier {
    let color: Color
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 8) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
}

// MARK: - Hover Highlight

struct HoverHighlight: ViewModifier {
    @State private var isHovered = false
    var highlightColor: Color = .white.opacity(0.05)

    func body(content: Content) -> some View {
        content
            .background(isHovered ? highlightColor : .clear)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

extension View {
    func hoverHighlight(color: Color = .white.opacity(0.05)) -> some View {
        modifier(HoverHighlight(highlightColor: color))
    }
}

// MARK: - Panel Header Style

struct PanelHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(CartoMixTypography.headline)
            .foregroundStyle(CartoMixColors.textPrimary)
            .padding(.bottom, CartoMixSpacing.sm)
    }
}

extension View {
    func panelHeader() -> some View {
        modifier(PanelHeaderStyle())
    }
}

// MARK: - Track Row Style

struct TrackRowStyle: ViewModifier {
    var isSelected: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, CartoMixSpacing.md)
            .padding(.vertical, CartoMixSpacing.sm)
            .background(isSelected ? CartoMixColors.accentBlue.opacity(0.2) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
            .hoverHighlight()
    }
}

extension View {
    func trackRowStyle(isSelected: Bool = false) -> some View {
        modifier(TrackRowStyle(isSelected: isSelected))
    }
}

// MARK: - Toolbar Button Style

struct ToolbarButtonStyle: ButtonStyle {
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isActive ? CartoMixColors.accentBlue.opacity(0.2) :
                configuration.isPressed ? CartoMixColors.backgroundElevated : CartoMixColors.backgroundTertiary
            )
            .foregroundStyle(isActive ? CartoMixColors.accentBlue : CartoMixColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = CartoMixColors.accentBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? color.opacity(0.8) : color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }
}

// MARK: - Secondary Button Style

struct SecondaryButtonStyle: ButtonStyle {
    var color: Color = CartoMixColors.textSecondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(configuration.isPressed ? color.opacity(0.15) : color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CartoMixRadius.md)
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
    }
}
