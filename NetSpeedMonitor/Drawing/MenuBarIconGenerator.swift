import AppKit

final class MenuBarIconGenerator {

    // MARK: - Original Text Icon (Template)

    /// Generates a simple template image rendering text for the menu bar icon.
    static func generateIcon(
        text: String,
        font: NSFont = .monospacedSystemFont(ofSize: 9.5, weight: .semibold)
    ) -> NSImage {
        let style = NSMutableParagraphStyle()
        style.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: style
        ]

        // Calculate dynamic size of the text
        let textSize = text.size(withAttributes: attributes)

        // Add minimal horizontal padding (e.g. 4px) to make it look premium without wasting space
        let padding: CGFloat = 4
        let imageWidth = max(textSize.width + padding, 20) // Ensure a safe minimum width

        let image = NSImage(size: NSSize(width: imageWidth, height: 22), flipped: false) { rect in
            let textRect = NSRect(
                x: (rect.width - textSize.width) / 2,
                y: (rect.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
            return true
        }

        image.isTemplate = true
        return image
    }

    // MARK: - Vertical Bar Icon (Battery-style)

    /// Draws a single vertical bar indicator, similar to macOS battery icon but vertical.
    /// Implements a fill-from-bottom pattern based on percentage with color thresholds.
    private static func drawVerticalBar(
        in context: CGContext,
        rect: CGRect,
        percentage: Double,
        fillColor: NSColor,
        borderColor: NSColor
    ) {
        let barWidth: CGFloat = 10
        let barHeight: CGFloat = 20
        let cornerRadius: CGFloat = 2.0

        // Center bar in the given rect
        let barX = rect.minX + (rect.width - barWidth) / 2
        let barY = rect.minY + (rect.height - barHeight) / 2

        let barRect = CGRect(x: barX, y: barY, width: barWidth, height: barHeight)
        let barPath = NSBezierPath(roundedRect: barRect, xRadius: cornerRadius, yRadius: cornerRadius)

        // Draw background capsule filled with semi-transparent color
        borderColor.withAlphaComponent(0.25).setFill()
        barPath.fill()

        // Draw fill from bottom to top based on percentage
        let clampedPercentage = min(max(percentage, 0.0), 1.0)
        let fillHeight = barHeight * clampedPercentage

        if fillHeight > 0 {
            context.saveGState()
            barPath.addClip()

            let fillRect = CGRect(
                x: barX,
                y: barY,
                width: barWidth,
                height: fillHeight
            )

            // Color based on usage level
            let displayColor: NSColor
            if clampedPercentage > 0.9 {
                displayColor = NSColor.systemRed
            } else if clampedPercentage > 0.75 {
                displayColor = NSColor.systemOrange
            } else {
                displayColor = fillColor
            }

            displayColor.setFill()
            let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: cornerRadius, yRadius: cornerRadius)
            fillPath.fill()

            context.restoreGState()
        }
    }

    // MARK: - Combined Icon (Bars + Text)

    /// Generates a combined icon composed of vertical bars (CPU, RAM, Battery) and text.
    /// Properly handles dark/light mode appearance by reading the current drawing context.
    static func generateCombinedIcon(
        text: String,
        cpuUsage: Double,
        ramUsage: Double,
        batteryLevel: Double,
        batteryIsCharging: Bool,
        showCPU: Bool,
        showRAM: Bool,
        showBattery: Bool,
        cpuColor: NSColor,
        ramColor: NSColor,
        batteryColor: NSColor,
        font: NSFont = .monospacedSystemFont(ofSize: 9.5, weight: .semibold)
    ) -> NSImage {
        // If no bars shown, fall back to original text-only icon
        if !showCPU && !showRAM && !showBattery {
            return generateIcon(text: text, font: font)
        }

        let barSlotWidth: CGFloat = 12
        let spacing: CGFloat = 2
        let menuBarHeight: CGFloat = 22

        // Calculate bars width
        var barCount = 0
        if showCPU { barCount += 1 }
        if showRAM { barCount += 1 }
        if showBattery { barCount += 1 }
        let barsWidth = CGFloat(barCount) * barSlotWidth + CGFloat(max(barCount - 1, 0)) * spacing

        // Calculate text size
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let textSize = text.size(withAttributes: [
            .font: font,
            .paragraphStyle: style
        ])
        let textPadding: CGFloat = 4
        let textWidth = max(textSize.width + textPadding, 20)

        // Spacing between bars and text
        let gapBetween: CGFloat = 2
        let totalWidth = barsWidth + gapBetween + textWidth

        // Generate a single non-template image, but inside the draw handler we read the current appearance context!
        let image = NSImage(size: NSSize(width: totalWidth, height: menuBarHeight), flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return true }

            // Get the current drawing appearance context set by the system (menu bar)
            let menuBarAppearance = NSAppearance.currentDrawing()
            let isDark = menuBarAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

            // Set foregroundColor to high contrast white (on dark background) or black (on light background)
            let foregroundColor = isDark ? NSColor.white : NSColor.black

            // Draw bars on the left
            var xOffset: CGFloat = 0

            if showCPU {
                let cpuRect = CGRect(x: xOffset, y: 0, width: barSlotWidth, height: menuBarHeight)
                context.saveGState()
                MenuBarIconGenerator.drawVerticalBar(
                    in: context,
                    rect: cpuRect,
                    percentage: cpuUsage,
                    fillColor: cpuColor,
                    borderColor: foregroundColor
                )
                context.restoreGState()
                xOffset += barSlotWidth + spacing
            }

            if showRAM {
                let ramRect = CGRect(x: xOffset, y: 0, width: barSlotWidth, height: menuBarHeight)
                context.saveGState()
                MenuBarIconGenerator.drawVerticalBar(
                    in: context,
                    rect: ramRect,
                    percentage: ramUsage,
                    fillColor: ramColor,
                    borderColor: foregroundColor
                )
                context.restoreGState()
                xOffset += barSlotWidth + spacing
            }

            if showBattery {
                let batteryRect = CGRect(x: xOffset, y: 0, width: barSlotWidth, height: menuBarHeight)
                context.saveGState()
                BatteryBarRenderer.draw(
                    in: context,
                    rect: batteryRect,
                    percentage: batteryLevel,
                    isCharging: batteryIsCharging,
                    fillColor: batteryColor,
                    foregroundColor: foregroundColor
                )
                context.restoreGState()
                xOffset += barSlotWidth
            }

            // Draw text on the right
            let textX = xOffset + gapBetween + (textWidth - textSize.width) / 2
            let textY = (rect.height - textSize.height) / 2
            let textRect = NSRect(
                x: textX,
                y: textY,
                width: textSize.width,
                height: textSize.height
            )

            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .paragraphStyle: style,
                .foregroundColor: foregroundColor
            ]
            text.draw(in: textRect, withAttributes: textAttributes)

            return true
        }

        // Don't set as template so colors of the fills are preserved
        image.isTemplate = false
        return image
    }
}
