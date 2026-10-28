import ScribeModels

/// Fans several sources into one stream. Chunks keep their origin so the pipeline
/// can tell the local user (mic) from remote participants (system audio).
public final class AudioMixer: AudioSource, @unchecked Sendable {
    private let sources: [any AudioSource]

    public init(sources: [any AudioSource]) {
        self.sources = sources
    }

    public func start() async throws -> AsyncStream<AudioChunk> {
        var streams: [AsyncStream<AudioChunk>] = []
        for source in sources {
            do {
                streams.append(try await source.start())
            } catch AudioCaptureError.notImplemented {
                continue  // Degrade gracefully while a source is still stubbed.
            }
        }
        let (merged, continuation) = AsyncStream.makeStream(of: AudioChunk.self)
        let streamsToMerge = streams
        let task = Task {
            await withTaskGroup(of: Void.self) { group in
                for stream in streamsToMerge {
                    group.addTask {
                        for await chunk in stream { continuation.yield(chunk) }
                    }
                }
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
        return merged
    }

    public func stop() async {
        for source in sources { await source.stop() }
    }
}
