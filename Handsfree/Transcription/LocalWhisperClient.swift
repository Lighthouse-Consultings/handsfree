import Foundation

// Offline transcription via whisper.cpp (`whisper-cli`). Shell-out, no network.
// Model lookup (first match wins):
//   1. /Users/Shared/.handsfree/models/ggml-large-v3-turbo.bin   (shared across users)
//   2. ~/.handsfree/models/ggml-large-v3-turbo.bin               (per-user fallback)
struct LocalWhisperClient {
    let binaryPath: String
    let modelPath: String

    static var modelFileName: String { Preferences.whisperModel.fileName }

    static func modelSearchPaths(for model: WhisperModel = Preferences.whisperModel) -> [String] {
        [
            "/Users/Shared/.handsfree/models/\(model.fileName)",
            ("~/.handsfree/models/\(model.fileName)" as NSString).expandingTildeInPath
        ]
    }

    static func detect() -> LocalWhisperClient? {
        guard let model = modelSearchPaths().first(where: { FileManager.default.fileExists(atPath: $0) })
        else { return nil }

        // 1. Prefer the bundled whisper-cli inside Handsfree.app (no brew needed)
        if let bundled = Bundle.main.url(forResource: "whisper-cli", withExtension: nil),
           FileManager.default.fileExists(atPath: bundled.path) {
            return LocalWhisperClient(binaryPath: bundled.path, modelPath: model)
        }

        // 2. Fallback: brew-installed system locations
        let candidates = [
            "/opt/homebrew/bin/whisper-cli",
            "/opt/homebrew/opt/whisper-cpp/bin/whisper-cli",
            "/usr/local/bin/whisper-cli",
            "/usr/local/opt/whisper-cpp/bin/whisper-cli"
        ]
        for path in candidates {
            let resolved = (path as NSString).resolvingSymlinksInPath
            if FileManager.default.fileExists(atPath: resolved) {
                return LocalWhisperClient(binaryPath: resolved, modelPath: model)
            }
        }
        return nil
    }

    func transcribe(wav: Data, language: String = "de") async throws -> String {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("handsfree-\(UUID().uuidString).wav")
        try wav.write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = [
            "-m", modelPath,
            "-f", tmp.path,
            "-l", language,
            "-nt",              // no timestamps
            "--no-prints",      // suppress progress
            "-sns",             // suppress non-speech tokens — blocks "you" / "[Music]" hallucinations on silence
            "-otxt",            // write <tmp>.txt
            "-of", tmp.path     // output file prefix
        ]

        let errPipe = Pipe()
        let outPipe = Pipe()
        process.standardError = errPipe
        process.standardOutput = outPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let err = String(data: errPipe.fileHandleForReading.availableData, encoding: .utf8) ?? "exit \(process.terminationStatus)"
            throw HandsfreeError.transcription("whisper-cli: \(err.prefix(800))")
        }

        let txtURL = URL(fileURLWithPath: tmp.path + ".txt")
        defer { try? FileManager.default.removeItem(at: txtURL) }
        let text = (try? String(contentsOf: txtURL, encoding: .utf8)) ?? ""
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
