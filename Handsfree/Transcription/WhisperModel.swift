import Foundation

enum WhisperModel: String, CaseIterable, Identifiable {
    case turbo = "large-v3-turbo"
    case small = "small"
    case tiny  = "tiny"

    var id: String { rawValue }

    var fileName: String { "ggml-\(rawValue).bin" }

    var displayName: String {
        switch self {
        case .turbo: return "Turbo"
        case .small: return "Small"
        case .tiny:  return "Tiny"
        }
    }

    var sizeLabel: String {
        switch self {
        case .turbo: return "1,5 GB"
        case .small: return "466 MB"
        case .tiny:  return "75 MB"
        }
    }

    // For progress display before server reports expected bytes.
    var approximateBytes: Int64 {
        switch self {
        case .turbo: return 1_550_000_000
        case .small: return 466_000_000
        case .tiny:  return 75_000_000
        }
    }

    var subtitle: String {
        switch self {
        case .turbo: return t("Beste Qualität, ~1,5 GB RAM", "Best quality, ~1.5 GB RAM")
        case .small: return t("Guter Kompromiss, ~500 MB RAM", "Good trade-off, ~500 MB RAM")
        case .tiny:  return t("Für schwache Macs, ~150 MB RAM", "For low-end Macs, ~150 MB RAM")
        }
    }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(fileName)")!
    }

    static let `default`: WhisperModel = .turbo
}
