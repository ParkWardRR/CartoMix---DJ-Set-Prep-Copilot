// CartoMix - Waveform View with Label Painting
// Interactive waveform visualization for section labeling

import SwiftUI
import DardaniaCore

struct WaveformView: View {
    let track: Track
    let waveformData: [Float]
    @Binding var sections: [TrackSection]
    @Binding var playheadPosition: Double

    @State private var isLabeling = false
    @State private var labelStart: Double?
    @State private var selectedLabelType: SectionType = .verse
    @State private var hoveredPosition: Double?
    @State private var zoomLevel: Double = 1.0
    @State private var scrollOffset: Double = 0.0

    private let waveformHeight: CGFloat = 120
    private let sectionColors: [SectionType: Color] = [
        .intro: .green.opacity(0.6),
        .verse: .blue.opacity(0.6),
        .chorus: .purple.opacity(0.6),
        .bridge: .orange.opacity(0.6),
        .drop: .red.opacity(0.6),
        .breakdown: .cyan.opacity(0.6),
        .build: .yellow.opacity(0.6),
        .outro: .gray.opacity(0.6)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            waveformToolbar

            // Main waveform area
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.black.opacity(0.9))

                    // Section overlays
                    ForEach(sections) { section in
                        sectionOverlay(section: section, in: geometry)
                    }

                    // Waveform
                    waveformPath(in: geometry)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )

                    // Label painting overlay
                    if isLabeling, let start = labelStart {
                        labelPaintingOverlay(start: start, in: geometry)
                    }

                    // Playhead
                    playheadMarker(in: geometry)

                    // Hover position indicator
                    if let hovered = hoveredPosition {
                        hoverIndicator(position: hovered, in: geometry)
                    }

                    // Time markers
                    timeMarkers(in: geometry)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDrag(value: value, in: geometry)
                        }
                        .onEnded { value in
                            handleDragEnd(value: value, in: geometry)
                        }
                )
                .onHover { hovering in
                    if !hovering {
                        hoveredPosition = nil
                    }
                }
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        hoveredPosition = location.x / geometry.size.width
                    case .ended:
                        hoveredPosition = nil
                    }
                }
            }
            .frame(height: waveformHeight)

            // Section legend
            sectionLegend
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Toolbar

    private var waveformToolbar: some View {
        HStack {
            Text("Waveform")
                .font(.headline)

            Spacer()

            // Zoom controls
            HStack(spacing: 8) {
                Button {
                    withAnimation { zoomLevel = max(0.5, zoomLevel - 0.25) }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.plain)

                Text("\(Int(zoomLevel * 100))%")
                    .font(.caption.monospacedDigit())
                    .frame(width: 40)

                Button {
                    withAnimation { zoomLevel = min(4.0, zoomLevel + 0.25) }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.plain)
            }

            Divider()
                .frame(height: 16)

            // Label mode toggle
            Toggle(isOn: $isLabeling) {
                Label("Paint Labels", systemImage: "paintbrush.fill")
            }
            .toggleStyle(.button)
            .tint(isLabeling ? .accentColor : nil)

            if isLabeling {
                Picker("Label Type", selection: $selectedLabelType) {
                    ForEach(SectionType.allCases, id: \.self) { type in
                        Text(type.displayName)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Waveform Path

    private func waveformPath(in geometry: GeometryProxy) -> Path {
        Path { path in
            guard !waveformData.isEmpty else { return }

            let width = geometry.size.width * zoomLevel
            let height = geometry.size.height
            let midY = height / 2

            let samplesPerPixel = max(1, waveformData.count / Int(width))
            let pixelCount = min(Int(width), waveformData.count)

            path.move(to: CGPoint(x: 0, y: midY))

            for i in 0..<pixelCount {
                let sampleIndex = min(i * samplesPerPixel, waveformData.count - 1)
                let sample = waveformData[sampleIndex]
                let x = CGFloat(i)
                let amplitude = CGFloat(sample) * (height / 2) * 0.9

                // Draw upper half
                path.addLine(to: CGPoint(x: x, y: midY - amplitude))
            }

            // Draw back along bottom
            for i in stride(from: pixelCount - 1, through: 0, by: -1) {
                let sampleIndex = min(i * samplesPerPixel, waveformData.count - 1)
                let sample = waveformData[sampleIndex]
                let x = CGFloat(i)
                let amplitude = CGFloat(sample) * (height / 2) * 0.9

                path.addLine(to: CGPoint(x: x, y: midY + amplitude))
            }

            path.closeSubpath()
        }
    }

    // MARK: - Section Overlay

    private func sectionOverlay(section: TrackSection, in geometry: GeometryProxy) -> some View {
        let duration = track.analysis?.durationSeconds ?? 1
        let startX = (section.startTime / duration) * geometry.size.width
        let endX = (section.endTime / duration) * geometry.size.width
        let width = endX - startX

        return Rectangle()
            .fill(sectionColors[section.type] ?? .gray.opacity(0.3))
            .frame(width: max(2, width))
            .offset(x: startX)
            .overlay(alignment: .topLeading) {
                if width > 40 {
                    Text(section.type.displayName)
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(2)
                        .background(.black.opacity(0.5))
                        .cornerRadius(2)
                        .offset(x: startX + 2, y: 2)
                }
            }
    }

    // MARK: - Playhead

    private func playheadMarker(in geometry: GeometryProxy) -> some View {
        let x = playheadPosition * geometry.size.width

        return Rectangle()
            .fill(Color.white)
            .frame(width: 2)
            .offset(x: x)
            .shadow(color: .white.opacity(0.5), radius: 2)
    }

    // MARK: - Hover Indicator

    private func hoverIndicator(position: Double, in geometry: GeometryProxy) -> some View {
        let x = position * geometry.size.width
        let duration = track.analysis?.durationSeconds ?? 0
        let timeAtPosition = position * duration

        return VStack(spacing: 0) {
            Text(formatTime(timeAtPosition))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(.black.opacity(0.8))
                .cornerRadius(4)

            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 1)
        }
        .offset(x: x)
    }

    // MARK: - Label Painting Overlay

    private func labelPaintingOverlay(start: Double, in geometry: GeometryProxy) -> some View {
        let currentPosition = hoveredPosition ?? start
        let minX = min(start, currentPosition) * geometry.size.width
        let maxX = max(start, currentPosition) * geometry.size.width
        let width = maxX - minX

        return Rectangle()
            .fill(sectionColors[selectedLabelType]?.opacity(0.5) ?? .white.opacity(0.3))
            .frame(width: max(2, width))
            .offset(x: minX)
            .overlay(
                Rectangle()
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .frame(width: max(2, width))
                    .offset(x: minX)
            )
    }

    // MARK: - Time Markers

    private func timeMarkers(in geometry: GeometryProxy) -> some View {
        let duration = track.analysis?.durationSeconds ?? 0
        let interval: Double = duration > 300 ? 60 : (duration > 120 ? 30 : 10)
        let markerCount = Int(duration / interval)

        return ZStack(alignment: .bottom) {
            ForEach(0..<markerCount, id: \.self) { i in
                let time = Double(i + 1) * interval
                let x = (time / duration) * geometry.size.width

                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 8)
                    Text(formatTime(time))
                        .font(.system(size: 8).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))
                }
                .offset(x: x)
            }
        }
    }

    // MARK: - Section Legend

    private var sectionLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SectionType.allCases, id: \.self) { type in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(sectionColors[type] ?? .gray)
                            .frame(width: 8, height: 8)
                        Text(type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Gestures

    private func handleDrag(value: DragGesture.Value, in geometry: GeometryProxy) {
        if isLabeling {
            if labelStart == nil {
                labelStart = value.startLocation.x / geometry.size.width
            }
            hoveredPosition = value.location.x / geometry.size.width
        } else {
            // Seek to position
            playheadPosition = max(0, min(1, value.location.x / geometry.size.width))
        }
    }

    private func handleDragEnd(value: DragGesture.Value, in geometry: GeometryProxy) {
        if isLabeling, let start = labelStart {
            let end = value.location.x / geometry.size.width
            let duration = track.analysis?.durationSeconds ?? 0

            let startTime = min(start, end) * duration
            let endTime = max(start, end) * duration

            // Only create section if it's at least 1 second
            if endTime - startTime >= 1.0 {
                let newSection = TrackSection(
                    id: UUID(),
                    type: selectedLabelType,
                    startTime: startTime,
                    endTime: endTime,
                    confidence: 1.0 // User-created
                )
                sections.append(newSection)
            }

            labelStart = nil
        }
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Section Type

enum SectionType: String, CaseIterable, Codable {
    case intro
    case verse
    case chorus
    case bridge
    case drop
    case breakdown
    case build
    case outro

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Track Section

struct TrackSection: Identifiable, Codable {
    let id: UUID
    var type: SectionType
    var startTime: Double
    var endTime: Double
    var confidence: Double

    var duration: Double {
        endTime - startTime
    }
}

// MARK: - Preview

#if DEBUG
struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        WaveformView(
            track: Track.preview,
            waveformData: (0..<1000).map { _ in Float.random(in: 0...1) },
            sections: .constant([]),
            playheadPosition: .constant(0.3)
        )
        .frame(height: 200)
        .padding()
    }
}
#endif
