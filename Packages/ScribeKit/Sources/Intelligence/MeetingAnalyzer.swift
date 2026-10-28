import Foundation
import ScribeModels

public struct MeetingInsights: Codable, Sendable, Equatable {
    public struct Item: Codable, Sendable, Equatable {
        public var text: String
        /// Highlights: seconds into the meeting. Action items: unused.
        public var at: TimeInterval?
        /// Action items: who owns it, if stated.
        public var owner: String?
    }

    public var summary: String
    public var highlights: [Item]
    public var actionItems: [Item]
}

/// Turns a diarized transcript into a summary, highlights and action items.
public struct MeetingAnalyzer: Sendable {
    private let provider: any LLMProvider

    public init(provider: any LLMProvider) {
        self.provider = provider
    }

    public func analyze(segments: [Segment], speakerNames: [String: String] = [:]) async throws -> MeetingInsights {
        let response = try await provider.complete(
            system: Prompts.system, prompt: Prompts.transcript(segments, speakerNames: speakerNames))
        return try Self.parse(response)
    }

    static func parse(_ response: String) throws -> MeetingInsights {
        // Models often wrap JSON in prose or code fences; take the outermost object.
        guard let open = response.firstIndex(of: "{"), let close = response.lastIndex(of: "}") else {
            throw LLMError.malformedResponse(response)
        }
        do {
            return try JSONDecoder().decode(MeetingInsights.self, from: Data(response[open...close].utf8))
        } catch {
            throw LLMError.malformedResponse(response)
        }
    }
}

enum Prompts {
    static let system = """
        You analyse meeting transcripts. Reply with only a JSON object of the form
        {"summary": string, "highlights": [{"text": string, "at": number}],
         "actionItems": [{"text": string, "owner": string|null}]}.
        "at" is the start time in seconds of the line the highlight comes from.
        Keep the summary under 150 words. Do not invent facts.
        """

    static func transcript(_ segments: [Segment], speakerNames: [String: String]) -> String {
        segments.map { segment in
            let speaker = segment.speakerLabel.map { speakerNames[$0] ?? $0 } ?? "Unknown"
            return "[\(Int(segment.start))s] \(speaker): \(segment.text)"
        }.joined(separator: "\n")
    }
}
