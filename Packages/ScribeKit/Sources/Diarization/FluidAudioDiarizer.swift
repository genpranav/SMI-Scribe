import FluidAudio
import Foundation

/// pyannote segmentation + WeSpeaker embeddings via FluidAudio (Core ML, Neural Engine).
public actor FluidAudioDiarizer: DiarizationEngine {
    public init() {}

    public func prepare() async throws {
        // TODO: Download/load models with FluidAudio's DiarizerModels and create a DiarizerManager.
        throw DiarizationError.notImplemented("FluidAudioDiarizer")
    }

    public func diarize(_ samples: [Float]) async throws -> [SpeakerTurn] {
        // TODO: DiarizerManager.performCompleteDiarization(samples) and map its segments
        // (speakerId, start/end, embedding) to SpeakerTurn.
        throw DiarizationError.notImplemented("FluidAudioDiarizer")
    }
}
