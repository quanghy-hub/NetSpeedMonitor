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
    @Published var menuText = "↑0.0B/s\n↓0.0B/s"
    
    var currentIcon: NSImage {
        return MenuBarIconGenerator.generateIcon(text: menuText)
    }
    
    private var timer: Timer?
    private var primaryInterface: String?
    private var netTrafficStat = NetTrafficStatReceiver()
    
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
                        
                        // Extremely compact format to remove extra spaces and format to 2 decimal places:
                        self.menuText = "↑\(String(format: "%.2f", displayUpload))\(upUnit)\n↓\(String(format: "%.2f", displayDownload))\(downUnit)"
                        
                        logger.info("SpeedIn: \(displayDownload) \(downUnit), SpeedOut: \(displayUpload) \(upUnit)")
                    }
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

