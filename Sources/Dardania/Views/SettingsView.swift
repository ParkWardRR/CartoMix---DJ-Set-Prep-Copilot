// Dardania - Settings View

import SwiftUI
import DardaniaCore

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AnalysisSettingsView()
                .tabItem {
                    Label("Analysis", systemImage: "waveform")
                }

            MLSettingsView()
                .tabItem {
                    Label("ML", systemImage: "brain")
                }

            ExportSettingsView()
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

            StorageSettingsView()
                .tabItem {
                    Label("Storage", systemImage: "externaldrive")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("theme") private var theme = "system"
    @AppStorage("showWelcome") private var showWelcome = true
    @AppStorage("autoScan") private var autoScan = true

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }

            Section("Behavior") {
                Toggle("Show welcome screen on launch", isOn: $showWelcome)
                Toggle("Auto-scan music folders on launch", isOn: $autoScan)
            }

            Section("Keyboard Shortcuts") {
                ShortcutRow(action: "Add Music Folder", shortcut: "Cmd + O")
                ShortcutRow(action: "Scan Library", shortcut: "Cmd + R")
                ShortcutRow(action: "Library View", shortcut: "Cmd + 1")
                ShortcutRow(action: "Set Builder", shortcut: "Cmd + 2")
                ShortcutRow(action: "Graph View", shortcut: "Cmd + 3")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ShortcutRow: View {
    let action: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Analysis Settings

struct AnalysisSettingsView: View {
    @AppStorage("concurrentAnalyses") private var concurrentAnalyses = 4
    @AppStorage("memoryBudgetMB") private var memoryBudgetMB = 550
    @AppStorage("analyzeOnImport") private var analyzeOnImport = true

    var body: some View {
        Form {
            Section("Concurrency") {
                Stepper("Concurrent analyses: \(concurrentAnalyses)",
                        value: $concurrentAnalyses, in: 1...8)

                Text("Higher values use more memory but analyze faster")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Memory") {
                Stepper("Memory budget: \(memoryBudgetMB) MB",
                        value: $memoryBudgetMB, in: 256...2048, step: 128)

                Text("Recommended: 550 MB for 8GB RAM, 1024 MB for 16GB+ RAM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Behavior") {
                Toggle("Analyze tracks on import", isOn: $analyzeOnImport)
            }

            Section("Analysis Features") {
                Toggle("Beatgrid detection", isOn: .constant(true))
                Toggle("Key detection", isOn: .constant(true))
                Toggle("Energy analysis", isOn: .constant(true))
                Toggle("Loudness (EBU R128)", isOn: .constant(true))
                Toggle("Section detection", isOn: .constant(true))
                Toggle("Cue point suggestions", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - ML Settings

struct MLSettingsView: View {
    @AppStorage("enableOpenL3") private var enableOpenL3 = true
    @AppStorage("enableSoundAnalysis") private var enableSoundAnalysis = true
    @AppStorage("enableCustomModel") private var enableCustomModel = true
    @AppStorage("similarityThreshold") private var similarityThreshold = 0.5

    var body: some View {
        Form {
            Section("ML Features") {
                Toggle(isOn: $enableOpenL3) {
                    VStack(alignment: .leading) {
                        Text("OpenL3 Embeddings")
                        Text("512-dimensional audio embeddings for vibe matching")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $enableSoundAnalysis) {
                    VStack(alignment: .leading) {
                        Text("Apple SoundAnalysis")
                        Text("300+ audio labels for context detection")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: $enableCustomModel) {
                    VStack(alignment: .leading) {
                        Text("Custom DJ Section Model")
                        Text("Use your trained model for section classification")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Similarity Search") {
                HStack {
                    Text("Minimum similarity threshold")
                    Spacer()
                    Text(String(format: "%.0f%%", similarityThreshold * 100))
                        .monospacedDigit()
                }
                Slider(value: $similarityThreshold, in: 0.3...0.9, step: 0.05)
            }

            Section("Hardware") {
                HStack {
                    Text("Neural Engine")
                    Spacer()
                    Label("Available", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                HStack {
                    Text("Metal GPU")
                    Spacer()
                    Label("Available", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                HStack {
                    Text("Compute Units")
                    Spacer()
                    Text("ANE + GPU (automatic)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Export Settings

struct ExportSettingsView: View {
    @AppStorage("defaultExportFormat") private var defaultExportFormat = "rekordbox"
    @AppStorage("includeWaveforms") private var includeWaveforms = true
    @AppStorage("includeCues") private var includeCues = true
    @AppStorage("exportLocation") private var exportLocation = ""

    var body: some View {
        Form {
            Section("Default Format") {
                Picker("Format", selection: $defaultExportFormat) {
                    Text("Rekordbox").tag("rekordbox")
                    Text("Serato").tag("serato")
                    Text("Traktor").tag("traktor")
                    Text("JSON").tag("json")
                    Text("M3U").tag("m3u")
                }
            }

            Section("Export Options") {
                Toggle("Include waveform data", isOn: $includeWaveforms)
                Toggle("Include cue points", isOn: $includeCues)
            }

            Section("Export Location") {
                HStack {
                    Text(exportLocation.isEmpty ? "Default (Downloads)" : exportLocation)
                        .foregroundStyle(exportLocation.isEmpty ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("Choose...") {
                        chooseExportLocation()
                    }
                }
            }

            Section("Format Notes") {
                Text("Rekordbox: DJ_PLAYLISTS XML with cues, tempo, key")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Serato: Binary .crate format with cues CSV")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Traktor: NML v19 with CUE_V2 markers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func chooseExportLocation() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK, let url = panel.url {
            exportLocation = url.path
        }
    }
}

// MARK: - Storage Settings

struct StorageSettingsView: View {
    @State private var databaseSize: Int64 = 0
    @State private var embeddingsSize: Int64 = 0
    @State private var cacheSize: Int64 = 0
    @State private var musicLocations: [MusicLocation] = []

    var body: some View {
        Form {
            Section("Music Locations") {
                ForEach(musicLocations, id: \.url) { location in
                    HStack {
                        Image(systemName: "folder")
                        Text(location.url.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(role: .destructive) {
                            // Remove location
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button("Add Folder...") {
                    // Add folder
                }
            }

            Section("Storage Usage") {
                StorageRow(label: "Database", size: databaseSize)
                StorageRow(label: "Embeddings", size: embeddingsSize)
                StorageRow(label: "Cache", size: cacheSize)

                Divider()

                StorageRow(label: "Total", size: databaseSize + embeddingsSize + cacheSize)
                    .fontWeight(.semibold)
            }

            Section("Maintenance") {
                Button("Clear Cache") {
                    // Clear cache
                }

                Button("Rebuild Database") {
                    // Rebuild
                }

                Button("Compact Database") {
                    // Compact
                }
            }

            Section("Data Location") {
                HStack {
                    Text("~/Library/Application Support/CartoMix/")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Reveal in Finder") {
                        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                            .appendingPathComponent("CartoMix")
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .task {
            await loadStorageInfo()
        }
    }

    private func loadStorageInfo() async {
        // Load storage sizes
    }
}

struct StorageRow: View {
    let label: String
    let size: Int64

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(formatSize(size))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// Preview commented out for SPM compatibility
// #Preview {
//     SettingsView()
//         .environmentObject(AppState())
// }
