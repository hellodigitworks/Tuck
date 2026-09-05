// Generates the Tuck app icon: cream rounded square, orange mark.
// The same mark Tuck shows in the menu bar, caught mid-rotation between plus and X.
// Regenerate with: swift scripts/make-icon.swift
// Output: icons/AppIcon.icns (plus the intermediate iconset)

import AppKit
import CoreGraphics

let orange = CGColor(red: 1.0, green: 0.18, blue: 0.0, alpha: 1.0)
let cream = CGColor(red: 0.957, green: 0.937, blue: 0.902, alpha: 1.0)

func draw(size: Int) -> CGImage? {
    let s = CGFloat(size)
    guard let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    // macOS style: rounded square with a margin, transparent corners.
    let margin = s * 0.09
    let rect = CGRect(x: margin, y: margin, width: s - margin * 2, height: s - margin * 2)
    let radius = rect.width * 0.225
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.setFillColor(cream)
    ctx.fillPath()

    // The mark: two crossed strokes. Upright is a plus, 45 degrees is an X.
    let arm = rect.width * 0.21
    let stroke = rect.width * 0.085
    let center = CGPoint(x: rect.midX, y: rect.midY)
    ctx.setStrokeColor(orange)
    ctx.setLineWidth(stroke)
    ctx.setLineCap(.round)
    for base in [CGFloat.zero, .pi / 2] {
        let dx = cos(base) * arm
        let dy = sin(base) * arm
        ctx.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
        ctx.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
    }
    ctx.strokePath()

    return ctx.makeImage()
}

func writePNG(_ image: CGImage, to url: URL) {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else { return }
    try? data.write(to: url)
}

let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let root = scriptDir.deletingLastPathComponent()
let iconsDir = root.appendingPathComponent("icons")
let iconset = iconsDir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in sizes {
    if let image = draw(size: px) {
        writePNG(image, to: iconset.appendingPathComponent("\(name).png"))
    }
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", iconsDir.appendingPathComponent("AppIcon.icns").path]
try task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "AppIcon.icns written" : "iconutil failed")
