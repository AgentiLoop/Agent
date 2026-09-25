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

        // Fluxion AI — OpenAI-compatible gateway (GPT, Claude, Grok, DeepSeek, Gemini,
        // GLM, Kimi) behind one sk-fx-… key. Model list comes from /v1/models.
        case .fluxion:
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "https://fluxionai.world/v1/chat/completions",
                    modelsURL: "https://fluxionai.world/v1/models"
                ),
                capabilities: [.streaming, .tools, .vision, .systemPrompt],
                contextSize: 200_000,
                supportedProtocols: [.openAI, .anthropic])

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

        // Alibaba DashScope — Model Studio / QwenCloud pay-as-you-go, OpenAI-compatible mode.
        // Regular keys (sk-… Model Studio, sk-ws-… QwenCloud); region picked from user locale.
        case .dashscope:
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

        // Qwen — QwenCloud Token Plan (qwen.ai subscription, dedicated sk-sp-… key).
        // Region-specific *.maas.aliyuncs.com endpoint; keys and base URLs are not
        // interchangeable with DashScope pay-as-you-go or the Coding Plan.
        case .qwen:
            let region = Locale.current.region?.identifier ?? ""
            let baseURL = region == "CN"
                ? "https://token-plan.cn-beijing.maas.aliyuncs.com/compatible-mode/v1"
                : "https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1"
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "\(baseURL)/chat/completions",
                    modelsURL: "\(baseURL)/models"
                ),
                model: "qwen3.7-plus",
                capabilities: [.streaming, .tools, .systemPrompt, .vision],
                contextSize: 131_072)

        // Qwen Code — Alibaba Model Studio Coding Plan (dedicated sk-sp-… key).
        // Fixed monthly quota endpoint used by Qwen Code / Claude Code / Cline;
        // not interchangeable with the pay-as-you-go or Token Plan keys above.
        case .qwenCoder:
            let region = Locale.current.region?.identifier ?? ""
            let baseURL = region == "CN"
                ? "https://coding.dashscope.aliyuncs.com/v1"
                : "https://coding-intl.dashscope.aliyuncs.com/v1"
            return make(provider, kind: .cloudAPI, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "\(baseURL)/chat/completions",
                    modelsURL: "\(baseURL)/models"
                ),
                model: "qwen3-coder-plus",
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

        // oMLX (https://omlx.ai) — macOS-native MLX inference server with paged SSD KV
        // caching and continuous batching. OpenAI-compatible Chat Completions on
        // http://localhost:<port>/v1; port + key come from ~/.omlx/settings.json.
        // No default model: it serves whatever is in its model directory.
        case .oMLX:
            let base = OMLXSettings.load().baseURL
            return make(provider, kind: .localServer, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "\(base)/chat/completions",
                    modelsURL: "\(base)/models",
                    authHeader: "", authPrefix: "",
                    defaultPort: OMLXSettings.defaultPort
                ),
                capabilities: [.streaming, .tools, .systemPrompt],
                contextSize: 32_000,
                apiKeyOptional: true)

        // MARK: - On-Device

        // Apple Foundation Models CLI (macOS 27 `/usr/bin/fm`). `fm serve` exposes a
        // loopback-only Chat Completions API on 127.0.0.1:1976 with a single model
        // ("system"). No API key; the fm license must be accepted once (`sudo fm license`).
        case .fmServe:
            return make(provider, kind: .localServer, apiProtocol: .openAI,
                endpoint: LLMEndpoint(
                    chatURL: "http://127.0.0.1:1976/v1/chat/completions",
                    modelsURL: "http://127.0.0.1:1976/v1/models",
                    authHeader: "", authPrefix: "",
                    defaultPort: 1976
                ),
                model: "system",
                capabilities: [.streaming, .tools, .systemPrompt],
                contextSize: 4_096,
                apiKeyOptional: true)

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
    /// Fluxion AI Anthropic-group keys speak the native Messages API here.
    static let fluxionAnthropicChatURL = "https://fluxionai.world/v1/messages"
}

/// `server.port` and `auth.api_key` from oMLX's own `~/.omlx/settings.json`, so a
/// locally installed oMLX server works with no configuration in Agent!.
nonisolated struct OMLXSettings: Sendable {
    static let defaultPort = 8000

    var port: Int?
    var apiKey: String?

    /// `http://localhost:<port>/v1` — settings.json port, else 8000.
    var baseURL: String { "http://localhost:\(port ?? Self.defaultPort)/v1" }

    static func load(from url: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".omlx/settings.json")) -> OMLXSettings {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return OMLXSettings() }
        let auth = json["auth"] as? [String: Any] ?? [:]
        // A key is only required when verification is on.
        let skip = auth["skip_api_key_verification"] as? Bool ?? false
        let key = skip ? nil : (auth["api_key"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let port = (json["server"] as? [String: Any])?["port"] as? Int
        return OMLXSettings(port: port.flatMap { (1...65535).contains($0) ? $0 : nil }, apiKey: key)
    }
}

/// Checks, BEFORE sending, whether the loaded oMLX model can take Agent!'s whole
/// request (system prompt + tool schemas + transcript): context window, KV-cache
/// memory vs oMLX's memory ceiling, and expected prefill time from oMLX's own
/// measured throughput (~/.omlx/stats.json). oMLX gives no feedback during a long
/// prefill, so without this a too-big prompt just looks like a dead model.
nonisolated enum OMLXPreflight {
    struct Report: Sendable {
        /// Idle timeout to use for the request (covers the silent prefill).
        let timeout: TimeInterval
        let summary: String
    }

    /// Longest silent prefill we accept before refusing to send.
    static let maxPrefillSeconds = 60.0

    /// Throws `AgentError.apiError(0, "oMLX preflight: …")` when the model can't handle the request.
    static func check(bodyData: Data, chatURL: URL, apiKey: String, model: String) async throws -> Report {
        // ~4 bytes of JSON per token (tool schemas + prose).
        let tokens = bodyData.count / 4
        var notes: [String] = []
        // No measured prefill rate (new model, or remote oMLX without local stats):
        // don't guess a short cap — a big model's silent prefill can take minutes.
        var timeout: TimeInterval = llmAPITimeout

        // 1. Server-side model status: context window + memory ceiling.
        let statusURL = chatURL.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("models/status")
        var req = URLRequest(url: statusURL)
        req.timeoutInterval = 5
        if !apiKey.isEmpty { req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
        if let (data, _) = try? await URLSession.shared.data(for: req),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let entry = (json["models"] as? [[String: Any]])?.first(where: { ($0["id"] as? String) == model })
        {
            let ctx = (entry["max_context_window"] as? Int) ?? (entry["model_context_length"] as? Int) ?? 0
            if ctx > 0 && tokens > ctx {
                throw fail("prompt is ~\(tokens) tokens but \(model) has a \(ctx)-token context window")
            }
            let ceiling = (json["final_ceiling"] as? NSNumber)?.doubleValue ?? 0
            let weights = ((entry["actual_size"] ?? entry["estimated_size"]) as? NSNumber)?.doubleValue ?? 0
            if ceiling > 0, let path = entry["model_path"] as? String,
               let kvPerToken = kvBytesPerToken(modelPath: path)
            {
                let need = weights + Double(tokens) * kvPerToken
                let gb = { (b: Double) in String(format: "%.1f GB", b / 1_073_741_824) }
                if need > ceiling {
                    throw fail("~\(tokens) prompt tokens need \(gb(need)) (weights + KV cache) but oMLX's memory ceiling is \(gb(ceiling))")
                }
                notes.append("memory \(gb(need)) of \(gb(ceiling))")
            }
        }

        // 2. Prefill time from oMLX's measured throughput for this model.
        let statsURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".omlx/stats.json")
        if let data = try? Data(contentsOf: statsURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let m = (json["per_model"] as? [String: Any])?[model] as? [String: Any],
           let promptTok = (m["prompt_tokens"] as? NSNumber)?.doubleValue,
           let secs = (m["prefill_duration"] as? NSNumber)?.doubleValue,
           promptTok > 1_000, secs > 0
        {
            let rate = promptTok / secs
            let eta = Double(tokens) / rate
            if eta > maxPrefillSeconds {
                throw fail("~\(tokens) prompt tokens at this Mac's measured \(Int(rate)) tok/s prefill = ~\(Int(eta)) s of silence before the first word (limit \(Int(maxPrefillSeconds)) s)")
            }
            timeout = max(120, eta * 2 + 30)
            notes.append("prefill ~\(Int(eta)) s at \(Int(rate)) tok/s")
        }

        let summary = "🔍 oMLX preflight: ~\(tokens) prompt tokens" + (notes.isEmpty ? "" : " — " + notes.joined(separator: ", "))
        return Report(timeout: timeout, summary: summary)
    }

    /// K+V fp16 bytes per token from the model's config.json.
    private static func kvBytesPerToken(modelPath: String) -> Double? {
        let url = URL(fileURLWithPath: modelPath).appendingPathComponent("config.json")
        guard let data = try? Data(contentsOf: url),
              var cfg = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let text = cfg["text_config"] as? [String: Any] { cfg = text }
        guard let layers = cfg["num_hidden_layers"] as? Int,
              let heads = cfg["num_attention_heads"] as? Int else { return nil }
        let kvHeads = cfg["num_key_value_heads"] as? Int ?? heads
        let headDim = cfg["head_dim"] as? Int ?? ((cfg["hidden_size"] as? Int ?? 0) / max(heads, 1))
        guard headDim > 0 else { return nil }
        return Double(2 * layers * kvHeads * headDim * 2)
    }

    private static func fail(_ why: String) -> AgentError {
        .apiError(statusCode: 0, message: "oMLX preflight: \(why). Not sending — Agent!'s prompt is too big for this model on this Mac.")
    }
}
