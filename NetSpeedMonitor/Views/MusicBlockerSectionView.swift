import SwiftUI

struct MusicBlockerSectionView: View {
    @EnvironmentObject private var menuBarState: MenuBarState
    @State private var isConfirmingEnable = false
    @State private var isEditingReplacement = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Music Blocker")

            HStack(spacing: 8) {
                Toggle("Block Apple Music / iTunes", isOn: enabledBinding)
                    .toggleStyle(.checkbox)

                Spacer()

                if menuBarState.xmusicEnabled {
                    Button(menuBarState.xmusicReplacement.isEmpty ? "Set Replacement..." : "Change...") {
                        isEditingReplacement = true
                    }
                    .controlSize(.small)

                    if !menuBarState.xmusicReplacement.isEmpty {
                        Button("Clear") {
                            menuBarState.saveMusicReplacement("")
                        }
                        .controlSize(.small)
                    }
                }
            }

            if menuBarState.xmusicEnabled {
                if !menuBarState.xmusicReplacement.isEmpty {
                    Text("Instead open: \(menuBarState.xmusicReplacement)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Text(menuBarState.musicBlockerStatus)
                    .foregroundStyle(menuBarState.musicBlockerHasError ? Color.red : Color.secondary)
            }
        }
        .font(.system(size: 11, design: .rounded))
        .alert("Enable Music Blocker?", isPresented: $isConfirmingEnable) {
            Button("Enable") {
                menuBarState.xmusicEnabled = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Apple Music or iTunes will be closed when detected. A configured replacement opens only after the blocked app has stopped.")
        }
        .sheet(isPresented: $isEditingReplacement) {
            MusicReplacementEditor(initialValue: menuBarState.xmusicReplacement) { value in
                menuBarState.saveMusicReplacement(value)
            }
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { menuBarState.xmusicEnabled },
            set: { newValue in
                if newValue {
                    isConfirmingEnable = true
                } else {
                    menuBarState.xmusicEnabled = false
                }
            }
        )
    }
}

private struct MusicReplacementEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var value: String
    @State private var validationMessage: String?

    let onSave: (String) -> Result<Void, MusicReplacement.ValidationError>

    init(
        initialValue: String,
        onSave: @escaping (String) -> Result<Void, MusicReplacement.ValidationError>
    ) {
        _value = State(initialValue: initialValue)
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Replacement App or Website")
                .font(.headline)
            Text("Use an absolute .app path or an http/https URL.")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("/Applications/Spotify.app or https://...", text: $value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 360)

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
    }

    private func save() {
        switch onSave(value) {
        case .success:
            dismiss()
        case .failure(let error):
            validationMessage = error.localizedDescription
        }
    }
}
