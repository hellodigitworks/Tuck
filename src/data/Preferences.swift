import Combine
import Foundation

/// Everything the user can change. Backed by UserDefaults, so it survives relaunches.
public final class Preferences: ObservableObject {
    public static let shared = Preferences()

    public enum Key {
        public static let autoHide = "autoHide"
        public static let autoHideSeconds = "autoHideSeconds"
        public static let hasHiddenBefore = "hasHiddenBefore"
        public static let hidingWidth = "hidingWidth"
        public static let hidingBarWidth = "hidingBarWidth"
    }

    /// The delays offered for hiding icons again, in seconds.
    public static let autoHideChoices: [Double] = [5, 10, 15, 30, 60]
    public static let defaultAutoHideSeconds: Double = 10

    private let defaults: UserDefaults

    @Published public var autoHide: Bool {
        didSet { defaults.set(autoHide, forKey: Key.autoHide) }
    }

    @Published public var autoHideSeconds: Double {
        didSet { defaults.set(autoHideSeconds, forKey: Key.autoHideSeconds) }
    }

    /// False until the user hides icons for the first time. On a fresh install Tuck stays
    /// open, and shows its window, until the user has seen where the mark is.
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

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.autoHide: true,
            Key.autoHideSeconds: Preferences.defaultAutoHideSeconds,
            Key.hasHiddenBefore: false,
        ])

        autoHide = defaults.bool(forKey: Key.autoHide)
        let storedSeconds = defaults.double(forKey: Key.autoHideSeconds)
        autoHideSeconds = Preferences.autoHideChoices.contains(storedSeconds)
            ? storedSeconds
            : Preferences.defaultAutoHideSeconds
        hasHiddenBefore = defaults.bool(forKey: Key.hasHiddenBefore)
        hidingWidth = defaults.double(forKey: Key.hidingWidth)
        hidingBarWidth = defaults.double(forKey: Key.hidingBarWidth)
    }
}
