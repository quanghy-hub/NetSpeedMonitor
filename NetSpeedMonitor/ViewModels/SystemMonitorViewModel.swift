import SwiftUI

@MainActor
final class SystemMonitorViewModel: ObservableObject {
    @Published var menuText = "0.0\n0.0"
    @Published var cpuUsage: Double = 0.0
    @Published var ramUsage: Double = 0.0
    @Published var batteryLevel: Double = 1.0
    @Published var batteryIsCharging: Bool = false
    
    let systemStatsMonitor: any SystemStatsProviding
    let netTrafficStat: any NetworkTrafficProviding
    let networkInterfaceManager: NetworkInterfaceManager
    
    private var pollingTask: Task<Void, Never>?
    
    init(
        systemStatsMonitor: any SystemStatsProviding,
        netTrafficStat: any NetworkTrafficProviding,
        networkInterfaceManager: NetworkInterfaceManager
    ) {
        self.systemStatsMonitor = systemStatsMonitor
        self.netTrafficStat = netTrafficStat
        self.networkInterfaceManager = networkInterfaceManager
    }
    
    func startPolling(interval: NetSpeedUpdateInterval, unit: SpeedUnit) {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { return }
                
                if let primaryInterface = self.networkInterfaceManager.getPrimaryInterface() {
                    let speed = await self.netTrafficStat.getSpeed(for: primaryInterface)
                    self.updateNetworkSpeedText(with: speed, unit: unit)
                }
                
                let cpu = await self.systemStatsMonitor.getCPUUsage()
                let ram = await self.systemStatsMonitor.getRAMUsage()
                let battery = await self.systemStatsMonitor.getBatteryInfo()
                
                self.cpuUsage = cpu
                self.ramUsage = ram
                self.batteryLevel = battery.level
                self.batteryIsCharging = battery.isCharging
                
                try? await Task.sleep(nanoseconds: UInt64(interval.rawValue * 1_000_000_000))
            }
        }
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    private func updateNetworkSpeedText(with speed: (upload: Double, download: Double)?, unit: SpeedUnit) {
        guard let speed = speed else { return }
        self.menuText = SpeedFormatter.format(upload: speed.upload, download: speed.download, unit: unit)
    }
    
    deinit {
        pollingTask?.cancel()
    }
}
