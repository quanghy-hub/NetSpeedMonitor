import Testing
@testable import NetSpeedMonitor

@Suite("SpeedFormatter Tests")
struct SpeedFormatterTests {
    
    @Test("Auto unit with small values")
    func autoUnitSmallValues() {
        let result = SpeedFormatter.format(upload: 500, download: 800, unit: .auto)
        #expect(result == "500.0\n800.0")
    }
    
    @Test("Auto unit with kilobyte range")
    func autoUnitKilobyteRange() {
        let result = SpeedFormatter.format(upload: 1024, download: 2048, unit: .auto)
        #expect(result == "1.0\n2.0")
    }
    
    @Test("Auto unit with megabyte range")
    func autoUnitMegabyteRange() {
        let result = SpeedFormatter.format(upload: 1024 * 1024, download: 1024 * 1024 * 2.5, unit: .auto)
        #expect(result == "1.0\n2.5")
    }
    
    @Test("Auto unit with gigabyte range")
    func autoUnitGigabyteRange() {
        let result = SpeedFormatter.format(upload: 1024 * 1024 * 1024, download: 1024 * 1024 * 1024 * 1.5, unit: .auto)
        #expect(result == "1.0\n1.5")
    }
    
    @Test("Fixed KB unit")
    func fixedKB() {
        let result = SpeedFormatter.format(upload: 1024, download: 1024 * 5, unit: .kb)
        #expect(result == "1.0\n5.0")
    }
    
    @Test("Fixed MB unit")
    func fixedMB() {
        let result = SpeedFormatter.format(upload: 1024 * 1024, download: 1024 * 1024 * 10, unit: .mb)
        #expect(result == "1.0\n10.0")
    }
    
    @Test("Bytes unit")
    func bytes() {
        let result = SpeedFormatter.format(upload: 1500, download: 2500, unit: .bytes)
        #expect(result == "1500.0\n2500.0")
    }
    
    @Test("Bits unit")
    func bits() {
        let result = SpeedFormatter.format(upload: 100, download: 200, unit: .bits)
        #expect(result == "800.0\n1600.0")
    }
    
    @Test("Zero values")
    func zeroValues() {
        let result = SpeedFormatter.format(upload: 0, download: 0, unit: .auto)
        #expect(result == "0.0\n0.0")
    }
    
    @Test("Output format is correctly spaced")
    func outputFormat() {
        let result = SpeedFormatter.format(upload: 10, download: 20, unit: .bytes)
        let parts = result.split(separator: "\n")
        #expect(parts.count == 2)
        #expect(parts[0] == "10.0")
        #expect(parts[1] == "20.0")
    }
}
