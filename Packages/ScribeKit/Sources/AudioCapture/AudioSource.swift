import ScribeModels

/// Something that produces 16 kHz mono audio while a meeting is recorded.
public protocol AudioSource: Sendable {
    func start() async throws -> AsyncStream<AudioChunk>
    func stop() async
}

public enum AudioCaptureError: Error, Sendable {
    case permissionDenied
    case formatUnsupported
    case notImplemented(String)
}
