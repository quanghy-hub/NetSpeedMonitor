import AppKit
import SwiftUI

struct PersistentColorPicker: NSViewRepresentable {
    @Binding var hex: String
    @Binding var archive: String

    func makeCoordinator() -> Coordinator {
        Coordinator(hex: $hex, archive: $archive)
    }

    func makeNSView(context: Context) -> ColorSwatchControl {
        let swatch = ColorSwatchControl()
        swatch.color = ColorArchive.resolve(archive, fallbackHex: hex)
        swatch.target = context.coordinator
        swatch.action = #selector(Coordinator.showColorPanel(_:))
        swatch.setAccessibilityLabel("Choose color")
        context.coordinator.swatch = swatch
        return swatch
    }

    func updateNSView(_ swatch: ColorSwatchControl, context: Context) {
        context.coordinator.hex = $hex
        context.coordinator.archive = $archive
        swatch.isEnabled = context.environment.isEnabled

        guard !context.coordinator.isPresenting else { return }
        let storedColor = ColorArchive.resolve(archive, fallbackHex: hex)
        if swatch.color != storedColor {
            swatch.color = storedColor
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var hex: Binding<String>
        var archive: Binding<String>
        weak var swatch: ColorSwatchControl?
        var isPresenting = false

        init(hex: Binding<String>, archive: Binding<String>) {
            self.hex = hex
            self.archive = archive
            super.init()
        }

        @objc func showColorPanel(_ sender: ColorSwatchControl) {
            isPresenting = true
            swatch = sender
            ColorPanelController.shared.present(
                color: sender.color,
                relativeTo: sender.window,
                onChange: { [weak self] color in
                    self?.store(color)
                },
                onClose: { [weak self] in
                    self?.isPresenting = false
                }
            )
        }

        private func store(_ color: NSColor) {
            swatch?.color = color
            if let encodedColor = ColorArchive.encode(color) {
                archive.wrappedValue = encodedColor
            }
            hex.wrappedValue = color.toHex()
        }
    }
}
