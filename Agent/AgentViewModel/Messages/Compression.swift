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

    /// Configured max output tokens (0 = provider default). Reserved off the
    /// top of the window so the response — and the compaction summary — fit.
    var maxTokens: Int = 0
    /// input_tokens from the provider's last usage report. Authoritative
    /// when present: it counts the system prompt and tool schemas the
    /// chars/4 estimate can't see. 0 = no report yet (or just compacted).
    var lastReportedInputTokens: Int = 0
    /// messages.count at the time of that report — only messages appended
    /// after it need estimating.
    var messageCountAtReport: Int = 0

    init(contextWindow: Int = 200_000, maxTokens: Int = 0) {
        self.maxTokens = maxTokens
        self.compactThreshold = Self.threshold(for: contextWindow, maxTokens: maxTokens)
    }

    /// Compact only when the transcript is about to stop fitting:
    /// window - reserved output - safety buffer. The reserved output is the
    /// configured max_tokens capped at 20K (enough for the summary call); the
    /// buffer is 13K, scaled down to 10% of the window for small local models.
    /// A 128K model now compacts at ~99K instead of 70K; Claude 1M at ~970K
    /// instead of 400K — bigger models keep proportionally more context.
    static func threshold(for contextWindow: Int, maxTokens: Int = 0) -> Int {
        let reservedOutput = min(maxTokens > 0 ? maxTokens : 8_192, 20_000)
        let buffer = min(13_000, contextWindow / 10)
        return max(2_000, contextWindow - reservedOutput - buffer)
    }

    /// Re-derive the threshold from the provider's current context window.
    /// The async local-server context fetch (LM Studio /api/v0/models,
    /// Ollama /api/show, vLLM /v1/models) can land AFTER a task starts —
    /// without this, the first task after launch runs on the 32K fallback.
    mutating func refreshThreshold(contextWindow: Int) {
        compactThreshold = Self.threshold(for: contextWindow, maxTokens: maxTokens)
    }

    /// Record the provider's reported input token count for the request that
    /// covered the first `messageCount` messages. Ignored when the provider
    /// reports nothing (0).
    mutating func recordUsage(inputTokens: Int, messageCount: Int) {
        guard inputTokens > 0 else { return }
        lastReportedInputTokens = inputTokens
        messageCountAtReport = messageCount
    }

    /// Best available token count for `messages`: the last real usage figure
    /// plus a chars/4 estimate of only what was appended since, or a pure
    /// estimate when no usage has been reported yet.
    @MainActor
    func measuredTokens(for messages: [[String: Any]]) -> Int {
        guard lastReportedInputTokens > 0, messageCountAtReport <= messages.count else {
            let cheap = AgentViewModel.estimateTokens(messages: messages)
            // chars/4 under-counts dense code (~3.3 chars/token) — inflate 25%.
            return cheap + cheap / 4
        }
        let appended = Array(messages[messageCountAtReport...])
        guard !appended.isEmpty else { return lastReportedInputTokens }
        return lastReportedInputTokens + AgentViewModel.estimateTokens(messages: appended)
    }

    /// True if we should attempt compaction for the given estimated token count.
    func shouldCompact(estimatedTokens: Int) -> Bool {
        if consecutiveFailures >= Self.maxFailures {
            // Circuit breaker tripped — but recover once the transcript has
            // grown another ~25% past the last failed attempt, instead of
            // never compacting again for the rest of the task.
            return tokensBeforeLastCompact > 0
                && estimatedTokens > tokensBeforeLastCompact + tokensBeforeLastCompact / 4
        }
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
        case .ollama, .localOllama:
            // Explicit user setting wins — it's also what gets sent as num_ctx.
            if localOllamaContextSize > 0 { return localOllamaContextSize }
            // Real per-model context from /api/show (num_ctx or context_length);
            // fall back to 32K only when the API hasn't answered.
            let model = provider == .ollama ? ollamaModel : localOllamaModel
            if let ctx = ollamaContextWindows[model], ctx > 0 { return ctx }
            return 32_000
        case .vLLM:
            // Real context from vLLM's /v1/models max_model_len; fall back to
            // 32K only when the API hasn't answered.
            if let ctx = vLLMContextWindows[vLLMModel], ctx > 0 { return ctx }
            return 32_000
        case .lmStudio:
            // Real context length from LM Studio's /api/v0/models (loaded or max);
            // fall back to 32K only when the REST API hasn't answered.
            if let ctx = lmStudioContextWindows[lmStudioModel], ctx > 0 { return ctx }
            return 32_000
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
        // Bound the in-memory summary cache — long sessions previously grew it
        // without limit. Dropping it all is safe: entries are re-summarized on
        // demand and keyed by content hash.
        if _summaryCache.count > 512 { _summaryCache.removeAll() }

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

    /// Produces the compaction summary for a request transcript (the live
    /// messages, images stripped, plus one summary-request user message).
    /// Returns nil on any failure so the caller falls back to pruning.
    typealias CompactSummarizer = @MainActor ([[String: Any]]) async -> String?

    /// The 9-section summary request appended as the final user message.
    /// Appending (not replacing) keeps the request prefix identical to the
    /// task's own requests, so the provider's prompt cache serves the whole
    /// transcript and the summary costs roughly its output tokens only.
    static let compactSummaryPrompt = """
        Your task is to create a detailed summary of the conversation so far, \
        paying close attention to the user's explicit requests and your previous actions. \
        This summary will REPLACE the conversation history; you will continue the task from it, \
        so it must capture everything needed to continue without re-doing work.

        Do NOT call any tools. Reply with plain text only, using exactly these sections:

        1. Primary Request and Intent: all of the user's explicit requests and intents, in detail.
        2. Key Technical Concepts: important technologies, frameworks, patterns and constraints discussed.
        3. Files and Code Sections: every file examined, modified or created, with full paths. \
        Include the relevant code snippets for anything you edited and why the file matters.
        4. Errors and Fixes: every error you hit and how you fixed it, plus any user feedback on how to do things differently.
        5. Problem Solving: problems solved and any ongoing troubleshooting.
        6. All User Messages: list ALL user messages that are not tool results, verbatim where short.
        7. Pending Tasks: work you have explicitly been asked to do that is not finished.
        8. Current Work: precisely what was being worked on immediately before this summary, \
        including file names, line numbers and code snippets.
        9. Next Step: the single next action, directly in line with the user's most recent request. \
        If the task was already finished, say so.
        """

    /// Compact by asking the active model for a structured summary and
    /// rebuilding the transcript as `[first user prompt] + summary + tail`.
    /// The summary sees the WHOLE transcript (up to the model's own window), so
    /// bigger models produce richer summaries automatically — unlike the
    /// on-device path, which is boxed into a 4K window. Returns false without
    /// touching `messages` on any failure.
    @MainActor
    static func compactWithLLM(
        _ messages: inout [[String: Any]],
        keepRecent: Int,
        summarizer: CompactSummarizer,
        log: ((String) -> Void)? = nil
    ) async -> Bool {
        guard messages.count > keepRecent + 4 else { return false }

        // Request = transcript minus images (huge, and they don't summarize)
        // + one summary-request user message. No transcript mutation yet.
        var request = messages
        stripOldImages(&request, keepRecentCount: 0)
        request.append(["role": "user", "content": compactSummaryPrompt])

        var summary = await summarizer(request)
        if summary == nil, messages.count > keepRecent + 8 {
            // The summary request itself may be too long for the provider
            // (forced compaction after a 413). Retry once summarizing only the
            // newer half of the middle — the older half is spilled below and
            // stays recoverable via restore_tool_result.
            let dropCount = (messages.count - 1 - keepRecent) / 2
            var shorter = [messages[0]]
            shorter.append(["role": "user", "content": "[\(dropCount) earlier messages omitted from this summary request]"])
            shorter.append(["role": "assistant", "content": "Understood."])
            var rest = Array(messages.dropFirst(1 + dropCount))
            demoteOrphanToolResults(&rest)
            shorter.append(contentsOf: rest)
            stripOldImages(&shorter, keepRecentCount: 0)
            shorter.append(["role": "user", "content": compactSummaryPrompt])
            log?("🗜️ Summary request too long — retrying with the oldest \(dropCount) messages omitted")
            summary = await summarizer(shorter)
        }
        guard let summary, !summary.isEmpty else {
            log?("⚠️ LLM compaction summary failed — falling back to prune")
            return false
        }

        let firstMsg = messages[0]
        var tail = Array(messages.suffix(keepRecent))
        let middle = Array(messages.dropFirst(1).dropLast(keepRecent))

        // The dropped middle may hold tool results the model will want back —
        // spill them so restore_tool_result still works after compaction.
        for msg in middle {
            guard let blocks = msg["content"] as? [[String: Any]] else { continue }
            for block in blocks where block["type"] as? String == "tool_result" {
                if let content = block["content"] as? String {
                    ToolResultCache.spill(toolUseID: block["tool_use_id"] as? String, content: content)
                }
            }
        }
        demoteOrphanToolResults(&tail)

        let continuation = """
            This session is being continued from a previous conversation that ran out of context. \
            The conversation is summarized below:

            \(summary)

            Continue the task from exactly where it left off without asking the user any further questions. \
            Recent messages after this summary are preserved verbatim. \
            Older tool output was cleared — call restore_tool_result(tool_use_id:) to recover any of it \
            instead of re-reading files.
            """

        messages = [firstMsg]
        messages.append(["role": "user", "content": continuation])
        messages.append(["role": "assistant", "content": "Understood, continuing."])
        messages.append(contentsOf: tail)
        log?("🗜️ LLM compaction: summarized \(middle.count) messages (\(summary.count) chars), kept last \(tail.count)")
        return true
    }

    /// Compaction ladder: LLM summary on the active provider (when a summarizer
    /// is supplied) → Apple AI per-message summaries → structural prune.
    /// Returns true if tokens were meaningfully reduced.
    @MainActor
    static func tieredCompact(
        _ messages: inout [[String: Any]],
        state: inout CompactionState,
        summarizer: CompactSummarizer? = nil,
        force: Bool = false,
        log: ((String) -> Void)? = nil
    ) async -> Bool
    {
        // Structural compaction (microcompact / image strip / Tier 2 prune) is a
        // safety mechanism, not a feature: without it the conversation grows until
        // the provider rejects it. It runs regardless of the Token Compression
        // toggle. Only Tier 1 — Apple Intelligence summarization — respects it.
        //
        // Cheap check first so an under-threshold turn costs nothing. When the
        // provider has reported input_tokens for the previous request that
        // figure is authoritative (it includes system prompt + tool schemas);
        // otherwise fall back to an inflated chars/4 estimate. `force` skips
        // the check — the provider already rejected the transcript as too long.
        let measured = state.measuredTokens(for: messages)
        guard force || state.shouldCompact(estimatedTokens: measured) else { return false }

        // Without a usage report, confirm with the on-device counter before
        // paying for a compaction — chars/4 alone is too noisy to act on.
        let tokensBefore: Int
        if force || state.lastReportedInputTokens > 0 {
            tokensBefore = measured
        } else {
            tokensBefore = await preciseTokenCount(messages: messages)
            guard state.shouldCompact(estimatedTokens: tokensBefore) else { return false }
        }
        // Whatever happens below rewrites the transcript, so the last usage
        // report no longer describes it. Estimate until the next response.
        state.lastReportedInputTokens = 0
        state.messageCountAtReport = 0

        log?("🗜️ Compacting context (\(tokensBefore) est. tokens, threshold \(state.compactThreshold))...")

        // How many recent messages / tool results survive scales with the
        // model's context budget — a 131K local model keeps far more reads
        // intact than a 4K one, so big models stop losing files they just read.
        let keepRecent = max(6, min(24, state.compactThreshold / 6_000))

        // Tier 0: structured summary from the active model over the FULL
        // transcript. Runs before microcompact so the summarizer still sees
        // the tool output it is summarizing.
        if let summarizer {
            if await compactWithLLM(&messages, keepRecent: keepRecent, summarizer: summarizer, log: log) {
                let tokensAfterT0 = await preciseTokenCount(messages: messages)
                if state.recordAttempt(tokensBefore: tokensBefore, tokensAfter: tokensAfterT0) {
                    log?("🗜️ LLM compaction: \(tokensBefore) → \(tokensAfterT0) tokens")
                    return true
                }
            }
        }

        // Microcompact: clear old tool results to recoverable stubs.
        microcompact(&messages, keepRecent: max(3, keepRecent))

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

        // Tier 2: Aggressive prune (drops middle messages into summary).
        pruneMessages(&messages, keepRecent: keepRecent)
        let tokensAfterT2 = await preciseTokenCount(messages: messages)
        let reduced = state.recordAttempt(tokensBefore: tokensBefore, tokensAfter: tokensAfterT2)
        if reduced {
            log?("🗜️ Pruned context: \(tokensBefore) → \(tokensAfterT2) tokens")
        } else {
            log?("⚠️ Compaction had no effect (\(state.consecutiveFailures)/\(CompactionState.maxFailures) failures)")
        }
        return reduced
    }


    // MARK: - Post-compaction re-attachment (Tier 7.4)

    /// What the model loses at compaction and needs back immediately: open
    /// goal criteria, the active plan checklist, and the current content of
    /// files edited this task (up to 5, ~10K tokens total). Also resets the
    /// read-dedup cache for the tab — the file contents are no longer in
    /// context, so a re-read is legitimate again. Returns nil when there is
    /// nothing to re-attach.
    func postCompactReattachment(tabID: UUID) -> String? {
        Self.clearReadCountsForTab(tabID: tabID)
        var parts: [String] = []
        if let goal = GoalStateStore.shared.current, !goal.openCriteria.isEmpty {
            parts.append(
                "OPEN GOAL — \(goal.goal)\nRemaining criteria:\n- "
                    + goal.openCriteria.map(\.text).joined(separator: "\n- ")
            )
        }
        let plan = PlanStateStore.promptBlock(projectFolder: projectFolder)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !plan.isEmpty { parts.append(plan) }

        var budget = 40_000 // chars ≈ 10K tokens across all files
        for path in FileBackupService.shared.snapshottedFiles().suffix(5) {
            guard budget > 0, let content = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            let head = String(content.prefix(min(8_000, budget)))
            budget -= head.count
            let scope = head.count < content.count ? "first \(head.count) of \(content.count) chars" : "full file"
            parts.append("FILE \(path) (\(scope), current on disk):\n```\n\(head)\n```")
        }
        guard !parts.isEmpty else { return nil }
        return "[Context restored after compaction]\n\n"
            + parts.joined(separator: "\n\n")
            + "\n\nRead-dedup was reset: you may re-read any file whose content is no longer in context."
    }

    /// Append `text` to the transcript as part of the last user message (or a
    /// new one) so the re-attachment lives inside the frozen post-compaction
    /// prefix instead of breaking user/assistant alternation.
    static func appendUserText(_ text: String, to messages: inout [[String: Any]]) {
        if let last = messages.last, last["role"] as? String == "user" {
            var blocks: [[String: Any]]
            if let existing = last["content"] as? [[String: Any]] {
                blocks = existing
            } else {
                blocks = [["type": "text", "text": last["content"] as? String ?? ""]]
            }
            blocks.append(["type": "text", "text": text])
            messages[messages.count - 1]["content"] = blocks
        } else {
            messages.append(["role": "user", "content": text])
        }
    }

    // MARK: - Microcompaction (clear old tool results)

    /// Tier 7.6: gap after which a carried-over transcript is treated as cold.
    /// Provider prompt caches expire well inside an hour, so nothing is saved
    /// by keeping stale tool results verbatim — clear all but the last 5.
    static let staleContinuationGap: TimeInterval = 60 * 60

    /// Time-based microcompact at task start. `lastActivity` is when the
    /// previous task last touched `messages`; returns true when the gap
    /// exceeded `gap` and old tool results were cleared.
    @discardableResult
    static func microcompactIfStale(
        _ messages: inout [[String: Any]],
        lastActivity: Date?,
        now: Date = Date(),
        gap: TimeInterval = staleContinuationGap
    ) -> Bool {
        guard let lastActivity, !messages.isEmpty,
              now.timeIntervalSince(lastActivity) > gap else { return false }
        microcompact(&messages, keepRecent: 5)
        return true
    }

    /// Clear old tool_result content to save tokens while preserving message structure.
    /// Keeps only the last `keepRecent` tool results intact; older ones are replaced
    /// with a short self-describing stub (head preview + restore instructions) so the
    /// model knows WHAT was cleared and how to get it back — instead of re-reading
    /// the same file in a loop.
    /// Tool results that are never cleared by microcompact: small, and the
    /// model steers on them (goal/plan state, user answers, sub-agent
    /// findings, memory). Everything else — file reads, shell output,
    /// searches, web fetches, edits — is cheap to recover via
    /// restore_tool_result and is what actually fills the window.
    static let microcompactProtectedTools: Set<String> = [
        "goal_state", "plan", "plan_mode", "ask_user", "task_complete", "done",
        "memory", "restore_tool_result", "spawn_agent", "tell_agent", "skill"
    ]

    static func microcompact(_ messages: inout [[String: Any]], keepRecent: Int = 3) {
        // No toggle gate — clearing stale tool results (spilled to ToolResultCache
        // first, so nothing is lost) is structural recovery, not an Apple
        // Intelligence feature.
        // Map tool_use id → tool name so protected results can be skipped.
        var toolNames: [String: String] = [:]
        for msg in messages where msg["role"] as? String == "assistant" {
            guard let blocks = msg["content"] as? [[String: Any]] else { continue }
            for block in blocks where block["type"] as? String == "tool_use" {
                if let id = block["id"] as? String, let name = block["name"] as? String {
                    toolNames[id] = name
                }
            }
        }
        // Find all tool_result indices
        var toolResultIndices: [(msgIdx: Int, blockIdx: Int)] = []
        for (i, msg) in messages.enumerated() {
            if let blocks = msg["content"] as? [[String: Any]] {
                for (j, block) in blocks.enumerated() {
                    guard block["type"] as? String == "tool_result" else { continue }
                    if let id = block["tool_use_id"] as? String,
                       let name = toolNames[id],
                       microcompactProtectedTools.contains(name)
                    {
                        continue
                    }
                    if let content = block["content"] as? String,
                       content.count > 100,
                       !content.hasPrefix("[cleared")
                    {
                        toolResultIndices.append((i, j))
                    } else if let nested = block["content"] as? [[String: Any]] {
                        // Block-array content (image/screenshot returns) — huge
                        // and previously never compacted.
                        let hasImage = nested.contains { $0["type"] as? String == "image" }
                        let textLen = nested.compactMap { $0["text"] as? String }.reduce(0) { $0 + $1.count }
                        if hasImage || textLen > 100 { toolResultIndices.append((i, j)) }
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
                    let id = blocks[j]["tool_use_id"] as? String
                    ToolResultCache.spill(toolUseID: id, content: content)
                    blocks[j]["content"] = clearedStub(content: content, toolUseID: id)
                } else if let nested = blocks[j]["content"] as? [[String: Any]] {
                    // Flatten block-array content: spill the text, drop images.
                    let text = nested.compactMap { $0["text"] as? String }.joined(separator: "\n")
                    let imageCount = nested.filter { $0["type"] as? String == "image" }.count
                    let id = blocks[j]["tool_use_id"] as? String
                    ToolResultCache.spill(toolUseID: id, content: text)
                    let header = imageCount > 0 ? "[\(imageCount) image(s) removed]\n" : ""
                    let recoverable = text.utf8.count >= ToolResultCache.minSpillBytes
                    blocks[j]["content"] = clearedStub(content: header + text, toolUseID: recoverable ? id : nil)
                }
                messages[i]["content"] = blocks
            }
        }
    }

    /// Build the replacement text for a cleared tool result. Keeps a 2-line head
    /// preview (usually enough to identify which file/command it was) and tells
    /// the model exactly how to recover the full text — so it calls
    /// restore_tool_result instead of re-reading the file.
    private static func clearedStub(content: String, toolUseID: String?) -> String {
        let head = content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .prefix(2)
            .map { String($0.prefix(120)) }
            .joined(separator: "\n")
        var stub = "[cleared to save context]\n\(head)\n"
        if let toolUseID, !toolUseID.isEmpty {
            stub += "Full content preserved — call restore_tool_result(tool_use_id:\"\(toolUseID)\") "
                + "to recover it. Do NOT re-read the file."
        } else {
            stub += "Re-run the tool only if this content is needed again."
        }
        return stub
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

    /// Flat token cost per attached image. Base64 length is NOT token length —
    /// the API bills a screenshot at roughly this much regardless of encoding.
    static let imageTokenEstimate = 1_600

    /// Walk a message array collecting countable text (including tool_use
    /// input JSON, which a write_file call can fill with an entire file) and
    /// the number of image blocks. Both counters previously skipped images
    /// and tool inputs, so vision-heavy and edit-heavy conversations
    /// undercounted badly and compaction/budget guards fired late or never.
    private static func countableContent(_ messages: [[String: Any]]) -> (text: String, imageTokens: Int) {
        var allText = ""
        var imageTokens = 0
        for msg in messages {
            if let text = msg["content"] as? String {
                allText += text
            } else if let blocks = msg["content"] as? [[String: Any]] {
                for block in blocks {
                    if let text = block["text"] as? String { allText += text }
                    else if let text = block["content"] as? String { allText += text }
                    else if let nested = block["content"] as? [[String: Any]] {
                        // tool_result with block-array content (image/screenshot
                        // returns) — previously invisible to both counters.
                        for n in nested {
                            if let t = n["text"] as? String { allText += t }
                            if n["type"] as? String == "image" { imageTokens += imageTokenEstimate }
                        }
                    }
                    if block["type"] as? String == "image" { imageTokens += imageTokenEstimate }
                    if let input = block["input"] as? [String: Any],
                       let data = try? JSONSerialization.data(withJSONObject: input)
                    {
                        allText += String(decoding: data, as: UTF8.self)
                    }
                }
            }
        }
        return (allText, imageTokens)
    }

    /// Count input tokens from message array.
    static func estimateTokens(messages: [[String: Any]]) -> Int {
        let (text, imageTokens) = countableContent(messages)
        return estimateTokensFallback(chars: text.count) + imageTokens
    }

    /// Precise async token count using Apple Intelligence when available.
    @MainActor
    static func preciseTokenCount(messages: [[String: Any]]) async -> Int {
        let (text, imageTokens) = countableContent(messages)
        return await countTokens(for: text) + imageTokens
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
