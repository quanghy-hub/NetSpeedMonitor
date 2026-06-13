import SwiftUI

struct PresetColorPicker: View {
    @Binding var selectedHex: String
    
    private let presetColors: [(name: String, hex: String)] = [
        ("Green", "#34C759"),
        ("Blue", "#007AFF"),
        ("Cyan", "#5AC8FA"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55"),
        ("Orange", "#FF9500"),
        ("Yellow", "#FFCC00"),
        ("White", "#FFFFFF"),
    ]
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(presetColors, id: \.hex) { preset in
                Button(action: {
                    selectedHex = preset.hex
                }) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: preset.hex))
                        .frame(width: 12, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(
                                    selectedHex == preset.hex ? Color.primary : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                }
                .buttonStyle(.plain)
                .help(preset.name)
            }
        }
    }
}
