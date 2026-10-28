import ScribeModels
import Testing

@testable import Diarization

@Test func matchesClosestVoiceprintAboveThreshold() {
    let alice = Speaker(name: "Alice", voiceprint: [1, 0, 0])
    let bob = Speaker(name: "Bob", voiceprint: [0, 1, 0])
    let matcher = VoiceprintMatcher(threshold: 0.7)

    #expect(matcher.bestMatch(for: [0.9, 0.1, 0], among: [alice, bob])?.name == "Alice")
    #expect(matcher.bestMatch(for: [0, 0, 1], among: [alice, bob]) == nil)
}

@Test func cosineSimilarityHandlesMismatchedLengths() {
    #expect(VoiceprintMatcher.cosineSimilarity([1, 2], [1, 2, 3]) == 0)
}
