import AppKit

final class ColorSwatchControl: NSControl {
    var color: NSColor = .systemBlue {
        didSet {
            needsDisplay = true
            setAccessibilityValue(color.toHex())
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 22, height: 22)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
        color.withAlphaComponent(isEnabled ? 1 : 0.4).setFill()
        circle.fill()
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        sendAction(action, to: target)
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}
