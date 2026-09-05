import SwiftUI
import TuckCore

/// The look: cream paper, ink text, one orange. Fraunces for the words that set the room,
/// Inter for the rest. Soft cards, round corners, a spring on everything that moves.
enum Ink {
    static let paper = Color(red: 0.957, green: 0.937, blue: 0.902)
    static let card = Color(red: 0.984, green: 0.973, blue: 0.953)
    static let text = Color(red: 0.078, green: 0.071, blue: 0.059)
    static let muted = Color(red: 0.435, green: 0.404, blue: 0.361)
    static let line = Color(red: 0.902, green: 0.875, blue: 0.827)
    static let edge = Color(red: 0.812, green: 0.776, blue: 0.722)
    static let accent = Color(red: 1, green: 0.18, blue: 0)
    static let shadow = Color(red: 0.25, green: 0.18, blue: 0.08).opacity(0.07)
    static let spring = Animation.spring(response: 0.32, dampingFraction: 0.72)
}

/// The two faces. Both ship inside the app; if one is missing the system font steps in.
enum Type {
    static func serif(_ size: CGFloat) -> Font { .custom("Fraunces-Regular", size: size) }
    static func sans(_ size: CGFloat) -> Font { .custom("Inter-Regular", size: size) }
    static func medium(_ size: CGFloat) -> Font { .custom("Inter-Medium", size: size) }
}

struct PreferencesView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var login: LoginItemModel
    @ObservedObject var updates: UpdateCheck

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // A fresh install gets the welcome. The moment icons are hidden for the first
            // time it turns into the preferences, and never opens on its own again.
            if preferences.hasHiddenBefore {
                settings
            } else {
                welcome
            }
        }
        .font(Type.sans(14))
        .foregroundStyle(Ink.text)
        .tint(Ink.text)
        .padding(.top, 34)
        .padding(.horizontal, 30)
        .padding(.bottom, 24)
        // One block, no wider than a comfortable line, sitting in the middle of whatever
        // size the window is. Grow the window and the block just gets more room around it.
        .frame(maxWidth: 620)
        .frame(minWidth: 440, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity, alignment: .center)
        .background(Ink.paper)
        .animation(Ink.spring, value: preferences.hasHiddenBefore)
        .onAppear { login.refresh() }
    }

    // MARK: - Welcome

    /// One screen for the first open: where the mark is and the three moves.
    private var welcome: some View {
        Group {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tuck is in your menu bar.")
                    .font(Type.serif(42))
                Text("Look for the ✕. Three things to know.")
                    .font(Type.sans(15))
                    .foregroundStyle(Ink.muted)
            }

            Card {
                MenuBarDemo()
            }

            VStack(alignment: .leading, spacing: 12) {
                step(1, "Hold ⌘ and drag the icons you want out of the way to the left of the ✕.")
                step(2, "Click the ✕. They tuck away and it turns into a plus.")
                step(3, "Click the plus and they are back.")
            }
            .font(Type.sans(14))
            .lineSpacing(2)

            Text("Once you have hidden them the first time this window becomes Preferences, and stays out of the way until you right-click the mark.")
                .font(Type.sans(12))
                .foregroundStyle(Ink.muted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            footer
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(Type.medium(12))
                .monospacedDigit()
                .foregroundStyle(Ink.paper)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Ink.text))
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    // MARK: - Preferences

    private var settings: some View {
        Group {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tuck")
                    .font(Type.serif(42))
                Text("Hide the menu bar icons you are not using right now.")
                    .font(Type.sans(15))
                    .foregroundStyle(Ink.muted)
            }

            Card {
                MenuBarDemo()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Hold ⌘ and drag an icon to the left of the mark. It hides with the rest.")
                Text("Click ✕ to hide them. Click + to bring them back.")
                Text("Right-click the mark for the menu.")
                    .font(Type.sans(12))
                    .foregroundStyle(Ink.muted)
                    .padding(.top, 2)
            }
            .font(Type.sans(14))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Start at login", isOn: launchBinding)
                    if let message = login.message {
                        note(message)
                    }
                    Toggle("Hide again automatically", isOn: $preferences.autoHide)
                    HStack(spacing: 6) {
                        ForEach(Preferences.autoHideChoices, id: \.self) { seconds in
                            Chip(label(for: seconds), selected: preferences.autoHideSeconds == seconds) {
                                withAnimation(Ink.spring) { preferences.autoHideSeconds = seconds }
                            }
                        }
                    }
                    .padding(.leading, 30)
                    .opacity(preferences.autoHide ? 1 : 0.35)
                    .disabled(!preferences.autoHide)
                    .animation(Ink.spring, value: preferences.autoHide)
                }
                .toggleStyle(Check())
            }

            footer
        }
    }

    /// The version, the links and Quit. The same row under both screens.
    private var footer: some View {
        HStack(spacing: 16) {
            Text("Tuck \(version)")
                .monospacedDigit()
            Link("GitHub", destination: URL(string: "https://github.com/hellodigitworks/Tuck")!)
                .focusable(false)
            if let newer = updates.newer {
                Link("Tuck \(newer.version) is out. Download", destination: newer.url)
                    .font(Type.medium(12))
                    .foregroundStyle(Ink.text)
                    .underline()
                    .focusable(false)
            }
            Spacer()
            Button("Quit Tuck") { NSApp.terminate(nil) }
                .buttonStyle(Outline())
                .focusable(false)
        }
        .font(Type.sans(12))
        .foregroundStyle(Ink.muted)
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
            .font(Type.sans(12))
            .foregroundStyle(Ink.muted)
            .padding(.leading, 30)
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
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Ink.paper))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Ink.line, lineWidth: 1))

            Text(tucked ? "Hidden. Click + and they are back." : "Showing. Click ✕ and they tuck away.")
                .font(Type.sans(12))
                .foregroundStyle(Ink.muted)
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
                    .foregroundStyle(Ink.text.opacity(0.32))
            }
        }
    }

    private func play() async {
        guard !still else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { state.on.toggle() }
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

// MARK: - Surfaces and controls

/// A soft card: a shade lighter than the paper, a hairline, a shadow you feel more than see.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Ink.card)
                    .shadow(color: Ink.shadow, radius: 14, y: 6)
            )
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Ink.line, lineWidth: 1))
    }
}

/// A checkbox: an outlined square that fills with ink when it is on.
struct Check: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(Ink.spring) { configuration.isOn.toggle() }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(configuration.isOn ? Ink.text : Color.clear)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(configuration.isOn ? Ink.text : Ink.edge, lineWidth: 1)
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Ink.paper)
                        .opacity(configuration.isOn ? 1 : 0)
                        .scaleEffect(configuration.isOn ? 1 : 0.4)
                }
                .frame(width: 20, height: 20)
                configuration.label
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

/// A round chip. Ink-filled when it is the one picked.
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
                .font(Type.medium(12))
                .monospacedDigit()
                .foregroundStyle(selected ? Ink.paper : Ink.muted)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Capsule().fill(selected ? Ink.text : Color.clear))
                .overlay(Capsule().stroke(selected ? Ink.text : (hovering ? Ink.text : Ink.edge), lineWidth: 1))
                .contentShape(Capsule())
                .scaleEffect(hovering && !selected ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { hover.on = $0 }
        .animation(Ink.spring, value: selected)
        .animation(Ink.spring, value: hovering)
    }
}

/// An outlined button that fills with ink while pressed.
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
                .font(Type.medium(13))
                .foregroundStyle(configuration.isPressed ? Ink.paper : Ink.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(configuration.isPressed ? Ink.text : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(hovering || configuration.isPressed ? Ink.text : Ink.edge, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .opacity(isEnabled ? 1 : 0.35)
                .onHover { hover.on = $0 }
                .animation(Ink.spring, value: hovering)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
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
