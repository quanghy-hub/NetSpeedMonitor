import AppKit
import IOKit

@MainActor
final class MediaPlayKeyMonitor {
    var onPlayPressed: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    @discardableResult
    func start() -> Bool {
        guard globalMonitor == nil, localMonitor == nil else {
            return true
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            guard Self.isInitialPlayPress(data1: event.data1) else { return }
            Task { @MainActor in
                self?.onPlayPressed?()
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            if Self.isInitialPlayPress(data1: event.data1) {
                self?.onPlayPressed?()
            }
            return event
        }

        return globalMonitor != nil && localMonitor != nil
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    static func isInitialPlayPress(data1: Int) -> Bool {
        let keyCode = (data1 & 0xFFFF0000) >> 16
        let keyFlags = data1 & 0x0000FFFF
        let keyState = (keyFlags & 0xFF00) >> 8
        let isRepeat = (keyFlags & 0x1) == 1

        // 0xA is the key-down state used by NX_SYSDEFINED media events.
        return keyCode == NX_KEYTYPE_PLAY && keyState == 0xA && !isRepeat
    }

    deinit {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }
}
