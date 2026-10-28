/// A local text-generation backend (MLX, Apple Foundation Models, ...).
public protocol LLMProvider: Sendable {
    var displayName: String { get }
    func prepare() async throws
    func complete(system: String, prompt: String) async throws -> String
}

public enum LLMError: Error, Sendable {
    case unavailable(String)
    case malformedResponse(String)
}
