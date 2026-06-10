import SwiftUI
import Combine
import ServiceManagement
import SystemConfiguration

enum NetSpeedUpdateInterval: Int, CaseIterable, Identifiable {
    case Sec1 = 1
    case Sec2 = 2
    case Sec5 = 5
    case Sec10 = 10
    case Sec30 = 30
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        switch self {
        case .Sec1: return "1s"
        case .Sec2: return "2s"
        case .Sec5: return "5s"
        case .Sec10: return "10s"
        case .Sec30: return "30s"
        }
    }
}

enum SpeedUnit: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case kb = "KB/s"
    case mb = "MB/s"
    case bytes = "B/s"
    case bits = "bps"
    
    var id: String { self.rawValue }
}

class MenuBarState: ObservableObject {
    @AppStorage("AutoLaunchEnabled") var autoLaunchEnabled: Bool = false {
        didSet { updateAutoLaunchStatus() }
    }
    @AppStorage("NetSpeedUpdateInterval") var netSpeedUpdateInterval: NetSpeedUpdateInterval = .Sec1 {
        didSet { updateNetSpeedUpdateIntervalStatus() }
    }
    @AppStorage("SpeedUnitSelection") var speedUnit: SpeedUnit = .auto {
        didSet { updateNetSpeedUpdateIntervalStatus() }
    }
    
    // System Monitor Settings
    @AppStorage("ShowCPUBar") var showCPUBar: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("ShowRAMBar") var showRAMBar: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("ShowBatteryBar") var showBatteryBar: Bool = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("CPUBarColor") var cpuBarColorHex: String = "#34C759" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("RAMBarColor") var ramBarColorHex: String = "#007AFF" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("BatteryBarColor") var batteryBarColorHex: String = "#34C759" {
        didSet { objectWillChange.send() }
    }
    
    @Published var menuText = "\u{2191}0.0\n\u{2193}0.0"
    @Published var cpuUsage: Double = 0.0
    @Published var ramUsage: Double = 0.0
    @Published var batteryLevel: Double = 1.0
    @Published var batteryIsCharging: Bool = false
    @Published var chargingAnimationPhase: Int = 0
    
    var currentIcon: NSImage {
        return MenuBarIconGenerator.generateCombinedIcon(
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
    
    private var timer: Timer?
    private var primaryInterface: String?
    private var netTrafficStat = NetTrafficStatReceiver()
    private var systemStatsMonitor = SystemStatsMonitor()
    
    private func currentAutoLaunchStatus() -> Bool {
        let service = SMAppService.mainApp
        let status = service.status
        return status == .enabled
    }
    
    private func updateAutoLaunchStatus() {
        let service = SMAppService.mainApp
        
        do {
            if autoLaunchEnabled {
                if service.status == .notFound || service.status == .notRegistered {
                    try service.register()
                }
            } else {
                if service.status == .enabled {
                    try service.unregister()
                }
            }
            logger.info("updateAutoLaunchStatus succeeded, autoLaunchEnabled: \(String(self.autoLaunchEnabled)), service.enabled: \(String(service.status == .enabled))")
        } catch {
            logger.warning("updateAutoLaunchStatus failed: \(error.localizedDescription), autoLaunchEnabled: \(String(self.autoLaunchEnabled)), service.enabled: \(String(service.status == .enabled))")
            autoLaunchEnabled = currentAutoLaunchStatus()
        }
    }
    
    private func updateNetSpeedUpdateIntervalStatus() {
        logger.info("netSpeedUpdateInterval, \(self.netSpeedUpdateInterval.displayName)")
        self.stopTimer()
        self.startTimer()
    }
    
    private func findPrimaryInterface() -> String? {
        let storeRef = SCDynamicStoreCreate(nil, "FindCurrentInterfaceIpMac" as CFString, nil, nil)
        let global = SCDynamicStoreCopyValue(storeRef, "State:/Network/Global/IPv4" as CFString)
        let primaryInterface = global?.value(forKey: "PrimaryInterface") as? String
        return primaryInterface
    }
    
    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.netSpeedUpdateInterval.rawValue), repeats: true) { _ in

                self.primaryInterface = self.findPrimaryInterface()
                if (self.primaryInterface == nil) { return }
                
                if let netTrafficStatMap = self.netTrafficStat.getNetTrafficStatMap() {
                    if let netTrafficStat = netTrafficStatMap.object(forKey: self.primaryInterface!) as? NetTrafficStat  {
                        let rawDownload = netTrafficStat.ibytes_per_sec as! Double
                        let rawUpload = netTrafficStat.obytes_per_sec as! Double
                        
                        var displayDownload = rawDownload
                        var displayUpload = rawUpload
                        var downUnit = ""
                        var upUnit = ""
                        
                        switch self.speedUnit {
                        case .auto:
                            let metrics = ["B", "KB", "MB", "GB", "TB"]
                            var downIdx = 0
                            var upIdx = 0
                            while displayDownload > 1000.0 && downIdx < metrics.count - 1 {
                                displayDownload /= 1024.0
                                downIdx += 1
                            }
                            while displayUpload > 1000.0 && upIdx < metrics.count - 1 {
                                displayUpload /= 1024.0
                                upIdx += 1
                            }
                            downUnit = metrics[downIdx]
                            upUnit = metrics[upIdx]
                        case .kb:
                            displayDownload /= 1024.0
                            displayUpload /= 1024.0
                            downUnit = "KB"
                            upUnit = "KB"
                        case .mb:
                            displayDownload /= (1024.0 * 1024.0)
                            displayUpload /= (1024.0 * 1024.0)
                            downUnit = "MB"
                            upUnit = "MB"
                        case .bytes:
                            downUnit = "B"
                            upUnit = "B"
                        case .bits:
                            displayDownload *= 8.0
                            displayUpload *= 8.0
                            downUnit = "b"
                            upUnit = "b"
                        }
                        
                        self.menuText = "↑\(String(format: "%.1f", displayUpload))\n↓\(String(format: "%.1f", displayDownload))"
                        
                        logger.info("SpeedIn: \(displayDownload) \(downUnit), SpeedOut: \(displayUpload) \(upUnit)")
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
            self.autoLaunchEnabled = self.currentAutoLaunchStatus()
            self.startTimer()
        }
    }
    
    deinit {
        DispatchQueue.main.async {
            self.stopTimer()
        }
    }
}

