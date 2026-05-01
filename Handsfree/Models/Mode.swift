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
        case .raw:      return t("Sprache rein. Text raus.", "Speech in. Text out.")
        case .polished: return t("Geschrieben sprechen.", "Speak it written.")
        case .compose:  return t("Instruction + Clipboard → Antwort.", "Instruction + clipboard → reply.")
        case .emoji:    return t("Text mit Emojis.", "Text with emojis.")
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
