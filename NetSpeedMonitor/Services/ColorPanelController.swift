import AppKit

@MainActor
final class ColorPanelController: NSObject {
    static let shared = ColorPanelController()

    private var onChange: ((NSColor) -> Void)?
    private var onClose: (() -> Void)?

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(panelWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: NSColorPanel.shared
        )
    }

    func present(
        color: NSColor,
        relativeTo parentWindow: NSWindow?,
        onChange: @escaping (NSColor) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.onClose?()
        self.onChange = onChange
        self.onClose = onClose

        let panel = NSColorPanel.shared
        panel.setTarget(self)
        panel.setAction(#selector(colorChanged(_:)))
        panel.isContinuous = true
        panel.showsAlpha = false
        panel.mode = .wheel
        panel.color = color

        if panel.parent !== parentWindow {
            panel.parent?.removeChildWindow(panel)
            parentWindow?.addChildWindow(panel, ordered: .above)
        }
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func colorChanged(_ panel: NSColorPanel) {
        onChange?(panel.color)
    }

    @objc private func panelWillClose(_ notification: Notification) {
        let panel = NSColorPanel.shared
        panel.parent?.removeChildWindow(panel)
        finishPresentation()
    }

    private func finishPresentation() {
        let closeHandler = onClose
        onChange = nil
        onClose = nil
        closeHandler?()
    }
}
