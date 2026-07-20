import AppKit
import Foundation

final class BrowserAudioController {
    private let scriptRunner: AppleScriptRunning
    
    init(scriptRunner: AppleScriptRunning = OsaScriptRunner()) {
        self.scriptRunner = scriptRunner
    }
    
    func audibleTabs(matching audibleProcessIDs: Set<pid_t>) async -> [BrowserAudioTab] {
        await safariTabs(matching: audibleProcessIDs) + chromeTabs(matching: audibleProcessIDs)
    }
    
    func setVolume(_ volume: Double, for tab: BrowserAudioTab) async -> Bool {
        switch tab.browserName {
        case "Safari":
            return await setSafariVolume(volume, windowIndex: tab.windowIndex, tabIndex: tab.tabIndex)
        case "Google Chrome":
            return await setChromeVolume(volume, windowIndex: tab.windowIndex, tabIndex: tab.tabIndex)
        default:
            return false
        }
    }
    
    private func safariTabs(matching audibleProcessIDs: Set<pid_t>) async -> [BrowserAudioTab] {
        guard isRunning(bundleID: "com.apple.Safari") else { return [] }
        return tabs(from: await run(script: BrowserAudioScripts.safariScanScript()), browserName: "Safari")
            .filter { tab in
                tab.isAudible || tab.processID.map { audibleProcessIDs.contains($0) } == true
            }
    }
    
    private func chromeTabs(matching audibleProcessIDs: Set<pid_t>) async -> [BrowserAudioTab] {
        guard isRunning(bundleID: "com.google.Chrome") else { return [] }
        return tabs(from: await run(script: BrowserAudioScripts.chromeScanScript()), browserName: "Google Chrome")
            .filter { tab in
                tab.isAudible || tab.processID.map { audibleProcessIDs.contains($0) } == true
            }
    }
    
    private func setSafariVolume(_ volume: Double, windowIndex: Int, tabIndex: Int) async -> Bool {
        await run(script: """
        tell application "Safari"
            do JavaScript "\(BrowserAudioScripts.setMediaVolumeJavaScript(volume: volume))" in tab \(tabIndex) of window \(windowIndex)
        end tell
        """) != nil
    }
    
    private func setChromeVolume(_ volume: Double, windowIndex: Int, tabIndex: Int) async -> Bool {
        await run(script: """
        tell application "Google Chrome"
            execute javascript "\(BrowserAudioScripts.setMediaVolumeJavaScript(volume: volume))" in tab \(tabIndex) of window \(windowIndex)
        end tell
        """) != nil
    }
    
    private func run(script: String) async -> String? {
        let runner = scriptRunner
        return await Task.detached(priority: .userInitiated) {
            do {
                return try runner.run(script: script)
            } catch {
                logger.warning("Browser audio AppleScript failed: \(error.localizedDescription)")
                return nil
            }
        }.value
    }
    
    private func tabs(from output: String?, browserName: String) -> [BrowserAudioTab] {
        output?
            .split(separator: "\n")
            .compactMap { BrowserAudioTab(line: String($0), browserName: browserName) } ?? []
    }
    
    private func isRunning(bundleID: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleID }
    }
}
