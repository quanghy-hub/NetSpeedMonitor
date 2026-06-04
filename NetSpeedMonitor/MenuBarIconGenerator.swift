import AppKit

final class MenuBarIconGenerator {
    
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
}
