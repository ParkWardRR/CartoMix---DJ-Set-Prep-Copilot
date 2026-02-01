import Foundation
import Sparkle

/// Thin wrapper around Sparkle's standard updater controller.
/// Keeps a shared instance alive for automatic/background checks and provides
/// a single entry point for Flutter to trigger manual update checks.
final class Updater {
    static let shared = Updater()

    private let updaterController: SPUStandardUpdaterController
    private var lastCheckDate: Date?

    private init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        // Enable once-per-day automatic checks; Sparkle handles UI.
        updaterController.updater.automaticallyChecksForUpdates = true
        updaterController.updater.updateCheckInterval = 60 * 60 * 24
    }

    /// Kick off a manual update check (shows Sparkle UI if an update is available).
    func checkForUpdates() {
        DispatchQueue.main.async { [weak self] in
            self?.lastCheckDate = Date()
            self?.updaterController.checkForUpdates(nil)
        }
    }

    /// Epoch seconds of the last update check trigger.
    func lastCheckTimestamp() -> TimeInterval? {
        lastCheckDate?.timeIntervalSince1970
    }
}
