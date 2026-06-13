import SwiftUI
import Combine
import SystemConfiguration

class MenuBarState: ObservableObject {
    @AppStorage("AutoLaunchEnabled") var autoLaunchEnabled: Bool = false {
        didSet {
            AutoLaunchManager.shared.isEnabled = autoLaunchEnabled
        }
    }
    @AppStorage("NetSpeedUpdateInterval") var netSpeedUpdateInterval: NetSpeedUpdateInterval = .Sec2 {
        didSet { updateNetSpeedUpdateIntervalStatus() }
    }
    @AppStorage("SpeedUnitSelection") var speedUnit: SpeedUnit = .auto {
        didSet { refreshIcon(force: true) }
    }
    
    // System Monitor Settings
    @AppStorage("ShowCPUBar") var showCPUBar: Bool = true {
        didSet { refreshIcon(force: true) }
    }
    @AppStorage("ShowRAMBar") var showRAMBar: Bool = true {
        didSet { refreshIcon(force: true) }
    }
    @AppStorage("ShowBatteryBar") var showBatteryBar: Bool = true {
        didSet { refreshIcon(force: true) }
    }
    @AppStorage("CPUBarColor") var cpuBarColorHex: String = "#34C759" {
        didSet { refreshIcon(force: true) }
    }
    @AppStorage("RAMBarColor") var ramBarColorHex: String = "#007AFF" {
        didSet { refreshIcon(force: true) }
    }
    @AppStorage("BatteryBarColor") var batteryBarColorHex: String = "#34C759" {
        didSet { refreshIcon(force: true) }
    }
    
    @Published var menuText = "0.0\n0.0"
    @Published var cpuUsage: Double = 0.0
    @Published var ramUsage: Double = 0.0
    @Published var batteryLevel: Double = 1.0
    @Published var batteryIsCharging: Bool = false
    @Published var chargingAnimationPhase: Int = 0
    @Published var currentIcon: NSImage = MenuBarIconGenerator.generateCombinedIcon(
        text: "0.0\n0.0",
        cpuUsage: 0.0,
        ramUsage: 0.0,
        batteryLevel: 1.0,
        batteryIsCharging: false,
        chargingAnimationPhase: 0,
        showCPU: true,
        showRAM: true,
        showBattery: true,
        cpuColor: NSColor(hex: "#34C759"),
        ramColor: NSColor(hex: "#007AFF"),
        batteryColor: NSColor(hex: "#34C759")
    )
    
    private var timer: Timer?
    private var lastIconSignature = ""
    private var netTrafficStat = NetTrafficStatReceiver()
    private var systemStatsMonitor = SystemStatsMonitor()
    
    private func updateNetSpeedUpdateIntervalStatus() {
        logger.info("netSpeedUpdateInterval, \(self.netSpeedUpdateInterval.displayName)")
        self.stopTimer()
        self.startTimer()
    }
    
    private func refreshIcon(force: Bool = false) {
        let signature = [
            menuText,
            String(Int(cpuUsage * 100)),
            String(Int(ramUsage * 100)),
            String(Int(batteryLevel * 100)),
            String(batteryIsCharging),
            String(chargingAnimationPhase % 2),
            String(showCPUBar),
            String(showRAMBar),
            String(showBatteryBar),
            cpuBarColorHex,
            ramBarColorHex,
            batteryBarColorHex
        ].joined(separator: "|")
        
        guard force || signature != lastIconSignature else { return }
        lastIconSignature = signature
        currentIcon = MenuBarIconGenerator.generateCombinedIcon(
            text: menuText,
            cpuUsage: cpuUsage,
            ramUsage: ramUsage,
            batteryLevel: batteryLevel,
            batteryIsCharging: batteryIsCharging,
            chargingAnimationPhase: chargingAnimationPhase,
            showCPU: showCPUBar,
            showRAM: showRAMBar,
            showBattery: showBatteryBar,
            cpuColor: NSColor(hex: cpuBarColorHex),
            ramColor: NSColor(hex: ramBarColorHex),
            batteryColor: NSColor(hex: batteryBarColorHex)
        )
    }
    
    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.netSpeedUpdateInterval.rawValue), repeats: true) { _ in
            
            guard let primaryInterface = NetworkInterfaceManager.shared.getPrimaryInterface() else { return }
            
            if let netTrafficStatMap = self.netTrafficStat.getNetTrafficStatMap() {
                if let netTrafficStat = netTrafficStatMap.object(forKey: primaryInterface) as? NetTrafficStat  {
                    let rawDownload = netTrafficStat.ibytes_per_sec as! Double
                    let rawUpload = netTrafficStat.obytes_per_sec as! Double
                    self.menuText = SpeedFormatter.format(upload: rawUpload, download: rawDownload, unit: self.speedUnit)
                }
            }
            
            // Update CPU & RAM stats
            self.cpuUsage = self.systemStatsMonitor.getCPUUsage()
            self.ramUsage = self.systemStatsMonitor.getRAMUsage()
            
            // Update Battery stats
            let batteryInfo = self.systemStatsMonitor.getBatteryInfo()
            self.batteryLevel = batteryInfo.level
            self.batteryIsCharging = batteryInfo.isCharging
            if batteryInfo.isCharging {
                self.chargingAnimationPhase += 1
            }
            
            self.refreshIcon()
        }
        RunLoop.current.add(timer, forMode: .common)
        self.timer = timer
        logger.info("startTimer")
    }
    
    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil
        logger.info("stopTimer")
    }
    
    init() {
        DispatchQueue.main.async {
            self.autoLaunchEnabled = AutoLaunchManager.shared.isEnabled
            self.startTimer()
        }
    }
    
    deinit {
        DispatchQueue.main.async {
            self.stopTimer()
        }
    }
}
