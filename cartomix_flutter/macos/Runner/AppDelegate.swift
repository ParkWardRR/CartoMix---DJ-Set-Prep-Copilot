import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private let updater = Updater.shared

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    installUpdateMenuItem()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  @objc private func checkForUpdates(_ sender: Any?) {
    updater.checkForUpdates()
  }

  private func installUpdateMenuItem() {
    guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }
    let updateItem = NSMenuItem(
      title: "Check for Updates…",
      action: #selector(checkForUpdates),
      keyEquivalent: ""
    )
    updateItem.target = self

    // Insert beneath the About item (index 1 is usually Preferences/Settings)
    let insertIndex = min(1, appMenu.items.count)
    appMenu.insertItem(updateItem, at: insertIndex)
  }
}
