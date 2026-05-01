import Foundation

enum TranscriptionBackend: String { case api, local }
enum LLMBackend: String { case anthropic, ollama }

enum Preferences {
    private static let backendKey = "handsfree.backend"
    private static let llmBackendKey = "handsfree.llmBackend"
    private static let styleGuideKey = "handsfree.styleGuide"
    private static let whisperModelKey = "handsfree.whisperModel"
    private static let updateCheckEnabledKey = "handsfree.updateCheckEnabled"
    private static let appLanguageKey = "handsfree.appLanguage"
    static let didChangeNotification = Notification.Name("handsfree.preferences.didChange")

    static var appLanguage: AppLanguage {
        get {
            let raw = UserDefaults.standard.string(forKey: appLanguageKey) ?? AppLanguage.system.rawValue
            return AppLanguage(rawValue: raw) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: appLanguageKey)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }

    static var updateCheckEnabled: Bool {
        get {
            // Default true for fresh installs; user can opt out in Settings.
            if UserDefaults.standard.object(forKey: updateCheckEnabledKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: updateCheckEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: updateCheckEnabledKey)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }

    static var whisperModel: WhisperModel {
        get {
            let raw = UserDefaults.standard.string(forKey: whisperModelKey) ?? WhisperModel.default.rawValue
            return WhisperModel(rawValue: raw) ?? .default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: whisperModelKey)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }

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
