import Foundation
import os

/// Duck's own log: a plain text file, because the unified log has not been reliable for
/// this app and a person can send a text file. Lives at ~/Library/Logs/Duck.log, capped
/// so it never grows past a few hundred KB. Every line also goes to the unified log.
public enum Log {
    public static let url: URL = {
        let logs = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logs, withIntermediateDirectories: true)
        return logs.appendingPathComponent("Duck.log")
    }()

    private static let system = Logger(subsystem: "com.hdw.duck", category: "app")
    private static let queue = DispatchQueue(label: "com.hdw.duck.log")
    private static let stamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    private static let cap = 400_000

    public static func note(_ message: String) {
        system.notice("\(message, privacy: .public)")
        let line = "\(stamp.string(from: Date())) \(message)\n"
        queue.async {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(Data(line.utf8))
                handle.closeFile()
            } else {
                try? Data(line.utf8).write(to: url)
            }
            trimIfNeeded()
        }
    }

    /// The last lines, for the diagnostics report.
    public static func tail(_ count: Int = 80) -> String {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return "(no log yet)" }
        return text.split(separator: "\n").suffix(count).joined(separator: "\n")
    }

    private static func trimIfNeeded() {
        guard let size = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int, size > cap,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        let kept = text.suffix(cap / 2)
        try? Data(kept.utf8).write(to: url)
    }
}
