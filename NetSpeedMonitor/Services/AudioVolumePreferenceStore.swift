import Foundation

final class AudioVolumePreferenceStore {
    private let defaults: UserDefaults
    private let keyPrefix = "AudioMixer.Volume."
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func volume(for targetID: String, maxVolume: Double = 1.0) -> Double {
        let key = keyPrefix + targetID
        guard defaults.object(forKey: key) != nil else { return 1.0 }
        return clamp(defaults.double(forKey: key), maxVolume: maxVolume)
    }
    
    func setVolume(_ volume: Double, for targetID: String) {
        defaults.set(clamp(volume, maxVolume: ProcessVolumeEngine.maxVolume), forKey: keyPrefix + targetID)
    }
    
    private func clamp(_ value: Double, maxVolume: Double) -> Double {
        guard value.isFinite else { return 1 }
        return min(max(value, 0), maxVolume)
    }
}
