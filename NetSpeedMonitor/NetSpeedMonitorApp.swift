import SwiftUI

@main
struct NetSpeedMonitorApp: App {
    @StateObject private var menuBarState: MenuBarState
    
    init() {
        let autoLaunchManager = AutoLaunchManager()
        let networkInterfaceManager = NetworkInterfaceManager()
        let musicBlockerService = MusicBlockerService()
        let systemStatsMonitor = SystemStatsMonitor()
        let netTrafficStat = NetTrafficStatReceiver()
        let audioSessionCatalog = AudioSessionCatalog()

        _menuBarState = StateObject(wrappedValue: MenuBarState(
            autoLaunchManager: autoLaunchManager,
            networkInterfaceManager: networkInterfaceManager,
            musicBlockerService: musicBlockerService,
            systemStatsMonitor: systemStatsMonitor,
            netTrafficStat: netTrafficStat,
            audioSessionCatalog: audioSessionCatalog
        ))
    }
    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environmentObject(menuBarState)
        } label: {
            Image(nsImage: menuBarState.currentIcon)
                .tag("MenuBarIcon")
        }
        .menuBarExtraStyle(.window)
    }
}
