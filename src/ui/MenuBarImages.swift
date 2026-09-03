import AppKit

/// The three marks Tuck puts in the menu bar. All template images, so they follow
/// the menu bar's light or dark appearance on their own.
enum MenuBarImages {
    static let chevronLeft = symbol("chevron.left")
    static let chevronRight = symbol("chevron.right")
    static let separator = line(dashed: false)
    static let dottedSeparator = line(dashed: true)

    private static func symbol(_ name: String) -> NSImage? {
        let configuration = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)
        image?.isTemplate = true
        return image
    }

    private static func line(dashed: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 8, height: 18), flipped: false) { rect in
            let path = NSBezierPath()
            path.lineWidth = 1.5
            path.lineCapStyle = .round
            if dashed {
                path.setLineDash([1.5, 3], count: 2, phase: 0)
            }
            path.move(to: NSPoint(x: rect.midX, y: 2))
            path.line(to: NSPoint(x: rect.midX, y: rect.maxY - 2))
            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}
