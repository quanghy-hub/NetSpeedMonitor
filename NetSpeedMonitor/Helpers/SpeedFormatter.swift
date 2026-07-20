import Foundation

final class SpeedFormatter {
    private static let outputLocale = Locale(identifier: "en_US_POSIX")

    /// Formats upload and download speeds into a display string (upload\ndownload).
    /// Auto mode divides by 1024 repeatedly until < 1000.
    /// Uses en_US_POSIX locale for consistent decimal formatting.
    /// - Parameters:
    ///   - upload: Upload speed to format.
    ///   - download: Download speed to format.
    ///   - unit: The speed unit mapping to use.
    /// - Returns: A formatted string containing both upload and download speeds.
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
