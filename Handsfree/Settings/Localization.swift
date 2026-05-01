import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, de, en

    var id: String { rawValue }

    var resolved: AppLanguage {
        switch self {
        case .system:
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            return code.lowercased().hasPrefix("de") ? .de : .en
        case .de, .en:
            return self
        }
    }

    var nativeName: String {
        switch self {
        case .system: return "System"
        case .de:     return "Deutsch"
        case .en:     return "English"
        }
    }
}

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    /// Atomic mirror used by the nonisolated `t(...)` helper. Updated from main alongside `language`.
    private static let lock = NSLock()
    private static var _current: AppLanguage = Preferences.appLanguage.resolved

    static var current: AppLanguage {
        lock.lock(); defer { lock.unlock() }
        return _current
    }

    @Published private(set) var language: AppLanguage

    private var observer: NSObjectProtocol?

    private init() {
        let initial = Preferences.appLanguage.resolved
        self.language = initial
        Self.lock.lock()
        Self._current = initial
        Self.lock.unlock()

        observer = NotificationCenter.default.addObserver(
            forName: Preferences.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let new = Preferences.appLanguage.resolved
            Self.lock.lock()
            Self._current = new
            Self.lock.unlock()
            if new != self.language { self.language = new }
        }
    }
}

/// Returns the German or English string based on the user's resolved language preference.
/// Safe to call from any context — backed by a lock-protected mirror of the active language.
func t(_ de: String, _ en: String) -> String {
    switch LocalizationManager.current {
    case .de:     return de
    case .en:     return en
    case .system: return Locale.current.language.languageCode?.identifier.lowercased().hasPrefix("de") == true ? de : en
    }
}
