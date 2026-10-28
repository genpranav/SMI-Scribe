import FluidAudio
import Foundation

/// NVIDIA Parakeet TDT v3 via FluidAudio (Core ML, Neural Engine).
/// Much faster than Whisper; English + 25 European languages.
public actor ParakeetEngine: TranscriptionEngine {
    public init() {}

    public func prepare() async throws {
        // TODO: Download/load models with FluidAudio's AsrModels and create an AsrManager.
        throw TranscriptionError.notImplemented("ParakeetEngine")
    }

    public func transcribe(_ samples: [Float]) async throws -> [TranscribedSpan] {
        // TODO: AsrManager.transcribe(samples) and map token timings to spans.
        throw TranscriptionError.notImplemented("ParakeetEngine")
    }
}
