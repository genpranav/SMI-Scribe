@preconcurrency import AVFoundation
import ScribeModels

/// Captures the default input device via AVAudioEngine and resamples to 16 kHz mono.
public final class MicrophoneSource: AudioSource, @unchecked Sendable {
    // Mutated only from start()/stop(), which the session actor serialises.
    private let engine = AVAudioEngine()

    public init() {}

    public func start() async throws -> AsyncStream<AudioChunk> {
        guard await AVCaptureDevice.requestAccess(for: .audio) else {
            throw AudioCaptureError.permissionDenied
        }

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard
            let targetFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32, sampleRate: AudioChunk.sampleRate, channels: 1, interleaved: false),
            let converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        else { throw AudioCaptureError.formatUnsupported }

        let (stream, continuation) = AsyncStream.makeStream(of: AudioChunk.self, bufferingPolicy: .bufferingNewest(64))
        let ratio = AudioChunk.sampleRate / inputFormat.sampleRate
        var framesEmitted: AVAudioFramePosition = 0

        input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
            guard let out = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }
            var consumed = false
            converter.convert(to: out, error: nil) { _, status in
                if consumed {
                    status.pointee = .noDataNow
                    return nil
                }
                consumed = true
                status.pointee = .haveData
                return buffer
            }
            guard let channel = out.floatChannelData?[0], out.frameLength > 0 else { return }
            let samples = Array(UnsafeBufferPointer(start: channel, count: Int(out.frameLength)))
            let timestamp = Double(framesEmitted) / AudioChunk.sampleRate
            framesEmitted += AVAudioFramePosition(out.frameLength)
            continuation.yield(AudioChunk(samples: samples, timestamp: timestamp, origin: .microphone))
        }

        continuation.onTermination = { [engine] _ in
            engine.inputNode.removeTap(onBus: 0)
        }
        engine.prepare()
        try engine.start()
        return stream
    }

    public func stop() async {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
    }
}
