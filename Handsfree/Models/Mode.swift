import Foundation

enum Mode: String, CaseIterable {
    case raw, polished, compose, emoji

    var title: String {
        switch self {
        case .raw:      return "Handsfree"
        case .polished: return "Handsfree+"
        case .compose:  return "Handsfree Compose"
        case .emoji:    return "Handsfree Emoji"
        }
    }

    var subtitle: String {
        switch self {
        case .raw:      return "Sprache rein. Text raus."
        case .polished: return "Geschrieben sprechen."
        case .compose:  return "Instruction + Clipboard → Antwort."
        case .emoji:    return "Text mit Emojis."
        }
    }

    var symbol: String {
        switch self {
        case .raw:      return "mic.fill"
        case .polished: return "text.alignleft"
        case .compose:  return "bubble.left.and.text.bubble.right"
        case .emoji:    return "face.smiling.fill"
        }
    }

    var hotkeyLabel: String {
        switch self {
        case .raw:      return "⌥ᴿ + ⇧"
        case .polished: return "⌥ᴿ + ⌃"
        case .compose:  return "⌥ᴿ + ⌥ᴸ"
        case .emoji:    return "⌥ᴿ + ⌘"
        }
    }
}
