// Makes the Duck app icon from icons/duck.svg, the duck drawn by hand.
// The duck sits on a cream rounded square with a margin, the macOS way, at every size an
// iconset needs, and iconutil folds them into icons/AppIcon.icns.
//
// Regenerate with: swift scripts/make-icon.swift
// Input:  icons/duck.svg, the master. Change the duck there, in Illustrator, never here.
// Output: icons/AppIcon.icns and the intermediate icons/AppIcon.iconset.
// make-images.swift reads the same duck.svg for the page, the README and the lab shot,
// so one drawing is the duck everywhere.

import AppKit

let cream = NSColor(red: 0.957, green: 0.937, blue: 0.902, alpha: 1.0)

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let root = scriptDir.deletingLastPathComponent()
let iconsDir = root.appendingPathComponent("icons")
let iconset = iconsDir.appendingPathComponent("AppIcon.iconset")

guard let duck = NSImage(contentsOf: iconsDir.appendingPathComponent("duck.svg")) else {
    fatalError("icons/duck.svg is missing. It is drawn by hand, so nothing here can make it.")
}

/// One tile. A cream rounded square with a margin and transparent corners, and the duck
/// centred on it at 72% of the square, so it breathes the way Apple's own icons do. The
/// drawing fills its own box edge to edge, which is why it needs the room.
func draw(size px: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high

    let s = CGFloat(px)
    let margin = s * 0.09
    let tile = NSRect(x: margin, y: margin, width: s - margin * 2, height: s - margin * 2)
    let radius = tile.width * 0.225
    cream.setFill()
    NSBezierPath(roundedRect: tile, xRadius: radius, yRadius: radius).fill()

    // Fit the drawing in a square 72% of the tile, keeping its own proportions.
    let box = tile.width * 0.72
    let scale = box / max(duck.size.width, duck.size.height)
    let w = duck.size.width * scale
    let h = duck.size.height * scale
    duck.draw(in: NSRect(x: tile.midX - w / 2, y: tile.midY - h / 2, width: w, height: h),
              from: .zero, operation: .sourceOver, fraction: 1)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in sizes {
    let rep = draw(size: px)
    guard let data = rep.representation(using: .png, properties: [:]) else { continue }
    try? data.write(to: iconset.appendingPathComponent("\(name).png"))
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", iconsDir.appendingPathComponent("AppIcon.icns").path]
try task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "AppIcon.icns written from icons/duck.svg" : "iconutil failed")
