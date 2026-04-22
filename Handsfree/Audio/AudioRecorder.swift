import AVFoundation

// Phase 1 stub — Automode will flesh out AVAudioEngine tap + WAV encoding.
// Security: hard-capped at 60s recording to bound memory + API cost (SECURITY.md #6).
actor AudioRecorder {
    static let maxRecordingSeconds: Double = 60

    private let engine = AVAudioEngine()
    private(set) var isRecording = false
    private var stopTask: Task<Void, Never>?

    func start() async throws {
        guard !isRecording else { return }
        isRecording = true
        // TODO (Automode): install tap on input node, buffer 16kHz mono PCM.
        stopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.maxRecordingSeconds))
            await self?.forceStop()
        }
    }

    func stop() async throws -> Data {
        stopTask?.cancel()
        stopTask = nil
        isRecording = false
        // TODO (Automode): return WAV-encoded data.
        return Data()
    }

    private func forceStop() {
        isRecording = false
        engine.stop()
    }
}
