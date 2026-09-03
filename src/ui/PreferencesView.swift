import SwiftUI
import TuckCore

struct PreferencesView: View {
    @ObservedObject var preferences: Preferences
    @ObservedObject var login: LoginItemModel

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tuck")
                    .font(.system(size: 30, weight: .regular))
                Text("Hide the menu bar icons you are not using right now.")
                    .foregroundStyle(.secondary)
            }

            MenuBarDiagram(alwaysHidden: preferences.alwaysHiddenEnabled)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                Text("Hold ⌘ and drag any icon to the left of the line. It now hides with the rest.")
                Text("Click ‹ to show everything. Click › to hide it again.")
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Start at login", isOn: launchBinding)
                if let message = login.message {
                    note(message)
                }
                Toggle("Show this window when Tuck starts", isOn: $preferences.showPreferencesOnLaunch)
                HStack(spacing: 8) {
                    Toggle("Hide again automatically after", isOn: $preferences.autoHide)
                    Picker("", selection: $preferences.autoHideSeconds) {
                        ForEach(Preferences.autoHideChoices, id: \.self) { seconds in
                            Text(label(for: seconds)).tag(seconds)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 110)
                    .disabled(!preferences.autoHide)
                }
                Toggle("Use the full menu bar while showing", isOn: $preferences.useFullMenuBar)
                note("Tuck becomes the front app for a moment. Its short menu leaves the most room for icons.")
                Toggle("Always-hidden section", isOn: $preferences.alwaysHiddenEnabled)
                note("Adds a dotted line. Icons left of it stay hidden even while the rest are showing. Option-click ‹ to peek at them.")
            }
            .toggleStyle(.checkbox)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text("Keyboard shortcut")
                    ShortcutRecorder(combo: $preferences.hotKey)
                    Button("Clear") { preferences.hotKey = nil }
                        .disabled(preferences.hotKey == nil)
                }
                Text("Works from any app. Needs ⌘, ⌥ or ⌃ plus a key.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Text("Tuck \(version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Quit Tuck") { NSApp.terminate(nil) }
            }
        }
        .padding(28)
        .frame(width: 470)
        .onAppear { login.refresh() }
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { login.isEnabled },
            set: { wanted in login.set(wanted) })
    }

    private func label(for seconds: Double) -> String {
        seconds >= 60 ? "1 minute" : "\(Int(seconds)) seconds"
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.leading, 20)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A sketch of the menu bar with Tuck's marks in it, so the sections are obvious.
struct MenuBarDiagram: View {
    let alwaysHidden: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if alwaysHidden {
                section(["moon.fill", "bolt.fill"], caption: "always hidden")
                marker { DottedLine() }
            }
            section(["wifi", "cloud.fill", "bell.fill"], caption: "hidden until you click ‹")
            marker { Rectangle().frame(width: 1.5, height: 16) }
            marker {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
            }
            section(["battery.100", "clock"], caption: "always showing")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }

    private func section(_ symbols: [String], caption: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                ForEach(symbols, id: \.self) { name in
                    Image(systemName: name).font(.system(size: 13))
                }
            }
            .foregroundStyle(.secondary)
            .frame(height: 20)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 10)
    }

    private func marker<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 10) {
            content().frame(width: 12, height: 20)
            Text(" ").font(.caption)
        }
    }
}

struct DottedLine: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0.75, y: 0))
            path.addLine(to: CGPoint(x: 0.75, y: 16))
        }
        .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [1.5, 3]))
        .frame(width: 1.5, height: 16)
    }
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
