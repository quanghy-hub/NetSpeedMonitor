import SwiftUI
import Combine
import SystemConfiguration

final class MenuBarState: ObservableObject {
    @AppStorage("AutoLaunchEnabled") var autoLaunchEnabled: Bool = false {
        didSet {
            AutoLaunchManager.shared.isEnabled = autoLaunchEnabled
        }
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

    // Music Blocker Settings
    @AppStorage("XMusicEnabled") var xmusicEnabled: Bool = false {
        didSet {
            let newValue = xmusicEnabled
            Task { @MainActor in
                MusicBlockerService.shared.setEnabled(newValue)
            }
        }
    }
    @AppStorage("XMusicReplacement") var xmusicReplacement: String = "" {
        didSet {
            let newValue = xmusicReplacement
            Task { @MainActor in
                MusicBlockerService.shared.updateReplacement(newValue)
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

    private var timer: Timer?
    private var lastIconSignature = ""
    private var netTrafficStat = NetTrafficStatReceiver()
    private var systemStatsMonitor = SystemStatsMonitor()
    private var audioSessionCatalog = AudioSessionCatalog()
    private var audioCommitWorkItems: [AudioMixerItem.ID: DispatchWorkItem] = [:]
    private var pendingRefreshWorkItem: DispatchWorkItem?

    private func queueRefreshIcon() {
        pendingRefreshWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.refreshIcon(force: true)
        }
        pendingRefreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: workItem)
    }

    private func updateNetSpeedUpdateIntervalStatus() {
        logger.info("netSpeedUpdateInterval, \(self.netSpeedUpdateInterval.displayName)")
        self.stopTimer()
        self.startTimer()
    }

    private func refreshIcon(force: Bool = false) {
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

    private func startTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(self.netSpeedUpdateInterval.rawValue), repeats: true) { _ in

            guard let primaryInterface = NetworkInterfaceManager.shared.getPrimaryInterface() else { return }

            if let netTrafficStatMap = self.netTrafficStat.getNetTrafficStatMap() {
                if let netTrafficStat = netTrafficStatMap.object(forKey: primaryInterface) as? NetTrafficStat  {
                    let rawDownload = netTrafficStat.ibytes_per_sec as! Double
                    let rawUpload = netTrafficStat.obytes_per_sec as! Double
                    self.menuText = SpeedFormatter.format(upload: rawUpload, download: rawDownload, unit: self.speedUnit)
                }
            }

            // Update CPU & RAM stats
            self.cpuUsage = self.systemStatsMonitor.getCPUUsage()
            self.ramUsage = self.systemStatsMonitor.getRAMUsage()

            // Update Battery stats
            let batteryInfo = self.systemStatsMonitor.getBatteryInfo()
            self.batteryLevel = batteryInfo.level
            self.batteryIsCharging = batteryInfo.isCharging

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

    func refreshAudioMixer() {
        guard !isAudioMixerRefreshing else { return }
        isAudioMixerRefreshing = true
        audioMixerStatus = "Scanning audio..."

        DispatchQueue.global(qos: .userInitiated).async {
            let items = self.audioSessionCatalog.loadItems()
            DispatchQueue.main.async {
                self.audioMixerItems = items
                self.audioMixerStatus = items.isEmpty ? "No audible app or media tab found" : "\(items.count) audio source\(items.count == 1 ? "" : "s")"
                self.isAudioMixerRefreshing = false
            }
        }
    }

    func setAudioVolume(_ volume: Double, for itemID: AudioMixerItem.ID, commitImmediately: Bool = false) {
        guard let index = audioMixerItems.firstIndex(where: { $0.id == itemID }) else { return }
        let item = audioMixerItems[index]
        let clampedVolume = min(max(volume, 0), item.maxVolume)
        let updatedItem = AudioMixerItem(
            id: item.id,
            kind: item.kind,
            processID: item.processID,
            bundleIdentifier: item.bundleIdentifier,
            title: item.title,
            subtitle: item.subtitle,
            isAudible: item.isAudible,
            canSetVolume: item.canSetVolume,
            volume: clampedVolume,
            maxVolume: item.maxVolume,
            audioObjectIDs: item.audioObjectIDs
        )
        audioMixerItems[index] = updatedItem

        audioCommitWorkItems[itemID]?.cancel()

        let commit = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if updatedItem.kind == .app {
                self.audioSessionCatalog.setVolume(clampedVolume, for: updatedItem)
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                self.audioSessionCatalog.setVolume(clampedVolume, for: updatedItem)
            }
        }
        audioCommitWorkItems[itemID] = commit

        if commitImmediately {
            commit.perform()
            audioCommitWorkItems[itemID] = nil
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: commit)
    }

    @discardableResult
    func saveMusicReplacement(_ value: String) -> Result<Void, MusicReplacement.ValidationError> {
        do {
            let replacement = try MusicReplacement.parse(value)
            xmusicReplacement = replacement?.storedValue ?? ""
            musicBlockerHasError = false
            musicBlockerStatus = replacement == nil ? "No replacement configured" : "Replacement ready"
            return .success(())
        } catch let error as MusicReplacement.ValidationError {
            musicBlockerHasError = true
            musicBlockerStatus = error.localizedDescription
            return .failure(error)
        } catch {
            musicBlockerHasError = true
            musicBlockerStatus = "Could not validate the replacement."
            return .failure(.unsupportedValue)
        }
    }

    init() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.autoLaunchEnabled = AutoLaunchManager.shared.isEnabled
            MusicBlockerService.shared.onEvent = { [weak self] event in
                self?.musicBlockerStatus = event.message
                self?.musicBlockerHasError = event.isError
            }
            MusicBlockerService.shared.start(
                isEnabled: self.xmusicEnabled,
                replacementValue: self.xmusicReplacement
            )
            self.startTimer()
        }
    }

    deinit {
        DispatchQueue.main.async {
            self.stopTimer()
            self.audioSessionCatalog.stop()
        }
    }
}
