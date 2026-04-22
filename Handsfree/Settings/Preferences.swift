import Foundation

enum TranscriptionBackend: String { case api, local }
enum LLMBackend: String { case anthropic, ollama }

enum Preferences {
    private static let backendKey = "handsfree.backend"
    private static let llmBackendKey = "handsfree.llmBackend"
    private static let styleGuideKey = "handsfree.styleGuide"
    static let didChangeNotification = Notification.Name("handsfree.preferences.didChange")

    static var styleGuide: String {
        get { UserDefaults.standard.string(forKey: styleGuideKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: styleGuideKey) }
    }

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

    static var llmBackend: LLMBackend {
        get {
            let raw = UserDefaults.standard.string(forKey: llmBackendKey) ?? LLMBackend.anthropic.rawValue
            return LLMBackend(rawValue: raw) ?? .anthropic
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: llmBackendKey)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }

    static func notifyChanged() {
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }
}
