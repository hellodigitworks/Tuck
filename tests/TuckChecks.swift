// Checks for the settings and shortcut logic. Run: zsh scripts/test.sh
import AppKit
import Carbon.HIToolbox
import Foundation
import TuckCore

var passed = 0
var failed = 0

func check(_ condition: Bool, _ message: String, line: Int = #line) {
    if condition {
        passed += 1
    } else {
        failed += 1
        print("✗ \(message) (line \(line))")
    }
}

func freshDefaults() -> (UserDefaults, String) {
    let name = "com.hdw.tuck.checks.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return (defaults, name)
}

// MARK: Shortcuts

let combo = KeyCombo(keyCode: UInt32(kVK_ANSI_H), modifiers: [.command, .option, .control, .shift], characters: "h")
check(combo.carbonModifiers == UInt32(cmdKey | optionKey | controlKey | shiftKey), "Carbon modifier bits")

check(KeyCombo(keyCode: UInt32(kVK_ANSI_H), modifiers: [.command, .control], characters: "h").displayString == "⌃⌘H",
      "modifiers read in macOS order")

check(!KeyCombo(keyCode: UInt32(kVK_ANSI_H), modifiers: [.shift], characters: "h").isUsable, "shift alone is not usable")
check(!KeyCombo(keyCode: UInt32(kVK_ANSI_H), modifiers: [], characters: "h").isUsable, "bare key is not usable")
check(KeyCombo(keyCode: UInt32(kVK_ANSI_H), modifiers: [.option], characters: "h").isUsable, "option plus key is usable")

check(KeyCombo(keyCode: UInt32(kVK_Space), modifiers: [.command], characters: " ").keyName == "Space", "space gets a name")
check(KeyCombo(keyCode: UInt32(kVK_Return), modifiers: [.command], characters: "\r").keyName == "↩", "return gets a symbol")
check(KeyCombo(keyCode: UInt32(kVK_F5), modifiers: [.command], characters: nil).keyName == "F5", "function keys get names")

check(KeyCombo(keyCode: UInt32(kVK_ANSI_H), modifiers: [.command, .capsLock, .function, .numericPad], characters: "h").modifiers == [.command],
      "caps lock, fn and keypad flags are dropped")

do {
    let original = KeyCombo(keyCode: UInt32(kVK_ANSI_T), modifiers: [.control, .option], characters: "t")
    let data = try JSONEncoder().encode(original)
    let back = try JSONDecoder().decode(KeyCombo.self, from: data)
    check(back == original, "shortcut survives JSON")
} catch {
    check(false, "shortcut JSON threw \(error)")
}

// MARK: Settings

do {
    let (defaults, name) = freshDefaults()
    defer { defaults.removePersistentDomain(forName: name) }
    let prefs = Preferences(defaults: defaults)
    check(prefs.showPreferencesOnLaunch == false, "window is not forced on every launch")
    check(prefs.autoHide == true, "auto hide on by default")
    check(prefs.autoHideSeconds == 10, "auto hide after 10 seconds by default")
    check(prefs.useFullMenuBar == false, "full menu bar off by default")
    check(prefs.hasHiddenBefore == false, "fresh install has not hidden yet")
    check(prefs.hotKey == nil, "no shortcut by default")
}

do {
    let (defaults, name) = freshDefaults()
    defer { defaults.removePersistentDomain(forName: name) }
    let prefs = Preferences(defaults: defaults)
    prefs.autoHide = false
    prefs.autoHideSeconds = 30
    prefs.hasHiddenBefore = true
    prefs.hidingWidth = 2100
    prefs.hidingBarWidth = 2560
    prefs.hotKey = KeyCombo(keyCode: UInt32(kVK_ANSI_H), modifiers: [.control, .option], characters: "h")

    let again = Preferences(defaults: UserDefaults(suiteName: name)!)
    check(again.autoHide == false, "auto hide change comes back")
    check(again.autoHideSeconds == 30, "delay change comes back")
    check(again.hasHiddenBefore == true, "hidden-before flag comes back")
    check(again.hidingWidth == 2100, "learned hiding width comes back")
    check(again.hidingBarWidth == 2560, "the screen it was learned on comes back")
    check(again.hotKey?.displayString == "⌃⌥H", "shortcut comes back")
}

do {
    let (defaults, name) = freshDefaults()
    defer { defaults.removePersistentDomain(forName: name) }
    let prefs = Preferences(defaults: defaults)
    prefs.hotKey = KeyCombo(keyCode: UInt32(kVK_ANSI_H), modifiers: [.command], characters: "h")
    prefs.hotKey = nil
    check(defaults.data(forKey: Preferences.Key.hotKey) == nil, "clearing the shortcut removes it")
    check(Preferences(defaults: UserDefaults(suiteName: name)!).hotKey == nil, "cleared shortcut stays cleared")
}

do {
    let (defaults, name) = freshDefaults()
    defer { defaults.removePersistentDomain(forName: name) }
    defaults.set(7.0, forKey: Preferences.Key.autoHideSeconds)
    check(Preferences(defaults: defaults).autoHideSeconds == 10, "unknown delay falls back to 10 seconds")
}

if failed == 0 {
    print("All \(passed) checks passed")
    exit(0)
} else {
    print("\(failed) of \(passed + failed) checks failed")
    exit(1)
}
