
@preconcurrency import Foundation
import AgentTools
import AgentMCP
import AgentD1F
import AgentSwift
import Cocoa

// MARK: - Task Execution — Provider / Model / Service Setup

extension AgentViewModel {

    /// / Bundled LLM services built for a single task iteration. Exactly one / of these four services is non-nil after
    /// `buildLLMServices` returns / (matching the original inline closure's invariant).
    struct LLMServiceBundle {
        var claude: ClaudeService?
        var codex: CodexService?
        var openAICompatible: OpenAICompatibleService?
        var ollama: OllamaService?
        var foundationModel: FoundationModelService?
    }

    /// Compaction summarizer bound to the task's own service instance — same
    /// system prompt, tools and model, so the request prefix is a prompt-cache
    /// hit and only the summary output is billed. Nil for the on-device
    /// provider (4K window — it can't see a transcript worth summarizing).
    func makeCompactSummarizer(services: LLMServiceBundle, log: ((String) -> Void)? = nil) -> CompactSummarizer? {
        guard services.claude != nil || services.codex != nil
            || services.openAICompatible != nil || services.ollama != nil
        else { return nil }
        return { request in
            do {
                let r: (content: [[String: Any]], stopReason: String, inputTokens: Int, outputTokens: Int)
                if let s = services.claude { r = try await s.send(messages: request) }
                else if let s = services.codex { r = try await s.send(messages: request) }
                else if let s = services.openAICompatible { r = try await s.send(messages: request) }
                else if let s = services.ollama { r = try await s.send(messages: request) }
                else { return nil }
                TokenUsageStore.shared.record(inputTokens: r.inputTokens, outputTokens: r.outputTokens)
                log?("🗜️ Summary call: \(r.inputTokens) in / \(r.outputTokens) out")
                let text = r.content.compactMap { $0["text"] as? String }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            } catch {
                log?("⚠️ Summary call failed: \(error.localizedDescription.prefix(200))")
                return nil
            }
        }
    }

    /// / Resolves the initial `(provider, modelName, isVision)` triple for a new task / from the currently-selected
    /// provider and per-provider model/vision settings.
    func resolveInitialProviderConfig() -> (provider: APIProvider, modelName: String, isVision: Bool) {
        let provider = selectedProvider
        let modelName = globalModelForProvider(provider)
        return (provider, modelName, resolveVision(provider: provider, modelName: modelName))
    }

    /// Whether the given provider/model pair accepts images (honours `forceVision`).
    /// Order: Force Vision → provider-wide rules → catalog metadata recorded at
    /// fetch time (`modelVisionSupport`) → model-name keyword heuristic.
    func resolveVision(provider: APIProvider, modelName: String) -> Bool {
        if forceVision { return true }
        switch provider {
        case .claude, .codex, .openAI, .gemini, .mistral:
            return true // every current model on these providers accepts images
        case .miniMax, .vibe, .foundationModel:
            return false
        case .zAI, .bigModel:
            return models[provider].hasSuffix(":v")
        case .ollama:
            return selectedOllamaSupportsVision || Self.isVisionModel(modelName)
        case .localOllama:
            return selectedLocalOllamaSupportsVision || Self.isVisionModel(modelName)
        default:
            if let known = modelVisionSupport[provider][modelName] { return known }
            return Self.isVisionModel(modelName)
        }
    }


    /// / Builds the LLM service bundle for a given provider/model/vision combo. / Called at task start and again
    /// whenever the fallback chain swaps providers / mid-task. Also used by tab tasks, the critic gate and sub-agents.
    /// `isVision` defaults to `resolveVision`; `projectFolder` defaults to the app's current project folder.
    func buildLLMServiceBundle(
        provider: APIProvider,
        modelName: String,
        isVision: Bool? = nil,
        historyContext: String,
        projectFolder folderOverride: String? = nil,
        maxTokens mt: Int
    ) -> LLMServiceBundle {
        let projectFolder = folderOverride ?? self.projectFolder
        let isVision = isVision ?? resolveVision(provider: provider, modelName: modelName)
        var claude: ClaudeService?
        var codex: CodexService?
        var openAICompatible: OpenAICompatibleService?
        var ollama: OllamaService?
        var foundationModelService: FoundationModelService?

        if provider == .codex {
            codex = CodexService(
                model: modelName,
                historyContext: historyContext,
                projectFolder: projectFolder,
                maxTokens: mt
            )
        }

        if provider == .claude {
            claude = ClaudeService(
                apiKey: apiKey, model: modelName,
                historyContext: historyContext,
                projectFolder: projectFolder, maxTokens: mt
            )
        } else if provider == .lmStudio && lmStudioProtocol == .anthropic {
            claude = ClaudeService(
                apiKey: apiKeys[.lmStudio], model: modelName,
                historyContext: historyContext,
                projectFolder: projectFolder,
                baseURL: lmStudioEndpoint, maxTokens: mt
            )
        } else if provider == .openRouter && openRouterProtocol == .anthropic {
            claude = ClaudeService(
                apiKey: apiKeys[.openRouter], model: modelName,
                historyContext: historyContext,
                projectFolder: projectFolder,
                baseURL: LLMProviderSetup.openRouterAnthropicChatURL, maxTokens: mt
            )
        } else {
            claude = nil
        }
        // OpenAI-compatible service — URLs from LLMRegistry (single source of truth)
        switch provider {
        case .claude, .codex, .ollama, .localOllama, .foundationModel:
            openAICompatible = nil
        case .lmStudio where lmStudioProtocol == .anthropic:
            openAICompatible = nil
        case .openRouter where openRouterProtocol == .anthropic:
            openAICompatible = nil
        case .lmStudio:
            let key = lmStudioProtocol == .lmStudio ? "input" : "messages"
            openAICompatible = OpenAICompatibleService(
                apiKey: apiKeyForProvider(provider), model: modelName,
                baseURL: lmStudioEndpoint, historyContext: historyContext,
                projectFolder: projectFolder, provider: provider,
                messagesKey: key, maxTokens: mt
            )
        case .vLLM:
            openAICompatible = OpenAICompatibleService(
                apiKey: apiKeyForProvider(provider), model: modelName,
                baseURL: vLLMEndpoint, historyContext: historyContext,
                projectFolder: projectFolder, provider: provider,
                maxTokens: mt
            )
        default:
            let url = chatURLForProvider(provider)
            openAICompatible = url.isEmpty ? nil : OpenAICompatibleService(
                apiKey: apiKeyForProvider(provider), model: modelName,
                baseURL: url, supportsVision: isVision,
                historyContext: historyContext, projectFolder: projectFolder,
                provider: provider, maxTokens: mt
            )
        }
        switch provider {
        case .ollama:
            ollama = OllamaService(
                apiKey: apiKeys[.ollama], model: modelName,
                endpoint: ollamaEndpoint, supportsVision: isVision,
                historyContext: historyContext, projectFolder: projectFolder,
                provider: .ollama
            )
        case .localOllama:
            ollama = OllamaService(
                apiKey: "", model: modelName, endpoint: localOllamaEndpoint,
                supportsVision: isVision, historyContext: historyContext,
                projectFolder: projectFolder, provider: .localOllama,
                contextSize: localOllamaContextSize
            )
        default:
            ollama = nil
        }
        foundationModelService = provider == .foundationModel
            ? FoundationModelService(historyContext: historyContext, projectFolder: projectFolder) : nil

        // Set temperature per provider
        claude?.temperature = temperatureForProvider(provider == .claude ? .claude : provider)
        codex?.temperature = temperatureForProvider(provider)
        ollama?.temperature = temperatureForProvider(provider)
        openAICompatible?.temperature = temperatureForProvider(provider)

        // Reasoning effort — thinking budget for Claude, reasoning_effort pass-through
        // for OpenAI-compatible. "off" leaves each service's default untouched.
        claude?.thinkingBudget = ClaudeService.thinkingBudget(forEffort: reasoningEffort)
        if reasoningEffort != "off" && !reasoningEffort.isEmpty {
            codex?.reasoningEffort = reasoningEffort
            openAICompatible?.reasoningEffort = reasoningEffort
        }

        return LLMServiceBundle(
            claude: claude,
            codex: codex,
            openAICompatible: openAICompatible,
            ollama: ollama,
            foundationModel: foundationModelService
        )
    }
}
