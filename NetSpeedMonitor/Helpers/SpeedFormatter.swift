import Foundation

final class SpeedFormatter {
    private static let outputLocale = Locale(identifier: "en_US_POSIX")

    static func format(upload: Double, download: Double, unit: SpeedUnit) -> String {
        var displayDownload = download
        var displayUpload = upload

        switch unit {
        case .auto:
            while displayDownload > 1000.0 {
                displayDownload /= 1024.0
            }
            while displayUpload > 1000.0 {
                displayUpload /= 1024.0
            }
        case .kb:
            displayDownload /= 1024.0
            displayUpload /= 1024.0
        case .mb:
            displayDownload /= (1024.0 * 1024.0)
            displayUpload /= (1024.0 * 1024.0)
        case .bytes:
            break
        case .bits:
            displayDownload *= 8.0
            displayUpload *= 8.0
        }

        let uploadText = String(format: "%.1f", locale: outputLocale, displayUpload)
        let downloadText = String(format: "%.1f", locale: outputLocale, displayDownload)
        return "\(uploadText)\n\(downloadText)"
    }
}
