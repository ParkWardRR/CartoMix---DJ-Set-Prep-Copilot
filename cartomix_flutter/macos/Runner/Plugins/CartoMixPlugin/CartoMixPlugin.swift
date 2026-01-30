import Cocoa
import FlutterMacOS

/// Main Flutter plugin for CartoMix
/// Bridges Flutter UI with native DardaniaCore backend
public class CartoMixPlugin: NSObject, FlutterPlugin {

    // MARK: - Properties

    private let registrar: FlutterPluginRegistrar

    // Method channels
    private var databaseChannel: FlutterMethodChannel?
    private var analyzerChannel: FlutterMethodChannel?
    private var playerChannel: FlutterMethodChannel?
    private var similarityChannel: FlutterMethodChannel?
    private var plannerChannel: FlutterMethodChannel?
    private var exporterChannel: FlutterMethodChannel?
    private var filePickerChannel: FlutterMethodChannel?

    // Event channels
    private var analyzerProgressChannel: FlutterEventChannel?
    private var playerStateChannel: FlutterEventChannel?

    // Event sinks
    private var analyzerProgressSink: FlutterEventSink?
    private var playerStateSink: FlutterEventSink?

    // MARK: - Plugin Registration

    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = CartoMixPlugin(registrar: registrar)
        plugin.setupChannels()
    }

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }

    // MARK: - Channel Setup

    private func setupChannels() {
        // Database channel
        databaseChannel = FlutterMethodChannel(
            name: "com.cartomix.database",
            binaryMessenger: registrar.messenger
        )
        databaseChannel?.setMethodCallHandler(handleDatabaseCall)

        // Analyzer channel
        analyzerChannel = FlutterMethodChannel(
            name: "com.cartomix.analyzer",
            binaryMessenger: registrar.messenger
        )
        analyzerChannel?.setMethodCallHandler(handleAnalyzerCall)

        // Player channel
        playerChannel = FlutterMethodChannel(
            name: "com.cartomix.player",
            binaryMessenger: registrar.messenger
        )
        playerChannel?.setMethodCallHandler(handlePlayerCall)

        // Similarity channel
        similarityChannel = FlutterMethodChannel(
            name: "com.cartomix.similarity",
            binaryMessenger: registrar.messenger
        )
        similarityChannel?.setMethodCallHandler(handleSimilarityCall)

        // Planner channel
        plannerChannel = FlutterMethodChannel(
            name: "com.cartomix.planner",
            binaryMessenger: registrar.messenger
        )
        plannerChannel?.setMethodCallHandler(handlePlannerCall)

        // Exporter channel
        exporterChannel = FlutterMethodChannel(
            name: "com.cartomix.exporter",
            binaryMessenger: registrar.messenger
        )
        exporterChannel?.setMethodCallHandler(handleExporterCall)

        // File picker channel
        filePickerChannel = FlutterMethodChannel(
            name: "com.cartomix.filepicker",
            binaryMessenger: registrar.messenger
        )
        filePickerChannel?.setMethodCallHandler(handleFilePickerCall)

        // Analyzer progress event channel
        analyzerProgressChannel = FlutterEventChannel(
            name: "com.cartomix.analyzer.progress",
            binaryMessenger: registrar.messenger
        )
        analyzerProgressChannel?.setStreamHandler(AnalyzerProgressStreamHandler(plugin: self))

        // Player state event channel
        playerStateChannel = FlutterEventChannel(
            name: "com.cartomix.player.state",
            binaryMessenger: registrar.messenger
        )
        playerStateChannel?.setStreamHandler(PlayerStateStreamHandler(plugin: self))
    }

    // MARK: - Database Handler

    private func handleDatabaseCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "fetchAllTracks":
            // TODO: Call FlutterBridge.shared.database.fetchAllTracks()
            // For now, return empty array
            result([])

        case "fetchTrack":
            guard let args = call.arguments as? [String: Any],
                  let _ = args["id"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing track ID", details: nil))
                return
            }
            // TODO: Implement
            result(nil)

        case "insertTrack":
            // TODO: Implement
            result(FlutterError(code: "NOT_IMPLEMENTED", message: nil, details: nil))

        case "upsertTrack":
            // TODO: Implement
            result(FlutterError(code: "NOT_IMPLEMENTED", message: nil, details: nil))

        case "fetchMusicLocations":
            // TODO: Implement
            result([])

        case "addMusicLocation":
            showFolderPicker { urls in
                // TODO: Add to database
                result(nil)
            }

        case "removeMusicLocation":
            // TODO: Implement
            result(nil)

        case "getStorageStats":
            result([
                "trackCount": 0,
                "analyzedCount": 0,
                "databaseSize": 0,
            ])

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Analyzer Handler

    private func handleAnalyzerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "scanDirectory":
            // TODO: Implement
            result(nil)

        case "analyzeTrack":
            guard let args = call.arguments as? [String: Any],
                  let _ = args["trackId"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing track ID", details: nil))
                return
            }
            // TODO: Implement with progress callback to analyzerProgressSink
            result(nil)

        case "analyzeAllPending":
            // TODO: Implement
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Player Handler

    private func handlePlayerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "load":
            guard let args = call.arguments as? [String: Any],
                  let _ = args["path"] as? String,
                  let _ = args["trackId"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            // TODO: Implement
            result(nil)

        case "play":
            // TODO: Implement
            result(nil)

        case "pause":
            // TODO: Implement
            result(nil)

        case "stop":
            // TODO: Implement
            result(nil)

        case "seek":
            guard let args = call.arguments as? [String: Any],
                  let _ = args["time"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            // TODO: Implement
            result(nil)

        case "setVolume":
            guard let args = call.arguments as? [String: Any],
                  let _ = args["volume"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            // TODO: Implement
            result(nil)

        case "setRate":
            guard let args = call.arguments as? [String: Any],
                  let _ = args["rate"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            // TODO: Implement
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Similarity Handler

    private func handleSimilarityCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "computeSimilarity":
            // TODO: Implement
            result(FlutterError(code: "NOT_IMPLEMENTED", message: nil, details: nil))

        case "findSimilarTracks":
            // TODO: Implement
            result([])

        case "computeAllSimilarities":
            // TODO: Implement
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Planner Handler

    private func handlePlannerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "optimizeSet":
            // TODO: Implement
            result([
                "orderedTrackIds": [],
                "transitions": [],
                "totalScore": 0.0,
            ])

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Exporter Handler

    private func handleExporterCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "exportRekordbox", "exportSerato", "exportTraktor", "exportJSON", "exportM3U":
            // TODO: Implement
            result("")

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - File Picker Handler

    private func handleFilePickerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickFolders":
            showFolderPicker { urls in
                let paths = urls.map { $0.path }
                result(paths)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Helpers

    private func showFolderPicker(completion: @escaping ([URL]) -> Void) {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = true
            panel.prompt = "Select Folder"
            panel.message = "Choose music folders to add to CartoMix"

            if panel.runModal() == .OK {
                completion(panel.urls)
            } else {
                completion([])
            }
        }
    }

    // MARK: - Event Sink Setters

    func setAnalyzerProgressSink(_ sink: FlutterEventSink?) {
        analyzerProgressSink = sink
    }

    func setPlayerStateSink(_ sink: FlutterEventSink?) {
        playerStateSink = sink
    }

    func sendAnalyzerProgress(_ progress: [String: Any]) {
        analyzerProgressSink?(progress)
    }

    func sendPlayerState(_ state: [String: Any]) {
        playerStateSink?(state)
    }
}

// MARK: - Stream Handlers

private class AnalyzerProgressStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: CartoMixPlugin?

    init(plugin: CartoMixPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setAnalyzerProgressSink(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setAnalyzerProgressSink(nil)
        return nil
    }
}

private class PlayerStateStreamHandler: NSObject, FlutterStreamHandler {
    weak var plugin: CartoMixPlugin?

    init(plugin: CartoMixPlugin) {
        self.plugin = plugin
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setPlayerStateSink(events)
        // Send initial state
        events([
            "isPlaying": false,
            "currentTime": 0.0,
            "duration": 0.0,
            "volume": 1.0,
            "rate": 1.0,
        ])
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setPlayerStateSink(nil)
        return nil
    }
}
