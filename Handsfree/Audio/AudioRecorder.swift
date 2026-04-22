import AVFoundation
import Foundation

// 16kHz mono PCM recorder. Writes to in-memory buffer, emits WAV on stop.
// Hard cap 60s (SECURITY.md #6).
actor AudioRecorder {
    static let maxRecordingSeconds: Double = 60
    static let sampleRate: Double = 16_000

    private let engine = AVAudioEngine()
    private var pcmSamples: [Int16] = []
    private var converter: AVAudioConverter?
    private var targetFormat: AVAudioFormat?
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
        targetFormat = outFormat
        converter = AVAudioConverter(from: inFormat, to: outFormat)

        input.installTap(onBus: 0, bufferSize: 1024, format: inFormat) { [weak self] buf, _ in
            Task { [weak self] in await self?.append(buf) }
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
        return wavEncoded()
    }

    private func forceStop() {
        guard isRecording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRecording = false
    }

    private func append(_ buffer: AVAudioPCMBuffer) {
        guard let converter, let targetFormat else { return }
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio + 1024)
        guard let outBuf = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outCapacity) else { return }

        var error: NSError?
        var fed = false
        converter.convert(to: outBuf, error: &error) { _, status in
            if fed { status.pointee = .noDataNow; return nil }
            fed = true
            status.pointee = .haveData
            return buffer
        }
        guard error == nil, let ptr = outBuf.int16ChannelData?.pointee else { return }
        let count = Int(outBuf.frameLength)
        pcmSamples.append(contentsOf: UnsafeBufferPointer(start: ptr, count: count))
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
