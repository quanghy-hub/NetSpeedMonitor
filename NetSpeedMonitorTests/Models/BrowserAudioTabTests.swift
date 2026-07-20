import Testing
@testable import NetSpeedMonitor

@Suite("BrowserAudioTab Tests")
struct BrowserAudioTabTests {
    
    @Test("Parse valid line")
    func validLine() {
        let line = "1\t2\t1234\tSong Title\t3\t1\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        
        #expect(tab != nil)
        #expect(tab?.windowIndex == 1)
        #expect(tab?.tabIndex == 2)
        #expect(tab?.processID == 1234)
        #expect(tab?.title == "Song Title")
        #expect(tab?.mediaElementCount == 3)
        #expect(tab?.audibleMediaElementCount == 1)
        #expect(tab?.url == "https://example.com")
        #expect(tab?.browserName == "Safari")
    }
    
    @Test("Parse invalid line (too few fields)")
    func invalidLineTooFewFields() {
        let line = "1\t2\t1234\tSong Title\t3\t1" // Missing URL field
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        #expect(tab == nil)
    }
    
    @Test("Parse invalid line (non int fields)")
    func invalidLineNonIntFields() {
        let line = "A\tB\t1234\tSong Title\t3\t1\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        #expect(tab == nil)
    }
    
    @Test("Empty title is replaced")
    func emptyTitle() {
        let line = "1\t2\t1234\t\t3\t1\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        #expect(tab?.title == "Untitled Tab")
    }
    
    @Test("Can set volume with media")
    func canSetVolumeWithMedia() {
        let line = "1\t2\t1234\tSong Title\t3\t1\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        #expect(tab?.canSetVolume == true)
    }
    
    @Test("Cannot set volume without media")
    func canSetVolumeNoMedia() {
        let line = "1\t2\t1234\tSong Title\t0\t0\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        #expect(tab?.canSetVolume == false)
    }
    
    @Test("Is audible with audible media")
    func isAudibleWithAudibleMedia() {
        let line = "1\t2\t1234\tSong Title\t3\t1\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        #expect(tab?.isAudible == true)
    }
    
    @Test("Is not audible without audible media")
    func isAudibleNoAudibleMedia() {
        let line = "1\t2\t1234\tSong Title\t3\t0\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        #expect(tab?.isAudible == false)
    }
    
    @Test("Browser bundle ID for Safari")
    func browserBundleIdSafari() {
        let line = "1\t2\t1234\tSong Title\t3\t1\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        #expect(tab?.browserBundleIdentifier == "com.apple.Safari")
    }
    
    @Test("Browser bundle ID for Chrome")
    func browserBundleIdChrome() {
        let line = "1\t2\t1234\tSong Title\t3\t1\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Google Chrome")
        #expect(tab?.browserBundleIdentifier == "com.google.Chrome")
    }
    
    @Test("Browser bundle ID for Unknown")
    func browserBundleIdUnknown() {
        let line = "1\t2\t1234\tSong Title\t3\t1\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Brave")
        #expect(tab?.browserBundleIdentifier == nil)
    }
    
    @Test("ID format check")
    func idFormat() {
        let line = "1\t2\t1234\tSong Title\t3\t1\thttps://example.com"
        let tab = BrowserAudioTab(line: line, browserName: "Safari")
        #expect(tab?.id == "Safari:window:1:tab:2")
    }
}
