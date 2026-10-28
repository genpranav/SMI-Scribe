import Foundation

/// A span of recognised speech, in seconds relative to the audio passed in.
public struct TranscribedSpan: Sendable, Hashable {
    public var start: TimeInterval
    public var end: TimeInterval
    public var text: String

    public init(start: TimeInterval, end: TimeInterval, text: String) {
        self.start = start
        self.end = end
        self.text = text
    }
}

public protocol TranscriptionEngine: Sendable {
    /// Downloads (if needed) and loads the model. Safe to call repeatedly.
    func prepare() async throws
    /// Transcribes 16 kHz mono samples.
    func transcribe(_ samples: [Float]) async throws -> [TranscribedSpan]
}

public enum TranscriptionError: Error, Sendable {
    case notPrepared
    case notImplemented(String)
}
