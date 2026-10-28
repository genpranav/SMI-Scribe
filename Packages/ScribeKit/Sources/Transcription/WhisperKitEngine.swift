import Foundation
@preconcurrency import WhisperKit

/// Whisper via Core ML (Neural Engine). Multilingual; the default engine.
public actor WhisperKitEngine: TranscriptionEngine {
    private let modelName: String
    private var pipe: WhisperKit?

    /// - Parameter modelName: a WhisperKit model id, e.g. "large-v3-v20240930_turbo"
    ///   (best quality) or "base.en" (fast, small download).
    public init(modelName: String = "large-v3-v20240930_turbo") {
        self.modelName = modelName
    }

    public func prepare() async throws {
        guard pipe == nil else { return }
        pipe = try await WhisperKit(WhisperKitConfig(model: modelName))
    }

    public func transcribe(_ samples: [Float]) async throws -> [TranscribedSpan] {
        guard let pipe else { throw TranscriptionError.notPrepared }
        let results = try await pipe.transcribe(audioArray: samples)
        return results.flatMap(\.segments).map {
            TranscribedSpan(start: TimeInterval($0.start), end: TimeInterval($0.end), text: $0.text)
        }
    }
}
