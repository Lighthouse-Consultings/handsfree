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
            let ready = KeychainStore.get("openai_api_key") != nil
            status.state = ready ? .ready : .notReady
            startHotkeys()
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

        guard let openai = KeychainStore.get("openai_api_key") else {
            status.state = .error("Kein OpenAI API Key"); return
        }

        do {
            let wav = try await recorder.stop()
            guard wav.count > 1024 else {
                status.state = .ready; return  // empty recording, ignore
            }

            let raw = try await WhisperClient(apiKey: openai).transcribe(wav: wav)
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

    private func requestMicrophonePermission() async {
        await withCheckedContinuation { cont in
            AVCaptureDevice.requestAccess(for: .audio) { _ in cont.resume() }
        }
    }
}
