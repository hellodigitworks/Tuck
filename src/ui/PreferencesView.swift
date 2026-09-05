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

            MenuBarDiagram()
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 6) {
                Text("Hold ⌘ and drag any icon to the left of the mark. It now hides with the rest.")
                Text("Click ✕ to hide them. Click + to bring them back.")
            }
            .fixedSize(horizontal: false, vertical: true)

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

/// A sketch of the menu bar, with the mark where Tuck puts it.
struct MenuBarDiagram: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            section(["wifi", "cloud.fill", "bell.fill"], caption: "hidden until you click +")
            VStack(spacing: 10) {
                MarkGlyph(crossed: false).frame(width: 16, height: 20)
                Text(" ").font(.caption)
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
