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
    let volume: Double
    let maxVolume: Double
    let audioObjectIDs: [UInt32]
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
}
