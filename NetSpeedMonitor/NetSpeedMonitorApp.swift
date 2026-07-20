import SwiftUI

@main
struct NetSpeedMonitorApp: App {
    @StateObject private var settingsVM: SettingsViewModel
    @StateObject private var systemVM: SystemMonitorViewModel
    @StateObject private var audioMixerVM: AudioMixerViewModel
    @StateObject private var musicBlockerVM: MusicBlockerViewModel
    @StateObject private var iconVM: MenuBarIconViewModel
    
    init() {
        if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "").count > 1 {
            NSApplication.shared.terminate(nil)
        }
        
        let autoLaunchManager = AutoLaunchManager()
        let networkInterfaceManager = NetworkInterfaceManager()
        let musicBlockerService = MusicBlockerService()
        let systemStatsMonitor = SystemStatsMonitor()
        let netTrafficStat = NetTrafficStatReceiver()
        let audioSessionCatalog = AudioSessionCatalog(processVolumeEngine: ProcessVolumeEngine.shared)

        let settings = SettingsViewModel(autoLaunchManager: autoLaunchManager)
        let system = SystemMonitorViewModel(
            systemStatsMonitor: systemStatsMonitor,
            netTrafficStat: netTrafficStat,
            networkInterfaceManager: networkInterfaceManager
        )
        let audioMixer = AudioMixerViewModel(audioSessionCatalog: audioSessionCatalog)
        let musicBlocker = MusicBlockerViewModel(musicBlockerService: musicBlockerService)
        let icon = MenuBarIconViewModel(systemVM: system, settingsVM: settings)
        
        _settingsVM = StateObject(wrappedValue: settings)
        _systemVM = StateObject(wrappedValue: system)
        _audioMixerVM = StateObject(wrappedValue: audioMixer)
        _musicBlockerVM = StateObject(wrappedValue: musicBlocker)
        _iconVM = StateObject(wrappedValue: icon)
        
        // Start polling immediately
        system.startPolling(interval: settings.netSpeedUpdateInterval, unit: settings.speedUnit)
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(settingsVM)
                .environmentObject(systemVM)
                .environmentObject(audioMixerVM)
                .environmentObject(musicBlockerVM)
                .onChange(of: settingsVM.netSpeedUpdateInterval) { _, newValue in
                    systemVM.startPolling(interval: newValue, unit: settingsVM.speedUnit)
                }
                .onChange(of: settingsVM.speedUnit) { _, newValue in
                    systemVM.startPolling(interval: settingsVM.netSpeedUpdateInterval, unit: newValue)
                }
        } label: {
            Image(nsImage: iconVM.currentIcon)
                .tag("MenuBarIcon")
        }
        .menuBarExtraStyle(.window)
    }
}
