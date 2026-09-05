import AppKit
import Combine
import TuckCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let toggleNotification = Notification.Name("com.hdw.tuck.toggle")

    private let preferences = Preferences.shared
    private let hotKeys = HotKeyCenter()
    private var statusBar: StatusBarController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.build()

        let statusBar = StatusBarController(preferences: preferences)
        statusBar.openPreferences = { [weak self] in self?.showPreferences(nil) }
        self.statusBar = statusBar

        hotKeys.handler = { [weak statusBar] in statusBar?.toggle() }
        hotKeys.register(preferences.hotKey)
        preferences.$hotKey
            .dropFirst()
            .sink { [weak self] combo in self?.hotKeys.register(combo) }
            .store(in: &cancellables)

        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(handleToggleNotification),
            name: AppDelegate.toggleNotification, object: nil)

        // The window shows itself until the user has hidden icons once. After that, only if asked.
        if preferences.showPreferencesOnLaunch || !preferences.hasHiddenBefore {
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
