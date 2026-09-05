// Draws the pictures Tuck shows the world, around the window photographed by make-images.sh.
// Run: zsh scripts/make-images.sh  (not this file on its own)
//
// Output, all in docs/images:
//   hero.png     1600×900   top of the README
//   menubar.png  1600×300   a menu bar before and after Tuck, drawn rather than photographed
//   social.png   1280×640   GitHub's social preview (set once in the repo's settings)
//   lab.jpg       600×375   the row on lab.hellodigitworks.com

import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let out = root.appendingPathComponent("docs/images")
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

let orange = NSColor(red: 1, green: 0.18, blue: 0, alpha: 1)
let white = NSColor.white
let grey = NSColor(white: 1, alpha: 0.55)
let dim = NSColor(white: 1, alpha: 0.85)
let line = NSColor(white: 1, alpha: 0.18)

// MARK: - Fonts

/// A font from a path in the environment, or the system font when it is not there.
func font(_ env: String, _ size: CGFloat) -> NSFont {
    if let path = ProcessInfo.processInfo.environment[env], FileManager.default.fileExists(atPath: path) {
        let url = URL(fileURLWithPath: path)
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        if let provider = CGDataProvider(url: url as CFURL), let graphics = CGFont(provider),
           let name = graphics.postScriptName as String?, let loaded = NSFont(name: name, size: size) {
            return loaded
        }
    }
    return env == "BASIS_MONO"
        ? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        : NSFont.systemFont(ofSize: size)
}

// MARK: - Drawing helpers

/// A black canvas of exactly this many pixels. Coordinates run from the bottom left.
func canvas(_ width: Int, _ height: Int, _ draw: (NSRect) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let frame = NSRect(x: 0, y: 0, width: width, height: height)
    NSColor.black.setFill()
    frame.fill()
    draw(frame)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func save(_ rep: NSBitmapImageRep, _ name: String) {
    let data = name.hasSuffix(".jpg")
        ? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        : rep.representation(using: .png, properties: [:])
    try! data!.write(to: out.appendingPathComponent(name))
    print("  \(name)")
}

/// Draws text with its top-left corner at (x, top). Returns the height used.
@discardableResult
func text(_ string: String, _ font: NSFont, _ color: NSColor, x: CGFloat, top: CGFloat, in frame: NSRect, width: CGFloat? = nil) -> CGFloat {
    let style = NSMutableParagraphStyle()
    style.lineHeightMultiple = 1.05
    let attributed = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
    let box = attributed.boundingRect(
        with: NSSize(width: width ?? 100_000, height: 100_000), options: [.usesLineFragmentOrigin])
    let rect = NSRect(x: x, y: frame.height - top - ceil(box.height), width: width ?? ceil(box.width), height: ceil(box.height))
    attributed.draw(with: rect, options: [.usesLineFragmentOrigin])
    return rect.height
}

/// Tuck's mark: two strokes, a plus at 0 and an ✕ at 45 degrees.
func mark(at center: NSPoint, arm: CGFloat, stroke: CGFloat, angle: CGFloat = 0, _ color: NSColor) {
    let path = NSBezierPath()
    path.lineWidth = stroke
    path.lineCapStyle = .round
    for base in [CGFloat.zero, .pi / 2] {
        let dx = cos(base + angle) * arm
        let dy = sin(base + angle) * arm
        path.move(to: NSPoint(x: center.x - dx, y: center.y - dy))
        path.line(to: NSPoint(x: center.x + dx, y: center.y + dy))
    }
    color.setStroke()
    path.stroke()
}

/// An SF Symbol in one colour, centred on a point.
func symbol(_ name: String, size: CGFloat, _ color: NSColor, at center: NSPoint) {
    let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(config) else { return }
    let tinted = NSImage(size: base.size, flipped: false) { rect in
        base.draw(in: rect)
        color.set()
        rect.fill(using: .sourceAtop)
        return true
    }
    tinted.draw(in: NSRect(x: center.x - base.size.width / 2, y: center.y - base.size.height / 2, width: base.size.width, height: base.size.height))
}

func outline(_ rect: NSRect, radius: CGFloat) {
    let path = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
    path.lineWidth = 1
    line.setStroke()
    path.stroke()
}

/// The window photograph, scaled to a width, with its top-left at (x, top). Whatever runs
/// past the bottom of the canvas is simply cut off, like a site screenshot.
func window(x: CGFloat, top: CGFloat, width: CGFloat, in frame: NSRect) {
    guard let data = try? Data(contentsOf: out.appendingPathComponent("window.png")),
          let shot = NSBitmapImageRep(data: data) else {
        print("  (no window.png, hero and lab shot drawn without it)")
        return
    }
    let scale = width / CGFloat(shot.pixelsWide)
    let height = CGFloat(shot.pixelsHigh) * scale
    let rect = NSRect(x: x, y: frame.height - top - height, width: width, height: height)
    // The photograph has square corners; the window does not. Clip to its shape.
    let radius = 22 * scale
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    NSGraphicsContext.current?.imageInterpolation = .high
    shot.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
    outline(rect, radius: radius)
}

// MARK: - The pictures

let delightBig = font("DELIGHT", 150)
let delightMid = font("DELIGHT", 120)
let delightBody = font("DELIGHT", 40)
let delightSmall = font("DELIGHT", 34)
let mono = font("BASIS_MONO", 22)
let monoSmall = font("BASIS_MONO", 20)

let tagline = "Hides the menu bar icons you are not using right now."

// Hero: name and line on the left, the window on the right.
save(canvas(1600, 900) { frame in
    mark(at: NSPoint(x: 190, y: frame.height - 190), arm: 46, stroke: 13, orange)
    text("Tuck", delightBig, white, x: 140, top: 280, in: frame)
    text(tagline, delightBody, grey, x: 140, top: 470, in: frame, width: 600)
    text("macOS 13 or later  ·  Apple silicon  ·  MIT", mono, grey, x: 140, top: 790, in: frame)
    window(x: 900, top: 120, width: 600, in: frame)
}, "hero.png")

// Before and after: a crowded bar, then the same bar with Tuck.
let staying = ["wifi", "speaker.wave.2.fill", "battery.100"]
let hiding = ["cloud.fill", "bell.fill", "moon.fill", "airplayvideo", "bolt.fill", "camera.fill",
              "mic.fill", "paperplane.fill", "keyboard", "display", "drop.fill", "lock.fill"]

func bar(top: CGFloat, label: String, icons: [String], withMark: Bool, in frame: NSRect) {
    text(label, monoSmall, grey, x: 0, top: top - 34, in: frame)
    let rect = NSRect(x: 0, y: frame.height - top - 60, width: frame.width, height: 60)
    outline(rect, radius: 12)
    let midY = rect.midY
    var x = rect.maxX - 28
    // The clock sits at the far right, then the icons walk left from it.
    let clock = NSAttributedString(string: "Mon 10:24", attributes: [.font: mono, .foregroundColor: white])
    x -= clock.size().width
    clock.draw(at: NSPoint(x: x, y: midY - clock.size().height / 2 + 1))
    x -= 36
    for name in icons.reversed() {
        x -= 13
        symbol(name, size: 24, dim, at: NSPoint(x: x, y: midY))
        x -= 13 + 34
    }
    if withMark {
        x -= 13
        mark(at: NSPoint(x: x, y: midY), arm: 11, stroke: 3, orange)
    }
}

save(canvas(1600, 300) { frame in
    bar(top: 40, label: "Before", icons: hiding + staying, withMark: false, in: frame)
    bar(top: 200, label: "After", icons: staying, withMark: true, in: frame)
}, "menubar.png")

// Social card: what a link to the repo looks like in a chat.
save(canvas(1280, 640) { frame in
    mark(at: NSPoint(x: 140, y: frame.height - 130), arm: 34, stroke: 10, orange)
    text("Tuck", delightMid, white, x: 100, top: 200, in: frame)
    text(tagline, delightSmall, grey, x: 100, top: 350, in: frame, width: 560)
    text("github.com/hellodigitworks/Tuck", mono, grey, x: 100, top: 560, in: frame)
    window(x: 800, top: 90, width: 420, in: frame)
}, "social.png")

// The lab row: the window alone on black, the same 600×375 as every other row.
save(canvas(600, 375) { frame in
    window(x: 90, top: 28, width: 420, in: frame)
}, "lab.jpg")
