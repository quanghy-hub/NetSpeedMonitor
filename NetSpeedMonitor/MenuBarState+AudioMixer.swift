import Foundation

extension MenuBarState {
    func refreshAudioMixer() {
        guard !isAudioMixerRefreshing else { return }
        isAudioMixerRefreshing = true
        audioMixerStatus = "Scanning audio..."

        Task {
            let items = await self.audioSessionCatalog.loadItems()
            self.audioMixerItems = items
            self.audioMixerStatus = items.isEmpty ? "No audible app or media tab found" : "\(items.count) audio source\(items.count == 1 ? "" : "s")"
            self.isAudioMixerRefreshing = false
        }
    }

    func setAudioVolume(_ volume: Double, for itemID: AudioMixerItem.ID, commitImmediately: Bool = false) {
        guard let index = audioMixerItems.firstIndex(where: { $0.id == itemID }) else { return }
        let item = audioMixerItems[index]
        let clampedVolume = min(max(volume, 0), item.maxVolume)
        let updatedItem = item.withVolume(clampedVolume)
        audioMixerItems[index] = updatedItem

        audioCommitTasks[itemID]?.cancel()

        let commit = { [weak self] in
            guard let self else { return }
            Task {
                await self.audioSessionCatalog.setVolume(clampedVolume, for: updatedItem)
            }
        }

        if commitImmediately {
            commit()
            audioCommitTasks[itemID] = nil
            return
        }

        audioCommitTasks[itemID] = Task {
            do {
                try await Task.sleep(nanoseconds: 120_000_000) // 0.12 seconds
                guard !Task.isCancelled else { return }
                commit()
            } catch {
            }
        }
    }
}
