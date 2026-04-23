import AVFoundation
import Foundation

// 16kHz mono PCM recorder. Writes to in-memory buffer, emits WAV on stop.
// Hard cap 60s (SECURITY.md #6).
//
// Critical implementation note: AVAudioEngine tap buffers are short-lived — the
// same PCMBuffer is re-used across callbacks. Conversion MUST happen
// synchronously inside the tap closure; we then pass a copied Int16 array
// (Sendable) to the actor for accumulation.
actor AudioRecorder {
    static let maxRecordingSeconds: Double = 60
    static let sampleRate: Double = 16_000

    private let engine = AVAudioEngine()
    private var pcmSamples: [Int16] = []
    private(set) var isRecording = false
    private var stopTask: Task<Void, Never>?

    func start() async throws {
        guard !isRecording else { return }
        pcmSamples.removeAll(keepingCapacity: true)

        let input = engine.inputNode
        let inFormat = input.outputFormat(forBus: 0)
        guard let outFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Self.sampleRate,
            channels: 1,
            interleaved: true
        ) else {
            throw HandsfreeError.transcription("cannot create target audio format")
        }
        guard let converter = AVAudioConverter(from: inFormat, to: outFormat) else {
            throw HandsfreeError.transcription("cannot create audio converter")
        }

        input.installTap(onBus: 0, bufferSize: 4096, format: inFormat) { [weak self] inBuffer, _ in
            // Convert + copy synchronously; tap buffers get recycled by AVAudioEngine.
            // Use a FRESH converter per buffer — sharing one across calls corrupts
            // its internal state after the first convert returns.
            guard let conv = AVAudioConverter(from: inBuffer.format, to: outFormat) else { return }
            _ = converter  // keep reference so ARC doesn't deallocate the setup one (harmless)

            let ratio = Self.sampleRate / inBuffer.format.sampleRate
            let outCapacity = AVAudioFrameCount(Double(inBuffer.frameLength) * ratio + 64)
            guard outCapacity > 0,
                  let outBuf = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: outCapacity)
            else { return }

            var err: NSError?
            var fed = false
            _ = conv.convert(to: outBuf, error: &err) { _, status in
                if fed { status.pointee = .endOfStream; return nil }
                fed = true
                status.pointee = .haveData
                return inBuffer
            }
            guard err == nil, let ptr = outBuf.int16ChannelData?.pointee else { return }
            let frames = Int(outBuf.frameLength)
            guard frames > 0 else { return }
            let copy = Array(UnsafeBufferPointer(start: ptr, count: frames))
            Task { [weak self] in await self?.appendSamples(copy) }
        }

        engine.prepare()
        try engine.start()
        isRecording = true

        stopTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.maxRecordingSeconds))
            await self?.forceStop()
        }
    }

    func stop() async throws -> Data {
        stopTask?.cancel()
        stopTask = nil
        guard isRecording else { return Data() }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
        // Give any in-flight append tasks a moment to land.
        try? await Task.sleep(for: .milliseconds(60))
        return wavEncoded()
    }

    private func forceStop() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
    }

    private func appendSamples(_ samples: [Int16]) {
        pcmSamples.append(contentsOf: samples)
    }

    private func wavEncoded() -> Data {
        let sampleCount = pcmSamples.count
        let byteCount = sampleCount * 2
        var data = Data(capacity: 44 + byteCount)

        func appendU32LE(_ v: UInt32) {
            var v = v.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }
        func appendU16LE(_ v: UInt16) {
            var v = v.littleEndian
            withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
        }

        data.append(contentsOf: Array("RIFF".utf8))
        appendU32LE(UInt32(36 + byteCount))
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8))
        appendU32LE(16)                             // fmt chunk size
        appendU16LE(1)                              // PCM
        appendU16LE(1)                              // channels
        appendU32LE(UInt32(Self.sampleRate))
        appendU32LE(UInt32(Self.sampleRate) * 2)    // byte rate
        appendU16LE(2)                              // block align
        appendU16LE(16)                             // bits per sample
        data.append(contentsOf: Array("data".utf8))
        appendU32LE(UInt32(byteCount))
        pcmSamples.withUnsafeBufferPointer { buf in
            data.append(UnsafeBufferPointer(start: buf.baseAddress, count: buf.count)
                .withMemoryRebound(to: UInt8.self) { Data(buffer: $0) })
        }
        return data
    }
}
