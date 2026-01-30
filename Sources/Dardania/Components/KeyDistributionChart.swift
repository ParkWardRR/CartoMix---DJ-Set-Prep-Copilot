// KeyDistributionChart - Colorful bar chart using Camelot colors

import SwiftUI

struct KeyDistributionChart: View {
    let distribution: [String: Int]
    var maxHeight: CGFloat = 100
    var showLabels: Bool = true

    // All Camelot keys in order
    static let camelotOrder = [
        "1A", "1B", "2A", "2B", "3A", "3B", "4A", "4B",
        "5A", "5B", "6A", "6B", "7A", "7B", "8A", "8B",
        "9A", "9B", "10A", "10B", "11A", "11B", "12A", "12B"
    ]

    var maxCount: Int {
        distribution.values.max() ?? 1
    }

    var body: some View {
        VStack(spacing: CartoMixSpacing.sm) {
            // Chart
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(Self.camelotOrder, id: \.self) { key in
                    let count = distribution[key] ?? 0
                    let height = maxCount > 0 ?
                        CGFloat(count) / CGFloat(maxCount) * maxHeight : 0

                    VStack(spacing: 2) {
                        // Bar
                        RoundedRectangle(cornerRadius: 2)
                            .fill(CartoMixColors.colorForKey(key))
                            .frame(height: max(height, count > 0 ? 4 : 0))
                            .animation(.spring(duration: 0.3), value: count)

                        // Count label (if non-zero and labels enabled)
                        if showLabels && count > 0 {
                            Text("\(count)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(CartoMixColors.textSecondary)
                        }
                    }
                }
            }
            .frame(height: maxHeight + (showLabels ? 16 : 0))

            // Key labels
            if showLabels {
                HStack(spacing: 2) {
                    ForEach(Self.camelotOrder, id: \.self) { key in
                        Text(key)
                            .font(.system(size: 6, weight: .medium))
                            .foregroundStyle(CartoMixColors.textTertiary)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
        }
        .padding(CartoMixSpacing.sm)
        .background(CartoMixColors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))
    }
}

// MARK: - Compact Key Distribution (horizontal bars)

struct CompactKeyDistribution: View {
    let distribution: [String: Int]
    var topN: Int = 5

    var sortedKeys: [(key: String, count: Int)] {
        distribution
            .sorted { $0.value > $1.value }
            .prefix(topN)
            .map { (key: $0.key, count: $0.value) }
    }

    var maxCount: Int {
        sortedKeys.first?.count ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CartoMixSpacing.xs) {
            ForEach(sortedKeys, id: \.key) { item in
                HStack(spacing: CartoMixSpacing.sm) {
                    // Key badge
                    Text(item.key)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(CartoMixColors.colorForKey(item.key))
                        .frame(width: 28, alignment: .trailing)

                    // Bar
                    GeometryReader { geometry in
                        let width = geometry.size.width * CGFloat(item.count) / CGFloat(maxCount)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(CartoMixColors.colorForKey(item.key).opacity(0.6))
                            .frame(width: width)
                    }

                    // Count
                    Text("\(item.count)")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(CartoMixColors.textSecondary)
                        .frame(width: 24, alignment: .trailing)
                }
                .frame(height: 12)
            }
        }
    }
}

// MARK: - Camelot Wheel View

struct CamelotWheelView: View {
    let highlightedKeys: Set<String>
    var size: CGFloat = 120

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let outerRadius = min(canvasSize.width, canvasSize.height) / 2 - 4
            let innerRadius = outerRadius * 0.5
            let segmentAngle = CGFloat.pi * 2 / 12

            // Draw segments
            for i in 0..<12 {
                let startAngle = CGFloat(i) * segmentAngle - CGFloat.pi / 2
                let endAngle = startAngle + segmentAngle

                let keyA = "\(i + 1)A"
                let keyB = "\(i + 1)B"

                // Outer ring (B keys - major)
                var outerPath = Path()
                outerPath.move(to: pointOnCircle(center: center, radius: innerRadius + (outerRadius - innerRadius) / 2, angle: startAngle))
                outerPath.addArc(center: center, radius: outerRadius, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: false)
                outerPath.addLine(to: pointOnCircle(center: center, radius: innerRadius + (outerRadius - innerRadius) / 2, angle: endAngle))
                outerPath.addArc(center: center, radius: innerRadius + (outerRadius - innerRadius) / 2, startAngle: Angle(radians: endAngle), endAngle: Angle(radians: startAngle), clockwise: true)
                outerPath.closeSubpath()

                let outerOpacity = highlightedKeys.contains(keyB) ? 1.0 : 0.3
                context.fill(outerPath, with: .color(CartoMixColors.colorForKey(keyB).opacity(outerOpacity)))

                // Inner ring (A keys - minor)
                var innerPath = Path()
                innerPath.move(to: pointOnCircle(center: center, radius: innerRadius, angle: startAngle))
                innerPath.addArc(center: center, radius: innerRadius + (outerRadius - innerRadius) / 2, startAngle: Angle(radians: startAngle), endAngle: Angle(radians: endAngle), clockwise: false)
                innerPath.addLine(to: pointOnCircle(center: center, radius: innerRadius, angle: endAngle))
                innerPath.addArc(center: center, radius: innerRadius, startAngle: Angle(radians: endAngle), endAngle: Angle(radians: startAngle), clockwise: true)
                innerPath.closeSubpath()

                let innerOpacity = highlightedKeys.contains(keyA) ? 1.0 : 0.3
                context.fill(innerPath, with: .color(CartoMixColors.colorForKey(keyA).opacity(innerOpacity)))

                // Key labels
                let labelRadius = innerRadius + (outerRadius - innerRadius) * 0.75
                let labelAngle = startAngle + segmentAngle / 2
                let labelPoint = pointOnCircle(center: center, radius: labelRadius, angle: labelAngle)

                context.draw(
                    Text("\(i + 1)B")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white),
                    at: labelPoint
                )

                let innerLabelRadius = innerRadius + (outerRadius - innerRadius) * 0.25
                let innerLabelPoint = pointOnCircle(center: center, radius: innerLabelRadius, angle: labelAngle)

                context.draw(
                    Text("\(i + 1)A")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white),
                    at: innerLabelPoint
                )
            }
        }
        .frame(width: size, height: size)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

// MARK: - Preview

#Preview {
    let mockDistribution: [String: Int] = [
        "8A": 12, "9A": 8, "7A": 6, "8B": 5, "10A": 4,
        "6A": 3, "9B": 3, "7B": 2, "5A": 2, "11A": 1
    ]

    VStack(spacing: 24) {
        Text("Key Distribution Chart")
            .font(.headline)
            .foregroundStyle(.white)

        KeyDistributionChart(distribution: mockDistribution)
            .frame(height: 150)

        Divider()

        Text("Compact Distribution")
            .font(.headline)
            .foregroundStyle(.white)

        CompactKeyDistribution(distribution: mockDistribution)
            .frame(width: 200)
            .padding()
            .background(CartoMixColors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))

        Divider()

        Text("Camelot Wheel")
            .font(.headline)
            .foregroundStyle(.white)

        CamelotWheelView(
            highlightedKeys: Set(["8A", "9A", "8B"]),
            size: 150
        )
    }
    .padding()
    .background(CartoMixColors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
