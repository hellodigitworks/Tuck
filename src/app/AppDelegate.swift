import AppKit
import TuckCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let toggleNotification = Notification.Name("com.hdw.tuck.toggle")

    private let preferences = Preferences.shared
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.build()

        let statusBar = StatusBarController(preferences: preferences, updates: .shared)
        statusBar.openPreferences = { [weak self] in self?.showPreferences(nil) }
        self.statusBar = statusBar

        UpdateCheck.shared.start()

        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(handleToggleNotification),
            name: AppDelegate.toggleNotification, object: nil)

        // The window shows itself until the user has hidden icons once. After that it is
        // a right-click away.
        if !preferences.hasHiddenBefore {
            showPreferences(nil)
        }
    }

    /// Opening Tuck again while it is running brings up the preferences window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPreferences(nil)
        return true
    }

    @objc func showPreferences(_ sender: Any?) {
        PreferencesWindowController.shared.show()
    }

    @objc private func handleToggleNotification() {
        statusBar?.toggle()
    }
}
