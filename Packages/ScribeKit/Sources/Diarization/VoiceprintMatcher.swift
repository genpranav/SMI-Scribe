import ScribeModels

/// Resolves anonymous diarization clusters to known speakers by cosine similarity.
public struct VoiceprintMatcher: Sendable {
    /// Minimum similarity to accept a match. Tune against real recordings.
    public var threshold: Float

    public init(threshold: Float = 0.7) {
        self.threshold = threshold
    }

    public func bestMatch(for embedding: [Float], among speakers: [Speaker]) -> Speaker? {
        var best: (speaker: Speaker, score: Float)?
        for speaker in speakers {
            guard let voiceprint = speaker.voiceprint else { continue }
            let score = Self.cosineSimilarity(embedding, voiceprint)
            if score >= threshold, score > (best?.score ?? -1) {
                best = (speaker, score)
            }
        }
        return best?.speaker
    }

    public static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        for i in a.indices {
            dot += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        let denominator = normA.squareRoot() * normB.squareRoot()
        return denominator > 0 ? dot / denominator : 0
    }
}
