import SwiftUI
import DuckCore

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
            VStack(alignment: .leading, spacing: 4) {
                Text("Duck")
                    .font(Type.serif(42))
                Text("Hide the menu bar icons you are not using right now.")
                    .font(Type.sans(15))
                    .foregroundStyle(Ink.muted)
            }

            Card {
                MenuBarDemo(style: preferences.markStyle)
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
                    Toggle("Show in Dock", isOn: $preferences.showInDock)
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

                    // The mark's look: each chip shows its hidden shape and its showing shape.
                    HStack(spacing: 6) {
                        Text("Mark")
                            .padding(.trailing, 4)
                        ForEach(MarkStyle.allCases, id: \.self) { style in
                            MarkChip(style: style, selected: preferences.markStyle == style) {
                                withAnimation(Ink.spring) { preferences.markStyle = style }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                .toggleStyle(Check())
            }

            HStack(spacing: 16) {
                Text("Duck \(version)")
                    .monospacedDigit()
                Link("GitHub", destination: URL(string: "https://github.com/hellodigitworks/Duck")!)
                    .focusable(false)
                if let newer = updates.newer {
                    Link("Duck \(newer.version) is out. Download", destination: newer.url)
                        .font(Type.medium(12))
                        .foregroundStyle(Ink.text)
                        .underline()
                        .focusable(false)
                }
                Spacer()
                Button("Quit Duck") { NSApp.terminate(nil) }
                    .buttonStyle(Outline())
                    .focusable(false)
            }
            .font(Type.sans(12))
            .foregroundStyle(Ink.muted)
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
            .font(Type.sans(12))
            .foregroundStyle(Ink.muted)
            .padding(.leading, 30)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - The demo

/// A small menu bar that plays what Duck does: the icons left of the mark slide away and
/// the ✕ turns into a plus, then they come back. Stands still when Reduce Motion is on.
struct MenuBarDemo: View {
    let style: MarkStyle
    @StateObject private var state = Flag()
    private var ducked: Bool { state.on }
    private let hiding = ["wifi", "cloud.fill", "bell.fill", "moon.fill"]
    private let staying = ["battery.100", "clock"]
    private let still = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                icons(hiding)
                    .offset(x: ducked ? -150 : 0)
                    .opacity(ducked ? 0 : 1)
                    .padding(.trailing, 20)
                Image(nsImage: Mark.image(style: style, fraction: ducked ? 0 : 1))
                    .renderingMode(.template)
                    .foregroundStyle(Ink.accent)
                    .id("\(style.rawValue)-\(ducked)")
                    .transition(.opacity)
                icons(staying)
                    .padding(.leading, 20)
            }
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Ink.paper))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Ink.line, lineWidth: 1))

            Text(ducked ? "Hidden. Click + and they are back." : "Showing. Click ✕ and they duck out.")
                .font(Type.sans(12))
                .foregroundStyle(Ink.muted)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: ducked)
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

/// A chip for one look of the mark: its hidden shape, then its showing shape. Ink-filled
/// when it is the one in use.
struct MarkChip: View {
    let style: MarkStyle
    let selected: Bool
    let action: () -> Void
    @StateObject private var hover = Flag()
    private var hovering: Bool { hover.on }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                glyph(0)
                glyph(1)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(selected ? Ink.text : Color.clear))
            .overlay(Capsule().stroke(selected ? Ink.text : (hovering ? Ink.text : Ink.edge), lineWidth: 1))
            .contentShape(Capsule())
            .scaleEffect(hovering && !selected ? 1.04 : 1)
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(style.name)
        .onHover { hover.on = $0 }
        .animation(Ink.spring, value: selected)
        .animation(Ink.spring, value: hovering)
    }

    private func glyph(_ fraction: CGFloat) -> some View {
        Image(nsImage: Mark.image(style: style, fraction: fraction))
            .renderingMode(.template)
            .resizable()
            .frame(width: 14, height: 14)
            .foregroundStyle(selected ? Ink.paper : Ink.text)
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
            message = "Approve Duck in System Settings → General → Login Items & Extensions."
        }
    }
}
