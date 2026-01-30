// EnergyJourneyView - Line chart showing set energy progression

import SwiftUI

struct EnergyJourneyView: View {
    let tracks: [EnergyTrackData]
    var showLabels: Bool = true
    var showGrid: Bool = true

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let padding: CGFloat = showLabels ? 40 : 16
            let graphWidth = size.width - padding * 2
            let graphHeight = size.height - padding * 2

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: CartoMixRadius.md)
                    .fill(CartoMixColors.backgroundTertiary)

                // Grid lines
                if showGrid {
                    GridLines(
                        width: graphWidth,
                        height: graphHeight,
                        horizontalLines: 5,
                        verticalLines: max(tracks.count - 1, 1)
                    )
                    .offset(x: padding, y: padding)
                }

                // Energy curve
                Canvas { context, canvasSize in
                    guard tracks.count >= 2 else { return }

                    let stepX = graphWidth / CGFloat(tracks.count - 1)

                    // Build curve path
                    var curvePath = Path()
                    var fillPath = Path()

                    for (index, track) in tracks.enumerated() {
                        let x = padding + CGFloat(index) * stepX
                        let energyNormalized = CGFloat(track.energy) / 10.0
                        let y = padding + graphHeight * (1 - energyNormalized)

                        if index == 0 {
                            curvePath.move(to: CGPoint(x: x, y: y))
                            fillPath.move(to: CGPoint(x: x, y: padding + graphHeight))
                            fillPath.addLine(to: CGPoint(x: x, y: y))
                        } else {
                            // Smooth curve using quadratic bezier
                            let prevX = padding + CGFloat(index - 1) * stepX
                            let controlX = (prevX + x) / 2
                            curvePath.addQuadCurve(
                                to: CGPoint(x: x, y: y),
                                control: CGPoint(x: controlX, y: y)
                            )
                            fillPath.addQuadCurve(
                                to: CGPoint(x: x, y: y),
                                control: CGPoint(x: controlX, y: y)
                            )
                        }
                    }

                    // Close fill path
                    fillPath.addLine(to: CGPoint(x: padding + graphWidth, y: padding + graphHeight))
                    fillPath.closeSubpath()

                    // Draw fill gradient
                    context.fill(
                        fillPath,
                        with: .linearGradient(
                            Gradient(colors: [
                                CartoMixColors.accentOrange.opacity(0.4),
                                CartoMixColors.accentRed.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: CGPoint(x: size.width / 2, y: padding),
                            endPoint: CGPoint(x: size.width / 2, y: padding + graphHeight)
                        )
                    )

                    // Draw curve stroke
                    context.stroke(
                        curvePath,
                        with: .linearGradient(
                            Gradient(colors: [
                                CartoMixColors.accentOrange,
                                CartoMixColors.accentRed,
                                CartoMixColors.accentPurple
                            ]),
                            startPoint: CGPoint(x: padding, y: size.height / 2),
                            endPoint: CGPoint(x: padding + graphWidth, y: size.height / 2)
                        ),
                        lineWidth: 3
                    )

                    // Draw data points
                    for (index, track) in tracks.enumerated() {
                        let x = padding + CGFloat(index) * stepX
                        let energyNormalized = CGFloat(track.energy) / 10.0
                        let y = padding + graphHeight * (1 - energyNormalized)

                        // Glow
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - 8, y: y - 8, width: 16, height: 16)),
                            with: .color(CartoMixColors.accentOrange.opacity(0.3))
                        )

                        // Point
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - 5, y: y - 5, width: 10, height: 10)),
                            with: .color(CartoMixColors.accentOrange)
                        )

                        // Inner highlight
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4)),
                            with: .color(.white)
                        )
                    }
                }

                // Y-axis labels
                if showLabels {
                    VStack {
                        Text("10")
                        Spacer()
                        Text("5")
                        Spacer()
                        Text("0")
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(CartoMixColors.textSecondary)
                    .frame(width: 20)
                    .padding(.vertical, padding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                }

                // Legend
                HStack(spacing: 4) {
                    Text("Low")
                        .foregroundStyle(CartoMixColors.accentOrange)
                    Text("—")
                        .foregroundStyle(CartoMixColors.textTertiary)
                    Text("Mid")
                        .foregroundStyle(CartoMixColors.accentRed)
                    Text("—")
                        .foregroundStyle(CartoMixColors.textTertiary)
                    Text("Peak")
                        .foregroundStyle(CartoMixColors.accentPurple)
                }
                .font(.system(size: 10, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(CartoMixSpacing.sm)
            }
        }
    }
}

// MARK: - Grid Lines

struct GridLines: View {
    let width: CGFloat
    let height: CGFloat
    let horizontalLines: Int
    let verticalLines: Int

    var body: some View {
        Canvas { context, size in
            let lineColor = CartoMixColors.textTertiary.opacity(0.3)

            // Horizontal lines
            for i in 0...horizontalLines {
                let y = CGFloat(i) / CGFloat(horizontalLines) * height
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }

            // Vertical lines
            for i in 0...verticalLines {
                let x = CGFloat(i) / CGFloat(verticalLines) * width
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
                context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Supporting Types

struct EnergyTrackData: Identifiable {
    let id = UUID()
    let title: String
    let energy: Int
    let bpm: Double
    let key: String
}

// MARK: - Mini Energy Bar (for track rows)

struct MiniEnergyBar: View {
    let energy: Int
    var maxEnergy: Int = 10
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geometry in
            let fillWidth = geometry.size.width * CGFloat(energy) / CGFloat(maxEnergy)

            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(CartoMixColors.backgroundTertiary)

                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: energyGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: fillWidth)
            }
        }
        .frame(height: height)
    }

    var energyGradientColors: [Color] {
        if energy <= 3 {
            return [CartoMixColors.accentGreen, CartoMixColors.accentCyan]
        } else if energy <= 6 {
            return [CartoMixColors.accentYellow, CartoMixColors.accentOrange]
        } else {
            return [CartoMixColors.accentOrange, CartoMixColors.accentRed]
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Energy Journey")
            .font(.headline)
            .foregroundStyle(.white)

        EnergyJourneyView(tracks: [
            EnergyTrackData(title: "Ambient Drift", energy: 3, bpm: 110, key: "6A"),
            EnergyTrackData(title: "Cascade Flow", energy: 5, bpm: 118, key: "7A"),
            EnergyTrackData(title: "Neon Bridge", energy: 6, bpm: 122, key: "8A"),
            EnergyTrackData(title: "Twilight Zone", energy: 7, bpm: 126, key: "8A"),
            EnergyTrackData(title: "Berghain Sunrise", energy: 9, bpm: 130, key: "9A"),
            EnergyTrackData(title: "Chrome Echo", energy: 8, bpm: 128, key: "9A"),
            EnergyTrackData(title: "Pulse Drive", energy: 6, bpm: 124, key: "8A"),
            EnergyTrackData(title: "Neon Rush", energy: 4, bpm: 118, key: "7A")
        ])
        .frame(height: 150)

        Divider()

        Text("Mini Energy Bars")
            .font(.headline)
            .foregroundStyle(.white)

        VStack(spacing: 8) {
            ForEach([2, 4, 6, 8, 10], id: \.self) { energy in
                HStack {
                    Text("Energy \(energy)")
                        .font(.caption)
                        .foregroundStyle(CartoMixColors.textSecondary)
                        .frame(width: 60, alignment: .trailing)
                    MiniEnergyBar(energy: energy)
                }
            }
        }
        .frame(width: 200)
    }
    .padding()
    .background(CartoMixColors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
