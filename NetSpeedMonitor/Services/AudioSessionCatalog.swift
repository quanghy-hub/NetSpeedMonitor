import AppKit
import CoreAudio
import Foundation

actor AudioSessionCatalog {
    private let browserController: BrowserAudioController
    private let volumeStore: AudioVolumePreferenceStore
    private let processVolumeEngine: ProcessVolumeEngine
    
    init(
        browserController: BrowserAudioController = BrowserAudioController(),
        volumeStore: AudioVolumePreferenceStore = AudioVolumePreferenceStore(),
        processVolumeEngine: ProcessVolumeEngine = .shared
    ) {
        self.browserController = browserController
        self.volumeStore = volumeStore
        self.processVolumeEngine = processVolumeEngine
    }
    
    func loadItems() -> [AudioMixerItem] {
        let sessions = audioOutputSessions()
        let audiblePIDs = Set(sessions.compactMap(\.processID))
        let browserTabs = browserController.audibleTabs(matching: audiblePIDs)
        let tabProcessIDs = Set(browserTabs.compactMap(\.processID))
        
        let appItems = sessions
            .filter(\.isRunningOutput)
            .filter { session in
                guard let processID = session.processID else { return true }
                return !tabProcessIDs.contains(processID)
            }
            .map { item(for: $0) }
        
        let tabItems = browserTabs.map { item(for: $0) }
        let items = (tabItems + appItems).sorted { lhs, rhs in
            if lhs.canSetVolume != rhs.canSetVolume {
                return lhs.canSetVolume
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        processVolumeEngine.reconcile(activeTargets: Dictionary(uniqueKeysWithValues: appItems.map { ($0.id, $0.audioObjectIDs) }))
        return items
    }
    
    func setVolume(_ volume: Double, for item: AudioMixerItem) {
        volumeStore.setVolume(volume, for: item.id)
        
        switch item.kind {
        case .app:
            processVolumeEngine.apply(volume: volume, targetID: item.id, audioObjectIDs: item.audioObjectIDs)
        case .browserTab:
            guard let tab = browserController.audibleTabs(matching: []).first(where: { $0.id == item.id }) else {
                return
            }
            _ = browserController.setVolume(volume, for: tab)
        }
    }
    
    func stop() {
        processVolumeEngine.stopAll()
    }
    
    private func item(for session: AudioOutputSession) -> AudioMixerItem {
        let volume = volumeStore.volume(for: session.id, maxVolume: ProcessVolumeEngine.maxVolume)
        
        return AudioMixerItem(
            id: session.id,
            kind: .app,
            processID: session.processID,
            bundleIdentifier: session.bundleID,
            title: session.name,
            subtitle: "App audio output",
            isAudible: session.isRunningOutput,
            canSetVolume: true,
            volume: volume,
            maxVolume: ProcessVolumeEngine.maxVolume,
            audioObjectIDs: session.audioObjectIDs
        )
    }
    
    private func item(for tab: BrowserAudioTab) -> AudioMixerItem {
        let subtitle = "\(tab.browserName) window \(tab.windowIndex), tab \(tab.tabIndex)"
        return AudioMixerItem(
            id: tab.id,
            kind: .browserTab,
            processID: tab.processID,
            bundleIdentifier: tab.browserBundleIdentifier,
            title: tab.title,
            subtitle: subtitle,
            isAudible: tab.isAudible,
            canSetVolume: tab.canSetVolume,
            volume: volumeStore.volume(for: tab.id, maxVolume: 1),
            maxVolume: 1,
            audioObjectIDs: []
        )
    }
    
    private func audioOutputSessions() -> [AudioOutputSession] {
        guard #available(macOS 14.4, *) else { return [] }
        
        let ownPID = ProcessInfo.processInfo.processIdentifier
        var groups: [pid_t: AudioOutputSessionBuilder] = [:]
        
        for objectID in audioProcessObjectIDs() {
            var pid: pid_t = -1
            guard read(objectID, kAudioProcessPropertyPID, &pid), pid > 0, pid != ownPID else {
                continue
            }
            
            let ownerPID = ResponsibleAudioProcessResolver.ownerPID(for: pid)
            guard let app = NSRunningApplication(processIdentifier: ownerPID),
                  app.activationPolicy == .regular else {
                continue
            }
            
            var runningOutput: UInt32 = 0
            _ = read(objectID, kAudioProcessPropertyIsRunningOutput, &runningOutput)
            
            var builder = groups[ownerPID] ?? AudioOutputSessionBuilder(
                processID: ownerPID,
                bundleID: app.bundleIdentifier,
                name: ResponsibleAudioProcessResolver.displayName(for: ownerPID, fallback: "PID \(ownerPID)")
            )
            builder.audioObjectIDs.append(objectID)
            builder.isRunningOutput = builder.isRunningOutput || runningOutput != 0
            groups[ownerPID] = builder
        }
        
        return groups.values.map { $0.session }.filter(\.isRunningOutput).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
    
    private func audioProcessObjectIDs() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size) == noErr else {
            return []
        }
        
        var objectIDs = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &objectIDs) == noErr else {
            return []
        }
        return objectIDs
    }
    
    private func read<T>(_ objectID: AudioObjectID, _ selector: AudioObjectPropertySelector, _ value: inout T) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<T>.size)
        return withUnsafeMutablePointer(to: &value) { pointer in
            AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, pointer) == noErr
        }
    }
}

private struct AudioOutputSessionBuilder {
    let processID: pid_t
    let bundleID: String?
    let name: String
    var audioObjectIDs: [AudioObjectID] = []
    var isRunningOutput = false
    
    var session: AudioOutputSession {
        AudioOutputSession(
            processID: processID,
            bundleID: bundleID,
            name: name,
            audioObjectIDs: audioObjectIDs.sorted(),
            isRunningOutput: isRunningOutput
        )
    }
}

private struct AudioOutputSession {
    let processID: pid_t?
    let bundleID: String?
    let name: String
    let audioObjectIDs: [UInt32]
    let isRunningOutput: Bool
    
    var id: String {
        if let bundleID, !bundleID.isEmpty {
            return "app:\(bundleID)"
        }
        if let processID {
            return "pid:\(processID)"
        }
        return "app:\(name)"
    }
}
