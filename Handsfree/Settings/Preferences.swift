import Foundation

enum TranscriptionBackend: String { case api, local }

enum Preferences {
    private static let backendKey = "handsfree.backend"
    static let didChangeNotification = Notification.Name("handsfree.preferences.didChange")

    static var backend: TranscriptionBackend {
        get {
            let raw = UserDefaults.standard.string(forKey: backendKey) ?? TranscriptionBackend.api.rawValue
            return TranscriptionBackend(rawValue: raw) ?? .api
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: backendKey)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }

    static func notifyChanged() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
