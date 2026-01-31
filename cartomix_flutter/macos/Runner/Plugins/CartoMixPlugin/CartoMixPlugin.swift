import Cocoa
import FlutterMacOS

/// Main Flutter plugin for CartoMix
/// Bridges Flutter UI with native Swift backend via FlutterBridge
public class CartoMixPlugin: NSObject, FlutterPlugin {

    // MARK: - Properties

    private let registrar: FlutterPluginRegistrar
    private let bridge = FlutterBridge.shared
    private let audioPlayer = AudioPlayer.shared

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

        // Set up audio player state callback
        audioPlayer.onStateChange = { [weak self] state in
            self?.sendPlayerState(state)
        }
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
            do {
                let tracks = try bridge.fetchAllTracks()
                result(tracks)
            } catch {
                result(FlutterError(code: "DB_ERROR", message: error.localizedDescription, details: nil))
            }

        case "fetchTrack":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing track ID", details: nil))
                return
            }
            do {
                let track = try bridge.fetchTrack(id: id)
                result(track)
            } catch {
                result(FlutterError(code: "DB_ERROR", message: error.localizedDescription, details: nil))
            }

        case "insertTrack":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing track data", details: nil))
                return
            }
            do {
                let track = try bridge.insertTrack(args)
                result(track)
            } catch {
                result(FlutterError(code: "DB_ERROR", message: error.localizedDescription, details: nil))
            }

        case "fetchMusicLocations":
            do {
                let locations = try bridge.fetchMusicLocations()
                result(locations)
            } catch {
                result(FlutterError(code: "DB_ERROR", message: error.localizedDescription, details: nil))
            }

        case "addMusicLocation":
            showFolderPicker { [weak self] urls in
                guard let self = self else { return }
                do {
                    for url in urls {
                        try self.bridge.addMusicLocation(url: url)
                    }
                    result(urls.map { $0.path })
                } catch {
                    result(FlutterError(code: "DB_ERROR", message: error.localizedDescription, details: nil))
                }
            }

        case "removeMusicLocation":
            guard let args = call.arguments as? [String: Any],
                  let id = args["id"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing location ID", details: nil))
                return
            }
            do {
                try bridge.removeMusicLocation(id: id)
                result(nil)
            } catch {
                result(FlutterError(code: "DB_ERROR", message: error.localizedDescription, details: nil))
            }

        case "getStorageStats":
            do {
                let stats = try bridge.getStorageStats()
                result(stats)
            } catch {
                result(FlutterError(code: "DB_ERROR", message: error.localizedDescription, details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Analyzer Handler

    private func handleAnalyzerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "scanDirectory":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing directory path", details: nil))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    let url = URL(fileURLWithPath: path)
                    let tracks = try self?.bridge.scanDirectory(at: url) ?? []

                    DispatchQueue.main.async {
                        result(tracks)
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "SCAN_ERROR", message: error.localizedDescription, details: nil))
                    }
                }
            }

        case "analyzeTrack":
            guard let args = call.arguments as? [String: Any],
                  let trackId = args["trackId"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing track ID", details: nil))
                return
            }

            // Send initial progress
            sendAnalyzerProgress([
                "trackId": trackId,
                "stage": "starting",
                "progress": 0.0,
            ])

            // Simulate analysis stages (real analyzer coming in v0.7)
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let stages = ["decoding", "beatgrid", "key", "energy", "embedding", "complete"]

                for (index, stage) in stages.enumerated() {
                    Thread.sleep(forTimeInterval: 0.3)
                    let progress = Double(index + 1) / Double(stages.count)

                    DispatchQueue.main.async {
                        self?.sendAnalyzerProgress([
                            "trackId": trackId,
                            "stage": stage,
                            "progress": progress,
                        ])
                    }
                }

                DispatchQueue.main.async {
                    result(["status": "complete", "trackId": trackId])
                }
            }

        case "analyzeAllPending":
            do {
                let tracks = try bridge.fetchAllTracks()
                let pendingTracks = tracks.filter { track in
                    guard let analysis = track["analysis"] as? [String: Any] else { return true }
                    return (analysis["status"] as? String) == "pending"
                }

                result([
                    "pendingCount": pendingTracks.count,
                    "message": "Analysis queued for \(pendingTracks.count) tracks",
                ])
            } catch {
                result(FlutterError(code: "DB_ERROR", message: error.localizedDescription, details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Player Handler

    private func handlePlayerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "load":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String,
                  let trackId = args["trackId"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }

            do {
                try audioPlayer.load(path: path, trackId: trackId)
                sendPlayerState(audioPlayer.getState())
                result([
                    "waveformData": audioPlayer.getWaveformData(),
                    "duration": audioPlayer.duration
                ])
            } catch {
                result(FlutterError(code: "PLAYER_ERROR", message: error.localizedDescription, details: nil))
            }

        case "play":
            audioPlayer.play()
            result(nil)

        case "pause":
            audioPlayer.pause()
            result(nil)

        case "stop":
            audioPlayer.stop()
            result(nil)

        case "seek":
            guard let args = call.arguments as? [String: Any],
                  let time = args["time"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            audioPlayer.seek(to: time)
            result(nil)

        case "setVolume":
            guard let args = call.arguments as? [String: Any],
                  let volume = args["volume"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            audioPlayer.setVolume(Float(volume))
            result(nil)

        case "setRate":
            guard let args = call.arguments as? [String: Any],
                  let rate = args["rate"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            audioPlayer.setRate(Float(rate))
            result(nil)

        case "getWaveformData":
            result(audioPlayer.getWaveformData())

        case "getState":
            result(audioPlayer.getState())

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Similarity Handler

    private func handleSimilarityCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "findSimilarTracks":
            guard let args = call.arguments as? [String: Any],
                  let trackId = args["trackId"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing track ID", details: nil))
                return
            }
            let limit = args["limit"] as? Int ?? 10

            do {
                let similar = try bridge.findSimilarTracks(trackId: trackId, limit: limit)
                result(similar)
            } catch {
                result(FlutterError(code: "DB_ERROR", message: error.localizedDescription, details: nil))
            }

        case "computeTransition":
            guard let args = call.arguments as? [String: Any],
                  let trackAId = args["trackAId"] as? Int64,
                  let trackBId = args["trackBId"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing track IDs", details: nil))
                return
            }

            // Transition analysis (real implementation coming in v0.7)
            result([
                "trackAId": trackAId,
                "trackBId": trackBId,
                "overallScore": 0.75,
                "vibeMatch": 82.0,
                "tempoMatch": 95.0,
                "keyMatch": 85.0,
                "energyMatch": 90.0,
                "explanation": "similar vibe (82%); tempo match; key compatible; same energy",
                "warnings": [],
            ])

        case "computeAllSimilarities":
            result([
                "message": "Similarity computation queued",
                "pairCount": 0,
            ])

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Planner Handler

    private func handlePlannerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "optimizeSet":
            guard let args = call.arguments as? [String: Any],
                  let trackIds = args["trackIds"] as? [Int64] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing track IDs", details: nil))
                return
            }

            result([
                "orderedTrackIds": trackIds,
                "transitions": [],
                "totalScore": 0.8,
            ])

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Exporter Handler

    private func handleExporterCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
            return
        }

        switch call.method {
        case "exportRekordbox":
            guard let trackIds = args["trackIds"] as? [Int],
                  let playlistName = args["playlistName"] as? String,
                  let outputPath = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing trackIds, playlistName, or path", details: nil))
                return
            }
            do {
                let path = try bridge.exportRekordbox(
                    trackIds: trackIds.map { Int64($0) },
                    playlistName: playlistName,
                    outputPath: outputPath
                )
                result(path)
            } catch {
                result(FlutterError(code: "EXPORT_ERROR", message: error.localizedDescription, details: nil))
            }

        case "exportSerato":
            guard let trackIds = args["trackIds"] as? [Int],
                  let playlistName = args["playlistName"] as? String,
                  let outputPath = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing trackIds, playlistName, or path", details: nil))
                return
            }
            do {
                let path = try bridge.exportSerato(
                    trackIds: trackIds.map { Int64($0) },
                    playlistName: playlistName,
                    outputPath: outputPath
                )
                result(path)
            } catch {
                result(FlutterError(code: "EXPORT_ERROR", message: error.localizedDescription, details: nil))
            }

        case "exportTraktor":
            guard let trackIds = args["trackIds"] as? [Int],
                  let playlistName = args["playlistName"] as? String,
                  let outputPath = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing trackIds, playlistName, or path", details: nil))
                return
            }
            do {
                let path = try bridge.exportTraktor(
                    trackIds: trackIds.map { Int64($0) },
                    playlistName: playlistName,
                    outputPath: outputPath
                )
                result(path)
            } catch {
                result(FlutterError(code: "EXPORT_ERROR", message: error.localizedDescription, details: nil))
            }

        case "exportJSON":
            guard let trackIds = args["trackIds"] as? [Int],
                  let outputPath = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing trackIds or path", details: nil))
                return
            }
            do {
                let path = try bridge.exportJSON(
                    trackIds: trackIds.map { Int64($0) },
                    outputPath: outputPath
                )
                result(path)
            } catch {
                result(FlutterError(code: "EXPORT_ERROR", message: error.localizedDescription, details: nil))
            }

        case "exportM3U":
            guard let trackIds = args["trackIds"] as? [Int],
                  let outputPath = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing trackIds or path", details: nil))
                return
            }
            do {
                let path = try bridge.exportM3U(
                    trackIds: trackIds.map { Int64($0) },
                    outputPath: outputPath
                )
                result(path)
            } catch {
                result(FlutterError(code: "EXPORT_ERROR", message: error.localizedDescription, details: nil))
            }

        case "exportCSV":
            guard let trackIds = args["trackIds"] as? [Int],
                  let outputPath = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing trackIds or path", details: nil))
                return
            }
            do {
                let path = try bridge.exportCSV(
                    trackIds: trackIds.map { Int64($0) },
                    outputPath: outputPath
                )
                result(path)
            } catch {
                result(FlutterError(code: "EXPORT_ERROR", message: error.localizedDescription, details: nil))
            }

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
