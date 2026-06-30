import Foundation

enum BrowserAudioScriptsTests {
    static func run() {
        let fractionalScript = BrowserAudioScripts.setMediaVolumeJavaScript(volume: 0.125)
        expect(fractionalScript.contains("const volume = 0.125;"), "Browser volume JavaScript should use a dot decimal separator")

        let lowScript = BrowserAudioScripts.setMediaVolumeJavaScript(volume: -1)
        expect(lowScript.contains("const volume = 0.000;"), "Browser volume JavaScript should clamp low values")

        let highScript = BrowserAudioScripts.setMediaVolumeJavaScript(volume: 2)
        expect(highScript.contains("const volume = 1.000;"), "Browser volume JavaScript should clamp high values")
    }
}
