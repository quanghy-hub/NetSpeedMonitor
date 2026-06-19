import Foundation

enum BrowserAudioScripts {
    static func setMediaVolumeJavaScript(volume: Double) -> String {
        let clamped = min(max(volume, 0), 1)
        return """
        (() => { const volume = \(String(format: "%.3f", clamped)); document.querySelectorAll('video,audio').forEach((media) => { media.volume = volume; media.muted = volume === 0; }); return true; })();
        """.appleScriptEscaped()
    }
    
    static func safariScanScript() -> String {
        """
        set outputLines to {}
        tell application "Safari"
            repeat with windowIndex from 1 to count of windows
                repeat with tabIndex from 1 to count of tabs of window windowIndex
                    set tabRef to tab tabIndex of window windowIndex
                    set tabTitle to my cleanText(name of tabRef)
                    set tabURL to my cleanText(URL of tabRef)
                    set tabPID to pid of tabRef
                    set mediaInfo to do JavaScript "\(scanMediaJavaScript())" in tabRef
                    set end of outputLines to ((windowIndex as text) & tab & (tabIndex as text) & tab & (tabPID as text) & tab & tabTitle & tab & mediaInfo & tab & tabURL)
                end repeat
            end repeat
        end tell
        return my joinLines(outputLines)
        \(sharedAppleScriptHandlers)
        """
    }
    
    static func chromeScanScript() -> String {
        """
        set outputLines to {}
        tell application "Google Chrome"
            repeat with windowIndex from 1 to count of windows
                repeat with tabIndex from 1 to count of tabs of window windowIndex
                    set tabRef to tab tabIndex of window windowIndex
                    set tabTitle to my cleanText(title of tabRef)
                    set tabURL to my cleanText(URL of tabRef)
                    set mediaInfo to execute javascript "\(scanMediaJavaScript())" in tabRef
                    set end of outputLines to ((windowIndex as text) & tab & (tabIndex as text) & tab & "" & tab & tabTitle & tab & mediaInfo & tab & tabURL)
                end repeat
            end repeat
        end tell
        return my joinLines(outputLines)
        \(sharedAppleScriptHandlers)
        """
    }
    
    private static func scanMediaJavaScript() -> String {
        """
        (() => { const media = Array.from(document.querySelectorAll('video,audio')); const audible = media.filter((item) => !item.paused && !item.muted && item.volume > 0).length; return `${media.length}\\t${audible}`; })();
        """.appleScriptEscaped()
    }
    
    private static let sharedAppleScriptHandlers = """
    
    on cleanText(valueText)
        set AppleScript's text item delimiters to {tab, linefeed, return}
        set parts to text items of (valueText as text)
        set AppleScript's text item delimiters to " "
        return parts as text
    end cleanText
    
    on joinLines(valuesList)
        set AppleScript's text item delimiters to linefeed
        set joinedText to valuesList as text
        set AppleScript's text item delimiters to ""
        return joinedText
    end joinLines
    """
}

private extension String {
    func appleScriptEscaped() -> String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
