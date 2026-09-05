import AppKit
import SwiftUI
import TuckCore

/// One preferences window for the life of the app. Closing it just hides it.
/// Cream, always: the window forces the light appearance so the system controls agree with it.
final class PreferencesWindowController: NSWindowController {
    static let shared = PreferencesWindowController()

    private init() {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.title = "Tuck"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .aqua)
        window.backgroundColor = NSColor(red: 0.957, green: 0.937, blue: 0.902, alpha: 1)
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: PreferencesView(preferences: .shared, login: LoginItemModel()))
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not used")
    }

    func show() {
        guard let window else { return }
        if !window.isVisible {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
