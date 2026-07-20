import SwiftUI
import Combine

@MainActor
final class MenuBarIconViewModel: ObservableObject {
    @Published var currentIcon: NSImage = NSImage()
    
    private var lastIconSignature = ""
    private var pendingRefreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    let systemVM: SystemMonitorViewModel
    let settingsVM: SettingsViewModel
    
    init(systemVM: SystemMonitorViewModel, settingsVM: SettingsViewModel) {
        self.systemVM = systemVM
        self.settingsVM = settingsVM
        
        // Listen to relevant changes
        systemVM.objectWillChange
            .sink { [weak self] _ in self?.queueRefreshIcon() }
            .store(in: &cancellables)
            
        settingsVM.objectWillChange
            .sink { [weak self] _ in self?.queueRefreshIcon() }
            .store(in: &cancellables)
            
        // Initial render
        refreshIcon(force: true)
    }
    
    func queueRefreshIcon() {
        pendingRefreshTask?.cancel()
        pendingRefreshTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 80_000_000) // 80ms debounce
            guard !Task.isCancelled else { return }
            self.refreshIcon()
        }
    }
    
    private func refreshIcon(force: Bool = false) {
        let signature = [
            systemVM.menuText,
            String(Int(systemVM.cpuUsage * 100)),
            String(Int(systemVM.ramUsage * 100)),
            String(Int(systemVM.batteryLevel * 100)),
            String(systemVM.batteryIsCharging),
            String(settingsVM.showCPUBar),
            String(settingsVM.showRAMBar),
            String(settingsVM.showBatteryBar),
            settingsVM.cpuBarColor.toHex(),
            settingsVM.ramBarColor.toHex(),
            settingsVM.batteryBarColor.toHex()
        ].joined(separator: "|")
        
        guard force || signature != lastIconSignature else { return }
        lastIconSignature = signature
        
        currentIcon = MenuBarIconGenerator.generateCombinedIcon(
            text: systemVM.menuText,
            cpuUsage: systemVM.cpuUsage,
            ramUsage: systemVM.ramUsage,
            batteryLevel: systemVM.batteryLevel,
            batteryIsCharging: systemVM.batteryIsCharging,
            showCPU: settingsVM.showCPUBar,
            showRAM: settingsVM.showRAMBar,
            showBattery: settingsVM.showBatteryBar,
            cpuColor: NSColor(settingsVM.cpuBarColor),
            ramColor: NSColor(settingsVM.ramBarColor),
            batteryColor: NSColor(settingsVM.batteryBarColor)
        )
    }
}
