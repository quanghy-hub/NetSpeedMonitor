import SwiftUI

struct MusicBlockerSectionView: View {
    @EnvironmentObject private var musicBlockerVM: MusicBlockerViewModel
    @State private var isConfirmingEnable = false
    @State private var isEditingReplacement = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Music Blocker")

            HStack(spacing: 8) {
                Toggle("Block Apple Music / iTunes", isOn: enabledBinding)
                    .toggleStyle(.checkbox)

                Spacer()

                if musicBlockerVM.isEnabled {
                    Button(musicBlockerVM.replacement.isEmpty ? "Set Replacement..." : "Change...") {
                        isEditingReplacement = true
                    }
                    .controlSize(.small)

                    if !musicBlockerVM.replacement.isEmpty {
                        Button("Clear") {
                            _ = musicBlockerVM.saveReplacement("")
                        }
                        .controlSize(.small)
                    }
                }
            }

            if musicBlockerVM.isEnabled {
                if !musicBlockerVM.replacement.isEmpty {
                    Text("Instead open: \(musicBlockerVM.replacement)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Text(musicBlockerVM.status)
                    .foregroundStyle(musicBlockerVM.hasError ? Color.red : Color.secondary)
            }
        }
        .font(.system(size: 11, design: .rounded))
        .alert("Enable Music Blocker?", isPresented: $isConfirmingEnable) {
            Button("Enable") {
                musicBlockerVM.isEnabled = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Apple Music or iTunes will be closed when detected. A configured replacement opens only after the blocked app has stopped.")
        }
        .sheet(isPresented: $isEditingReplacement) {
            MusicReplacementEditor(initialValue: musicBlockerVM.replacement) { value in
                musicBlockerVM.saveReplacement(value)
            }
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { musicBlockerVM.isEnabled },
            set: { newValue in
                if newValue {
                    isConfirmingEnable = true
                } else {
                    musicBlockerVM.isEnabled = false
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
