import SwiftUI

/// Central ViewModel for the menu bar app, using @Observable pattern.
/// Coordinates timer-based polling, icon rendering, audio mixer, and music blocker.
/// Properties use @AppStorage for UserDefaults persistence with didSet side effects.
/// Dependencies are injected via protocols for testability.
@MainActor
final class MenuBarState: ObservableObject {
    @AppStorage("AutoLaunchEnabled") var autoLaunchEnabled: Bool = false {
        didSet {
            autoLaunchManager.isEnabled = autoLaunchEnabled
        }
    }
    @AppStorage("NetSpeedUpdateInterval") var netSpeedUpdateInterval: NetSpeedUpdateInterval = .Sec2 {
        didSet { updateNetSpeedUpdateIntervalStatus() }
    }
    @AppStorage("SpeedUnitSelection") var speedUnit: SpeedUnit = .auto {
        didSet { refreshIcon(force: true) }
    }

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
        didSet { queueRefreshIcon() }
    }
    @AppStorage("RAMBarColor") var ramBarColorHex: String = "#007AFF" {
        didSet { queueRefreshIcon() }
    }
    @AppStorage("BatteryBarColor") var batteryBarColorHex: String = "#34C759" {
        didSet { queueRefreshIcon() }
    }
    @AppStorage("CPUBarColorArchive") var cpuBarColorArchive: String = "" {
        didSet { queueRefreshIcon() }
    }
    @AppStorage("RAMBarColorArchive") var ramBarColorArchive: String = "" {
        didSet { queueRefreshIcon() }
    }
    @AppStorage("BatteryBarColorArchive") var batteryBarColorArchive: String = "" {
        didSet { queueRefreshIcon() }
    }

    var cpuBarColor: NSColor {
        ColorArchive.resolve(cpuBarColorArchive, fallbackHex: cpuBarColorHex)
    }

    var ramBarColor: NSColor {
        ColorArchive.resolve(ramBarColorArchive, fallbackHex: ramBarColorHex)
    }

    var batteryBarColor: NSColor {
        ColorArchive.resolve(batteryBarColorArchive, fallbackHex: batteryBarColorHex)
    }

    @AppStorage("XMusicEnabled") var xmusicEnabled: Bool = false {
        didSet {
            let newValue = xmusicEnabled
            Task { @MainActor in
                musicBlockerService.setEnabled(newValue)
            }
        }
    }
    @AppStorage("XMusicReplacement") var xmusicReplacement: String = "" {
        didSet {
            let newValue = xmusicReplacement
            Task { @MainActor in
                musicBlockerService.updateReplacement(newValue)
            }
        }
    }

    @Published var menuText = "0.0\n0.0"
    @Published var cpuUsage: Double = 0.0
    @Published var ramUsage: Double = 0.0
    @Published var batteryLevel: Double = 1.0
    @Published var batteryIsCharging: Bool = false
    @Published var audioMixerItems: [AudioMixerItem] = []
    @Published var audioMixerStatus = "Refresh to scan playing apps"
    @Published var isAudioMixerRefreshing = false
    @Published var musicBlockerStatus = "Disabled"
    @Published var musicBlockerHasError = false
    @Published var currentIcon: NSImage = MenuBarIconGenerator.generateCombinedIcon(
        text: "0.0\n0.0",
        cpuUsage: 0.0,
        ramUsage: 0.0,
        batteryLevel: 1.0,
        batteryIsCharging: false,
        showCPU: true,
        showRAM: true,
        showBattery: true,
        cpuColor: NSColor(hex: "#34C759"),
        ramColor: NSColor(hex: "#007AFF"),
        batteryColor: NSColor(hex: "#34C759")
    )

    var timer: DispatchSourceTimer?
    var lastIconSignature = ""
    let netTrafficStat: any NetworkTrafficProviding
    let systemStatsMonitor: any SystemStatsProviding
    let audioSessionCatalog: any AudioSessionProviding
    let autoLaunchManager: AutoLaunchManager
    let networkInterfaceManager: NetworkInterfaceManager
    let musicBlockerService: MusicBlockerService
    var audioCommitTasks: [AudioMixerItem.ID: Task<Void, Never>] = [:]
    var pendingRefreshWorkItem: DispatchWorkItem?

    init(
        autoLaunchManager: AutoLaunchManager,
        networkInterfaceManager: NetworkInterfaceManager,
        musicBlockerService: MusicBlockerService,
        systemStatsMonitor: any SystemStatsProviding,
        netTrafficStat: any NetworkTrafficProviding,
        audioSessionCatalog: any AudioSessionProviding
    ) {
        self.autoLaunchManager = autoLaunchManager
        self.networkInterfaceManager = networkInterfaceManager
        self.musicBlockerService = musicBlockerService
        self.systemStatsMonitor = systemStatsMonitor
        self.netTrafficStat = netTrafficStat
        self.audioSessionCatalog = audioSessionCatalog

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.autoLaunchEnabled = self.autoLaunchManager.isEnabled
            self.musicBlockerService.onEvent = { [weak self] event in
                self?.musicBlockerStatus = event.message
                self?.musicBlockerHasError = event.isError
            }
            self.musicBlockerService.start(
                isEnabled: self.xmusicEnabled,
                replacementValue: self.xmusicReplacement
            )
            self.startTimer()
        }
    }

    deinit {
        timer?.cancel()
        pendingRefreshWorkItem?.cancel()
        for task in audioCommitTasks.values {
            task.cancel()
        }
        let catalog = audioSessionCatalog
        Task {
            await catalog.stop()
        }
    }
}
