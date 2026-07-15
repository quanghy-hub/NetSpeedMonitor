import Foundation

extension MenuBarState {
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
}
