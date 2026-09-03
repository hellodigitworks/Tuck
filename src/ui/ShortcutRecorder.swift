import AppKit
import Carbon.HIToolbox
import SwiftUI
import TuckCore

/// A button that records the next shortcut typed: click it, press the keys, done.
struct ShortcutRecorder: NSViewRepresentable {
    @Binding var combo: KeyCombo?

    func makeNSView(context: Context) -> ShortcutRecorderView {
        let view = ShortcutRecorderView()
        view.onChange = { combo = $0 }
        return view
    }

    func updateNSView(_ view: ShortcutRecorderView, context: Context) {
        view.onChange = { combo = $0 }
        if view.combo != combo {
            view.combo = combo
        }
    }
}

final class ShortcutRecorderView: NSView {
    var combo: KeyCombo? {
        didSet { refreshTitle() }
    }
    var onChange: ((KeyCombo?) -> Void)?

    private let button = NSButton(title: "", target: nil, action: nil)
    private var pendingModifiers: NSEvent.ModifierFlags = []
    private var isRecording = false {
        didSet {
            button.highlight(isRecording)
            refreshTitle()
        }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(buttonClicked)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        refreshTitle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Not used")
    }

    override var acceptsFirstResponder: Bool { true }

    override var intrinsicContentSize: NSSize {
        let size = button.intrinsicContentSize
        return NSSize(width: max(160, size.width), height: size.height)
    }

    @objc private func buttonClicked() {
        if isRecording {
            stopRecording()
        } else {
            pendingModifiers = []
            isRecording = true
            window?.makeFirstResponder(self)
        }
    }

    private func stopRecording() {
        isRecording = false
        pendingModifiers = []
        if window?.firstResponder == self {
            window?.makeFirstResponder(nil)
        }
    }

    override func resignFirstResponder() -> Bool {
        if isRecording {
            isRecording = false
            pendingModifiers = []
        }
        return super.resignFirstResponder()
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else {
            super.flagsChanged(with: event)
            return
        }
        pendingModifiers = event.modifierFlags.intersection(KeyCombo.relevantModifiers)
        refreshTitle()
    }

    // Shortcuts with ⌘ arrive here first, before the menu bar gets a chance to act on them.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else { return super.performKeyEquivalent(with: event) }
        handle(event)
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        handle(event)
    }

    private func handle(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(KeyCombo.relevantModifiers)
        let keyCode = Int(event.keyCode)

        if keyCode == kVK_Escape, modifiers.isEmpty {
            stopRecording()
            return
        }
        if modifiers.isEmpty, keyCode == kVK_Delete || keyCode == kVK_ForwardDelete {
            combo = nil
            onChange?(nil)
            stopRecording()
            return
        }

        let candidate = KeyCombo(
            keyCode: UInt32(event.keyCode),
            modifiers: modifiers,
            characters: event.charactersIgnoringModifiers)
        guard candidate.isUsable else {
            NSSound.beep()
            return
        }
        combo = candidate
        onChange?(candidate)
        stopRecording()
    }

    private func refreshTitle() {
        if isRecording {
            button.title = pendingModifiers.isEmpty
                ? "Type a shortcut…"
                : KeyCombo.symbols(for: pendingModifiers) + "…"
        } else {
            button.title = combo?.displayString ?? "Record shortcut"
        }
        invalidateIntrinsicContentSize()
    }
}
