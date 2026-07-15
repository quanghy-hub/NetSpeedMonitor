import AppKit
import os.log

@MainActor
final class MusicBlockerService {
    enum Event {
        case ready
        case blocked(String)
        case failed(String)

        var message: String {
            switch self {
            case .ready:
                return "Watching for Apple Music and iTunes"
            case .blocked(let applicationName):
                return "Blocked \(applicationName)"
            case .failed(let message):
                return message
            }
        }

        var isError: Bool {
            if case .failed = self { return true }
            return false
        }
    }

    var onEvent: ((Event) -> Void)?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.elegracer.NetSpeedMonitor",
        category: "music-blocker"
    )
    private let workspace: NSWorkspace
    private let playKeyMonitor: MediaPlayKeyMonitor
    private var isEnabled = false
    private var replacement: MusicReplacement?
    private var isObservingLaunches = false
    private var pendingProcessIdentifiers: Set<pid_t> = []
    private var lastReplacementLaunchDate = Date.distantPast

    init(
        workspace: NSWorkspace = .shared,
        playKeyMonitor: MediaPlayKeyMonitor? = nil
    ) {
        self.workspace = workspace
        self.playKeyMonitor = playKeyMonitor ?? MediaPlayKeyMonitor()
        self.playKeyMonitor.onPlayPressed = { [weak self] in
            self?.handlePlayKeyPress()
        }
    }

    func start(isEnabled: Bool, replacementValue: String) {
        updateReplacement(replacementValue)
        setEnabled(isEnabled)
    }

    func setEnabled(_ newValue: Bool) {
        isEnabled = newValue
        updateObserverState()

        guard newValue else {
            playKeyMonitor.stop()
            pendingProcessIdentifiers.removeAll()
            return
        }

        guard playKeyMonitor.start() else {
            onEvent?(.failed("Could not monitor the media Play key."))
            return
        }
        onEvent?(.ready)
        blockRunningMusicApplications()
    }

    func updateReplacement(_ value: String) {
        do {
            replacement = try MusicReplacement.parse(value)
        } catch {
            replacement = nil
            onEvent?(.failed(error.localizedDescription))
        }
    }

    private func updateObserverState() {
        let notificationCenter = workspace.notificationCenter
        if isEnabled, !isObservingLaunches {
            notificationCenter.addObserver(
                self,
                selector: #selector(applicationDidLaunch(_:)),
                name: NSWorkspace.didLaunchApplicationNotification,
                object: nil
            )
            isObservingLaunches = true
            logger.info("Music Blocker started observing launches")
        } else if !isEnabled, isObservingLaunches {
            notificationCenter.removeObserver(
                self,
                name: NSWorkspace.didLaunchApplicationNotification,
                object: nil
            )
            isObservingLaunches = false
            logger.info("Music Blocker stopped observing launches")
        }
    }

    @objc private func applicationDidLaunch(_ notification: Notification) {
        guard isEnabled,
              let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              isBlockedApplication(application) else {
            return
        }

        block(application)
    }

    private func blockRunningMusicApplications() {
        workspace.runningApplications
            .filter(isBlockedApplication)
            .forEach(block)
    }

    private func handlePlayKeyPress() {
        guard isEnabled else { return }
        logger.info("Media Play key detected")
        launchReplacementIfNeeded()
        blockRunningMusicApplications()
    }

    private func block(_ application: NSRunningApplication) {
        let processIdentifier = application.processIdentifier
        guard !application.isTerminated,
              pendingProcessIdentifiers.insert(processIdentifier).inserted else {
            return
        }

        let applicationName = application.localizedName ?? "Music"
        logger.info("Requesting termination for blocked application")
        _ = application.terminate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self, weak application] in
            guard let self, let application else { return }
            if !application.isTerminated {
                self.logger.warning("Blocked application did not terminate gracefully; forcing termination")
                _ = application.forceTerminate()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self, weak application] in
                guard let self else { return }
                self.pendingProcessIdentifiers.remove(processIdentifier)

                guard application?.isTerminated == true else {
                    self.onEvent?(.failed("Could not close \(applicationName)."))
                    return
                }

                guard self.isEnabled else { return }
                self.onEvent?(.blocked(applicationName))
                self.launchReplacementIfNeeded()
            }
        }
    }

    private func isBlockedApplication(_ application: NSRunningApplication) -> Bool {
        ["com.apple.Music", "com.apple.iTunes"].contains(application.bundleIdentifier)
    }

    private func launchReplacementIfNeeded() {
        guard let replacement else { return }

        let now = Date()
        guard now.timeIntervalSince(lastReplacementLaunchDate) >= 2 else { return }
        lastReplacementLaunchDate = now

        switch replacement.kind {
        case .application:
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            workspace.openApplication(at: replacement.url, configuration: configuration) { [weak self] _, error in
                Task { @MainActor in
                    self?.handleLaunchCompletion(error)
                }
            }
        case .website:
            guard workspace.open(replacement.url) else {
                onEvent?(.failed("Could not open the replacement URL."))
                return
            }
        }
    }

    private func handleLaunchCompletion(_ error: Error?) {
        guard error != nil else { return }
        logger.error("Could not open replacement application")
        onEvent?(.failed("Could not open the replacement application."))
    }

    deinit {
        if isObservingLaunches {
            workspace.notificationCenter.removeObserver(self)
        }
    }
}
