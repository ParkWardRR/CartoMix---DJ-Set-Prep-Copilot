// Dardania - Main Content View

import SwiftUI
import DardaniaCore

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } content: {
            switch appState.selectedTab {
            case .library:
                LibraryView()
            case .setBuilder:
                SetBuilderView()
            case .graph:
                TransitionGraphView()
            case .training:
                TrainingView()
            }
        } detail: {
            if let track = appState.selectedTrack {
                TrackDetailView(track: track)
            } else {
                EmptyStateView(
                    icon: "music.note",
                    title: "No Track Selected",
                    subtitle: "Select a track from your library to view details"
                )
            }
        }
        .navigationSplitViewStyle(.prominentDetail)
        .preferredColorScheme(appState.isDarkMode ? .dark : .light)
        .overlay(alignment: .bottom) {
            if appState.isScanning {
                ScanProgressBar(progress: appState.scanProgress)
            }
        }
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(selection: $appState.selectedTab) {
            Section("Views") {
                ForEach(NavigationTab.allCases, id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                        .foregroundStyle(appState.selectedTab == tab ? CartoMixColors.accentBlue : CartoMixColors.textPrimary)
                }
            }

            Section("Library") {
                Label("\(appState.tracks.count) Tracks", systemImage: "music.note.list")
                    .foregroundStyle(CartoMixColors.textSecondary)

                if !appState.setTracks.isEmpty {
                    Label("\(appState.setTracks.count) in Set", systemImage: "list.bullet.rectangle")
                        .foregroundStyle(CartoMixColors.accentGreen)
                }
            }

            Section("Quick Stats") {
                let analyzedCount = appState.tracks.filter { $0.analysis != nil }.count
                HStack {
                    Text("Analyzed")
                        .foregroundStyle(CartoMixColors.textSecondary)
                    Spacer()
                    Text("\(analyzedCount)/\(appState.tracks.count)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(CartoMixColors.textTertiary)
                }

                if let avgBPM = averageBPM {
                    HStack {
                        Text("Avg BPM")
                            .foregroundStyle(CartoMixColors.textSecondary)
                        Spacer()
                        Text(String(format: "%.1f", avgBPM))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(CartoMixColors.accentBlue)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    appState.isDarkMode.toggle()
                } label: {
                    Image(systemName: appState.isDarkMode ? "sun.max.fill" : "moon.fill")
                        .foregroundStyle(CartoMixColors.accentYellow)
                }
                .help("Toggle Theme")
            }
        }
    }

    private var averageBPM: Double? {
        let bpms = appState.tracks.compactMap { $0.analysis?.bpm }
        guard !bpms.isEmpty else { return nil }
        return bpms.reduce(0, +) / Double(bpms.count)
    }
}

extension NavigationTab {
    var icon: String {
        switch self {
        case .library: return "square.grid.2x2"
        case .setBuilder: return "rectangle.stack"
        case .graph: return "point.3.connected.trianglepath.dotted"
        case .training: return "brain"
        }
    }
}

// MARK: - Scan Progress

struct ScanProgressBar: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(CartoMixColors.accentCyan)
                Text("Scanning library...")
                    .font(CartoMixTypography.body)
                    .foregroundStyle(CartoMixColors.textPrimary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(CartoMixColors.textSecondary)
            }

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(CartoMixColors.accentCyan)
        }
        .padding(CartoMixSpacing.md)
        .background(CartoMixColors.backgroundSecondary, in: RoundedRectangle(cornerRadius: CartoMixRadius.md))
        .padding(CartoMixSpacing.md)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: CartoMixSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(CartoMixColors.textTertiary)

            Text(title)
                .font(CartoMixTypography.headline)
                .foregroundStyle(CartoMixColors.textPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(CartoMixTypography.body)
                .foregroundStyle(CartoMixColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(CartoMixSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CartoMixColors.backgroundPrimary)
    }
}

// Preview commented out for SPM compatibility
// #Preview {
//     ContentView()
//         .environmentObject(AppState())
//         .frame(width: 1200, height: 800)
// }
