import AppKit
import Carbon.HIToolbox

/// One keyboard shortcut: a key plus modifier keys.
/// Stored as plain numbers so it can be saved and restored between launches.
public struct KeyCombo: Codable, Equatable {
    public let keyCode: UInt32
    public let modifierFlags: UInt
    public let characters: String?

    public static let relevantModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    public init(keyCode: UInt32, modifiers: NSEvent.ModifierFlags, characters: String?) {
        self.keyCode = keyCode
        self.modifierFlags = modifiers.intersection(KeyCombo.relevantModifiers).rawValue
        self.characters = characters
    }

    public var modifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlags)
    }

    /// Carbon's own bit layout, which RegisterEventHotKey expects.
    public var carbonModifiers: UInt32 {
        var flags: UInt32 = 0
        if modifiers.contains(.command) { flags |= UInt32(cmdKey) }
        if modifiers.contains(.option) { flags |= UInt32(optionKey) }
        if modifiers.contains(.control) { flags |= UInt32(controlKey) }
        if modifiers.contains(.shift) { flags |= UInt32(shiftKey) }
        return flags
    }

    /// A shortcut needs ⌘, ⌥ or ⌃. Without one it would swallow ordinary typing.
    public var isUsable: Bool {
        !modifiers.intersection([.command, .option, .control]).isEmpty
    }

    /// What the user sees, for example "⌃⌥H".
    public var displayString: String {
        KeyCombo.symbols(for: modifiers) + keyName
    }

    public static func symbols(for modifiers: NSEvent.ModifierFlags) -> String {
        var text = ""
        if modifiers.contains(.control) { text += "⌃" }
        if modifiers.contains(.option) { text += "⌥" }
        if modifiers.contains(.shift) { text += "⇧" }
        if modifiers.contains(.command) { text += "⌘" }
        return text
    }

    public var keyName: String {
        switch Int(keyCode) {
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Space: return "Space"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            if let characters, let first = characters.first {
                return String(first).uppercased()
            }
            return "Key \(keyCode)"
        }
    }
}
