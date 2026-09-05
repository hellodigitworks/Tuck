import SwiftUI
import TuckCore

/// The house look: black, white, one orange. Hierarchy by size only, outlines over fills.
enum Ink {
    static let accent = Color(red: 1, green: 0.18, blue: 0)
    static let text = Color.white
    static let grey = Color.white.opacity(0.55)
    static let line = Color.white.opacity(0.14)
    static let edge = Color.white.opacity(0.35)
    static let bg = Color.black
}

struct PreferencesView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var login: LoginItemModel

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tuck")
                    .font(.system(size: 36))
                Text("Hide the menu bar icons you are not using right now.")
                    .font(.system(size: 15))
                    .foregroundStyle(Ink.grey)
            }

            MenuBarDemo()

            VStack(alignment: .leading, spacing: 8) {
                Text("Hold ⌘ and drag any icon to the left of the mark. It now hides with the rest.")
                Text("Click ✕ to hide them. Click + to bring them back.")
            }
            .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 5) {
                Text("The first time, nothing hides until you click ✕. After that Tuck starts hidden.")
                Text("Right-click the mark for the menu.")
                Text("From Raycast, Shortcuts or a script:")
                Text("/Applications/Tuck.app/Contents/MacOS/Tuck --toggle")
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
            }
            .font(.system(size: 12))
            .foregroundStyle(Ink.grey)
            .fixedSize(horizontal: false, vertical: true)

            Rule()

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Start at login", isOn: launchBinding)
                if let message = login.message {
                    note(message)
                }
                Toggle("Show this window every time Tuck starts", isOn: $preferences.showPreferencesOnLaunch)
                Toggle("Hide again automatically", isOn: $preferences.autoHide)
                HStack(spacing: 8) {
                    ForEach(Preferences.autoHideChoices, id: \.self) { seconds in
                        Chip(label(for: seconds), selected: preferences.autoHideSeconds == seconds) {
                            preferences.autoHideSeconds = seconds
                        }
                    }
                }
                .padding(.leading, 28)
                .opacity(preferences.autoHide ? 1 : 0.35)
                .disabled(!preferences.autoHide)
                .animation(.easeOut(duration: 0.2), value: preferences.autoHide)
                Toggle("Use the full menu bar while showing", isOn: $preferences.useFullMenuBar)
                note("Tuck becomes the front app for a moment. Its short menu leaves the most room for icons.")
            }
            .toggleStyle(Check())

            Rule()

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Text("Keyboard shortcut")
                    ShortcutRecorder(combo: $preferences.hotKey)
                    Button("Clear") { preferences.hotKey = nil }
                        .buttonStyle(Outline())
                        .disabled(preferences.hotKey == nil)
                }
                Text("Works from any app. Needs ⌘, ⌥ or ⌃ plus a key.")
                    .font(.system(size: 12))
                    .foregroundStyle(Ink.grey)
            }

            Rule()

            HStack(spacing: 18) {
                Text("Tuck \(version)")
                    .monospacedDigit()
                Link("GitHub", destination: URL(string: "https://github.com/hellodigitworks/Tuck")!)
                Spacer()
                Button("Quit Tuck") { NSApp.terminate(nil) }
                    .buttonStyle(Outline())
            }
            .font(.system(size: 12))
            .foregroundStyle(Ink.grey)
        }
        .font(.system(size: 14))
        .foregroundStyle(Ink.text)
        .tint(Ink.accent)
        .padding(.top, 40)
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .frame(width: 480)
        .background(Ink.bg)
        .onAppear { login.refresh() }
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { login.isEnabled },
            set: { wanted in login.set(wanted) })
    }

    private func label(for seconds: Double) -> String {
        seconds >= 60 ? "1 min" : "\(Int(seconds)) s"
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Ink.grey)
            .padding(.leading, 28)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - The demo

/// A small menu bar that plays what Tuck does: the icons left of the mark slide away and
/// the ✕ turns into a plus, then they come back. Stands still when Reduce Motion is on.
struct MenuBarDemo: View {
    @StateObject private var state = Flag()
    private var tucked: Bool { state.on }
    private let hiding = ["wifi", "cloud.fill", "bell.fill", "moon.fill"]
    private let staying = ["battery.100", "clock"]
    private let still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                icons(hiding)
                    .offset(x: tucked ? -150 : 0)
                    .opacity(tucked ? 0 : 1)
                    .padding(.trailing, 20)
                MarkGlyph(crossed: !tucked)
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Ink.accent)
                icons(staying)
                    .padding(.leading, 20)
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Ink.line, lineWidth: 1))

            Text(tucked ? "Hidden. Click + and they are back." : "Showing. Click ✕ and they tuck away.")
                .font(.system(size: 12))
                .foregroundStyle(Ink.grey)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: tucked)
        }
        .task { await play() }
    }

    private func icons(_ names: [String]) -> some View {
        HStack(spacing: 18) {
            ForEach(names, id: \.self) { name in
                Image(systemName: name)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
        }
    }

    private func play() async {
        guard !still else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.5)) { state.on.toggle() }
        }
    }
}

/// The same mark Tuck shows in the menu bar: a plus that rotates into an ✕.
struct MarkGlyph: View {
    var crossed: Bool

    var body: some View {
        ZStack {
            Capsule().frame(width: 13.2, height: 1.7)
            Capsule().frame(width: 1.7, height: 13.2)
        }
        .rotationEffect(.degrees(crossed ? 45 : 0))
    }
}

// MARK: - Controls

/// A thin line between sections.
struct Rule: View {
    var body: some View {
        Rectangle().fill(Ink.line).frame(height: 1)
    }
}

/// A checkbox drawn the house way: an outlined square, orange when on.
struct Check: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { configuration.isOn.toggle() }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(configuration.isOn ? Ink.accent : Ink.edge, lineWidth: 1)
                        .frame(width: 18, height: 18)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Ink.accent)
                        .opacity(configuration.isOn ? 1 : 0)
                        .scaleEffect(configuration.isOn ? 1 : 0.4)
                }
                configuration.label
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

/// A round chip. Orange outline when it is the one picked.
struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void
    @StateObject private var hover = Flag()
    private var hovering: Bool { hover.on }

    init(_ title: String, selected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.selected = selected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(selected ? Ink.accent : Ink.grey)
                .padding(.horizontal, 11)
                .padding(.vertical, 4)
                .overlay(Capsule().stroke(selected ? Ink.accent : (hovering ? Ink.text : Ink.line), lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { hover.on = $0 }
        .animation(.easeOut(duration: 0.15), value: selected)
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

/// An outlined button: white edge, brighter on hover, orange while pressed.
struct Outline: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label(configuration: configuration)
    }

    private struct Label: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled
        @StateObject private var hover = Flag()
        private var hovering: Bool { hover.on }

        var body: some View {
            configuration.label
                .font(.system(size: 13))
                .foregroundStyle(Ink.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(configuration.isPressed ? Ink.accent : (hovering ? Ink.text : Ink.edge), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .opacity(isEnabled ? 1 : 0.35)
                .onHover { hover.on = $0 }
                .animation(.easeOut(duration: 0.15), value: hovering)
        }
    }
}

/// One published bool. Views keep small state in these because the command line tools
/// ship SwiftUI without the plugin that `@State` needs; `@StateObject` works everywhere.
final class Flag: ObservableObject {
    @Published var on = false
}

/// Mirrors the system's start-at-login switch so the checkbox can show the real state.
final class LoginItemModel: ObservableObject {
    @Published var isEnabled = LoginItem.isEnabled
    @Published var message: String?

    func refresh() {
        isEnabled = LoginItem.isEnabled
    }

    func set(_ wanted: Bool) {
        message = LoginItem.setEnabled(wanted)
        isEnabled = LoginItem.isEnabled
        if wanted, message == nil, LoginItem.needsApproval {
            message = "Approve Tuck in System Settings → General → Login Items & Extensions."
        }
    }
}
