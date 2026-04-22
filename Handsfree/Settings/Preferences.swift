import Foundation

enum TranscriptionBackend: String { case api, local }

enum Preferences {
    private static let backendKey = "handsfree.backend"

    static var backend: TranscriptionBackend {
        get {
            let raw = UserDefaults.standard.string(forKey: backendKey) ?? TranscriptionBackend.api.rawValue
            return TranscriptionBackend(rawValue: raw) ?? .api
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: backendKey) }
    }
}
