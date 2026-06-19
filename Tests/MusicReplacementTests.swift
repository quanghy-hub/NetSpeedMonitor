import AppKit
import Foundation

@main
struct MusicReplacementTests {
    @MainActor
    static func main() throws {
        try testEmptyValueDisablesReplacement()
        try testWebsiteValidation()
        try testApplicationValidation()
        try testBlockedApplicationValidation()
        try testWideGamutColorArchive()
        testMediaPlayKeyParsing()
        print("MusicReplacementTests: all tests passed")
    }

    private static func testEmptyValueDisablesReplacement() throws {
        let replacement = try MusicReplacement.parse("  \n")
        expect(replacement == nil, "An empty value should disable the replacement")
    }

    private static func testWebsiteValidation() throws {
        let replacement = try MusicReplacement.parse("https://open.spotify.com/collection")
        expect(replacement?.kind == .website, "An HTTPS URL should be accepted")
        expect(replacement?.storedValue == "https://open.spotify.com/collection", "The URL should be preserved")

        expectError(.unsupportedValue) {
            _ = try MusicReplacement.parse("spotify://collection")
        }
        expectError(.unsupportedValue) {
            _ = try MusicReplacement.parse("Spotify.app")
        }
    }

    private static func testApplicationValidation() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let applicationURL = temporaryDirectory.appendingPathComponent("Player.app")
        try FileManager.default.createDirectory(at: applicationURL, withIntermediateDirectories: true)

        let replacement = try MusicReplacement.parse(applicationURL.path)
        expect(replacement?.kind == .application, "An existing .app directory should be accepted")
        expect(replacement?.storedValue == applicationURL.path, "The app path should be standardized")

        expectError(.applicationDoesNotExist) {
            _ = try MusicReplacement.parse(temporaryDirectory.appendingPathComponent("Missing.app").path)
        }
        expectError(.applicationRequired) {
            _ = try MusicReplacement.parse(temporaryDirectory.path)
        }
    }

    private static func testBlockedApplicationValidation() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let applicationURL = temporaryDirectory.appendingPathComponent("Music.app")
        let contentsURL = applicationURL.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)

        let plist: [String: Any] = [
            "CFBundleIdentifier": "com.apple.Music",
            "CFBundlePackageType": "APPL"
        ]
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try plistData.write(to: contentsURL.appendingPathComponent("Info.plist"))

        expectError(.blockedApplication) {
            _ = try MusicReplacement.parse(applicationURL.path)
        }
    }

    private static func testWideGamutColorArchive() throws {
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

    @MainActor
    private static func testMediaPlayKeyParsing() {
        let playKeyDown = (16 << 16) | (0xA << 8)
        let playKeyUp = (16 << 16) | (0xB << 8)
        let repeatedPlayKeyDown = playKeyDown | 0x1
        let nextKeyDown = (17 << 16) | (0xA << 8)

        expect(MediaPlayKeyMonitor.isInitialPlayPress(data1: playKeyDown), "Play key-down should be handled")
        expect(!MediaPlayKeyMonitor.isInitialPlayPress(data1: playKeyUp), "Play key-up should be ignored")
        expect(!MediaPlayKeyMonitor.isInitialPlayPress(data1: repeatedPlayKeyDown), "Repeated Play should be ignored")
        expect(!MediaPlayKeyMonitor.isInitialPlayPress(data1: nextKeyDown), "Other media keys should be ignored")
    }


    private static func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("NetSpeedMonitorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func expectError(
        _ expectedError: MusicReplacement.ValidationError,
        operation: () throws -> Void
    ) {
        do {
            try operation()
            fatalError("Expected \(expectedError), but validation succeeded")
        } catch let error as MusicReplacement.ValidationError {
            expect(error == expectedError, "Expected \(expectedError), received \(error)")
        } catch {
            fatalError("Unexpected error: \(error)")
        }
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fatalError(message) }
    }
}
