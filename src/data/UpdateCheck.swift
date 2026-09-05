import Foundation

/// Asks GitHub now and then whether a newer Duck exists, and says so. Never downloads
/// anything on its own: the person clicks through to the release page.
public final class UpdateCheck: ObservableObject {
    public struct Release: Equatable {
        public let version: String
        public let url: URL
    }

    public static let shared = UpdateCheck(
        current: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0")

    /// Set once a newer release is known. Nil until then.
    @Published public private(set) var newer: Release?

    private let current: String
    private let endpoint = URL(string: "https://api.github.com/repos/hellodigitworks/Duck/releases/latest")!
    private var timer: Timer?
    private static let interval: TimeInterval = 6 * 60 * 60

    public init(current: String) {
        self.current = current
    }

    /// A first look a few seconds after launch, then every six hours while Duck runs.
    public func start() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in self?.check() }
        timer = Timer.scheduledTimer(withTimeInterval: Self.interval, repeats: true) { [weak self] _ in
            self?.check()
        }
    }

    public func check() {
        var request = URLRequest(url: endpoint, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Duck/\(current)", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self, let data, let release = Self.parse(data) else { return }
            guard Self.isNewer(release.version, than: self.current) else { return }
            DispatchQueue.main.async {
                if self.newer != release {
                    Log.note("Newer release: \(release.version)")
                    self.newer = release
                }
            }
        }.resume()
    }

    /// Reads GitHub's "latest release" answer. Tags are "v1.2.0"; the v is dropped.
    public static func parse(_ data: Data) -> Release? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let page = json["html_url"] as? String,
              let url = URL(string: page)
        else { return nil }
        return Release(version: tag.hasPrefix("v") ? String(tag.dropFirst()) : tag, url: url)
    }

    /// "1.2.0" is newer than "1.1.1". "1.2" and "1.2.0" are the same.
    public static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = numbers(candidate)
        let b = numbers(current)
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? a[index] : 0
            let y = index < b.count ? b[index] : 0
            if x != y { return x > y }
        }
        return false
    }

    private static func numbers(_ version: String) -> [Int] {
        version.split(separator: ".").map { Int($0.filter(\.isNumber)) ?? 0 }
    }
}
