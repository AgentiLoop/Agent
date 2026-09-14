@preconcurrency import Foundation

// Hardcoded model lists go stale the moment a provider ships a new model
// (Opus 4.7 on 2026-04-17 was the trigger). The source of truth is each
// provider's live /models endpoint. These arrays stay empty so the picker
// shows nothing until a real fetch succeeds.
extension AgentViewModel {
    nonisolated static let defaultZAIModels: [OpenAIModelInfo] = []

    /// Coding Plan has a fixed, documented model list (Alibaba Model Studio "Coding plan overview"),
    /// so it is the one provider whose defaults are hardcoded.
    nonisolated static let defaultQwenCoderModels: [OpenAIModelInfo] = [
        "qwen3-coder-plus", "qwen3-coder-next", "qwen3.7-plus", "qwen3.6-plus", "qwen3.5-plus",
        "qwen3-max-2026-01-23", "kimi-k2.5", "glm-5", "glm-4.7", "MiniMax-M2.5",
    ].map { OpenAIModelInfo(id: $0, name: $0) }
    nonisolated static let defaultQwenModels: [OpenAIModelInfo] = []
    nonisolated static let defaultHuggingFaceModels: [OpenAIModelInfo] = []
    nonisolated static let defaultOllamaModels: [OllamaModelInfo] = []
    nonisolated static let defaultClaudeModels: [ClaudeModelInfo] = []
}
