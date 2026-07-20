import Foundation

enum WhisperModel: String, CaseIterable, Identifiable {
    case turbo = "large-v3-turbo"
    case small = "small"
    case tiny  = "tiny"

    var id: String { rawValue }

    var fileName: String { "ggml-\(rawValue).bin" }

    // Device-based recommendation: Turbo needs headroom, 8 GB Macs choke on it.
    // On the x86_64 slice whisper runs CPU-only (no Metal) — Turbo takes tens of
    // seconds per dictation clip on Intel Macs, Small is the usable sweet spot.
    static var recommended: WhisperModel {
        #if arch(x86_64)
        return .small
        #else
        return ProcessInfo.processInfo.physicalMemory >= 16 * 1024 * 1024 * 1024 ? .turbo : .small
        #endif
    }

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
        #if arch(x86_64)
        case .turbo: return t("Beste Qualität, langsam auf Intel-Macs", "Best quality, slow on Intel Macs")
        #else
        case .turbo: return t("Beste Qualität, ~1,5 GB RAM", "Best quality, ~1.5 GB RAM")
        #endif
        case .small: return t("Guter Kompromiss, ~500 MB RAM", "Good trade-off, ~500 MB RAM")
        case .tiny:  return t("Für schwache Macs, ~150 MB RAM", "For low-end Macs, ~150 MB RAM")
        }
    }

    var downloadURL: URL {
        URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(fileName)")!
    }
}
