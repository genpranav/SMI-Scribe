import Foundation

/// Mono Float32 PCM at `AudioChunk.sampleRate`, the format every engine consumes.
public struct AudioChunk: Sendable {
    public static let sampleRate: Double = 16_000

    public enum Origin: Sendable { case microphone, system, mixed }

    public var samples: [Float]
    /// Offset of the first sample from the start of the recording, in seconds.
    public var timestamp: TimeInterval
    public var origin: Origin

    public init(samples: [Float], timestamp: TimeInterval, origin: Origin) {
        self.samples = samples
        self.timestamp = timestamp
        self.origin = origin
    }

    public var duration: TimeInterval { Double(samples.count) / Self.sampleRate }
}
