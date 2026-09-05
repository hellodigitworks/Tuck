import AppKit
import DuckCore

// `Duck --toggle` from a script, Raycast or Shortcuts flips the menu bar without a click.
if CommandLine.arguments.contains("--toggle") {
    DistributedNotificationCenter.default().postNotificationName(
        AppDelegate.toggleNotification, object: nil, userInfo: nil, deliverImmediately: true)
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
