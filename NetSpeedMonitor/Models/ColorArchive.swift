import AppKit

enum ColorArchive {
    static func encode(_ color: NSColor) -> String? {
        let data: Data
        do {
            data = try NSKeyedArchiver.archivedData(
                withRootObject: color,
                requiringSecureCoding: true
            )
        } catch {
            logger.warning("Failed to archive color: \(error.localizedDescription)")
            return nil
        }
        return data.base64EncodedString()
    }

    static func decode(_ value: String) -> NSColor? {
        guard !value.isEmpty,
              let data = Data(base64Encoded: value) else {
            return nil
        }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        } catch {
            logger.warning("Failed to unarchive color: \(error.localizedDescription)")
            return nil
        }
    }

    static func resolve(_ value: String, fallbackHex: String) -> NSColor {
        decode(value) ?? NSColor(hex: fallbackHex)
    }
}
