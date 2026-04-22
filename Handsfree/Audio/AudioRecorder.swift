import AVFoundation

// Phase 1 stub — Automode will flesh out AVAudioEngine tap + WAV encoding.
actor AudioRecorder {
    private let engine = AVAudioEngine()
    private(set) var isRecording = false

    func start() async throws {
        guard !isRecording else { return }
        isRecording = true
        // TODO: install tap on input node, buffer 16kHz mono PCM.
    }

    func stop() async throws -> Data {
        isRecording = false
        // TODO: return WAV-encoded data.
        return Data()
    }
}
