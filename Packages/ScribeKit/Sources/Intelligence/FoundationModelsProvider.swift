#if canImport(FoundationModels)
import FoundationModels

/// Apple's on-device model (macOS 26+). No download; runs on the Neural Engine.
@available(macOS 26, *)
public struct FoundationModelsProvider: LLMProvider {
    public let displayName = "Apple Intelligence (on-device)"

    public init() {}

    public func prepare() async throws {
        guard case .available = SystemLanguageModel.default.availability else {
            throw LLMError.unavailable("Apple Intelligence is not available on this Mac")
        }
    }

    public func complete(system: String, prompt: String) async throws -> String {
        let session = LanguageModelSession(instructions: system)
        return try await session.respond(to: prompt).content
    }
}
#endif
