// GradientWaveformView - High-impact colorful waveform with section overlays

import SwiftUI

struct GradientWaveformView: View {
    let samples: [Float]
    var sections: [WaveformSection] = []
    var cuePoints: [WaveformCuePoint] = []
    var duration: Double = 0
    var playheadPosition: Double? = nil
    var onSeek: ((Double) -> Void)? = nil

    @State private var hoveredPosition: CGFloat? = nil

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: CartoMixRadius.md)
                    .fill(CartoMixColors.backgroundTertiary)

                // Canvas for waveform
                Canvas { context, canvasSize in
                    drawSections(context: context, size: canvasSize)
                    drawWaveform(context: context, size: canvasSize)
                    drawCuePoints(context: context, size: canvasSize)
                    drawPlayhead(context: context, size: canvasSize)
                }
                .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.md))

                // Hover indicator
                if let hovered = hoveredPosition {
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 1)
                        .position(x: hovered, y: size.height / 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        hoveredPosition = value.location.x
                    }
                    .onEnded { value in
                        if let onSeek, duration > 0 {
                            let position = value.location.x / size.width
                            onSeek(position * duration)
                        }
                        hoveredPosition = nil
                    }
            )
            .onHover { hovering in
                if !hovering {
                    hoveredPosition = nil
                }
            }
        }
    }

    // MARK: - Drawing Functions

    private func drawSections(context: GraphicsContext, size: CGSize) {
        guard duration > 0, !sections.isEmpty else { return }

        for section in sections {
            let startX = CGFloat(section.startTime / duration) * size.width
            let endX = CGFloat(section.endTime / duration) * size.width
            let rect = CGRect(x: startX, y: 0, width: endX - startX, height: size.height)

            context.fill(
                Path(rect),
                with: .color(section.color.opacity(0.15))
            )
        }
    }

    private func drawWaveform(context: GraphicsContext, size: CGSize) {
        guard !samples.isEmpty else { return }

        let midY = size.height / 2
        let maxAmplitude = size.height / 2 - 4

        // Downsample to one point per 2 pixels for performance
        let targetPoints = Int(size.width / 2)
        let samplesPerPoint = max(1, samples.count / targetPoints)

        var path = Path()
        var points: [CGPoint] = []

        for i in 0..<targetPoints {
            let startIdx = i * samplesPerPoint
            let endIdx = min(startIdx + samplesPerPoint, samples.count)

            if startIdx >= samples.count { break }

            // Get max amplitude in this window
            var maxVal: Float = 0
            for j in startIdx..<endIdx {
                maxVal = max(maxVal, abs(samples[j]))
            }

            let x = CGFloat(i) / CGFloat(targetPoints) * size.width
            let amplitude = CGFloat(maxVal) * maxAmplitude

            points.append(CGPoint(x: x, y: midY - amplitude))
        }

        // Draw upper half
        if let first = points.first {
            path.move(to: CGPoint(x: first.x, y: midY))
            for point in points {
                path.addLine(to: point)
            }
        }

        // Draw lower half (mirrored)
        for point in points.reversed() {
            let mirroredY = midY + (midY - point.y)
            path.addLine(to: CGPoint(x: point.x, y: mirroredY))
        }

        path.closeSubpath()

        // Fill with gradient
        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [
                    Color(hex: "#64D2FF"),
                    Color(hex: "#0A84FF"),
                    Color(hex: "#BF5AF2"),
                    Color(hex: "#FF375F")
                ]),
                startPoint: CGPoint(x: 0, y: size.height / 2),
                endPoint: CGPoint(x: size.width, y: size.height / 2)
            )
        )
    }

    private func drawCuePoints(context: GraphicsContext, size: CGSize) {
        guard duration > 0 else { return }

        for cue in cuePoints {
            let x = CGFloat(cue.time / duration) * size.width

            // Vertical line
            var linePath = Path()
            linePath.move(to: CGPoint(x: x, y: 0))
            linePath.addLine(to: CGPoint(x: x, y: size.height))

            context.stroke(
                linePath,
                with: .color(cue.color),
                lineWidth: 2
            )

            // Cue marker triangle at top
            var markerPath = Path()
            markerPath.move(to: CGPoint(x: x, y: 0))
            markerPath.addLine(to: CGPoint(x: x - 5, y: 8))
            markerPath.addLine(to: CGPoint(x: x + 5, y: 8))
            markerPath.closeSubpath()

            context.fill(markerPath, with: .color(cue.color))
        }
    }

    private func drawPlayhead(context: GraphicsContext, size: CGSize) {
        guard let position = playheadPosition, duration > 0 else { return }

        let x = CGFloat(position / duration) * size.width

        // Playhead line
        var path = Path()
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: size.height))

        context.stroke(
            path,
            with: .color(.white),
            lineWidth: 2
        )

        // Glow effect
        context.stroke(
            path,
            with: .color(.white.opacity(0.5)),
            lineWidth: 6
        )
    }
}

// MARK: - Supporting Types

struct WaveformSection: Identifiable {
    let id = UUID()
    let type: String
    let startTime: Double
    let endTime: Double

    var color: Color {
        CartoMixColors.colorForSection(type)
    }
}

struct WaveformCuePoint: Identifiable {
    let id = UUID()
    let label: String
    let time: Double
    let type: String

    var color: Color {
        switch type.lowercased() {
        case "hotcue", "hot_cue": return CartoMixColors.accentGreen
        case "loop": return CartoMixColors.accentOrange
        case "fade_in": return CartoMixColors.accentCyan
        case "fade_out": return CartoMixColors.accentPurple
        case "load": return CartoMixColors.accentBlue
        default: return CartoMixColors.accentYellow
        }
    }
}

// MARK: - Compact Waveform (for track rows)

struct CompactWaveformView: View {
    let samples: [Float]
    var sections: [WaveformSection] = []
    var height: CGFloat = 32

    var body: some View {
        Canvas { context, size in
            // Draw sections
            if !sections.isEmpty {
                for section in sections {
                    let total = sections.reduce(0.0) { $0 + ($1.endTime - $1.startTime) }
                    guard total > 0 else { continue }

                    var currentX: CGFloat = 0
                    for s in sections {
                        let width = CGFloat((s.endTime - s.startTime) / total) * size.width
                        if s.id == section.id {
                            let rect = CGRect(x: currentX, y: 0, width: width, height: size.height)
                            context.fill(Path(rect), with: .color(s.color.opacity(0.2)))
                        }
                        currentX += width
                    }
                }
            }

            // Draw waveform
            guard !samples.isEmpty else { return }

            let midY = size.height / 2
            let maxAmplitude = size.height / 2 - 2
            let pointCount = min(samples.count, Int(size.width))
            let samplesPerPoint = max(1, samples.count / pointCount)

            var path = Path()
            var points: [CGPoint] = []

            for i in 0..<pointCount {
                let startIdx = i * samplesPerPoint
                let endIdx = min(startIdx + samplesPerPoint, samples.count)
                if startIdx >= samples.count { break }

                var maxVal: Float = 0
                for j in startIdx..<endIdx {
                    maxVal = max(maxVal, abs(samples[j]))
                }

                let x = CGFloat(i) / CGFloat(pointCount) * size.width
                let amplitude = CGFloat(maxVal) * maxAmplitude
                points.append(CGPoint(x: x, y: midY - amplitude))
            }

            if let first = points.first {
                path.move(to: CGPoint(x: first.x, y: midY))
                for point in points {
                    path.addLine(to: point)
                }
            }

            for point in points.reversed() {
                let mirroredY = midY + (midY - point.y)
                path.addLine(to: CGPoint(x: point.x, y: mirroredY))
            }

            path.closeSubpath()

            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(hex: "#64D2FF").opacity(0.8),
                        Color(hex: "#0A84FF").opacity(0.6),
                        Color(hex: "#BF5AF2").opacity(0.4)
                    ]),
                    startPoint: CGPoint(x: 0, y: size.height / 2),
                    endPoint: CGPoint(x: size.width, y: size.height / 2)
                )
            )
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: CartoMixRadius.sm))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Gradient Waveform")
            .font(.headline)
            .foregroundStyle(.white)

        // Generate mock waveform data
        let mockSamples: [Float] = (0..<500).map { i in
            let t = Float(i) / 500
            return sin(t * 20) * (0.3 + 0.7 * sin(t * 3)) * Float.random(in: 0.8...1.0)
        }

        let mockSections: [WaveformSection] = [
            WaveformSection(type: "intro", startTime: 0, endTime: 30),
            WaveformSection(type: "build", startTime: 30, endTime: 60),
            WaveformSection(type: "drop", startTime: 60, endTime: 120),
            WaveformSection(type: "breakdown", startTime: 120, endTime: 150),
            WaveformSection(type: "drop", startTime: 150, endTime: 210),
            WaveformSection(type: "outro", startTime: 210, endTime: 240)
        ]

        let mockCues: [WaveformCuePoint] = [
            WaveformCuePoint(label: "CUE 1", time: 30, type: "hotcue"),
            WaveformCuePoint(label: "DROP", time: 60, type: "hotcue"),
            WaveformCuePoint(label: "MIX OUT", time: 210, type: "fade_out")
        ]

        GradientWaveformView(
            samples: mockSamples,
            sections: mockSections,
            cuePoints: mockCues,
            duration: 240,
            playheadPosition: 90
        )
        .frame(height: 120)

        Divider()

        Text("Compact Waveform")
            .font(.headline)
            .foregroundStyle(.white)

        CompactWaveformView(
            samples: mockSamples,
            sections: mockSections
        )
    }
    .padding()
    .background(CartoMixColors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
