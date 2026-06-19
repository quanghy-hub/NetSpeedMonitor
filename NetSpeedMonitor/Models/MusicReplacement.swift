import Foundation

struct MusicReplacement: Equatable {
    enum Kind: Equatable {
        case application
        case website
    }

    enum ValidationError: LocalizedError, Equatable {
        case unsupportedValue
        case applicationDoesNotExist
        case applicationRequired
        case blockedApplication

        var errorDescription: String? {
            switch self {
            case .unsupportedValue:
                return "Enter an absolute .app path or an http/https URL."
            case .applicationDoesNotExist:
                return "The selected application does not exist."
            case .applicationRequired:
                return "The replacement path must point to an .app bundle."
            case .blockedApplication:
                return "Music and iTunes cannot be used as their own replacement."
            }
        }
    }

    let kind: Kind
    let url: URL

    var storedValue: String {
        switch kind {
        case .application:
            return url.path
        case .website:
            return url.absoluteString
        }
    }

    static func parse(_ value: String, fileManager: FileManager = .default) throws -> MusicReplacement? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }

        if let website = URL(string: trimmedValue),
           let scheme = website.scheme?.lowercased(),
           ["http", "https"].contains(scheme),
           website.host != nil {
            return MusicReplacement(kind: .website, url: website)
        }

        guard trimmedValue.hasPrefix("/") else {
            throw ValidationError.unsupportedValue
        }

        let applicationURL = URL(fileURLWithPath: trimmedValue).standardizedFileURL
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: applicationURL.path, isDirectory: &isDirectory) else {
            throw ValidationError.applicationDoesNotExist
        }
        guard isDirectory.boolValue, applicationURL.pathExtension.lowercased() == "app" else {
            throw ValidationError.applicationRequired
        }

        let blockedBundleIdentifiers = ["com.apple.Music", "com.apple.iTunes"]
        if let bundleIdentifier = Bundle(url: applicationURL)?.bundleIdentifier,
           blockedBundleIdentifiers.contains(bundleIdentifier) {
            throw ValidationError.blockedApplication
        }

        return MusicReplacement(kind: .application, url: applicationURL)
    }
}
