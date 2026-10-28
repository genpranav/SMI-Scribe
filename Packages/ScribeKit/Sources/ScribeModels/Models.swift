import Foundation

public struct Meeting: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var title: String
    public var startedAt: Date
    public var endedAt: Date?
    /// Path to the recorded audio, relative to the app's recordings directory.
    public var audioFile: String?
    public var summary: String?

    public init(
        id: UUID = UUID(), title: String, startedAt: Date = .now, endedAt: Date? = nil,
        audioFile: String? = nil, summary: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.audioFile = audioFile
        self.summary = summary
    }
}

/// A known person, identified across meetings by their voiceprint.
public struct Speaker: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var name: String
    /// Speaker embedding (e.g. WeSpeaker, 256-d). Nil until enrolled.
    public var voiceprint: [Float]?

    public init(id: UUID = UUID(), name: String, voiceprint: [Float]? = nil) {
        self.id = id
        self.name = name
        self.voiceprint = voiceprint
    }
}

/// One contiguous utterance in a meeting transcript.
public struct Segment: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var meetingID: UUID
    public var start: TimeInterval
    public var end: TimeInterval
    public var text: String
    /// Diarization cluster label within this meeting ("S1", "S2", ...).
    public var speakerLabel: String?
    /// Resolved known speaker, if the voiceprint matched.
    public var speakerID: UUID?

    public init(
        id: UUID = UUID(), meetingID: UUID, start: TimeInterval, end: TimeInterval, text: String,
        speakerLabel: String? = nil, speakerID: UUID? = nil
    ) {
        self.id = id
        self.meetingID = meetingID
        self.start = start
        self.end = end
        self.text = text
        self.speakerLabel = speakerLabel
        self.speakerID = speakerID
    }
}

public struct Highlight: Identifiable, Hashable, Codable, Sendable {
    public enum Source: String, Codable, Sendable {
        /// User pressed the highlight hotkey during recording.
        case manual
        /// Extracted by the LLM after the meeting.
        case generated
    }

    public var id: UUID
    public var meetingID: UUID
    public var at: TimeInterval
    public var text: String
    public var source: Source

    public init(id: UUID = UUID(), meetingID: UUID, at: TimeInterval, text: String, source: Source) {
        self.id = id
        self.meetingID = meetingID
        self.at = at
        self.text = text
        self.source = source
    }
}

public struct ActionItem: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var meetingID: UUID
    public var text: String
    public var owner: String?
    public var done: Bool

    public init(id: UUID = UUID(), meetingID: UUID, text: String, owner: String? = nil, done: Bool = false) {
        self.id = id
        self.meetingID = meetingID
        self.text = text
        self.owner = owner
        self.done = done
    }
}
