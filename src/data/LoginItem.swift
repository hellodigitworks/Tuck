import Foundation
import ServiceManagement

/// Start at login, through the system's own list
/// (System Settings → General → Login Items & Extensions).
public enum LoginItem {
    public static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// True when macOS wants the user to approve it in System Settings first.
    public static var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    /// Returns a message if macOS refused, otherwise nil.
    public static func setEnabled(_ enabled: Bool) -> String? {
        Log.note("Start at login set to \(enabled)")
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
