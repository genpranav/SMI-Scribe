import Diarization
import Foundation
import ScribeModels

/// Assigns each transcript segment the speaker turn it overlaps most,
/// then resolves turn clusters to known speakers by voiceprint.
public enum SpeakerAligner {
    public static func assign(
        turns: [SpeakerTurn],
        to segments: [Segment],
        knownSpeakers: [Speaker],
        matcher: VoiceprintMatcher = .init()
    ) -> [Segment] {
        var resolved: [String: UUID] = [:]
        for turn in turns where resolved[turn.label] == nil {
            if let speaker = matcher.bestMatch(for: turn.embedding, among: knownSpeakers) {
                resolved[turn.label] = speaker.id
            }
        }

        return segments.map { segment in
            var segment = segment
            let best = turns.max { overlap($0, segment) < overlap($1, segment) }
            if let best, overlap(best, segment) > 0 {
                segment.speakerLabel = best.label
                segment.speakerID = resolved[best.label]
            }
            return segment
        }
    }

    private static func overlap(_ turn: SpeakerTurn, _ segment: Segment) -> TimeInterval {
        max(0, min(turn.end, segment.end) - max(turn.start, segment.start))
    }
}
