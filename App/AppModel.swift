import AudioCapture
import Diarization
import Foundation
import Intelligence
import Observation
import ScribeCore
import ScribeModels
import Storage
import Transcription

/// App-wide state and the wiring of concrete engines into the pipeline.
@MainActor
@Observable
final class AppModel {
    private(set) var meetings: [Meeting] = []
    private(set) var liveSegments: [Segment] = []
    private(set) var liveHighlights: [Highlight] = []
    private(set) var status = "Idle"
    private(set) var isRecording = false
    var selectedMeetingID: Meeting.ID?

    let database: AppDatabase?
    private var session: MeetingSession?

    init() {
        do {
            database = try AppDatabase.live()
        } catch {
            database = nil
            status = "Database unavailable: \(error.localizedDescription)"
        }
        reloadMeetings()
    }

    /// Prefers Apple's on-device model when present (no download), else MLX.
    static func makeLLMProvider() -> any LLMProvider {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) { return FoundationModelsProvider() }
        #endif
        return MLXProvider()
    }

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func startRecording() {
        guard let database, !isRecording else { return }
        let session = MeetingSession(
            database: database,
            source: AudioMixer(sources: [MicrophoneSource(), SystemAudioTapSource()]),
            transcriber: WhisperKitEngine(),
            diarizer: FluidAudioDiarizer(),
            analyzer: MeetingAnalyzer(provider: Self.makeLLMProvider()))
        self.session = session
        liveSegments = []
        liveHighlights = []
        isRecording = true
        status = "Loading models…"

        let title = "Meeting \(Date.now.formatted(date: .abbreviated, time: .shortened))"
        Task {
            do {
                let events = try await session.start(title: title)
                reloadMeetings()
                for await event in events { handle(event) }
            } catch {
                status = "Could not start: \(error.localizedDescription)"
                isRecording = false
            }
        }
    }

    func stopRecording() {
        guard let session, isRecording else { return }
        isRecording = false
        status = "Processing…"
        Task { await session.stop() }
    }

    func markHighlight() {
        guard let session, isRecording else { return }
        Task { try? await session.markHighlight() }
    }

    func reloadMeetings() {
        meetings = (try? database?.meetings()) ?? []
    }

    private func handle(_ event: MeetingSession.Event) {
        switch event {
        case .segments(let segments):
            liveSegments.append(contentsOf: segments)
        case .highlight(let highlight):
            liveHighlights.append(highlight)
        case .status(let message):
            status = message
        case .finished(let meeting):
            status = "Idle"
            session = nil
            reloadMeetings()
            selectedMeetingID = meeting.id
        }
    }
}
