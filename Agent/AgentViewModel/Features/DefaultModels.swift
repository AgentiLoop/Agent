@preconcurrency import Foundation

// Hardcoded model lists go stale the moment a provider ships a new model
// (Opus 4.7 on 2026-04-17 was the trigger). The source of truth is each
// provider's live /models endpoint. These arrays stay empty so the picker
// shows nothing until a real fetch succeeds.
extension AgentViewModel {
    nonisolated static let defaultOpenAIModels: [OpenAIModelInfo] = []
    nonisolated static let defaultDeepSeekModels: [OpenAIModelInfo] = []
    nonisolated static let defaultZAIModels: [OpenAIModelInfo] = []
    nonisolated static let defaultQwenModels: [OpenAIModelInfo] = []
    nonisolated static let defaultGeminiModels: [OpenAIModelInfo] = []
    nonisolated static let defaultGrokModels: [OpenAIModelInfo] = []
    nonisolated static let defaultMistralModels: [OpenAIModelInfo] = []
    nonisolated static let defaultCodestralModels: [OpenAIModelInfo] = []
    nonisolated static let defaultVibeModels: [OpenAIModelInfo] = []
    nonisolated static let defaultHuggingFaceModels: [OpenAIModelInfo] = []
    nonisolated static let defaultMiniMaxModels: [OpenAIModelInfo] = []
    nonisolated static let defaultOllamaModels: [OllamaModelInfo] = []
    nonisolated static let defaultClaudeModels: [ClaudeModelInfo] = []
}
