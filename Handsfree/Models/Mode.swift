import Foundation

enum Mode: String, CaseIterable {
    case raw, polished, rage, emoji

    var title: String {
        switch self {
        case .raw:      return "Handsfree"
        case .polished: return "Handsfree+"
        case .rage:     return "Handsfree $%&!"
        case .emoji:    return "Handsfree Emoji"
        }
    }

    var subtitle: String {
        switch self {
        case .raw:      return "Sprache rein. Text raus."
        case .polished: return "Geschrieben sprechen."
        case .rage:     return "Frust rein. Entspannt raus."
        case .emoji:    return "Text mit Emojis."
        }
    }

    var symbol: String {
        switch self {
        case .raw:      return "mic.fill"
        case .polished: return "text.alignleft"
        case .rage:     return "flame.fill"
        case .emoji:    return "face.smiling.fill"
        }
    }

    var hotkeyLabel: String {
        switch self {
        case .raw:      return "fn + ⇧"
        case .polished: return "fn + ⌃"
        case .rage:     return "fn + ⌥"
        case .emoji:    return "fn + ⌘"
        }
    }
}
