import AppKit

enum ColorArchive {
    static func encode(_ color: NSColor) -> String? {
        guard let data = try? NSKeyedArchiver.archivedData(
            withRootObject: color,
            requiringSecureCoding: true
        ) else {
            return nil
        }
        return data.base64EncodedString()
    }

    static func decode(_ value: String) -> NSColor? {
        guard !value.isEmpty,
              let data = Data(base64Encoded: value) else {
            return nil
        }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
    }

    static func resolve(_ value: String, fallbackHex: String) -> NSColor {
        decode(value) ?? NSColor(hex: fallbackHex)
    }
}
