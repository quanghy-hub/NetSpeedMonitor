import Foundation

extension MenuBarState {
    func updateNetSpeedUpdateIntervalStatus() {
        logger.info("netSpeedUpdateInterval, \(self.netSpeedUpdateInterval.displayName)")
        self.stopTimer()
        self.startTimer()
    }

    func startTimer() {
        let queue = DispatchQueue.main
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: TimeInterval(self.netSpeedUpdateInterval.rawValue))
        
        source.setEventHandler { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                guard let primaryInterface = self.networkInterfaceManager.getPrimaryInterface() else { return }
                
                let cpuUsage = await self.systemStatsMonitor.getCPUUsage()
                let ramUsage = await self.systemStatsMonitor.getRAMUsage()
                let batteryInfo = await self.systemStatsMonitor.getBatteryInfo()
                let speed = await self.netTrafficStat.getSpeed(for: primaryInterface)
                
                self.updateNetworkSpeedText(with: speed)
                self.cpuUsage = cpuUsage
                self.ramUsage = ramUsage
                self.batteryLevel = batteryInfo.level
                self.batteryIsCharging = batteryInfo.isCharging
                self.refreshIcon()
            }
        }
        
        source.resume()
        self.timer = source
        logger.info("startTimer")
    }

    func stopTimer() {
        self.timer?.cancel()
        self.timer = nil
        logger.info("stopTimer")
    }

    func updateNetworkSpeedText(with speed: (upload: Double, download: Double)?) {
        guard let speed = speed else { return }
        menuText = SpeedFormatter.format(upload: speed.upload, download: speed.download, unit: speedUnit)
    }
}
