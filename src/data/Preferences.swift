import Combine
import Foundation

/// The five looks the mark can have. Each is a pair: one shape while the icons are hidden,
/// another while they are showing.
public enum MarkStyle: String, CaseIterable {
    case plus, chevron, dot, line, corner

    /// What the Preferences window calls it.
    public var name: String {
        switch self {
        case .plus: return "Plus"
        case .chevron: return "Chevron"
        case .dot: return "Dot"
        case .line: return "Line"
        case .corner: return "Corner"
        }
    }
}

/// Everything the user can change. Backed by UserDefaults, so it survives relaunches.
public final class Preferences: ObservableObject {
    public static let shared = Preferences()

    public enum Key {
        public static let autoHide = "autoHide"
        public static let autoHideSeconds = "autoHideSeconds"
        public static let hasHiddenBefore = "hasHiddenBefore"
        public static let hidingWidth = "hidingWidth"
        public static let hidingBarWidth = "hidingBarWidth"
        public static let markStyle = "markStyle"
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

    /// False until the user hides icons for the first time. On a fresh install Duck stays
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

    /// Which look the mark has. Plus unless the person picked another.
    @Published public var markStyle: MarkStyle {
        didSet { defaults.set(markStyle.rawValue, forKey: Key.markStyle) }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.autoHide: true,
            Key.autoHideSeconds: Preferences.defaultAutoHideSeconds,
            Key.hasHiddenBefore: false,
            Key.markStyle: MarkStyle.plus.rawValue,
        ])

        autoHide = defaults.bool(forKey: Key.autoHide)
        let storedSeconds = defaults.double(forKey: Key.autoHideSeconds)
        autoHideSeconds = Preferences.autoHideChoices.contains(storedSeconds)
            ? storedSeconds
            : Preferences.defaultAutoHideSeconds
        hasHiddenBefore = defaults.bool(forKey: Key.hasHiddenBefore)
        hidingWidth = defaults.double(forKey: Key.hidingWidth)
        hidingBarWidth = defaults.double(forKey: Key.hidingBarWidth)
        markStyle = MarkStyle(rawValue: defaults.string(forKey: Key.markStyle) ?? "") ?? .plus
    }
}
