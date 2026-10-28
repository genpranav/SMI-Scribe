import AudioCapture
import Diarization
import Foundation
import Intelligence
import ScribeModels
import Storage
import Testing
import Transcription

@testable import ScribeCore

// MARK: - Fakes

private struct FakeSource: AudioSource {
    var seconds: Int
    func start() async throws -> AsyncStream<AudioChunk> {
        AsyncStream { continuation in
            for second in 0..<seconds {
                let samples = [Float](repeating: 0.1, count: Int(AudioChunk.sampleRate))
                continuation.yield(AudioChunk(samples: samples, timestamp: Double(second), origin: .microphone))
            }
            continuation.finish()
        }
    }
    func stop() async {}
}

private struct FakeTranscriber: TranscriptionEngine {
    func prepare() async throws {}
    func transcribe(_ samples: [Float]) async throws -> [TranscribedSpan] {
        [TranscribedSpan(start: 0, end: Double(samples.count) / AudioChunk.sampleRate, text: "We ship on Friday")]
    }
}

private struct FakeDiarizer: DiarizationEngine {
    func prepare() async throws {}
    func diarize(_ samples: [Float]) async throws -> [SpeakerTurn] {
        [SpeakerTurn(label: "S1", start: 0, end: 100, embedding: [1, 0])]
    }
}

private struct FakeLLM: LLMProvider {
    let displayName = "Fake"
    func prepare() async throws {}
    func complete(system: String, prompt: String) async throws -> String {
        """
        Sure! ```json
        {"summary": "Ship Friday.", "highlights": [{"text": "Ship date", "at": 0}],
         "actionItems": [{"text": "Prepare release", "owner": "Alice"}]}
        ```
        """
    }
}

// MARK: - Tests

@Test func endToEndPipelineWithFakes() async throws {
    let db = try AppDatabase.inMemory()
    try db.save(Speaker(name: "Alice", voiceprint: [1, 0]))
    let session = MeetingSession(
        database: db,
        source: FakeSource(seconds: 25),
        transcriber: FakeTranscriber(),
        diarizer: FakeDiarizer(),
        analyzer: MeetingAnalyzer(provider: FakeLLM()))

    _ = try await session.start(title: "Standup")
    try await Task.sleep(for: .milliseconds(200))  // let the fake stream drain
    await session.stop()

    let meeting = try #require(try db.meetings().first)
    let segments = try db.segments(meetingID: meeting.id)
    #expect(meeting.summary == "Ship Friday.")
    #expect(meeting.endedAt != nil)
    #expect(segments.count == 3)  // 10s + 10s + 5s windows
    #expect(segments.allSatisfy { $0.speakerLabel == "S1" && $0.speakerID != nil })
    #expect(try db.actionItems(meetingID: meeting.id).first?.owner == "Alice")
}

@Test func alignerPicksMaxOverlap() {
    let meetingID = UUID()
    let segments = [Segment(meetingID: meetingID, start: 4, end: 10, text: "hi")]
    let turns = [
        SpeakerTurn(label: "S1", start: 0, end: 5, embedding: []),
        SpeakerTurn(label: "S2", start: 5, end: 12, embedding: []),
    ]
    #expect(SpeakerAligner.assign(turns: turns, to: segments, knownSpeakers: []).first?.speakerLabel == "S2")
}
