import Foundation

enum MediaPlayKeyMonitorTests {
    @MainActor
    static func run() {
        let playKeyDown = (16 << 16) | (0xA << 8)
        let playKeyUp = (16 << 16) | (0xB << 8)
        let repeatedPlayKeyDown = playKeyDown | 0x1
        let nextKeyDown = (17 << 16) | (0xA << 8)

        expect(MediaPlayKeyMonitor.isInitialPlayPress(data1: playKeyDown), "Play key-down should be handled")
        expect(!MediaPlayKeyMonitor.isInitialPlayPress(data1: playKeyUp), "Play key-up should be ignored")
        expect(!MediaPlayKeyMonitor.isInitialPlayPress(data1: repeatedPlayKeyDown), "Repeated Play should be ignored")
        expect(!MediaPlayKeyMonitor.isInitialPlayPress(data1: nextKeyDown), "Other media keys should be ignored")
    }
}
