import SwiftUI
import AppKit

@MainActor
final class AudioMixerViewModel: ObservableObject {
    @Published var audioMixerItems: [AudioMixerItem] = []
    @Published var audioMixerStatus = "Refresh to scan playing apps"
    @Published var isAudioMixerRefreshing = false
    
    let audioSessionCatalog: any AudioSessionProviding
    private var audioCommitTasks: [AudioMixerItem.ID: Task<Void, Never>] = [:]
    
    init(audioSessionCatalog: any AudioSessionProviding) {
        self.audioSessionCatalog = audioSessionCatalog
    }
    
    func refreshAudioMixer() {
        guard !isAudioMixerRefreshing else { return }
        isAudioMixerRefreshing = true
        audioMixerStatus = "Scanning for playing apps..."
        
        let catalog = audioSessionCatalog
        Task {
            let items = await catalog.loadItems()
            self.audioMixerItems = items
            
            if items.isEmpty {
                self.audioMixerStatus = "No playing apps detected."
            } else {
                self.audioMixerStatus = ""
            }
            self.isAudioMixerRefreshing = false
        }
    }
    
    func setAudioVolume(_ volume: Double, for itemID: AudioMixerItem.ID, commitImmediately: Bool = false) {
        if let index = audioMixerItems.firstIndex(where: { $0.id == itemID }) {
            audioMixerItems[index].volume = volume
        }
        
        audioCommitTasks[itemID]?.cancel()
        
        let catalog = audioSessionCatalog
        audioCommitTasks[itemID] = Task {
            if !commitImmediately {
                try? await Task.sleep(nanoseconds: 150_000_000)
                guard !Task.isCancelled else { return }
            }
            guard let item = self.audioMixerItems.first(where: { $0.id == itemID }) else { return }
            await catalog.setVolume(volume, for: item)
        }
    }
    
    deinit {
        for task in audioCommitTasks.values {
            task.cancel()
        }
        let catalog = audioSessionCatalog
        Task {
            await catalog.stop()
        }
    }
}
