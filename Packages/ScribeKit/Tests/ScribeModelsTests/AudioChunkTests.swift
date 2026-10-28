import Testing

@testable import ScribeModels

@Test func chunkDurationUsesSampleRate() {
    let chunk = AudioChunk(samples: Array(repeating: 0, count: 8_000), timestamp: 0, origin: .microphone)
    #expect(chunk.duration == 0.5)
}
