import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @AppStorage("AutoLaunchEnabled") var autoLaunchEnabled: Bool = false {
        didSet {
            autoLaunchManager.isEnabled = autoLaunchEnabled
        }
    }
    @AppStorage("NetSpeedUpdateInterval") var netSpeedUpdateInterval: NetSpeedUpdateInterval = .Sec2
    @AppStorage("SpeedUnitSelection") var speedUnit: SpeedUnit = .auto
    
    @AppStorage("ShowCPUBar") var showCPUBar: Bool = true
    @AppStorage("ShowRAMBar") var showRAMBar: Bool = true
    @AppStorage("ShowBatteryBar") var showBatteryBar: Bool = true
    
    @AppStorage("CPUBarColor") var cpuBarColor: Color = Color(hex: "#34C759")
    @AppStorage("RAMBarColor") var ramBarColor: Color = Color(hex: "#007AFF")
    @AppStorage("BatteryBarColor") var batteryBarColor: Color = Color(hex: "#34C759")
    
    let autoLaunchManager: AutoLaunchManager
    
    init(autoLaunchManager: AutoLaunchManager) {
        self.autoLaunchManager = autoLaunchManager
        
        // Sync initial state
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.autoLaunchEnabled = self.autoLaunchManager.isEnabled
        }
    }
}
