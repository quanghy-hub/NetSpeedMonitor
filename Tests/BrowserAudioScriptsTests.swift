import Foundation

enum BrowserAudioScriptsTests {
    static func run() {
        let fractionalScript = BrowserAudioScripts.setMediaVolumeJavaScript(volume: 0.125)
        expect(fractionalScript.contains("const volume = 0.125;"), "Browser volume JavaScript should use a dot decimal separator")

        let lowScript = BrowserAudioScripts.setMediaVolumeJavaScript(volume: -1)
        expect(lowScript.contains("const volume = 0.000;"), "Browser volume JavaScript should clamp low values")

        let highScript = BrowserAudioScripts.setMediaVolumeJavaScript(volume: 2)
        expect(highScript.contains("const volume = 1.000;"), "Browser volume JavaScript should clamp high values")

        let tab = BrowserAudioTab(
            line: "1\t2\t123\tExample\t1\t1\thttps://private.example/watch?id=secret",
            browserName: "Safari"
        )
        expect(tab?.id == "Safari:window:1:tab:2", "Browser tab preference IDs should not include URL data")
        expect(tab?.url == "https://private.example/watch?id=secret", "Browser tab should still keep URL for runtime display/debug context")
    }
}
