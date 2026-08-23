import AgentTools
import CryptoKit
import Foundation
import FoundationModels

/// Tracks compaction state across iterations to avoid redundant or runaway compaction attempts.
struct CompactionState {
    /// Estimated tokens at which compaction should trigger (leave buffer for response).
    var compactThreshold: Int
    /// Consecutive compaction failures — stops retrying after 3.
    var consecutiveFailures: Int = 0
    /// Whether the last compaction attempt succeeded.
    var lastCompactSucceeded: Bool = true
    /// Total tokens estimated before the last compaction attempt.
    var tokensBeforeLastCompact: Int = 0

    /// Max consecutive failures before circuit breaker trips.
    static let maxFailures = 3

    init(contextWindow: Int = 200_000) {
        // Compact once the transcript passes ~55% of the model's real context
        // window, leaving headroom for the system prompt, tool schemas and the
        // response. Previously this argument was ignored and every model — 4K
        // Foundation Models or 1M Claude — compacted at a hardcoded 30K.
        let target = Int(Double(contextWindow) * 0.55)
        self.compactThreshold = max(2_000, min(target, 400_000))
    }

    /// True if we should attempt compaction for the given estimated token count.
    func shouldCompact(estimatedTokens: Int) -> Bool {
        guard consecutiveFailures < Self.maxFailures else { return false }
        return estimatedTokens > compactThreshold
    }

    /// Record a compaction attempt result. Returns true if compaction actually reduced tokens.
    mutating func recordAttempt(tokensBefore: Int, tokensAfter: Int) -> Bool {
        tokensBeforeLastCompact = tokensBefore
        let reduced = tokensAfter < tokensBefore
        if reduced {
            consecutiveFailures = 0
            lastCompactSucceeded = true
        } else {
            consecutiveFailures += 1
            lastCompactSucceeded = false
        }
        return reduced
    }
}

extension AgentViewModel {
    // MARK: - Context Window

    /// Approximate context window for a provider/model. Single source of truth for
    /// both the token meter in ThinkingIndicatorView and the compaction threshold
    /// in CompactionState.
    func contextWindow(for provider: APIProvider) -> Int {
        switch provider {
        case .claude: return 1_000_000
        case .codex:
            // Real context window from the live /models response; fall back
            // to gpt-5.2's published 272K if we haven't fetched yet.
            if let ctx = codexContextWindows[codexModel], ctx > 0 { return ctx }
            return 272_000
        case .openAI: return 272_000
        case .deepSeek: return 128_000
        case .gemini: return 2_000_000
        case .grok: return 2_000_000
        case .zAI: return 128_000
        case .bigModel: return 128_000
        case .miniMax: return 1_000_000
        case .openRouter: return 200_000
        case .qwen: return 131_072
        case .mistral: return 256_000
        case .codestral: return 256_000
        case .vibe: return 128_000
        case .huggingFace: return 32_000
        case .ollama, .localOllama: return localOllamaContextSize > 0 ? localOllamaContextSize : 32_000
        case .vLLM, .lmStudio: return 32_000
        case .foundationModel: return 4_096
        }
    }

    // MARK: - Message History Compression

    // NOTE: the old per-turn compressMessages sliding window is gone on purpose.
    // Rewriting the conversation middle on every request changed the serialized
    // prefix every turn, so provider prompt caches (Anthropic cache_control and
    // the automatic prefix caches on OpenAI-compatible providers) missed on the
    // whole conversation body each iteration. All truncation now happens inside
    // tieredCompact, which only fires past the token threshold — messages are
    // append-only between compaction events.

    /// Cache summaries so we don't re-summarize the same content.
    /// Keyed by SHA-256 of the content — `hashValue` is per-process seeded and
    /// collision-prone, and a collision would serve another tool result's summary.
    nonisolated(unsafe) private static var _summaryCache: [String: String] = [:]

    /// Stable content-addressed cache key.
    private static func cacheKey(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Async version: summarize old messages using Apple AI before sending.
    /// Call this before compressMessages for best results.
    static func summarizeOldMessages(_ messages: inout [[String: Any]], keepRecent: Int = 4) async {
        guard AppleIntelligenceMediator.shared.tokenCompressionEnabled else { return }
        guard messages.count > keepRecent + 1, FoundationModelService.isAvailable else {
            return
        }

        let middleEnd = messages.count - keepRecent
        let session = LanguageModelSession(
            model: .default,
            instructions: Instructions("Summarize in 1-2 concise sentences. Keep file paths, function names, errors, and key results.")
        )

        for i in 1..<middleEnd {
            let role = messages[i]["role"] as? String ?? ""

            if role == "user" {
                if var blocks = messages[i]["content"] as? [[String: Any]] {
                    var changed = false
                    for j in 0..<blocks.count {
                        if let content = blocks[j]["content"] as? String, content.count > 300 {
                            let key = cacheKey(content)
                            if _summaryCache[key] == nil {
                                let input = LogLimits.trim(content, cap: LogLimits.summaryChars)
                                if let resp = try? await session.respond(to: input) {
                                    _summaryCache[key] = "[summary] " + resp.content
                                }
                            }
                            if let cached = _summaryCache[key] {
                                blocks[j]["content"] = cached
                                changed = true
                            }
                        }
                    }
                    if changed { messages[i]["content"] = blocks }
                } else if let text = messages[i]["content"] as? String, text.count > 300 {
                    let key = cacheKey(text)
                    if _summaryCache[key] == nil {
                        let input = LogLimits.trim(text, cap: LogLimits.summaryChars)
                        if let resp = try? await session.respond(to: input) {
                            _summaryCache[key] = "[summary] " + resp.content
                        }
                    }
                    if let cached = _summaryCache[key] { messages[i]["content"] = cached }
                }
            }
        }
    }

    // MARK: - Tiered Compaction (token-budget-aware)

    /// Two-tier compaction: try Apple AI summarization first (fast), fall back to aggressive pruning.
    /// Returns true if tokens were meaningfully reduced.
    @MainActor
    static func tieredCompact(
        _ messages: inout [[String: Any]],
        state: inout CompactionState,
        log: ((String) -> Void)? = nil
    ) async -> Bool
    {
        // Structural compaction (microcompact / image strip / Tier 2 prune) is a
        // safety mechanism, not a feature: without it the conversation grows until
        // the provider rejects it. It runs regardless of the Token Compression
        // toggle. Only Tier 1 — Apple Intelligence summarization — respects it.
        //
        // Cheap chars/4 estimate first so an under-threshold turn costs nothing:
        // preciseTokenCount runs an on-device model pass over the whole transcript.
        guard state.shouldCompact(estimatedTokens: estimateTokens(messages: messages)) else { return false }

        let tokensBefore = await preciseTokenCount(messages: messages)
        guard state.shouldCompact(estimatedTokens: tokensBefore) else { return false }

        log?("🗜️ Compacting context (\(tokensBefore) est. tokens, threshold \(state.compactThreshold))...")

        // Microcompact: clear old tool results to "[cleared]" (keeps last 3)
        microcompact(&messages)

        // Strip images — they're huge and won't summarize well
        stripOldImages(&messages)

        // Tier 1: Apple AI summarization (fast, on-device).
        if FoundationModelService.isAvailable, AppleIntelligenceMediator.shared.tokenCompressionEnabled {
            await summarizeOldMessages(&messages)
            let tokensAfterT1 = await preciseTokenCount(messages: messages)
            if state.recordAttempt(tokensBefore: tokensBefore, tokensAfter: tokensAfterT1) {
                log?("🗜️ Apple AI compaction: \(tokensBefore) → \(tokensAfterT1) tokens")
                if tokensAfterT1 <= state.compactThreshold { return true }
            }
        }

        // Tier 2: Aggressive prune (drops middle messages into summary)
        pruneMessages(&messages)
        let tokensAfterT2 = await preciseTokenCount(messages: messages)
        let reduced = state.recordAttempt(tokensBefore: tokensBefore, tokensAfter: tokensAfterT2)
        if reduced {
            log?("🗜️ Pruned context: \(tokensBefore) → \(tokensAfterT2) tokens")
        } else {
            log?("⚠️ Compaction had no effect (\(state.consecutiveFailures)/\(CompactionState.maxFailures) failures)")
        }
        return reduced
    }

    // MARK: - Microcompaction (clear old tool results)

    /// Clear old tool_result content to save tokens while preserving message structure.
    /// Keeps only the last `keepRecent` tool results intact; older ones replaced with "[cleared]".
    static func microcompact(_ messages: inout [[String: Any]], keepRecent: Int = 3) {
        // No toggle gate — clearing stale tool results (spilled to ToolResultCache
        // first, so nothing is lost) is structural recovery, not an Apple
        // Intelligence feature.
        // Find all tool_result indices
        var toolResultIndices: [(msgIdx: Int, blockIdx: Int)] = []
        for (i, msg) in messages.enumerated() {
            if let blocks = msg["content"] as? [[String: Any]] {
                for (j, block) in blocks.enumerated() {
                    if block["type"] as? String == "tool_result",
                       let content = block["content"] as? String,
                       content.count > 100
                    {
                        toolResultIndices.append((i, j))
                    }
                }
            }
        }
        // Clear all but the last keepRecent
        let clearCount = max(0, toolResultIndices.count - keepRecent)
        for k in 0..<clearCount {
            let (i, j) = toolResultIndices[k]
            if var blocks = messages[i]["content"] as? [[String: Any]] {
                // Spill before clearing — otherwise this content is unrecoverable.
                if let content = blocks[j]["content"] as? String {
                    ToolResultCache.spill(
                        toolUseID: blocks[j]["tool_use_id"] as? String, content: content)
                }
                blocks[j]["content"] = "[cleared]"
                messages[i]["content"] = blocks
            }
        }
    }

    // MARK: - Token Counting (precise via Apple AI on macOS 26.4+, fallback ~4 chars/token)

    /// Count tokens using Apple Intelligence's tokenCount(for:) when available (macOS 26.4+),
    /// falls back to ~4 chars per token estimate otherwise.
    @MainActor
    private static func countTokens(for text: String) async -> Int {
        if FoundationModelService.isAvailable {
            do {
                return try await SystemLanguageModel.default.tokenCount(for: text)
            } catch {
                // Fall through to estimate
            }
        }
        return max(1, text.count / 4)
    }

    /// Synchronous ~4 chars per token estimate (used when async isn't available).
    private static func estimateTokensFallback(chars: Int) -> Int {
        max(1, chars / 4)
    }

    /// Count input tokens from message array.
    static func estimateTokens(messages: [[String: Any]]) -> Int {
        var chars = 0
        for msg in messages {
            if let text = msg["content"] as? String {
                chars += text.count
            } else if let blocks = msg["content"] as? [[String: Any]] {
                for block in blocks {
                    if let text = block["text"] as? String { chars += text.count }
                    else if let text = block["content"] as? String { chars += text.count }
                }
            }
        }
        return estimateTokensFallback(chars: chars)
    }

    /// Precise async token count using Apple Intelligence when available.
    @MainActor
    static func preciseTokenCount(messages: [[String: Any]]) async -> Int {
        var allText = ""
        for msg in messages {
            if let text = msg["content"] as? String {
                allText += text
            } else if let blocks = msg["content"] as? [[String: Any]] {
                for block in blocks {
                    if let text = block["text"] as? String { allText += text }
                    else if let text = block["content"] as? String { allText += text }
                }
            }
        }
        return await countTokens(for: allText)
    }

    /// Count output tokens from response content blocks.
    static func estimateTokens(content: [[String: Any]]) -> Int {
        var chars = 0
        for block in content {
            if let text = block["text"] as? String { chars += text.count }
            if let input = block["input"] as? [String: Any],
               let data = try? JSONSerialization.data(withJSONObject: input)
            {
                chars += data.count
            }
        }
        return estimateTokensFallback(chars: chars)
    }
}
