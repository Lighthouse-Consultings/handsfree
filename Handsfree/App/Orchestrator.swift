import AppKit
import AVFoundation
import os

@MainActor
final class Orchestrator {
    private let status: AppStatus
    private let recorder = AudioRecorder()
    private var hotkeys: GlobalHotkeyManager?
    private var composeClipboardContext: String?
    private let log = Logger(subsystem: "com.lighthouseconsultings.handsfree", category: "orchestrator")

    init(status: AppStatus) {
        self.status = status
    }

    func startup() {
        Task {
            await requestMicrophonePermission()
            refreshReadiness()
            startHotkeys()
            NotificationCenter.default.addObserver(
                forName: Preferences.didChangeNotification,
                object: nil, queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.refreshReadiness() }
            }
        }
    }

    func refreshReadiness() {
        switch status.state {
        case .recording, .transcribing: return
        default: break
        }
        switch readinessCheck() {
        case .ok: status.state = .ready
        case .missing(let why):
            log.info("readiness: \(why, privacy: .public)")
            status.state = .notReady(why)
        }
    }

    private enum Readiness { case ok, missing(String) }

    private func readinessCheck() -> Readiness {
        switch Preferences.backend {
        case .api:
            return KeychainStore.get("openai_api_key") == nil ? .missing("OpenAI API Key fehlt") : .ok
        case .local:
            let modelPath = ("~/.handsfree/models/ggml-large-v3-turbo.bin" as NSString).expandingTildeInPath
            if !FileManager.default.fileExists(atPath: modelPath) {
                return .missing("Modell fehlt: \(modelPath)")
            }
            if LocalWhisperClient.detect() == nil {
                return .missing("whisper-cli nicht gefunden in /opt/homebrew/bin")
            }
            return .ok
        }
    }

    private func startHotkeys() {
        hotkeys = GlobalHotkeyManager { [weak self] mode, phase in
            Task { @MainActor in await self?.handle(mode: mode, phase: phase) }
        }
        hotkeys?.start()
    }

    private func handle(mode: Mode, phase: GlobalHotkeyManager.HotkeyPhase) async {
        switch phase {
        case .begin:
            guard case .ready = status.state else { return }
            // Snapshot clipboard at record-start for Compose mode.
            if mode == .compose {
                composeClipboardContext = NSPasteboard.general.string(forType: .string)
            } else {
                composeClipboardContext = nil
            }
            status.activeMode = mode
            status.state = .recording
            do { try await recorder.start() }
            catch {
                status.state = .error("Aufnahme fehlgeschlagen")
                log.error("recorder start: \(String(describing: error))")
            }
        case .end:
            guard status.activeMode == mode else { return }
            await finish(mode: mode)
        }
    }

    private func finish(mode: Mode) async {
        status.state = .transcribing
        defer { status.activeMode = nil }

        do {
            let wav = try await recorder.stop()
            guard wav.count > 1024 else {
                status.state = .ready; return  // empty recording, ignore
            }

            let raw = try await transcribe(wav: wav)
            let text: String
            switch mode {
            case .raw:
                text = raw
            case .compose:
                text = try await runCompose(instruction: raw, context: composeClipboardContext)
            case .polished, .emoji:
                text = try await runRewrite(text: raw, mode: mode)
            }

            try TextInjector.insert(text)
            status.state = .ready
        } catch {
            log.error("pipeline: \(String(describing: error))")
            status.state = .error(String(describing: error).prefix(60).description)
        }
    }

    private func runRewrite(text: String, mode: Mode) async throws -> String {
        switch Preferences.llmBackend {
        case .anthropic:
            guard let key = KeychainStore.get("anthropic_api_key") else {
                throw HandsfreeError.postprocess("Anthropic API Key fehlt")
            }
            return try await LLMClient(apiKey: key).process(text: text, mode: mode)
        case .ollama:
            let system = ollamaRewriteSystemPrompt(mode: mode)
            return try await OllamaClient().generate(system: system, user: text)
        }
    }

    private func runCompose(instruction: String, context: String?) async throws -> String {
        let system = """
        Du bist ein präziser Schreib-Assistent. Der Nutzer gibt dir eine Instruction
        per Sprache, optional mit einem Clipboard-Text als Kontext. Liefere den
        fertigen Text so, dass er sofort in eine E-Mail, Chat-Nachricht oder Notiz
        eingefügt werden kann. Keine Meta-Kommentare, keine Anführungszeichen um
        das Ergebnis, keine Einleitung wie "Hier ist…". Antworte in der Sprache,
        in der die Instruction verfasst ist.
        """
        let user: String
        if let ctx = context, !ctx.isEmpty {
            user = "<clipboard>\n\(ctx)\n</clipboard>\n\n<instruction>\n\(instruction)\n</instruction>"
        } else {
            user = "<instruction>\n\(instruction)\n</instruction>"
        }

        switch Preferences.llmBackend {
        case .anthropic:
            guard let key = KeychainStore.get("anthropic_api_key") else {
                throw HandsfreeError.postprocess("Anthropic API Key fehlt")
            }
            return try await LLMClient(apiKey: key).raw(system: system, user: user)
        case .ollama:
            return try await OllamaClient().generate(system: system, user: user)
        }
    }

    private func ollamaRewriteSystemPrompt(mode: Mode) -> String {
        switch mode {
        case .polished:
            return "Du bekommst gesprochenen Text. Schreibe ihn in sauberes Deutsch/Englisch um (je nach Sprache des Inputs). Entferne Füllwörter, glätte Satzbau. Antworte NUR mit dem umformulierten Text."
        case .emoji:
            return "Du bekommst gesprochenen Text. Behalte ihn originalgetreu bei und streue passende Emojis ein. Antworte NUR mit dem Text."
        default:
            return "Antworte NUR mit dem umformulierten Text."
        }
    }

    private func transcribe(wav: Data) async throws -> String {
        switch Preferences.backend {
        case .local:
            guard let local = LocalWhisperClient.detect() else {
                throw HandsfreeError.transcription("Local model nicht gefunden (~/.handsfree/models/ggml-large-v3-turbo.bin)")
            }
            return try await local.transcribe(wav: wav)
        case .api:
            guard let openai = KeychainStore.get("openai_api_key") else {
                throw HandsfreeError.missingAPIKey
            }
            return try await WhisperClient(apiKey: openai).transcribe(wav: wav)
        }
    }

    private func requestMicrophonePermission() async {
        await withCheckedContinuation { cont in
            AVCaptureDevice.requestAccess(for: .audio) { _ in cont.resume() }
        }
    }
}
