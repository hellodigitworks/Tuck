// Generates the Duck app icon and the duck itself for the website.
// A rubber duck, drawn from a handful of numbers below: yellow body, ink outline, orange
// bill, one wing line. Cream rounded square behind it for the app icon, nothing behind it
// for the web.
//
// Regenerate with: swift scripts/make-icon.swift
// Output: icons/AppIcon.icns (plus the intermediate iconset) and icons/duck.svg, which
// make-images.swift draws everywhere the duck appears on the page and in the README.

import AppKit
import CoreGraphics

let orange = CGColor(red: 1.0, green: 0.18, blue: 0.0, alpha: 1.0)
let cream = CGColor(red: 0.957, green: 0.937, blue: 0.902, alpha: 1.0)
let ink = CGColor(red: 0.078, green: 0.071, blue: 0.059, alpha: 1.0)
let yellow = CGColor(red: 1.0, green: 0.82, blue: 0.22, alpha: 1.0)
let white = CGColor(gray: 1, alpha: 1)

/// The duck in a unit square, y up. Every picture of it comes from these points.
enum Duck {
    static let head = CGPoint(x: 0.63, y: 0.66)
    static let headRadius: CGFloat = 0.19
    static let tail = CGPoint(x: 0.09, y: 0.62)
    static let line: CGFloat = 0.03

    static func onHead(_ degrees: CGFloat) -> CGPoint {
        CGPoint(x: head.x + headRadius * cos(degrees * .pi / 180), y: head.y + headRadius * sin(degrees * .pi / 180))
    }

    /// The bill, drawn first so the head covers its root: two curves meeting at the tip.
    static let billStart = onHead(14)
    static let billTip = CGPoint(x: 0.975, y: 0.635)
    static let billUpper = CGPoint(x: 0.91, y: 0.745)
    static let billEnd = onHead(-18)
    static let billLower = CGPoint(x: 0.93, y: 0.565)

    /// One outline: from the tail tip down its back, along the belly, up the chest, round
    /// the head (an arc from -42 to 200 degrees) and back along the dip to the tail.
    static let belly: [(to: CGPoint, control: CGPoint)] = [
        (CGPoint(x: 0.17, y: 0.33), CGPoint(x: 0.05, y: 0.44)),
        (CGPoint(x: 0.52, y: 0.19), CGPoint(x: 0.27, y: 0.15)),
        (CGPoint(x: 0.86, y: 0.35), CGPoint(x: 0.80, y: 0.19)),
        (onHead(-42), CGPoint(x: 0.94, y: 0.48)),
    ]
    static let arcStart: CGFloat = -42
    static let arcEnd: CGFloat = 200
    static let backControl = CGPoint(x: 0.27, y: 0.47)

    static let mouth = (from: CGPoint(x: 0.85, y: 0.648), to: CGPoint(x: 0.935, y: 0.642), control: CGPoint(x: 0.895, y: 0.628))
    static let wing = (from: CGPoint(x: 0.27, y: 0.42), to: CGPoint(x: 0.62, y: 0.31), control: CGPoint(x: 0.53, y: 0.55))
    static let eye = CGPoint(x: 0.68, y: 0.72)
    static let eyeRadius: CGFloat = 0.045
}

// MARK: - Drawing with CoreGraphics, for the app icon

func drawDuck(in ctx: CGContext, rect: CGRect) {
    let w = rect.width
    func P(_ p: CGPoint) -> CGPoint { CGPoint(x: rect.minX + p.x * w, y: rect.minY + p.y * w) }
    let line = w * Duck.line

    let bill = CGMutablePath()
    bill.move(to: P(Duck.billStart))
    bill.addQuadCurve(to: P(Duck.billTip), control: P(Duck.billUpper))
    bill.addQuadCurve(to: P(Duck.billEnd), control: P(Duck.billLower))
    bill.closeSubpath()

    let body = CGMutablePath()
    body.move(to: P(Duck.tail))
    for segment in Duck.belly {
        body.addQuadCurve(to: P(segment.to), control: P(segment.control))
    }
    body.addArc(center: P(Duck.head), radius: Duck.headRadius * w,
                startAngle: Duck.arcStart * .pi / 180, endAngle: Duck.arcEnd * .pi / 180, clockwise: false)
    body.addQuadCurve(to: P(Duck.tail), control: P(Duck.backControl))
    body.closeSubpath()

    ctx.setLineWidth(line)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.setStrokeColor(ink)

    ctx.setFillColor(orange)
    ctx.addPath(bill); ctx.fillPath()
    ctx.addPath(bill); ctx.strokePath()
    ctx.setFillColor(yellow)
    ctx.addPath(body); ctx.fillPath()
    ctx.addPath(body); ctx.strokePath()

    ctx.setLineWidth(line * 0.8)
    ctx.move(to: P(Duck.mouth.from)); ctx.addQuadCurve(to: P(Duck.mouth.to), control: P(Duck.mouth.control)); ctx.strokePath()
    ctx.setLineWidth(line)
    ctx.move(to: P(Duck.wing.from)); ctx.addQuadCurve(to: P(Duck.wing.to), control: P(Duck.wing.control)); ctx.strokePath()

    let e = w * Duck.eyeRadius
    let c = P(Duck.eye)
    ctx.setFillColor(ink)
    ctx.addEllipse(in: CGRect(x: c.x - e, y: c.y - e, width: e * 2, height: e * 2)); ctx.fillPath()
    let h = e * 0.38
    ctx.setFillColor(white)
    ctx.addEllipse(in: CGRect(x: c.x + e * 0.2 - h, y: c.y + e * 0.25 - h, width: h * 2, height: h * 2)); ctx.fillPath()
}

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

    drawDuck(in: ctx, rect: rect)
    return ctx.makeImage()
}

// MARK: - The same duck as SVG, for the website

/// The unit square becomes a 100-unit viewBox with y pointing down, as SVG has it.
func svg() -> String {
    func s(_ p: CGPoint) -> String { String(format: "%.2f %.2f", p.x * 100, (1 - p.y) * 100) }
    func hex(_ c: CGColor) -> String {
        let k = c.components!
        return String(format: "#%02X%02X%02X", Int(k[0] * 255 + 0.5), Int(k[1] * 255 + 0.5), Int(k[2] * 255 + 0.5))
    }
    var bill = "M \(s(Duck.billStart)) Q \(s(Duck.billUpper)) \(s(Duck.billTip)) Q \(s(Duck.billLower)) \(s(Duck.billEnd)) Z"
    bill = bill.replacingOccurrences(of: "  ", with: " ")
    var body = "M \(s(Duck.tail))"
    for segment in Duck.belly {
        body += " Q \(s(segment.control)) \(s(segment.to))"
    }
    // Up the front of the head, over the top, down the back. On the page, with y pointing
    // down, that is anticlockwise: sweep 0. More than half a circle: large arc 1.
    let r = String(format: "%.2f", Duck.headRadius * 100)
    body += " A \(r) \(r) 0 1 0 \(s(Duck.onHead(Duck.arcEnd)))"
    body += " Q \(s(Duck.backControl)) \(s(Duck.tail)) Z"
    let mouth = "M \(s(Duck.mouth.from)) Q \(s(Duck.mouth.control)) \(s(Duck.mouth.to))"
    let wing = "M \(s(Duck.wing.from)) Q \(s(Duck.wing.control)) \(s(Duck.wing.to))"
    let line = Duck.line * 100
    let e = Duck.eyeRadius * 100
    let eye = CGPoint(x: Duck.eye.x * 100, y: (1 - Duck.eye.y) * 100)
    let highlight = CGPoint(x: eye.x + e * 0.2, y: eye.y - e * 0.25)
    return """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
      <path d="\(bill)" fill="\(hex(orange))" stroke="\(hex(ink))" stroke-width="\(line)" stroke-linejoin="round"/>
      <path d="\(body)" fill="\(hex(yellow))" stroke="\(hex(ink))" stroke-width="\(line)" stroke-linejoin="round"/>
      <path d="\(mouth)" fill="none" stroke="\(hex(ink))" stroke-width="\(line * 0.8)" stroke-linecap="round"/>
      <path d="\(wing)" fill="none" stroke="\(hex(ink))" stroke-width="\(line)" stroke-linecap="round"/>
      <circle cx="\(String(format: "%.2f", eye.x))" cy="\(String(format: "%.2f", eye.y))" r="\(e)" fill="\(hex(ink))"/>
      <circle cx="\(String(format: "%.2f", highlight.x))" cy="\(String(format: "%.2f", highlight.y))" r="\(e * 0.38)" fill="#FFFFFF"/>
    </svg>

    """
}

// MARK: - Files

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

try svg().write(to: iconsDir.appendingPathComponent("duck.svg"), atomically: true, encoding: .utf8)
print("duck.svg written")
