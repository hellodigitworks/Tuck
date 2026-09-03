// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Tuck",
    platforms: [.macOS(.v13)],
    targets: [
        // Settings, shortcut, login item. Never touches the screen.
        .target(
            name: "TuckCore",
            path: "src/data",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // The app itself: menu bar items and the preferences window.
        .executableTarget(
            name: "Tuck",
            dependencies: ["TuckCore"],
            path: "src",
            exclude: ["data"],
            sources: ["app", "ui"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Plain checks run with `swift run TuckChecks`. The command line tools ship
        // Swift Testing without its library paths wired up, so a test target cannot load here.
        .executableTarget(
            name: "TuckChecks",
            dependencies: ["TuckCore"],
            path: "tests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
