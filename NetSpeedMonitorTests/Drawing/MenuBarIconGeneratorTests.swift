import AppKit
import Testing
@testable import NetSpeedMonitor

@Suite("MenuBarIconGenerator Tests")
struct MenuBarIconGeneratorTests {
    
    @Test("Generate icon returns non nil image")
    func generateIconReturnsNonNil() {
        let image = MenuBarIconGenerator.generateIcon(text: "Test")
        #expect(image != nil)
    }
    
    @Test("Generate icon is template")
    func generateIconIsTemplate() {
        let image = MenuBarIconGenerator.generateIcon(text: "Test")
        #expect(image.isTemplate == true)
    }
    
    @Test("Generate icon has correct height")
    func generateIconHasCorrectHeight() {
        let image = MenuBarIconGenerator.generateIcon(text: "Test")
        #expect(image.size.height == 22.0)
    }
    
    @Test("Generate icon minimum width")
    func generateIconMinWidth() {
        let image = MenuBarIconGenerator.generateIcon(text: ".")
        #expect(image.size.width >= 20.0)
    }
    
    @Test("Generate combined icon with no bars returns template text icon")
    func generateCombinedIconNoBarsReturnsTemplate() {
        let image = MenuBarIconGenerator.generateCombinedIcon(
            text: "Test",
            cpuUsage: 0.5,
            ramUsage: 0.5,
            batteryLevel: 0.5,
            batteryIsCharging: false,
            showCPU: false,
            showRAM: false,
            showBattery: false,
            cpuColor: .red,
            ramColor: .green,
            batteryColor: .blue
        )
        
        #expect(image.isTemplate == true)
    }
    
    @Test("Generate combined icon with bars is not template")
    func generateCombinedIconWithBarsNotTemplate() {
        let image = MenuBarIconGenerator.generateCombinedIcon(
            text: "Test",
            cpuUsage: 0.5,
            ramUsage: 0.5,
            batteryLevel: 0.5,
            batteryIsCharging: false,
            showCPU: true,
            showRAM: false,
            showBattery: false,
            cpuColor: .red,
            ramColor: .green,
            batteryColor: .blue
        )
        
        #expect(image.isTemplate == false)
    }
    
    @Test("Generate combined icon with bars is wider than text only")
    func generateCombinedIconWithBarsWiderThanTextOnly() {
        let textOnlyImage = MenuBarIconGenerator.generateIcon(text: "Test")
        let combinedImage = MenuBarIconGenerator.generateCombinedIcon(
            text: "Test",
            cpuUsage: 0.5,
            ramUsage: 0.5,
            batteryLevel: 0.5,
            batteryIsCharging: false,
            showCPU: true,
            showRAM: true,
            showBattery: true,
            cpuColor: .red,
            ramColor: .green,
            batteryColor: .blue
        )
        
        #expect(combinedImage.size.width > textOnlyImage.size.width)
    }
}
