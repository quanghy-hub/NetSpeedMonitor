import AppKit
import Foundation

enum ColorArchiveTests {
    static func run() throws {
        let original = NSColor(displayP3Red: 1, green: 0.1, blue: 0.2, alpha: 1)
        guard let archive = ColorArchive.encode(original),
              let restored = ColorArchive.decode(archive),
              let restoredP3 = restored.usingColorSpace(.displayP3) else {
            fatalError("Display P3 color should round-trip through secure storage")
        }

        expect(restored.colorSpace == .displayP3, "The original Display P3 color space should be preserved")
        expect(abs(restoredP3.redComponent - 1) < 0.0001, "The red component should be preserved")
        expect(abs(restoredP3.greenComponent - 0.1) < 0.0001, "The green component should be preserved")
        expect(abs(restoredP3.blueComponent - 0.2) < 0.0001, "The blue component should be preserved")
        expect(ColorArchive.resolve("invalid", fallbackHex: "#123456").toHex() == "#123456", "Invalid archives should use the HEX fallback")
    }
}
