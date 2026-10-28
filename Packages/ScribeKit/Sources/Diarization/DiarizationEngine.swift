import Foundation

/// A stretch of audio attributed to one (anonymous) speaker cluster.
public struct SpeakerTurn: Sendable, Hashable {
    /// Cluster label, stable within one meeting ("S1", "S2", ...).
    public var label: String
    public var start: TimeInterval
    public var end: TimeInterval
    /// Speaker embedding for the cluster, used to match known voiceprints.
    public var embedding: [Float]

    public init(label: String, start: TimeInterval, end: TimeInterval, embedding: [Float]) {
        self.label = label
        self.start = start
        self.end = end
        self.embedding = embedding
    }
}

public protocol DiarizationEngine: Sendable {
    func prepare() async throws
    /// Diarizes a full recording of 16 kHz mono samples.
    func diarize(_ samples: [Float]) async throws -> [SpeakerTurn]
}

public enum DiarizationError: Error, Sendable {
    case notPrepared
    case notImplemented(String)
}
