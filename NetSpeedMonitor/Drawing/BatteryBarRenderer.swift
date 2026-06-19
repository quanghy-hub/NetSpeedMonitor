import AppKit

enum BatteryBarRenderer {
    static func draw(
        in context: CGContext,
        rect: CGRect,
        percentage: Double,
        isCharging: Bool,
        fillColor: NSColor,
        foregroundColor: NSColor
    ) {
        let barSize = CGSize(width: 10, height: 20)
        let cornerRadius: CGFloat = 2
        let barRect = CGRect(
            x: rect.midX - barSize.width / 2,
            y: rect.midY - barSize.height / 2,
            width: barSize.width,
            height: barSize.height
        )
        let barPath = NSBezierPath(
            roundedRect: barRect,
            xRadius: cornerRadius,
            yRadius: cornerRadius
        )

        foregroundColor.withAlphaComponent(0.25).setFill()
        barPath.fill()

        let level = min(max(percentage, 0), 1)
        drawLevel(
            level,
            in: context,
            barRect: barRect,
            clipPath: barPath,
            cornerRadius: cornerRadius,
            preferredColor: fillColor
        )

        if isCharging {
            drawChargingBolt(in: barRect, color: foregroundColor)
        }
    }

    private static func drawLevel(
        _ level: Double,
        in context: CGContext,
        barRect: CGRect,
        clipPath: NSBezierPath,
        cornerRadius: CGFloat,
        preferredColor: NSColor
    ) {
        let fillHeight = barRect.height * level
        guard fillHeight > 0 else { return }

        context.saveGState()
        defer { context.restoreGState() }
        clipPath.addClip()

        let fillRect = CGRect(
            x: barRect.minX,
            y: barRect.minY,
            width: barRect.width,
            height: fillHeight
        )
        let displayColor: NSColor
        if level <= 0.1 {
            displayColor = .systemRed
        } else if level <= 0.2 {
            displayColor = .systemOrange
        } else {
            displayColor = preferredColor
        }

        displayColor.setFill()
        NSBezierPath(
            roundedRect: fillRect,
            xRadius: cornerRadius,
            yRadius: cornerRadius
        ).fill()
    }

    private static func drawChargingBolt(in barRect: CGRect, color: NSColor) {
        let boltSize = CGSize(width: 10, height: 18)
        let sizeConfiguration = NSImage.SymbolConfiguration(
            pointSize: boltSize.height,
            weight: .heavy
        )
        let colorConfiguration = NSImage.SymbolConfiguration(paletteColors: [color])
        guard let bolt = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "Charging")?
            .withSymbolConfiguration(sizeConfiguration.applying(colorConfiguration)) else {
            return
        }

        bolt.draw(in: CGRect(
            x: barRect.midX - boltSize.width / 2,
            y: barRect.midY - boltSize.height / 2,
            width: boltSize.width,
            height: boltSize.height
        ))
    }
}
