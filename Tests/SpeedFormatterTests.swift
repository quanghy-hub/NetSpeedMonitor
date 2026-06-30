import Foundation

enum SpeedFormatterTests {
    static func run() {
        expect(SpeedFormatter.format(upload: 1536, download: 2048, unit: .kb) == "1.5\n2.0", "KB formatting should use KiB conversion")
        expect(SpeedFormatter.format(upload: 1, download: 2, unit: .bits) == "8.0\n16.0", "Bit formatting should convert bytes to bits")
    }
}
