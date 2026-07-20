import Testing
import AppKit
@testable import NetSpeedMonitor

@Suite("MediaPlayKeyMonitor Tests")
struct MediaPlayKeyMonitorTests {
    
    // NX_KEYTYPE_PLAY is 16
    
    @Test("Valid play press")
    func validPlayPress() {
        let keyCode = 16
        let keyState = 0xA
        let isRepeat = 0
        let data1 = (keyCode << 16) | (keyState << 8) | isRepeat
        
        #expect(MediaPlayKeyMonitor.isInitialPlayPress(data1: data1) == true)
    }
    
    @Test("Wrong key code")
    func wrongKeyCode() {
        let keyCode = 17 // Not NX_KEYTYPE_PLAY
        let keyState = 0xA
        let isRepeat = 0
        let data1 = (keyCode << 16) | (keyState << 8) | isRepeat
        
        #expect(MediaPlayKeyMonitor.isInitialPlayPress(data1: data1) == false)
    }
    
    @Test("Repeat press")
    func repeatPress() {
        let keyCode = 16
        let keyState = 0xA
        let isRepeat = 1 // Repeated press
        let data1 = (keyCode << 16) | (keyState << 8) | isRepeat
        
        #expect(MediaPlayKeyMonitor.isInitialPlayPress(data1: data1) == false)
    }
    
    @Test("Wrong key state")
    func wrongKeyState() {
        let keyCode = 16
        let keyState = 0xB // Not 0xA
        let isRepeat = 0
        let data1 = (keyCode << 16) | (keyState << 8) | isRepeat
        
        #expect(MediaPlayKeyMonitor.isInitialPlayPress(data1: data1) == false)
    }
}
