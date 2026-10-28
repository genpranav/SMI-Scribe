import HuggingFace
import Intelligence
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Local LLM on the GPU via MLX. Weights download from Hugging Face on first use.
actor MLXProvider: LLMProvider {
    nonisolated let displayName = "Qwen3 4B (MLX)"
    private var container: ModelContainer?

    func prepare() async throws {
        guard container == nil else { return }
        container = try await #huggingFaceLoadModelContainer(configuration: LLMRegistry.qwen3_4b_4bit)
    }

    func complete(system: String, prompt: String) async throws -> String {
        try await prepare()
        guard let container else { throw LLMError.unavailable(displayName) }
        return try await ChatSession(container, instructions: system).respond(to: prompt)
    }
}
