import Foundation

enum MusicReplacementTests {
    static func run() throws {
        try testEmptyValueDisablesReplacement()
        try testWebsiteValidation()
        try testApplicationValidation()
        try testBlockedApplicationValidation()
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
}
