import AudioCapture
import Diarization
import Foundation
import Intelligence
import ScribeModels
import Storage
import Transcription

/// Runs one meeting end to end:
/// capture → windowed live transcription → (stop) diarize → align speakers → match voiceprints → LLM insights.
public actor MeetingSession {
    public enum Event: Sendable {
        case segments([Segment])
        case highlight(Highlight)
        case status(String)
        case finished(Meeting)
    }

    public struct Configuration: Sendable {
        /// Audio accumulated before each live transcription pass.
        public var liveWindow: TimeInterval = 10

        public init() {}
    }

    private let database: AppDatabase
    private let source: any AudioSource
    private let transcriber: any TranscriptionEngine
    private let diarizer: any DiarizationEngine
    private let analyzer: MeetingAnalyzer?
    private let configuration: Configuration

    private var meeting: Meeting?
    // TODO: Stream audio to an .m4a on disk instead of keeping the whole meeting in memory.
    private var recording: [Float] = []
    private var pending: [Float] = []
    private var pendingStart: TimeInterval = 0
    private var captureTask: Task<Void, Never>?
    private var continuation: AsyncStream<Event>.Continuation?

    public init(
        database: AppDatabase,
        source: any AudioSource,
        transcriber: any TranscriptionEngine,
        diarizer: any DiarizationEngine,
        analyzer: MeetingAnalyzer?,
        configuration: Configuration = .init()
    ) {
        self.database = database
        self.source = source
        self.transcriber = transcriber
        self.diarizer = diarizer
        self.analyzer = analyzer
        self.configuration = configuration
    }

    private var elapsed: TimeInterval { Double(recording.count) / AudioChunk.sampleRate }

    public func start(title: String) async throws -> AsyncStream<Event> {
        let meeting = Meeting(title: title)
        try database.save(meeting)
        self.meeting = meeting

        let (events, continuation) = AsyncStream.makeStream(of: Event.self)
        self.continuation = continuation

        try await transcriber.prepare()
        let audio = try await source.start()
        captureTask = Task { [weak self] in
            for await chunk in audio {
                await self?.ingest(chunk)
            }
        }
        continuation.yield(.status("Recording"))
        return events
    }

    /// Marks "this moment matters" at the current position in the recording.
    public func markHighlight(note: String = "") throws {
        guard let meeting else { return }
        let highlight = Highlight(meetingID: meeting.id, at: elapsed, text: note, source: .manual)
        try database.insert(highlight)
        continuation?.yield(.highlight(highlight))
    }

    public func stop() async {
        await source.stop()
        captureTask?.cancel()
        await captureTask?.value
        await transcribePending()
        await finalize()
        continuation?.finish()
    }

    private func ingest(_ chunk: AudioChunk) async {
        // TODO: Time-align mic and system chunks (by timestamp) before mixing; for now they are appended in arrival order.
        // TODO: Gate on VAD (FluidAudio Silero) so silence is never sent to the ASR model.
        if pending.isEmpty { pendingStart = elapsed }
        recording.append(contentsOf: chunk.samples)
        pending.append(contentsOf: chunk.samples)
        if Double(pending.count) / AudioChunk.sampleRate >= configuration.liveWindow {
            await transcribePending()
        }
    }

    private func transcribePending() async {
        guard let meeting, !pending.isEmpty else { return }
        let window = pending
        let offset = pendingStart
        pending.removeAll(keepingCapacity: true)
        do {
            let spans = try await transcriber.transcribe(window)
            let segments = spans
                .filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { Segment(meetingID: meeting.id, start: offset + $0.start, end: offset + $0.end, text: $0.text) }
            try database.insert(segments)
            continuation?.yield(.segments(segments))
        } catch {
            continuation?.yield(.status("Transcription failed: \(error)"))
        }
    }

    private func finalize() async {
        guard var meeting else { return }
        meeting.endedAt = .now

        var segments = (try? database.segments(meetingID: meeting.id)) ?? []
        do {
            continuation?.yield(.status("Identifying speakers"))
            try await diarizer.prepare()
            let turns = try await diarizer.diarize(recording)
            let speakers = try database.speakers()
            segments = SpeakerAligner.assign(turns: turns, to: segments, knownSpeakers: speakers)
            try database.update(segments)
        } catch {
            continuation?.yield(.status("Speaker identification skipped: \(error)"))
        }

        if let analyzer, !segments.isEmpty {
            do {
                continuation?.yield(.status("Summarising"))
                let insights = try await analyzer.analyze(segments: segments)
                meeting.summary = insights.summary
                try database.replaceInsights(
                    meetingID: meeting.id,
                    highlights: insights.highlights.map {
                        Highlight(meetingID: meeting.id, at: $0.at ?? 0, text: $0.text, source: .generated)
                    },
                    actionItems: insights.actionItems.map {
                        ActionItem(meetingID: meeting.id, text: $0.text, owner: $0.owner)
                    })
            } catch {
                continuation?.yield(.status("Summary skipped: \(error)"))
            }
        }

        try? database.save(meeting)
        self.meeting = meeting
        continuation?.yield(.finished(meeting))
    }
}
