// Generates the Tuck app icon: white rounded square, orange line, black chevron.
// The same marks Tuck puts in the menu bar, in the same order.
// Regenerate with: swift scripts/make-icon.swift
// Output: icons/AppIcon.icns (plus the intermediate iconset)

import AppKit
import CoreGraphics

let orange = CGColor(red: 1.0, green: 0.18, blue: 0.0, alpha: 1.0)
let black = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
let white = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

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
    ctx.setFillColor(white)
    ctx.fillPath()

    let markHeight = rect.height * 0.34
    let stroke = rect.width * 0.075

    // Orange line, left of centre.
    let lineX = rect.midX - rect.width * 0.14
    let lineRect = CGRect(x: lineX - stroke / 2, y: rect.midY - markHeight / 2, width: stroke, height: markHeight)
    ctx.addPath(CGPath(roundedRect: lineRect, cornerWidth: stroke / 2, cornerHeight: stroke / 2, transform: nil))
    ctx.setFillColor(orange)
    ctx.fillPath()

    // Black chevron pointing left, right of centre.
    let chevronX = rect.midX + rect.width * 0.14
    let chevronWidth = rect.width * 0.16
    ctx.setStrokeColor(black)
    ctx.setLineWidth(stroke)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: chevronX + chevronWidth / 2, y: rect.midY + markHeight / 2))
    ctx.addLine(to: CGPoint(x: chevronX - chevronWidth / 2, y: rect.midY))
    ctx.addLine(to: CGPoint(x: chevronX + chevronWidth / 2, y: rect.midY - markHeight / 2))
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
