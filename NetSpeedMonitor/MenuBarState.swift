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
    private var primaryInterface: String?
    private var primaryInterfaceLastCheckedAt = Date.distantPast
    private var lastIconSignature = ""
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

    private func refreshPrimaryInterfaceIfNeeded() {
        let now = Date()
        if primaryInterface == nil || now.timeIntervalSince(primaryInterfaceLastCheckedAt) >= 10.0 {
            primaryInterface = findPrimaryInterface()
            primaryInterfaceLastCheckedAt = now
        }
    }

    private func formattedSpeeds(upload: Double, download: Double) -> String {
        var displayDownload = download
        var displayUpload = upload

        switch speedUnit {
        case .auto:
            while displayDownload > 1000.0 {
                displayDownload /= 1024.0
            }
            while displayUpload > 1000.0 {
                displayUpload /= 1024.0
            }
        case .kb:
            displayDownload /= 1024.0
            displayUpload /= 1024.0
        case .mb:
            displayDownload /= (1024.0 * 1024.0)
            displayUpload /= (1024.0 * 1024.0)
        case .bytes:
            break
        case .bits:
            displayDownload *= 8.0
            displayUpload *= 8.0
        }

        return "\(String(format: "%.1f", displayUpload))\n\(String(format: "%.1f", displayDownload))"
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

                self.refreshPrimaryInterfaceIfNeeded()
                if (self.primaryInterface == nil) { return }
                
                if let netTrafficStatMap = self.netTrafficStat.getNetTrafficStatMap() {
                    if let netTrafficStat = netTrafficStatMap.object(forKey: self.primaryInterface!) as? NetTrafficStat  {
                        let rawDownload = netTrafficStat.ibytes_per_sec as! Double
                        let rawUpload = netTrafficStat.obytes_per_sec as! Double
                        self.menuText = self.formattedSpeeds(upload: rawUpload, download: rawDownload)
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
