import Foundation
import AgentLLM

/// All Agent! LLM provider configurations — defined in the app, not the package.
/// `APIProvider` is the single list of providers; `config(for:)` is exhaustive, so
/// adding a case there forces its endpoint/protocol/capabilities/defaults to be described here.
@MainActor
enum LLMProviderSetup {

    static func registerAllProviders() {
        LLMRegistry.shared.registerAll(APIProvider.allCases.map(config(for:)))
    }

    /// Endpoint, protocol, capabilities and defaults (model, temperature, context window) per provider.
    static func config(for provider: APIProvider) -> LLMProviderConfig {
        switch provider {

        // MARK: - Cloud API Providers

        case .claude:
            return make(provider, kind: .cloudAPI, apiProtocol: .anthropic,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.anthropic.com/v1/messages",
                    modelsURL: "https://api.anthropic.com/v1/models",
                    authHeader: "x-api-key",
                    authPrefix: "",
                    extraHeaders: ["anthropic-version": "2023-06-01"]
                ),
                model: "claude-sonnet-4-20250514",
                capabilities: [.streaming, .tools, .vision, .systemPrompt, .caching, .thinking, .webSearch],
                contextSize: 1_000_000)

        case .openAI:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.openai.com/v1/chat/completions",
                    modelsURL: "https://api.openai.com/v1/models"
                ),
                model: "gpt-4.1-nano",
                capabilities: [.streaming, .tools, .vision, .systemPrompt],
                contextSize: 272_000)

        /// Codex — ChatGPT-authenticated Responses API used by the Codex CLI.
        /// Requires OAuth (JWT bearer token) to chatgpt.com/backend-api/codex.
        /// API protocol is `.custom` because the /v1/responses shape differs from
        /// the standard /v1/chat/completions OpenAI shape — CodexService handles it.
        case .codex:
            return make(provider, kind: .cloudAPI, apiProtocol: .custom,
                endpoint: LLMEndpoint(
                    chatURL: "https://chatgpt.com/backend-api/codex/responses",
                    modelsURL: "https://chatgpt.com/backend-api/codex/models"
                ),
                model: "gpt-5",
                capabilities: [.streaming, .tools, .vision, .systemPrompt, .thinking],
                contextSize: 272_000)

        case .deepSeek:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.deepseek.com/chat/completions",
                    modelsURL: "https://api.deepseek.com/v1/models"
                ),
                model: "deepseek-chat",
                capabilities: [.streaming, .tools, .systemPrompt],
                contextSize: 128_000)

        case .huggingFace:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://router.huggingface.co/v1/chat/completions",
                    modelsURL: "https://router.huggingface.co/v1/models"
                ),
                model: "deepseek-ai/DeepSeek-V3-0324",
                capabilities: [.streaming, .tools, .systemPrompt],
                contextSize: 32_000)

        case .openRouter:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://openrouter.ai/api/v1/chat/completions",
                    modelsURL: "https://openrouter.ai/api/v1/models"
                ),
                capabilities: [.streaming, .tools, .vision, .systemPrompt],
                contextSize: 200_000,
                supportedProtocols: [.openAI, .anthropic])

        case .requesty:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://router.requesty.ai/v1/chat/completions",
                    modelsURL: "https://router.requesty.ai/v1/models"
                ),
                capabilities: [.streaming, .tools, .vision, .systemPrompt],
                contextSize: 200_000)

        // A2Agent — OpenAI-compatible gateway for DeepSeek, GLM, Kimi, MiniMax and Qwen.
        case .a2Agent:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.a2agent.me/v1/chat/completions",
                    modelsURL: "https://api.a2agent.me/v1/models"
                ),
                model: "deepseek-v4-flash",
                capabilities: [.streaming, .tools, .vision, .systemPrompt],
                contextSize: 128_000)

        // OrcaRouter — OpenAI-compatible gateway routing to OpenAI, Anthropic,
        // Gemini, DeepSeek, Qwen, MiniMax, Z.ai and more behind one key.
        case .orcaRouter:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.orcarouter.ai/v1/chat/completions",
                    modelsURL: "https://api.orcarouter.ai/v1/models"
                ),
                model: "orcarouter/fusion",
                capabilities: [.streaming, .tools, .vision, .systemPrompt],
                contextSize: 200_000)

        case .miniMax:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.minimax.io/v1/chat/completions",
                    modelsURL: "https://api.minimax.io/v1/models"
                ),
                model: "MiniMax-M3",
                capabilities: [.streaming, .tools, .systemPrompt],
                temperature: 1.0,
                contextSize: 1_000_000)

        case .zAI:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.z.ai/api/coding/paas/v4/chat/completions",
                    modelsURL: "https://api.z.ai/api/coding/paas/v4/models",
                    visionChatURL: "https://api.z.ai/api/paas/v4/chat/completions",
                    visionModelsURL: "https://api.z.ai/api/paas/v4/models"
                ),
                model: "glm-4.7",
                capabilities: [.streaming, .tools, .systemPrompt, .vision],
                contextSize: 128_000)

        // BigModel.cn — China mainland mirror of Z.ai, same dual-API structure
        case .bigModel:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://open.bigmodel.cn/api/coding/paas/v4/chat/completions",
                    modelsURL: "https://open.bigmodel.cn/api/coding/paas/v4/models",
                    visionChatURL: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
                    visionModelsURL: "https://open.bigmodel.cn/api/paas/v4/models"
                ),
                model: "glm-4.7",
                capabilities: [.streaming, .tools, .systemPrompt, .vision],
                contextSize: 128_000)

        // Qwen (Alibaba DashScope) — URL based on user locale
        case .qwen:
            let region = Locale.current.region?.identifier ?? ""
            let baseURL: String
            switch region {
            case "CN": baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1"
            case "HK": baseURL = "https://cn-hongkong.aliyuncs.com/compatible-mode/v1"
            default: baseURL = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1"
            }
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "\(baseURL)/chat/completions",
                    modelsURL: "\(baseURL)/models"
                ),
                model: "qwen-plus",
                capabilities: [.streaming, .tools, .systemPrompt, .vision],
                contextSize: 131_072)

        case .gemini:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
                    modelsURL: "https://generativelanguage.googleapis.com/v1beta/openai/models"
                ),
                model: "gemini-2.5-flash",
                capabilities: [.streaming, .tools, .vision, .systemPrompt],
                contextSize: 2_000_000)

        case .grok:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.x.ai/v1/chat/completions",
                    modelsURL: "https://api.x.ai/v1/models"
                ),
                model: "grok-3-mini-fast",
                capabilities: [.streaming, .tools, .vision, .systemPrompt],
                contextSize: 2_000_000)

        case .mistral:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.mistral.ai/v1/chat/completions",
                    modelsURL: "https://api.mistral.ai/v1/models"
                ),
                model: "mistral-large-latest",
                capabilities: [.streaming, .tools, .vision, .systemPrompt],
                contextSize: 256_000)

        case .vibe:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://api.mistral.ai/v1/chat/completions",
                    modelsURL: "https://api.mistral.ai/v1/models"
                ),
                model: "devstral-latest",
                capabilities: [.streaming, .tools, .systemPrompt],
                contextSize: 128_000)

        // MARK: - Ollama

        case .ollama:
            return make(provider, kind: .remoteServer, apiProtocol: .ollama,
                endpoint: LLMEndpoint(
                    chatURL: "https://ollama.com/api/chat",
                    modelsURL: "https://ollama.com/api/tags",
                    defaultPort: LLMEndpoint.ollamaPort
                ),
                capabilities: [.streaming, .tools, .systemPrompt, .vision],
                contextSize: 32_000)

        case .localOllama:
            return make(provider, kind: .localServer, apiProtocol: .ollama,
                endpoint: LLMEndpoint(
                    chatURL: "http://localhost:\(LLMEndpoint.ollamaPort)/api/chat",
                    modelsURL: "http://localhost:\(LLMEndpoint.ollamaPort)/api/tags",
                    authHeader: "", authPrefix: "",
                    defaultPort: LLMEndpoint.ollamaPort
                ),
                capabilities: [.streaming, .tools, .systemPrompt, .vision],
                contextSize: 32_000,
                apiKeyOptional: true)

        // MARK: - Self-Hosted

        case .vLLM:
            return make(provider, kind: .remoteServer, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "http://localhost:\(LLMEndpoint.vLLMPort)/v1/chat/completions",
                    modelsURL: "http://localhost:\(LLMEndpoint.vLLMPort)/v1/models",
                    authHeader: "", authPrefix: "",
                    defaultPort: LLMEndpoint.vLLMPort
                ),
                capabilities: [.streaming, .tools, .systemPrompt],
                contextSize: 32_000,
                apiKeyOptional: true)

        // MARK: - LM Studio (3 protocol variants)

        case .lmStudio:
            return make(provider, kind: .localServer, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "http://localhost:\(LLMEndpoint.lmStudioPort)/v1/chat/completions",
                    modelsURL: "http://localhost:\(LLMEndpoint.lmStudioPort)/v1/models",
                    authHeader: "", authPrefix: "",
                    defaultPort: LLMEndpoint.lmStudioPort
                ),
                capabilities: [.streaming, .tools, .systemPrompt],
                contextSize: 32_000,
                apiKeyOptional: true,
                supportedProtocols: [.openAI, .anthropic, .custom])

        // MARK: - On-Device

        case .foundationModel:
            return make(provider, kind: .embedded, apiProtocol: .foundationModel,
                endpoint: LLMEndpoint(chatURL: ""),
                model: "Apple Intelligence",
                capabilities: [.streaming, .tools, .systemPrompt],
                contextSize: 4_096,
                apiKeyOptional: true)
        }
    }

    private static func make(
        _ provider: APIProvider,
        kind: LLMProviderKind,
        apiProtocol: LLMAPIProtocol,
        endpoint: LLMEndpoint,
        model: String = "",
        capabilities: LLMCapability,
        temperature: Double = 0.2,
        contextSize: Int,
        apiKeyOptional: Bool = false,
        supportedProtocols: [LLMAPIProtocol] = []
    ) -> LLMProviderConfig {
        LLMProviderConfig(
            id: provider.rawValue, displayName: provider.displayName,
            kind: kind, apiProtocol: apiProtocol,
            endpoint: endpoint, model: model,
            capabilities: capabilities, temperature: temperature,
            contextSize: contextSize, apiKeyOptional: apiKeyOptional,
            supportedProtocols: supportedProtocols
        )
    }

    /// LM Studio endpoint for Anthropic Compatible mode
    static let lmStudioAnthropicEndpoint = LLMEndpoint(
        chatURL: "http://localhost:\(LLMEndpoint.lmStudioPort)/v1/messages",
        modelsURL: "http://localhost:\(LLMEndpoint.lmStudioPort)/v1/models",
        authHeader: "", authPrefix: "",
        defaultPort: LLMEndpoint.lmStudioPort
    )

    /// LM Studio endpoint for Native mode
    static let lmStudioNativeEndpoint = LLMEndpoint(
        chatURL: "http://localhost:\(LLMEndpoint.lmStudioPort)/api/v1/chat",
        modelsURL: "http://localhost:\(LLMEndpoint.lmStudioPort)/api/v1/models",
        authHeader: "", authPrefix: "",
        defaultPort: LLMEndpoint.lmStudioPort
    )

    /// OpenRouter's Anthropic-Messages-compatible chat URL (used when the user picks the Anthropic protocol).
    static let openRouterAnthropicChatURL = "https://openrouter.ai/api/v1/messages"
}
