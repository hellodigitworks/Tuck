// Checks for the settings and update logic. Run: zsh scripts/test.sh
import Foundation
import DuckCore

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
    let name = "com.hdw.duck.checks.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return (defaults, name)
}

// MARK: Settings

do {
    let (defaults, name) = freshDefaults()
    defer { defaults.removePersistentDomain(forName: name) }
    let prefs = Preferences(defaults: defaults)
    check(prefs.autoHide == true, "auto hide on by default")
    check(prefs.autoHideSeconds == 10, "auto hide after 10 seconds by default")
    check(prefs.hasHiddenBefore == false, "fresh install has not hidden yet")
    check(prefs.hidingWidth == 0, "no learned width yet")
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

    let again = Preferences(defaults: UserDefaults(suiteName: name)!)
    check(again.autoHide == false, "auto hide change comes back")
    check(again.autoHideSeconds == 30, "delay change comes back")
    check(again.hasHiddenBefore == true, "hidden-before flag comes back")
    check(again.hidingWidth == 2100, "learned hiding width comes back")
    check(again.hidingBarWidth == 2560, "the screen it was learned on comes back")
}

do {
    let (defaults, name) = freshDefaults()
    defer { defaults.removePersistentDomain(forName: name) }
    defaults.set(7.0, forKey: Preferences.Key.autoHideSeconds)
    check(Preferences(defaults: defaults).autoHideSeconds == 10, "unknown delay falls back to 10 seconds")
}

// MARK: The mark

do {
    let (defaults, name) = freshDefaults()
    defer { defaults.removePersistentDomain(forName: name) }
    let prefs = Preferences(defaults: defaults)
    check(prefs.markStyle == .plus, "the mark is a plus by default")
    check(MarkStyle.allCases.count == 5, "five looks to pick from")
    prefs.markStyle = .chevron
    check(Preferences(defaults: UserDefaults(suiteName: name)!).markStyle == .chevron, "a chosen look comes back")
    defaults.set("banana", forKey: Preferences.Key.markStyle)
    check(Preferences(defaults: defaults).markStyle == .plus, "an unknown look falls back to the plus")
}

// MARK: Updates

check(UpdateCheck.isNewer("1.2.0", than: "1.1.1"), "1.2.0 is newer than 1.1.1")
check(UpdateCheck.isNewer("2.0", than: "1.9.9"), "2.0 is newer than 1.9.9")
check(UpdateCheck.isNewer("1.1.10", than: "1.1.9"), "1.1.10 is newer than 1.1.9, digit by digit")
check(!UpdateCheck.isNewer("1.2", than: "1.2.0"), "1.2 and 1.2.0 are the same")
check(!UpdateCheck.isNewer("1.1.0", than: "1.1.1"), "an older version is not newer")
check(!UpdateCheck.isNewer("1.1.1", than: "1.1.1"), "the same version is not newer")

do {
    let json = #"{"tag_name":"v1.3.0","html_url":"https://github.com/hellodigitworks/Duck/releases/tag/v1.3.0","draft":false}"#
    let release = UpdateCheck.parse(Data(json.utf8))
    check(release?.version == "1.3.0", "the v is dropped from the tag")
    check(release?.url.host == "github.com", "the release page comes through")
    check(UpdateCheck.parse(Data("not json".utf8)) == nil, "garbage is ignored")
    check(UpdateCheck.parse(Data(#"{"message":"rate limited"}"#.utf8)) == nil, "an error answer is ignored")
}

if failed == 0 {
    print("All \(passed) checks passed")
    exit(0)
} else {
    print("\(failed) of \(passed + failed) checks failed")
    exit(1)
}
