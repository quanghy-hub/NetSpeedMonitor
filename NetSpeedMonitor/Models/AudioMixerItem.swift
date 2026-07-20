import Foundation

enum AudioMixerTargetKind: String, Hashable {
    case app
    case browserTab
}

struct AudioMixerItem: Identifiable, Hashable {
    let id: String
    let kind: AudioMixerTargetKind
    let processID: pid_t?
    let bundleIdentifier: String?
    let title: String
    let subtitle: String
    let isAudible: Bool
    let canSetVolume: Bool
    var volume: Double
    let maxVolume: Double
    let audioObjectIDs: [UInt32]

    /// Returns a copy of this item with only the volume replaced.
    func withVolume(_ newVolume: Double) -> AudioMixerItem {
        AudioMixerItem(
            id: id, kind: kind, processID: processID,
            bundleIdentifier: bundleIdentifier, title: title,
            subtitle: subtitle, isAudible: isAudible,
            canSetVolume: canSetVolume, volume: newVolume,
            maxVolume: maxVolume, audioObjectIDs: audioObjectIDs
        )
    }
}

struct BrowserAudioTab: Identifiable, Hashable {
    let id: String
    let browserName: String
    let windowIndex: Int
    let tabIndex: Int
    let processID: pid_t?
    let title: String
    let url: String
    let mediaElementCount: Int
    let audibleMediaElementCount: Int
    
    var canSetVolume: Bool {
        mediaElementCount > 0
    }
    
    var isAudible: Bool {
        audibleMediaElementCount > 0
    }
    
    var browserBundleIdentifier: String? {
        switch browserName {
        case "Safari":
            return "com.apple.Safari"
        case "Google Chrome":
            return "com.google.Chrome"
        default:
            return nil
        }
    }

    init?(line: String, browserName: String) {
        let fields = line.components(separatedBy: "\t")
        guard fields.count >= 7,
              let windowIndex = Int(fields[0]),
              let tabIndex = Int(fields[1]),
              let mediaCount = Int(fields[4]),
              let audibleCount = Int(fields[5]) else { return nil }

        self.browserName = browserName
        self.windowIndex = windowIndex
        self.tabIndex = tabIndex
        self.processID = Int32(fields[2])
        self.title = fields[3].isEmpty ? "Untitled Tab" : fields[3]
        self.mediaElementCount = mediaCount
        self.audibleMediaElementCount = audibleCount
        self.url = fields[6]
        self.id = "\(browserName):window:\(windowIndex):tab:\(tabIndex)"
    }
}
