import Foundation

extension MenuBarState {
    func queueRefreshIcon() {
        pendingRefreshWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.refreshIcon(force: true)
        }
        pendingRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: workItem)
    }

    func refreshIcon(force: Bool = false) {
        let signature = [
            menuText,
            String(Int(cpuUsage * 100)),
            String(Int(ramUsage * 100)),
            String(Int(batteryLevel * 100)),
            String(batteryIsCharging),
            String(showCPUBar),
            String(showRAMBar),
            String(showBatteryBar),
            cpuBarColorHex,
            ramBarColorHex,
            batteryBarColorHex,
            cpuBarColorArchive,
            ramBarColorArchive,
            batteryBarColorArchive
        ].joined(separator: "|")

        guard force || signature != lastIconSignature else { return }
        lastIconSignature = signature
        currentIcon = MenuBarIconGenerator.generateCombinedIcon(
            text: menuText,
            cpuUsage: cpuUsage,
            ramUsage: ramUsage,
            batteryLevel: batteryLevel,
            batteryIsCharging: batteryIsCharging,
            showCPU: showCPUBar,
            showRAM: showRAMBar,
            showBattery: showBatteryBar,
            cpuColor: cpuBarColor,
            ramColor: ramBarColor,
            batteryColor: batteryBarColor
        )
    }
}
