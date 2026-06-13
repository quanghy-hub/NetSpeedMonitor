import AppKit

final class MenuBarIconGenerator {
    
    // MARK: - Original Text Icon (Template)
    
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
    
    /// Draws a single vertical bar indicator, similar to macOS battery icon but vertical
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
        
        // Draw border/outline with adaptive color
        borderColor.withAlphaComponent(0.85).setStroke()
        barPath.lineWidth = 1.0
        barPath.stroke()
        
        // Draw fill from bottom to top based on percentage
        let clampedPercentage = min(max(percentage, 0.0), 1.0)
        let fillHeight = (barHeight - 2) * clampedPercentage
        
        if fillHeight > 0 {
            let fillRect = CGRect(
                x: barX + 1,
                y: barY + 1,
                width: barWidth - 2,
                height: fillHeight
            )
            let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: cornerRadius * 0.5, yRadius: cornerRadius * 0.5)
            
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
            fillPath.fill()
        }
    }
    
    // MARK: - Battery Bar (with charging animation)
    
    private static func drawBatteryBar(
        in context: CGContext,
        rect: CGRect,
        percentage: Double,
        isCharging: Bool,
        animationPhase: Int,
        fillColor: NSColor,
        borderColor: NSColor
    ) {
        let barWidth: CGFloat = 10
        let barHeight: CGFloat = 20
        let cornerRadius: CGFloat = 2.0
        
        let barX = rect.minX + (rect.width - barWidth) / 2
        let barY = rect.minY + (rect.height - barHeight) / 2
        
        let barRect = CGRect(x: barX, y: barY, width: barWidth, height: barHeight)
        let barPath = NSBezierPath(roundedRect: barRect, xRadius: cornerRadius, yRadius: cornerRadius)
        
        // Border with adaptive color
        borderColor.withAlphaComponent(0.85).setStroke()
        barPath.lineWidth = 1.0
        barPath.stroke()
        
        // Fill
        let clampedPercentage = min(max(percentage, 0.0), 1.0)
        let fillHeight = (barHeight - 2) * clampedPercentage
        
        if fillHeight > 0 {
            let fillRect = CGRect(
                x: barX + 1,
                y: barY + 1,
                width: barWidth - 2,
                height: fillHeight
            )
            let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: cornerRadius * 0.5, yRadius: cornerRadius * 0.5)
            
            let displayColor: NSColor
            if clampedPercentage <= 0.1 {
                displayColor = NSColor.systemRed
            } else if clampedPercentage <= 0.2 {
                displayColor = NSColor.systemOrange
            } else {
                displayColor = fillColor
            }
            
            displayColor.setFill()
            fillPath.fill()
        }
        
        // Charging: draw lightning bolt (filled, no border, centered)
        if isCharging {
            let boltWidth: CGFloat = 6.0
            let boltHeight: CGFloat = 12.0
            let boltX = barX + (barWidth - boltWidth) / 2
            let boltY = barY + (barHeight - boltHeight) / 2
            
            let bolt = NSBezierPath()
            // Draw lightning bolt shape (top-right to bottom-left zigzag)
            bolt.move(to: CGPoint(x: boltX + boltWidth * 0.55, y: boltY + boltHeight))        // top
            bolt.line(to: CGPoint(x: boltX + boltWidth * 0.15, y: boltY + boltHeight * 0.55)) // mid-left
            bolt.line(to: CGPoint(x: boltX + boltWidth * 0.45, y: boltY + boltHeight * 0.55)) // mid-center
            bolt.line(to: CGPoint(x: boltX + boltWidth * 0.35, y: boltY))                     // bottom
            bolt.line(to: CGPoint(x: boltX + boltWidth * 0.85, y: boltY + boltHeight * 0.45)) // mid-right
            bolt.line(to: CGPoint(x: boltX + boltWidth * 0.55, y: boltY + boltHeight * 0.45)) // mid-center
            bolt.close()
            
            NSColor.white.setFill()
            bolt.fill()
        }
    }
    
    // MARK: - Combined Icon (Bars + Text)
    
    static func generateCombinedIcon(
        text: String,
        cpuUsage: Double,
        ramUsage: Double,
        batteryLevel: Double,
        batteryIsCharging: Bool,
        chargingAnimationPhase: Int,
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
            // Get the current drawing appearance context set by the system (menu bar)
            let menuBarAppearance = NSAppearance.currentDrawing()
            let isDark = menuBarAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            
            // Set foregroundColor to high contrast white (on dark background) or black (on light background)
            let foregroundColor = isDark ? NSColor.white : NSColor.black
            
            // Draw bars on the left
            var xOffset: CGFloat = 0
            
            if showCPU {
                let cpuRect = CGRect(x: xOffset, y: 0, width: barSlotWidth, height: menuBarHeight)
                NSGraphicsContext.current?.cgContext.saveGState()
                MenuBarIconGenerator.drawVerticalBar(
                    in: NSGraphicsContext.current!.cgContext,
                    rect: cpuRect,
                    percentage: cpuUsage,
                    fillColor: cpuColor,
                    borderColor: foregroundColor
                )
                NSGraphicsContext.current?.cgContext.restoreGState()
                xOffset += barSlotWidth + spacing
            }
            
            if showRAM {
                let ramRect = CGRect(x: xOffset, y: 0, width: barSlotWidth, height: menuBarHeight)
                NSGraphicsContext.current?.cgContext.saveGState()
                MenuBarIconGenerator.drawVerticalBar(
                    in: NSGraphicsContext.current!.cgContext,
                    rect: ramRect,
                    percentage: ramUsage,
                    fillColor: ramColor,
                    borderColor: foregroundColor
                )
                NSGraphicsContext.current?.cgContext.restoreGState()
                xOffset += barSlotWidth + spacing
            }
            
            if showBattery {
                let batteryRect = CGRect(x: xOffset, y: 0, width: barSlotWidth, height: menuBarHeight)
                NSGraphicsContext.current?.cgContext.saveGState()
                MenuBarIconGenerator.drawBatteryBar(
                    in: NSGraphicsContext.current!.cgContext,
                    rect: batteryRect,
                    percentage: batteryLevel,
                    isCharging: batteryIsCharging,
                    animationPhase: chargingAnimationPhase,
                    fillColor: batteryColor,
                    borderColor: foregroundColor
                )
                NSGraphicsContext.current?.cgContext.restoreGState()
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
