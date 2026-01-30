// Dardania - 100% macOS Native DJ Set Prep Copilot
// SwiftUI App Entry Point

import SwiftUI
import DardaniaCore
import Logging

@main
struct DardaniaApp: App {
    @StateObject private var appState = AppState()

    init() {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .info
            return handler
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Music Folder...") {
                    appState.addMusicFolder()
                }
                .keyboardShortcut("o", modifiers: [.command])

                Button("Scan Library") {
                    Task {
                        await appState.scanLibrary()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command])
            }

            CommandGroup(after: .sidebar) {
                Button("Library") {
                    appState.selectedTab = .library
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Set Builder") {
                    appState.selectedTab = .setBuilder
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Graph View") {
                    appState.selectedTab = .graph
                }
                .keyboardShortcut("3", modifiers: [.command])
            }

            CommandGroup(replacing: .help) {
                Button("CartoMix Help") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/cartomix/cartomix")!)
                }
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: NavigationTab = .library
    @Published var tracks: [Track] = []
    @Published var selectedTrack: Track?
    @Published var setTracks: [Track] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var analysisProgress: AnalysisProgress?
    @Published var errorMessage: String?
    @Published var isDarkMode = true

    private let database: DatabaseManager
    private let analyzer: AnalyzerService
    private let logger = Logger(label: "com.dardania.app")

    init() {
        do {
            self.database = try DatabaseManager.shared
            self.analyzer = AnalyzerService(database: database)
            Task {
                await loadTracks()
            }
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
    }

    func loadTracks() async {
        do {
            let loadedTracks = try await database.fetchAllTracks()
            await MainActor.run {
                self.tracks = loadedTracks
            }
        } catch {
            logger.error("Failed to load tracks: \(error)")
        }
    }

    func addMusicFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.message = "Select music folders to scan"
        panel.prompt = "Add"

        if panel.runModal() == .OK {
            for url in panel.urls {
                Task {
                    do {
                        try await database.addMusicLocation(url: url)
                        await scanLibrary()
                    } catch {
                        await MainActor.run {
                            self.errorMessage = "Failed to add folder: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }

    func scanLibrary() async {
        await MainActor.run {
            isScanning = true
            scanProgress = 0
        }

        do {
            let locations = try await database.fetchMusicLocations()
            for location in locations {
                try await analyzer.scanDirectory(
                    url: location.url,
                    progress: { progress in
                        Task { @MainActor in
                            self.scanProgress = progress
                        }
                    }
                )
            }
            await loadTracks()
        } catch {
            logger.error("Scan failed: \(error)")
            await MainActor.run {
                self.errorMessage = "Scan failed: \(error.localizedDescription)"
            }
        }

        await MainActor.run {
            isScanning = false
        }
    }

    func analyzeTrack(_ track: Track) async {
        do {
            try await analyzer.analyzeTrack(
                track: track,
                progress: { progress in
                    Task { @MainActor in
                        self.analysisProgress = progress
                    }
                }
            )
            await loadTracks()
        } catch {
            logger.error("Analysis failed: \(error)")
        }
    }

    func addToSet(_ track: Track) {
        if !setTracks.contains(where: { $0.id == track.id }) {
            setTracks.append(track)
        }
    }

    func removeFromSet(_ track: Track) {
        setTracks.removeAll { $0.id == track.id }
    }

    func reorderSet(from source: IndexSet, to destination: Int) {
        setTracks.move(fromOffsets: source, toOffset: destination)
    }
}

enum NavigationTab: String, CaseIterable {
    case library = "Library"
    case setBuilder = "Set Builder"
    case graph = "Graph"
    case training = "Training"
}
