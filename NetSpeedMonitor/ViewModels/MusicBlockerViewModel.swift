import SwiftUI

@MainActor
final class MusicBlockerViewModel: ObservableObject {
    @AppStorage("XMusicEnabled") var isEnabled: Bool = false {
        didSet {
            let newValue = isEnabled
            Task { @MainActor in
                musicBlockerService.setEnabled(newValue)
            }
        }
    }
    @AppStorage("XMusicReplacement") var replacement: String = "" {
        didSet {
            let newValue = replacement
            Task { @MainActor in
                musicBlockerService.updateReplacement(newValue)
            }
        }
    }
    
    @Published var status = "Disabled"
    @Published var hasError = false
    
    let musicBlockerService: MusicBlockerService
    
    init(musicBlockerService: MusicBlockerService) {
        self.musicBlockerService = musicBlockerService
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.musicBlockerService.onEvent = { [weak self] event in
                self?.status = event.message
                self?.hasError = event.isError
            }
            self.musicBlockerService.start(
                isEnabled: self.isEnabled,
                replacementValue: self.replacement
            )
        }
    }
    
    func saveReplacement(_ value: String) -> Result<Void, MusicReplacement.ValidationError> {
        if value.isEmpty {
            replacement = ""
            return .success(())
        }
        
        do {
            if let validated = try MusicReplacement.parse(value) {
                replacement = validated.storedValue
            } else {
                replacement = ""
            }
            return .success(())
        } catch let error as MusicReplacement.ValidationError {
            return .failure(error)
        } catch {
            return .failure(.unsupportedValue)
        }
    }
}
