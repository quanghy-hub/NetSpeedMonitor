import Foundation

@main
struct TestRunner {
    @MainActor
    static func main() throws {
        try MusicReplacementTests.run()
        try ColorArchiveTests.run()
        MediaPlayKeyMonitorTests.run()
        BrowserAudioScriptsTests.run()
        SpeedFormatterTests.run()
        print("NetSpeedMonitor tests: all tests passed")
    }
}
