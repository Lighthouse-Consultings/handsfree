import Foundation

// Offline transcription via whisper.cpp (`whisper-cli`). Shell-out, no network.
// Model default: ~/.handsfree/models/ggml-large-v3-turbo.bin
struct LocalWhisperClient {
    let binaryPath: String
    let modelPath: String

    static func detect() -> LocalWhisperClient? {
        let model = ("~/.handsfree/models/ggml-large-v3-turbo.bin" as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: model) else { return nil }

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

    func transcribe(wav: Data, language: String = "auto") async throws -> String {
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
            "-otxt",            // write <tmp>.txt
            "-of", tmp.path     // output file prefix
        ]
        // If we're running the bundled whisper-cli, tell ggml where our backend
        // .so files live. Absence of this var causes ggml to look in the build
        // machine's /opt/homebrew path which doesn't exist on the user's Mac.
        let binaryURL = URL(fileURLWithPath: binaryPath)
        if binaryURL.path.contains(".app/Contents/Resources/") {
            let backendsDir = binaryURL.deletingLastPathComponent()
                .appendingPathComponent("ggml-backends").path
            var env = ProcessInfo.processInfo.environment
            env["GGML_BACKEND_PATH"] = backendsDir
            process.environment = env
        }

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
