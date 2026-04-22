import AppKit
import AVFoundation
import os

@MainActor
final class Orchestrator {
    private let status: AppStatus
    private let recorder = AudioRecorder()
    private var hotkeys: GlobalHotkeyManager?
    private let log = Logger(subsystem: "com.lighthouseconsultings.handsfree", category: "orchestrator")

    init(status: AppStatus) {
        self.status = status
    }

    func startup() {
        Task {
            await requestMicrophonePermission()
            status.state = isReady() ? .ready : .notReady
            startHotkeys()
        }
    }

    private func isReady() -> Bool {
        switch Preferences.backend {
        case .api:   return KeychainStore.get("openai_api_key") != nil
        case .local: return LocalWhisperClient.detect() != nil
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
            if mode == .raw {
                text = raw
            } else {
                guard let anthropic = KeychainStore.get("anthropic_api_key") else {
                    status.state = .error("Kein Anthropic API Key"); return
                }
                text = try await LLMClient(apiKey: anthropic).process(text: raw, mode: mode)
            }

            try TextInjector.insert(text)
            status.state = .ready
        } catch {
            log.error("pipeline: \(String(describing: error))")
            status.state = .error(String(describing: error).prefix(60).description)
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
