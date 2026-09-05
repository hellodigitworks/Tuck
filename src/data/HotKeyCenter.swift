import Carbon.HIToolbox
import Foundation

/// Registers one system-wide keyboard shortcut and calls `handler` when it is pressed.
/// Uses Carbon's RegisterEventHotKey, which works from any app and needs no permissions.
public final class HotKeyCenter {
    public var handler: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let signature: OSType = 0x5455_434B // "TUCK"

    public init() {}

    deinit {
        unregister()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    /// Replaces whatever shortcut was registered before. Pass nil to have none.
    public func register(_ combo: KeyCombo?) {
        unregister()
        guard let combo, combo.isUsable else { return }
        installEventHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: signature, id: 1)
        var reference: EventHotKeyRef?
        let status = RegisterEventHotKey(
            combo.keyCode, combo.carbonModifiers, hotKeyID,
            GetApplicationEventTarget(), 0, &reference)
        if status == noErr {
            hotKeyRef = reference
        }
    }

    public func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData -> OSStatus in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let center = Unmanaged<HotKeyCenter>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { center.handler?() }
            return noErr
        }, 1, &eventType, context, &eventHandlerRef)
    }
}
