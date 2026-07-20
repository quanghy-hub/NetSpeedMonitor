import Testing
@testable import NetSpeedMonitor

@Suite("ProcessVolumeEngine Tests")
struct ProcessVolumeEngineTests {
    
    @Test("Clamp normal value")
    func clampNormal() {
        #expect(ProcessVolumeEngine.clamp(1.0) == 1.0)
    }
    
    @Test("Clamp zero value")
    func clampZero() {
        #expect(ProcessVolumeEngine.clamp(0.0) == 0.0)
    }
    
    @Test("Clamp max value")
    func clampMax() {
        #expect(ProcessVolumeEngine.clamp(2.0) == 2.0)
    }
    
    @Test("Clamp over max value")
    func clampOverMax() {
        #expect(ProcessVolumeEngine.clamp(3.0) == 2.0)
    }
    
    @Test("Clamp negative value")
    func clampNegative() {
        #expect(ProcessVolumeEngine.clamp(-1.0) == 0.0)
    }
    
    @Test("Clamp NaN")
    func clampNaN() {
        #expect(ProcessVolumeEngine.clamp(.nan) == 1.0)
    }
    
    @Test("Clamp infinity")
    func clampInfinity() {
        #expect(ProcessVolumeEngine.clamp(.infinity) == 1.0)
    }
}
