import AgentLLM
import AgentAudit
@preconcurrency import Foundation
import AgentTools

@MainActor
final class ClaudeService {
    let apiKey: String
    let model: String
    let endpointURL: URL

    private static let defaultBaseURL = URL(string: "https://api.anthropic.com/v1/messages") ?? URL(filePath: "/")
    private static let apiVersion = "2023-06-01"
    private let isLocalEndpoint: Bool
    /// True only when the endpoint host is localhost — gates the compact-prompt fallback.
    /// Why: LM Studio runs on tiny context windows so we shrink the system prompt;
    /// remote Anthropic-compat proxies (OpenRouter) have full Claude context, so they should get the full prompt.
    private let isLocalhostEndpoint: Bool

    // MARK: - Rate Limit Tracking
    // Delegated to LLMRateLimiter actor — see Services/LLMRateLimiter.swift.

    nonisolated private static func enforceRateLimit() async {
        await LLMRateLimiter.shared.enforce(provider: APIProvider.claude.rawValue)
    }

    nonisolated static func recordRetryAfter(_ seconds: Double) async {
        await LLMRateLimiter.shared.recordRetryAfter(seconds, provider: APIProvider.claude.rawValue)
    }

    nonisolated static func parseRetryAfter(_ headerValue: String?) -> Double {
        LLMRateLimiter.parseRetryAfter(headerValue)
    }

    let historyContext: String
    let userHome: String
    let userName: String
    let projectFolder: String
    /// Max output tokens. 0 = use default (16384). Claude API requires this field.
    let maxTokens: Int

    init(
        apiKey: String,
        model: String,
        historyContext: String = "",
        projectFolder: String = "",
        baseURL: String? = nil,
        maxTokens: Int = 0
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpointURL = baseURL.flatMap { URL(string: $0) } ?? Self.defaultBaseURL
        self.isLocalEndpoint = baseURL != nil
        let host = self.endpointURL.host ?? ""
        self.isLocalhostEndpoint = baseURL != nil
            && (host == "localhost" || host == "127.0.0.1" || host == "::1")
        self.maxTokens = maxTokens
        self.historyContext = historyContext
        self.userHome = FileManager.default.homeDirectoryForCurrentUser.path
        self.userName = NSUserName()
        self.projectFolder = projectFolder
    }

    /// When set, overrides the full system prompt (used for coding mode iterations 2+)
    var overrideSystemPrompt: String?

    /// Snapshot of the dynamic state blocks (memory / goal / tool outcomes /
    /// plan), taken on first use and frozen for this service's lifetime —
    /// services are rebuilt at task start and on provider fallback. Reading
    /// the live stores per request changed the system-prompt bytes mid-task
    /// (every goal tick, plan update, or memory append), invalidating the
    /// provider's prompt cache; mid-task changes still reach the model
    /// through those tools' own results.
    private lazy var stateBlocks: String = MemoryStore.shared.contextBlock
        + GoalStateStore.shared.promptBlock
        + ToolOutcomeStore.shared.promptBlock
        + PlanStateStore.promptBlock(projectFolder: projectFolder)

    var systemPrompt: String {
        if let override = overrideSystemPrompt { return override }
        if isLocalhostEndpoint {
            // Local Claude-protocol endpoints (LM Studio) bypass SystemPromptService — wrap with anti-hallucination rules to match other providers.
            return SystemPromptService.wrapWithRules(
                AgentTools.compactSystemPrompt(userName: userName, userHome: userHome, projectFolder: projectFolder)
            )
        }
        var prompt = SystemPromptService.shared.prompt(for: .claude, userName: userName, userHome: userHome, projectFolder: projectFolder)
        if !projectFolder.isEmpty {
            prompt =
                "CURRENT PROJECT FOLDER: \(projectFolder)\n"
                    + "Always cd to this directory before running any "
                    + "shell commands. Use it as the default for all file "
                    + "operations. You may go outside it when needed.\n\n" +
                prompt
        }
        if !historyContext.isEmpty {
            prompt += historyContext
        }
        prompt += stateBlocks
        return prompt
    }

    func tools(activeGroups: Set<String>? = nil, compact: Bool = false) -> [[String: Any]] {
        // No mode-based narrowing — every user-enabled tool flows through.
        // Local endpoints with tight context windows can disable groups via the UI.
        var t = AgentTools.claudeFormat(activeGroups: activeGroups, compact: compact, projectFolder: projectFolder)
        // Keep the spill cache pointed at the current project so restore_tool_result
        // reads back from the same .agent/toolcache the compactor wrote to.
        ToolResultCache.setProjectFolder(projectFolder)
        // Recovery for content compaction truncated. Defined here because AgentTools
        // is a remote package — this is the local seam for app-specific tools.
        t.append([
            "name": "restore_tool_result",
            "description":
                "Recover the FULL text of an earlier tool result that context compaction "
                + "truncated to a 3-line preview or '[cleared]'. Pass the tool_use_id shown "
                + "in the truncated block. Use this INSTEAD of re-reading a file you already "
                + "read earlier in this task.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "tool_use_id": [
                        "type": "string",
                        "description": "The tool_use_id of the truncated tool result to restore."
                    ]
                ],
                "required": ["tool_use_id"]
            ]
        ])
        // Only add native web_search for real Anthropic API — remove Tavily duplicate first
        if !isLocalEndpoint {
            t.removeAll { ($0["name"] as? String) == "web_search" }
            t.append([
                "type": "web_search_20250305",
                "name": "web_search"
            ])
        }
        // Persistent goal state + self-verification (app-local tool).
        t.append(contentsOf: AgentTools.localToolSchemas())
        return t
    }

    /// Strip orphan `tool_result` blocks (no matching `tool_use` in the prior
    /// assistant message). Anthropic returns 400 on these. Also drop user messages
    /// that become empty after stripping. Mirrors the logic in MessageSanitizer
    /// but runs at the request boundary so stale state can't reach the API.
    private func stripOrphanToolResults(_ messages: [[String: Any]]) -> [[String: Any]] {
        var result = messages
        var i = 0
        while i < result.count {
            guard (result[i]["role"] as? String) == "user",
                  var blocks = result[i]["content"] as? [[String: Any]]
            else { i += 1; continue }

            var validIds = Set<String>()
            if i > 0,
               (result[i - 1]["role"] as? String) == "assistant",
               let prev = result[i - 1]["content"] as? [[String: Any]]
            {
                for block in prev where (block["type"] as? String) == "tool_use" {
                    if let id = block["id"] as? String { validIds.insert(id) }
                }
            }

            var changed = false
            blocks.removeAll { block in
                guard (block["type"] as? String) == "tool_result",
                      let id = block["tool_use_id"] as? String
                else { return false }
                if validIds.contains(id) { return false }
                changed = true
                return true
            }
            if changed {
                if blocks.isEmpty {
                    result.remove(at: i)
                    continue
                }
                result[i]["content"] = blocks
            }
            i += 1
        }
        return result
    }

    // The old withFolderPrefix mutated the newest user message per-request, which
    // changed already-sent message bytes on the next turn and defeated incremental
    // prompt caching. The folder is already in the system prompt and in the task's
    // first user message via newTaskPrefix, so no per-request mutation is needed.

    /// Mark the last content block of the newest user message with cache_control
    /// so the conversation body caches turn-over-turn (system prompt and tools
    /// carry their own breakpoints; Anthropic allows 4 total). Standard Anthropic
    /// multi-turn pattern — the marker moves forward each turn without
    /// invalidating prior-prefix cache hits.
    private func withMessageCacheBreakpoint(_ messages: [[String: Any]]) -> [[String: Any]] {
        guard !isLocalhostEndpoint else { return messages }
        var result = messages
        for i in stride(from: result.count - 1, through: 0, by: -1) {
            guard result[i]["role"] as? String == "user" else { continue }
            if let text = result[i]["content"] as? String {
                result[i]["content"] = [
                    ["type": "text", "text": text, "cache_control": ["type": "ephemeral"]]
                ]
            } else if var blocks = result[i]["content"] as? [[String: Any]], !blocks.isEmpty {
                let last = blocks.count - 1
                let type = blocks[last]["type"] as? String ?? ""
                if type == "text" || type == "tool_result" || type == "image" {
                    blocks[last]["cache_control"] = ["type": "ephemeral"]
                    result[i]["content"] = blocks
                }
            }
            break
        }
        return result
    }

    var temperature: Double = 0.2
    var compactTools: Bool = false
    /// Extended-thinking budget in tokens. 0 = disabled. When enabled the API
    /// requires temperature unset and max_tokens greater than the budget.
    var thinkingBudget: Int = 0

    /// Effort → budget mapping shared by every construction site.
    nonisolated static func thinkingBudget(forEffort effort: String) -> Int {
        switch effort {
        case "low": return 2048
        case "medium": return 8192
        case "high": return 16384
        default: return 0
        }
    }

    /// Apply thinking to a request body: budget, temperature removal, and a
    /// max_tokens floor above the budget.
    private func applyThinking(to body: inout [String: Any]) {
        guard thinkingBudget > 0, !isLocalhostEndpoint else { return }
        body["thinking"] = ["type": "enabled", "budget_tokens": thinkingBudget]
        body.removeValue(forKey: "temperature")
        let mt = body["max_tokens"] as? Int ?? 16384
        body["max_tokens"] = max(mt, thinkingBudget + 8192)
    }

    func send(
        messages: [[String: Any]],
        activeGroups: Set<String>? = nil
    ) async throws
        -> (content: [[String: Any]], stopReason: String, inputTokens: Int, outputTokens: Int)
    {
        guard isLocalEndpoint || !apiKey.isEmpty else { throw AgentError.noAPIKey }
        await Self.enforceRateLimit()

        let systemBlock: Any = isLocalEndpoint ? systemPrompt : Self.buildSystemBlock(
            systemPrompt: systemPrompt,
            credential: apiKey
        )

        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens > 0 ? maxTokens : 16384,
            "temperature": temperature,
            "system": systemBlock,
            "messages": withMessageCacheBreakpoint(stripOrphanToolResults(messages))
        ]
        // Skip tools only for actual localhost servers (LM Studio's Claude-compat
        // mode often mis-handles native Anthropic tool format). Remote
        // Anthropic-compat proxies like OpenRouter forward tools correctly.
        if !isLocalhostEndpoint {
            var toolDefs = tools(activeGroups: activeGroups, compact: compactTools)
            // Mark last tool with cache_control for prompt caching
            if !toolDefs.isEmpty {
                toolDefs[toolDefs.count - 1]["cache_control"] = ["type": "ephemeral"]
            }
            body["tools"] = toolDefs
        }
        applyThinking(to: &body)

        // Serialize on main actor, then offload network I/O + parsing. .sortedKeys produces byte-stable JSON regardless of dict iteration order — required for prefix caching to hit.
        let bodyData = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        return try await Self.performRequest(
            bodyData: bodyData,
            apiKey: apiKey,
            apiVersion: Self.apiVersion,
            url: endpointURL,
            thinkingEnabled: thinkingBudget > 0 && !isLocalhostEndpoint
        )
    }

    /// Strip every whitespace / control character from a pasted credential.
    /// Terminals visually wrap long OAuth tokens across multiple lines; depending
    /// on the emulator and copy method, the paste can include `\n`, `\r`, spaces,
    /// or tabs. A bearer credential with any of those embedded breaks the
    /// `Authorization` header (Anthropic rejects with 401, and rapid rejections
    /// can cascade into 429 rate-limit responses per IP / account).
    nonisolated static func sanitizedCredential(_ raw: String) -> String {
        raw.unicodeScalars
            .filter { !CharacterSet.whitespacesAndNewlines.contains($0)
                    && !CharacterSet.controlCharacters.contains($0) }
            .map { String($0) }
            .joined()
    }

    /// True when `credential` is a Claude Code OAuth token (from
    /// `claude setup-token`) rather than a standard API key. OAuth tokens
    /// start with `sk-ant-oat01-`; API keys start with `sk-ant-api…`.
    nonisolated static func isOAuthToken(_ credential: String) -> Bool {
        sanitizedCredential(credential).hasPrefix("sk-ant-oat01-")
    }

    /// Claude Code's identity system prompt. OAuth tokens minted by
    /// `claude setup-token` are gated at the API to requests whose first
    /// system block is this string; anything else 429s immediately with a
    /// bare `"message":"Error"` body (no Retry-After). API-key requests
    /// skip this block — only Agent's own prompt goes through.
    nonisolated static let claudeCodeIdentityPrompt =
        "You are Claude Code, Anthropic's official CLI for Claude."

    /// Build the `system` array. For OAuth credentials, prepend the Claude
    /// Code identity block so the request passes Anthropic's OAuth gate.
    /// Agent's real system prompt follows, still marked for prompt caching.
    nonisolated static func buildSystemBlock(
        systemPrompt: String,
        credential: String
    ) -> [[String: Any]] {
        if isOAuthToken(credential) {
            return [
                ["type": "text", "text": claudeCodeIdentityPrompt],
                ["type": "text", "text": systemPrompt, "cache_control": ["type": "ephemeral"]]
            ]
        }
        return [
            ["type": "text", "text": systemPrompt, "cache_control": ["type": "ephemeral"]]
        ]
    }

    /// Apply the correct auth headers for either an API key or an OAuth token.
    /// OAuth tokens use `Authorization: Bearer` + the `oauth-2025-04-20` beta
    /// header (alongside prompt-caching); API keys use `x-api-key`.
    nonisolated private static func applyAuthHeaders(
        on request: inout URLRequest,
        credential: String,
        apiVersion: String,
        thinkingEnabled: Bool = false
    ) {
        let clean = sanitizedCredential(credential)
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        // Interleaved thinking lets Claude 4+ models think between tool calls.
        let thinkingFlag = thinkingEnabled ? ",interleaved-thinking-2025-05-14" : ""
        if clean.hasPrefix("sk-ant-oat01-") {
            request.setValue("Bearer \(clean)", forHTTPHeaderField: "Authorization")
            // All beta flags in a single comma-separated header value.
            request.setValue(
                "oauth-2025-04-20,prompt-caching-2024-07-31" + thinkingFlag,
                forHTTPHeaderField: "anthropic-beta"
            )
        } else if clean.hasPrefix("sk-or-") {
            // OpenRouter Anthropic-compat endpoint — wants Bearer auth, no Anthropic beta headers.
            request.setValue("Bearer \(clean)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue(clean, forHTTPHeaderField: "x-api-key")
            request.setValue("prompt-caching-2024-07-31" + thinkingFlag, forHTTPHeaderField: "anthropic-beta")
        }
    }

    /// Network I/O and response parsing off the main thread
    nonisolated private static func performRequest(
        bodyData: Data, apiKey: String, apiVersion: String, url: URL, thinkingEnabled: Bool = false
    ) async throws -> (content: [[String: Any]], stopReason: String, inputTokens: Int, outputTokens: Int) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyAuthHeaders(on: &request, credential: apiKey, apiVersion: apiVersion, thinkingEnabled: thinkingEnabled)
        request.httpBody = bodyData
        request.timeoutInterval = llmAPITimeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // 429 = rate limit, 529 = Anthropic "Overloaded". Both include Retry-After header (integer seconds); record it so next call's enforceRateLimit pads the wait. Default 30s if header missing.
            if httpResponse.statusCode == 429 || httpResponse.statusCode == 529 {
                let header = httpResponse.value(forHTTPHeaderField: "Retry-After")
                let parsed = Self.parseRetryAfter(header)
                let waitSeconds = parsed > 0 ? parsed : 30
                await Self.recordRetryAfter(waitSeconds)
            }
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let stopReason = json["stop_reason"] as? String else
        {
            throw AgentError.invalidResponse
        }

        let usage = json["usage"] as? [String: Any]
        let inputTokens = usage?["input_tokens"] as? Int ?? 0
        let outputTokens = usage?["output_tokens"] as? Int ?? 0
        let cacheRead = usage?["cache_read_input_tokens"] as? Int ?? 0
        let cacheCreation = usage?["cache_creation_input_tokens"] as? Int ?? 0
        if cacheRead > 0 || cacheCreation > 0 {
            Task { @MainActor in
                TokenUsageStore.shared.recordCacheMetrics(read: cacheRead, creation: cacheCreation)
            }
        }

        return (content, stopReason, inputTokens, outputTokens)
    }

    // MARK: - Streaming

    func sendStreaming(
        messages: [[String: Any]],
        activeGroups: Set<String>? = nil,
        onTextDelta: @escaping @Sendable (String) -> Void
    ) async throws -> (content: [[String: Any]], stopReason: String, inputTokens: Int, outputTokens: Int) {
        guard isLocalEndpoint || !apiKey.isEmpty else { throw AgentError.noAPIKey }
        await Self.enforceRateLimit()

        let systemBlock: Any = isLocalEndpoint ? systemPrompt : Self.buildSystemBlock(
            systemPrompt: systemPrompt,
            credential: apiKey
        )

        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens > 0 ? maxTokens : 16384,
            "system": systemBlock,
            "messages": withMessageCacheBreakpoint(stripOrphanToolResults(messages)),
            "stream": true
        ]
        if !isLocalhostEndpoint {
            var toolDefs = tools(activeGroups: activeGroups, compact: compactTools)
            if !toolDefs.isEmpty {
                toolDefs[toolDefs.count - 1]["cache_control"] = ["type": "ephemeral"]
            }
            body["tools"] = toolDefs
        }
        applyThinking(to: &body)

        // .sortedKeys for byte-stable prefix caching — see send() for rationale.
        let bodyData = try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
        return try await Self.performStreamingRequest(
            bodyData: bodyData,
            apiKey: apiKey,
            apiVersion: Self.apiVersion,
            url: endpointURL,
            thinkingEnabled: thinkingBudget > 0 && !isLocalhostEndpoint,
            onTextDelta: onTextDelta
        )
    }

    nonisolated private static func performStreamingRequest(
        bodyData: Data, apiKey: String, apiVersion: String, url: URL,
        thinkingEnabled: Bool = false,
        onTextDelta: @escaping @Sendable (String) -> Void
    ) async throws -> (content: [[String: Any]], stopReason: String, inputTokens: Int, outputTokens: Int) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyAuthHeaders(on: &request, credential: apiKey, apiVersion: apiVersion, thinkingEnabled: thinkingEnabled)
        request.httpBody = bodyData
        request.timeoutInterval = llmAPITimeout

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AgentError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // 429/529 Retry-After capture — see performRequest for rationale.
            if httpResponse.statusCode == 429 || httpResponse.statusCode == 529 {
                let header = httpResponse.value(forHTTPHeaderField: "Retry-After")
                let parsed = Self.parseRetryAfter(header)
                let waitSeconds = parsed > 0 ? parsed : 30
                await Self.recordRetryAfter(waitSeconds)
            }
            var errorData = Data()
            for try await byte in bytes {
                errorData.append(byte)
            }
            let errorBody = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw AgentError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        var contentBlocks: [[String: Any]] = []
        var currentTextBlock = ""
        var currentToolId = ""
        var currentToolName = ""
        var currentToolJson = ""
        var currentThinking = ""
        var currentThinkingSignature = ""
        var stopReason = ""
        var inToolUse = false
        var inServerToolUse = false
        var inThinking = false
        var pendingServerResult: [String: Any]?
        var inputTokens = 0
        var outputTokens = 0

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonStr = String(line.dropFirst(6))
            guard let data = jsonStr.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = event["type"] as? String else { continue }

            switch type {
            case "message_start":
                if let message = event["message"] as? [String: Any],
                   let usage = message["usage"] as? [String: Any]
                {
                    inputTokens = usage["input_tokens"] as? Int ?? 0
                    // Track prompt cache metrics
                    let cacheRead = usage["cache_read_input_tokens"] as? Int ?? 0
                    let cacheCreation = usage["cache_creation_input_tokens"] as? Int ?? 0
                    if cacheRead > 0 || cacheCreation > 0 {
                        Task { @MainActor in
                            TokenUsageStore.shared.recordCacheMetrics(read: cacheRead, creation: cacheCreation)
                        }
                    }
                }

            case "content_block_start":
                if let block = event["content_block"] as? [String: Any],
                   let blockType = block["type"] as? String
                {
                    if blockType == "text" {
                        currentTextBlock = ""
                        inToolUse = false
                        inServerToolUse = false
                    } else if blockType == "thinking" {
                        currentThinking = ""
                        currentThinkingSignature = ""
                        inThinking = true
                        inToolUse = false
                        inServerToolUse = false
                    } else if blockType == "redacted_thinking" {
                        // Arrives complete — must be passed back unmodified.
                        contentBlocks.append(block)
                    } else if blockType == "tool_use" {
                        currentToolId = block["id"] as? String ?? ""
                        currentToolName = block["name"] as? String ?? ""
                        currentToolJson = ""
                        inToolUse = true
                        inServerToolUse = false
                    } else if blockType == "server_tool_use" {
                        currentToolId = block["id"] as? String ?? ""
                        currentToolName = block["name"] as? String ?? ""
                        currentToolJson = ""
                        inToolUse = true
                        inServerToolUse = true
                    } else if blockType == "web_search_tool_result" {
                        pendingServerResult = block
                    }
                }

            case "content_block_delta":
                if let delta = event["delta"] as? [String: Any],
                   let deltaType = delta["type"] as? String
                {
                    if deltaType == "text_delta", let text = delta["text"] as? String {
                        currentTextBlock += text
                        onTextDelta(text)
                    } else if deltaType == "input_json_delta", let json = delta["partial_json"] as? String {
                        currentToolJson += json
                    } else if deltaType == "thinking_delta", let text = delta["thinking"] as? String {
                        currentThinking += text
                    } else if deltaType == "signature_delta", let sig = delta["signature"] as? String {
                        currentThinkingSignature += sig
                    }
                }

            case "content_block_stop":
                if inThinking {
                    // Signature must ride along — the API verifies it when the
                    // block is passed back on the next turn.
                    contentBlocks.append([
                        "type": "thinking",
                        "thinking": currentThinking,
                        "signature": currentThinkingSignature
                    ])
                    currentThinking = ""
                    currentThinkingSignature = ""
                    inThinking = false
                } else if inToolUse {
                    let input: [String: Any]
                    if let parsed = try? JSONSerialization.jsonObject(with: Data(currentToolJson.utf8)) as? [String: Any] {
                        input = parsed
                    } else {
                        AuditLog.log(
                            .api,
                            "[ClaudeService] Failed to parse tool args for \(currentToolName): \(currentToolJson.prefix(200))"
                        )
                        input = [:]
                    }
                    let blockType = inServerToolUse ? "server_tool_use" : "tool_use"
                    contentBlocks.append([
                        "type": blockType,
                        "id": currentToolId,
                        "name": currentToolName,
                        "input": input
                    ])
                    currentToolName = ""
                    currentToolId = ""
                    currentToolJson = ""
                    inToolUse = false
                    inServerToolUse = false
                } else if let result = pendingServerResult {
                    contentBlocks.append(result)
                    pendingServerResult = nil
                } else if !currentTextBlock.isEmpty {
                    contentBlocks.append(["type": "text", "text": currentTextBlock])
                    currentTextBlock = ""
                }

            case "message_delta":
                if let delta = event["delta"] as? [String: Any],
                   let reason = delta["stop_reason"] as? String
                {
                    stopReason = reason
                }
                if let usage = event["usage"] as? [String: Any] {
                    outputTokens = usage["output_tokens"] as? Int ?? outputTokens
                }

            default:
                break
            }
        }

        return (contentBlocks, stopReason, inputTokens, outputTokens)
    }
}
