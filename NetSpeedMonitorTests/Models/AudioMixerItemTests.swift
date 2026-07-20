import Testing
@testable import NetSpeedMonitor

@Suite("AudioMixerItem Tests")
struct AudioMixerItemTests {
    
    @Test("withVolume preserves all fields except volume")
    func withVolumePreservesAllFields() {
        let item = AudioMixerItem(
            id: "test-id",
            kind: .app,
            processID: 123,
            bundleIdentifier: "com.test.app",
            title: "Test App",
            subtitle: "Test Subtitle",
            isAudible: true,
            canSetVolume: true,
            volume: 0.5,
            maxVolume: 1.0,
            audioObjectIDs: [1, 2, 3]
        )
        
        let updatedItem = item.withVolume(0.8)
        
        #expect(updatedItem.id == item.id)
        #expect(updatedItem.kind == item.kind)
        #expect(updatedItem.processID == item.processID)
        #expect(updatedItem.bundleIdentifier == item.bundleIdentifier)
        #expect(updatedItem.title == item.title)
        #expect(updatedItem.subtitle == item.subtitle)
        #expect(updatedItem.isAudible == item.isAudible)
        #expect(updatedItem.canSetVolume == item.canSetVolume)
        #expect(updatedItem.maxVolume == item.maxVolume)
        #expect(updatedItem.audioObjectIDs == item.audioObjectIDs)
    }
    
    @Test("withVolume updates the volume")
    func withVolumeUpdatesVolume() {
        let item = AudioMixerItem(
            id: "test-id",
            kind: .app,
            processID: 123,
            bundleIdentifier: "com.test.app",
            title: "Test App",
            subtitle: "Test Subtitle",
            isAudible: true,
            canSetVolume: true,
            volume: 0.5,
            maxVolume: 1.0,
            audioObjectIDs: [1, 2, 3]
        )
        
        let updatedItem = item.withVolume(0.8)
        #expect(updatedItem.volume == 0.8)
    }
}
