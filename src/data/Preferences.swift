import Combine
import Foundation

/// Everything the user can change. Backed by UserDefaults, so it survives relaunches.
public final class Preferences: ObservableObject {
    public static let shared = Preferences()

    public enum Key {
        public static let showPreferencesOnLaunch = "showPreferencesOnLaunch"
        public static let autoHide = "autoHide"
        public static let autoHideSeconds = "autoHideSeconds"
        public static let useFullMenuBar = "useFullMenuBar"
        public static let hotKey = "hotKey"
        public static let hasHiddenBefore = "hasHiddenBefore"
        public static let hidingWidth = "hidingWidth"
        public static let hidingBarWidth = "hidingBarWidth"
    }

    /// The delays offered for hiding icons again, in seconds.
    public static let autoHideChoices: [Double] = [5, 10, 15, 30, 60]
    public static let defaultAutoHideSeconds: Double = 10

    private let defaults: UserDefaults

    @Published public var showPreferencesOnLaunch: Bool {
        didSet { defaults.set(showPreferencesOnLaunch, forKey: Key.showPreferencesOnLaunch) }
    }

    @Published public var autoHide: Bool {
        didSet { defaults.set(autoHide, forKey: Key.autoHide) }
    }

    @Published public var autoHideSeconds: Double {
        didSet { defaults.set(autoHideSeconds, forKey: Key.autoHideSeconds) }
    }

    @Published public var useFullMenuBar: Bool {
        didSet { defaults.set(useFullMenuBar, forKey: Key.useFullMenuBar) }
    }

    /// False until the user hides icons for the first time. On a fresh install Tuck stays
    /// open so nothing vanishes before the user has seen where the line is.
    @Published public var hasHiddenBefore: Bool {
        didSet { defaults.set(hasHiddenBefore, forKey: Key.hasHiddenBefore) }
    }

    /// The width that last did the hiding, and the screen it was measured on. Saves
    /// walking the width up from nothing every time, which is what makes icons crawl.
    @Published public var hidingWidth: Double {
        didSet { defaults.set(hidingWidth, forKey: Key.hidingWidth) }
    }

    @Published public var hidingBarWidth: Double {
        didSet { defaults.set(hidingBarWidth, forKey: Key.hidingBarWidth) }
    }

    @Published public var hotKey: KeyCombo? {
        didSet {
            if let hotKey, let data = try? JSONEncoder().encode(hotKey) {
                defaults.set(data, forKey: Key.hotKey)
            } else {
                defaults.removeObject(forKey: Key.hotKey)
            }
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.showPreferencesOnLaunch: true,
            Key.autoHide: true,
            Key.autoHideSeconds: Preferences.defaultAutoHideSeconds,
            Key.useFullMenuBar: false,
            Key.hasHiddenBefore: false,
        ])

        showPreferencesOnLaunch = defaults.bool(forKey: Key.showPreferencesOnLaunch)
        autoHide = defaults.bool(forKey: Key.autoHide)
        let storedSeconds = defaults.double(forKey: Key.autoHideSeconds)
        autoHideSeconds = Preferences.autoHideChoices.contains(storedSeconds)
            ? storedSeconds
            : Preferences.defaultAutoHideSeconds
        useFullMenuBar = defaults.bool(forKey: Key.useFullMenuBar)
        hasHiddenBefore = defaults.bool(forKey: Key.hasHiddenBefore)
        hidingWidth = defaults.double(forKey: Key.hidingWidth)
        hidingBarWidth = defaults.double(forKey: Key.hidingBarWidth)
        if let data = defaults.data(forKey: Key.hotKey) {
            hotKey = try? JSONDecoder().decode(KeyCombo.self, from: data)
        } else {
            hotKey = nil
        }
    }
}
