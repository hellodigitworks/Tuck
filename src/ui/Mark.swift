import AppKit

/// The one mark Tuck puts in the menu bar: a plus that turns into an ✕ by rotating
/// 45 degrees. Plus while icons are hidden, ✕ while they are showing.
///
/// Drawn rather than an SF Symbol, because the rotation has to land on any angle in
/// between. Sized and weighted to sit with the system's own menu bar glyphs.
enum Mark {
    private static let box: CGFloat = 18
    private static let arm: CGFloat = 6.6
    private static let stroke: CGFloat = 1.7

    /// Frames from plus (0) to ✕ (1). Precomputed once: the animation only swaps images.
    private static let frames: [NSImage] = (0..<25).map { step in
        draw(fraction: CGFloat(step) / 24)
    }

    static func image(fraction: CGFloat) -> NSImage {
        frames[index(for: fraction)]
    }

    private static func index(for fraction: CGFloat) -> Int {
        let clamped = min(max(fraction, 0), 1)
        return Int((clamped * CGFloat(frames.count - 1)).rounded())
    }

    private static func draw(fraction: CGFloat) -> NSImage {
        let angle = fraction * .pi / 4
        let image = NSImage(size: NSSize(width: box, height: box), flipped: false) { rect in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let path = NSBezierPath()
            path.lineWidth = stroke
            path.lineCapStyle = .round
            for base in [CGFloat.zero, .pi / 2] {
                let dx = cos(base + angle) * arm
                let dy = sin(base + angle) * arm
                path.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
                path.line(to: CGPoint(x: center.x + dx, y: center.y + dy))
            }
            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        // Template: the menu bar tints it for light and dark on its own.
        image.isTemplate = true
        return image
    }
}
