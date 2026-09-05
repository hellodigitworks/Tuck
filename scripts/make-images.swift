// Draws the pictures Tuck shows the world, around the window photographed by make-images.sh.
// Run: zsh scripts/make-images.sh  (not this file on its own)
//
// docs/images (the README and the lab):
//   hero.png     1600×900   top of the README
//   menubar.png  1600×300   a menu bar before and after Tuck, drawn rather than photographed
//   social.png   1280×640   GitHub's social preview (set once in the repo's settings)
//   lab.jpg       600×375   the row on lab.hellodigitworks.com
// site/images (the landing page):
//   og.png       1200×630   the link preview
//   favicon-32.png, favicon.png, apple-touch-icon.png, icon-192.png, icon-512.png
//
// The fonts are the ones the app ships, read straight from fonts/.

import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent()
let docs = root.appendingPathComponent("docs/images")
let site = root.appendingPathComponent("site/images")
for dir in [docs, site] {
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
}

let paper = NSColor(red: 0.957, green: 0.937, blue: 0.902, alpha: 1)
let card = NSColor(red: 0.984, green: 0.973, blue: 0.953, alpha: 1)
let ink = NSColor(red: 0.078, green: 0.071, blue: 0.059, alpha: 1)
let muted = NSColor(red: 0.435, green: 0.404, blue: 0.361, alpha: 1)
let line = NSColor(red: 0.902, green: 0.875, blue: 0.827, alpha: 1)
let orange = NSColor(red: 1, green: 0.18, blue: 0, alpha: 1)

// MARK: - Fonts

/// One of the faces in fonts/, by PostScript name. The system font if it is missing.
func font(_ name: String, _ size: CGFloat) -> NSFont {
    let url = root.appendingPathComponent("fonts/\(name).ttf")
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    return NSFont(name: name, size: size) ?? .systemFont(ofSize: size)
}

// MARK: - Drawing helpers

/// A canvas of exactly this many pixels, filled with a colour. Coordinates run from the bottom left.
func canvas(_ width: Int, _ height: Int, fill: NSColor? = paper, _ draw: (NSRect) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let frame = NSRect(x: 0, y: 0, width: width, height: height)
    if let fill {
        fill.setFill()
        frame.fill()
    }
    draw(frame)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func save(_ rep: NSBitmapImageRep, _ url: URL) {
    let data = url.pathExtension == "jpg"
        ? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        : rep.representation(using: .png, properties: [:])
    try! data!.write(to: url)
    print("  \(url.path.replacingOccurrences(of: root.path + "/", with: ""))")
}

/// Draws text with its top-left corner at (x, top). Returns the height used.
@discardableResult
func text(_ string: String, _ font: NSFont, _ color: NSColor, x: CGFloat, top: CGFloat, in frame: NSRect, width: CGFloat? = nil, tracking: CGFloat = 0) -> CGFloat {
    let style = NSMutableParagraphStyle()
    style.lineHeightMultiple = 1.02
    let attributed = NSAttributedString(string: string, attributes: [
        .font: font, .foregroundColor: color, .paragraphStyle: style, .kern: tracking,
    ])
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

/// A soft card: a shade lighter than the paper, a hairline, a shadow you feel more than see.
func cardRect(_ rect: NSRect, radius: CGFloat) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(red: 0.25, green: 0.18, blue: 0.08, alpha: 0.08)
    shadow.shadowBlurRadius = 24
    shadow.shadowOffset = NSSize(width: 0, height: -8)
    shadow.set()
    card.setFill()
    path.fill()
    NSGraphicsContext.restoreGraphicsState()
    line.setStroke()
    path.lineWidth = 1
    path.stroke()
}

/// The window photograph, scaled to a width, with its top-left at (x, top). Whatever runs
/// past the bottom of the canvas is simply cut off, like a site screenshot.
func window(x: CGFloat, top: CGFloat, width: CGFloat, in frame: NSRect) {
    guard let data = try? Data(contentsOf: docs.appendingPathComponent("window.png")),
          let shot = NSBitmapImageRep(data: data) else {
        print("  (no window.png, hero and lab shot drawn without it)")
        return
    }
    let scale = width / CGFloat(shot.pixelsWide)
    let height = CGFloat(shot.pixelsHigh) * scale
    let rect = NSRect(x: x, y: frame.height - top - height, width: width, height: height)
    let radius = 22 * scale
    let shape = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(red: 0.25, green: 0.18, blue: 0.08, alpha: 0.16)
    shadow.shadowBlurRadius = 60
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    shadow.set()
    paper.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    NSGraphicsContext.current?.imageInterpolation = .high
    shot.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
    line.setStroke()
    shape.lineWidth = 1
    shape.stroke()
}

/// The app icon as a full-bleed tile: cream, orange plus. For the web, where the
/// platform rounds the corners itself.
func tile(_ size: Int, transparent: Bool = false) -> NSBitmapImageRep {
    canvas(size, size, fill: transparent ? nil : paper) { frame in
        let s = CGFloat(size)
        mark(at: NSPoint(x: s / 2, y: s / 2), arm: s * 0.19, stroke: s * 0.075, orange)
    }
}

// MARK: - The pictures

let serifBig = font("Fraunces-Regular", 150)
let serifMid = font("Fraunces-Regular", 116)
let italicBody = font("Fraunces-Italic", 40)
let italicSmall = font("Fraunces-Italic", 34)
let sans = font("Inter-Regular", 22)
let sansSmall = font("Inter-Regular", 18)
let sansMedium = font("Inter-Medium", 22)

let tagline = "Hide the menu bar icons you are not using right now."

// Hero: name and line on the left, the window on the right.
save(canvas(1600, 900) { frame in
    mark(at: NSPoint(x: 186, y: frame.height - 186), arm: 42, stroke: 12, orange)
    text("Tuck", serifBig, ink, x: 140, top: 275, in: frame, tracking: -3)
    text(tagline, italicBody, muted, x: 142, top: 455, in: frame, width: 600)
    text("macOS 13 or later  ·  Apple silicon  ·  free  ·  MIT", sans, muted, x: 142, top: 790, in: frame)
    window(x: 900, top: 110, width: 600, in: frame)
}, docs.appendingPathComponent("hero.png"))

// Before and after: a crowded bar, then the same bar with Tuck.
let staying = ["wifi", "speaker.wave.2.fill", "battery.100"]
let hiding = ["cloud.fill", "bell.fill", "moon.fill", "airplayvideo", "bolt.fill", "camera.fill",
              "mic.fill", "paperplane.fill", "keyboard", "display", "drop.fill", "lock.fill"]

func bar(top: CGFloat, label: String, icons: [String], withMark: Bool, in frame: NSRect) {
    text(label, sansSmall, muted, x: 2, top: top - 32, in: frame)
    let rect = NSRect(x: 0, y: frame.height - top - 60, width: frame.width, height: 60).insetBy(dx: 1, dy: 1)
    cardRect(rect, radius: 14)
    let midY = rect.midY
    var x = rect.maxX - 28
    // The clock sits at the far right, then the icons walk left from it.
    let clock = NSAttributedString(string: "Mon 10:24", attributes: [.font: sans, .foregroundColor: ink])
    x -= clock.size().width
    clock.draw(at: NSPoint(x: x, y: midY - clock.size().height / 2 + 1))
    x -= 36
    for name in icons.reversed() {
        x -= 13
        symbol(name, size: 24, ink.withAlphaComponent(0.78), at: NSPoint(x: x, y: midY))
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
}, docs.appendingPathComponent("menubar.png"))

// Social card for GitHub, and the link preview for the landing page.
func card(_ width: Int, _ height: Int, footer: String) -> NSBitmapImageRep {
    canvas(width, height) { frame in
        mark(at: NSPoint(x: 138, y: frame.height - 128), arm: 32, stroke: 9, orange)
        text("Tuck", serifMid, ink, x: 100, top: 196, in: frame, tracking: -2.5)
        text(tagline, italicSmall, muted, x: 102, top: 340, in: frame, width: 540)
        text(footer, sans, muted, x: 102, top: CGFloat(height) - 80, in: frame)
        window(x: CGFloat(width) - 480, top: 90, width: 420, in: frame)
    }
}
save(card(1280, 640, footer: "github.com/hellodigitworks/Tuck"), docs.appendingPathComponent("social.png"))
save(card(1200, 630, footer: "tuck.hellodigitworks.com  ·  free for the Mac"), site.appendingPathComponent("og.png"))

// The lab row: the window alone, the same 600×375 as every other row.
save(canvas(600, 375) { frame in
    window(x: 90, top: 28, width: 420, in: frame)
}, docs.appendingPathComponent("lab.jpg"))

// Icons for the landing page.
save(tile(32, transparent: true), site.appendingPathComponent("favicon-32.png"))
save(tile(512, transparent: true), site.appendingPathComponent("favicon.png"))
save(tile(180), site.appendingPathComponent("apple-touch-icon.png"))
save(tile(192), site.appendingPathComponent("icon-192.png"))
save(tile(512), site.appendingPathComponent("icon-512.png"))
