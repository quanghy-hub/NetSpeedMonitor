import Foundation

enum SpeedUnit: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case kb = "KB/s"
    case mb = "MB/s"
    case bytes = "B/s"
    case bits = "bps"
    
    var id: String { self.rawValue }
}
