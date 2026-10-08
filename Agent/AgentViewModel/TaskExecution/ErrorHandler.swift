
@preconcurrency import Foundation
import AgentTools
import AgentMCP
import AgentD1F
import AgentSwift
import Cocoa

// MARK: - Task Execution — LLM Error Handling

extension AgentViewModel {

    /// Result of handling a thrown error inside the LLM task loop.
    enum TaskLoopErrorOutcome {
        /// Caller should `continue` the outer while loop (retry with the same or updated state).
        case continueLoop
        /// Caller should `break` out of the outer while loop.
        case breakLoop
        /// Caller should switch to the named fallback provider/model and `continue`.
        /// The caller is responsible for rebuilding LLM services from these values.
        case fallbackRequested(provider: APIProvider, modelName: String, isVision: Bool)
        /// Tier 10.3: the provider said input + max_tokens exceeds the window.
        /// Caller should rebuild services with this smaller max_tokens and `continue`
        /// — the transcript itself still fits, so nothing is pruned.
        case lowerMaxTokens(Int)
    }

    /// Handles an error from LLM streaming: context-overflow pruning, stale connection retries, timeouts (with
    /// Ollama health-check/restart), 429 rate-limits, recoverable AgentErrors, network loss, and fallback-chain
    /// switching. Mutates `messages` and `timeoutRetryCount` inout. Returns TaskLoopErrorOutcome.
    ///
    /// `provider` is the provider the failing iteration was talking to; its protocol decides the
    /// error-source label and rate-limiter key.
    /// `appendLogFn`/`flushFn` route log lines: nil = self.appendLog/flushLog (main task), non-nil = a tab's
    /// log writer (used by handleTabTaskError shim).
    func handleTaskLoopError(
        _ error: Error,
        provider: APIProvider,
        model: String? = nil,
        messages: inout [[String: Any]],
        timeoutRetryCount: inout Int,
        maxTimeoutRetries: Int,
        appendLogFn: ((String) -> Void)? = nil,
        flushFn: (() -> Void)? = nil,
        overflowCompactor: (@MainActor (inout [[String: Any]]) async -> Bool)? = nil
    ) async -> TaskLoopErrorOutcome {
        let appendLog: (String) -> Void = appendLogFn ?? { [weak self] s in self?.appendLog(s) }
        let flushLog: () -> Void = flushFn ?? { [weak self] in self?.flushLog() }
        if Task.isCancelled { return .breakLoop }
        let errMsg = error.localizedDescription
        // Limiter key the services record Retry-After under: ClaudeService always records as "claude",
        // even when it is serving LM Studio / OpenRouter in Anthropic-protocol mode.
        let usesClaudeService = provider == .claude
            || (provider == .lmStudio && lmStudioProtocol == .anthropic)
            || (provider == .openRouter && openRouterProtocol == .anthropic)
            || (provider == .fluxion && fluxionProtocol == .anthropic)
        let limiterKey = usesClaudeService ? APIProvider.claude.rawValue : provider.rawValue

        // Output budget above the model's real ceiling ("max_tokens: X > Y,
        // which is the maximum allowed number of output tokens for MODEL" on
        // Anthropic; "This model supports at most Y completion tokens" on
        // OpenAI). Learn Y for this model and retry the same transcript at Y.
        if let cap = Self.parseMaxOutputCap(errMsg) {
            let capModel = cap.model.isEmpty ? (model ?? "") : cap.model
            if !capModel.isEmpty { modelMaxOutputTokens[capModel] = cap.limit }
            appendLog("⚠️ \(capModel.isEmpty ? "model" : capModel) caps output at \(cap.limit) tokens (asked \(cap.requested)) — remembering it and retrying")
            flushLog()
            return .lowerMaxTokens(cap.limit)
        }

        // Context overflow — prune messages aggressively and retry.
        // Detection requires an overflow phrase, not just a keyword: plain
        // "max_tokens" appears in unrelated parameter errors (e.g. "max_tokens
        // must be a positive integer"), and treating those as overflow caused
        // infinite same-second prune loops on bogus model ids.
        if Self.isContextOverflowMessage(errMsg) {
            // The provider told us its real window (vLLM / LM Studio / OpenAI
            // "maximum context length is N", Anthropic "X tokens > N maximum").
            // Remember it when smaller than what we assumed so the proactive
            // compaction threshold stops overshooting on every later request.
            if let model, !model.isEmpty, let window = Self.parseReportedContextWindow(errMsg),
               window < contextWindow(for: provider, model: model)
            {
                modelContextWindows[provider][model] = window
                appendLog("📏 \(provider.displayName) reports a \(window)-token context window for \(model) — compaction threshold adjusted")
            }
            // Tier 10.3: input + output budget exceeds the window ("A + B > C",
            // vLLM "(B > C - A)", OpenAI "I in the messages, O in the completion")
            // — only the output budget is too big. Lower it and retry the same
            // transcript instead of throwing context away.
            if let parsed = Self.parseInputPlusMaxTokensOverflow(errMsg) {
                let lowered = Self.loweredMaxTokens(limit: parsed.limit, input: parsed.input)
                if lowered < parsed.maxTokens, parsed.input + 3_000 < parsed.limit {
                    appendLog("⚠️ input (\(parsed.input)) + max_tokens (\(parsed.maxTokens)) exceeds the \(parsed.limit) window — lowering max_tokens to \(lowered) and retrying")
                    flushLog()
                    return .lowerMaxTokens(lowered)
                }
            }
            let beforeCount = messages.count
            let beforeTokens = Self.estimateTokens(messages: messages)
            // Reactive compaction: the provider already rejected the transcript,
            // so run the full compactor (LLM summary → prune) with the threshold
            // check bypassed. Falls back to the blind prune when the caller
            // supplied no compactor (sub-agents).
            var compacted = false
            if let overflowCompactor {
                compacted = await overflowCompactor(&messages)
            }
            if !compacted {
                Self.pruneMessages(&messages, keepRecent: 4)
                Self.stripOldImages(&messages)
            }
            let didShrink = messages.count < beforeCount
                || Self.estimateTokens(messages: messages) < beforeTokens
            // Cap consecutive prune attempts; if pruning didn't actually shrink the
            // history, the error is misclassified or the model's limit is so small
            // even pruning can't help — either way, retrying is futile.
            timeoutRetryCount += 1
            if !didShrink || timeoutRetryCount > 3 {
                // Tiny transcript + overflow = the bloat is outside `messages`
                // (system prompt: chat history, config, tool schemas) — pruning
                // can never fix that, so say so instead of "didn't help".
                let remaining = Self.estimateTokens(messages: messages)
                let hint = remaining < 5_000
                    ? "\nTranscript is only ~\(remaining) tokens — the overflow is in the system prompt (chat history / config), not the messages. Clearing chat history will resolve it."
                    : ""
                appendLog(
                    """
                    ⚠️ Context overflow — pruning to \(messages.count) messages didn't help. Stopping.\(hint)
                    Original error: \(errMsg.prefix(300))
                    """
                )
                flushLog()
                recordError(error, context: "\(provider.displayName) context overflow")
                return .breakLoop
            }
            appendLog("⚠️ Context overflow — pruned \(beforeCount) → \(messages.count) messages, retrying (\(timeoutRetryCount)/3)")
            flushLog()
            try? await Task.sleep(for: .milliseconds(500))
            return .continueLoop
        }

        // Stale connection — retry with fresh request
        let isStaleConnection = errMsg.contains("ECONNRESET") || errMsg.contains("EPIPE")
            || errMsg.contains("connection reset") || errMsg.contains("broken pipe")
        if isStaleConnection && timeoutRetryCount < maxTimeoutRetries {
            timeoutRetryCount += 1
            appendLog("🔌 Connection reset — retrying (\(timeoutRetryCount)/\(maxTimeoutRetries))")
            flushLog()
            try? await Task.sleep(for: .seconds(2))
            return .continueLoop
        }

        // Detect timeout errors
        let isNetworkTimeout = errMsg.lowercased().contains("timeout") || errMsg.lowercased().contains("timed out")


        // Determine error source for better logging
        let errorSource: String
        switch provider.apiProtocol {
        case .ollama: errorSource = "Ollama API"
        case .foundationModel: errorSource = "Apple Intelligence"
        default: errorSource = "\(provider.displayName) API"
        }

        // Handle timeout errors with retry logic
        if isNetworkTimeout {
            // Check if we've already retried this timeout
            if timeoutRetryCount < maxTimeoutRetries {
                timeoutRetryCount += 1

                // Special handling for Ollama timeouts - check server health
                if errorSource == "Ollama API" || errorSource == "Local Ollama" {
                    appendLog("🔍 Checking Ollama server health...")
                    flushLog()

                    // Run Ollama health check in background
                    let healthCheckResult = await Self.offMain {
                        let healthCheckTask = Process()
                        healthCheckTask.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
                        healthCheckTask.arguments = ["-s", "-f", "http://localhost:11434/api/tags", "--max-time", "5"]
                        healthCheckTask.currentDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())

                        let pipe = Pipe()
                        healthCheckTask.standardOutput = pipe
                        healthCheckTask.standardError = pipe

                        do {
                            try healthCheckTask.run()
                            // Drain before waiting — /api/tags JSON can exceed the 64KB pipe buffer.
                            _ = pipe.fileHandleForReading.readDataToEndOfFile()
                            healthCheckTask.waitUntilExit()
                            return healthCheckTask.terminationStatus
                        } catch {
                            return -1
                        }
                    }

                    if healthCheckResult != 0 {
                        appendLog("⚠️ Ollama server not responding. Attempting to restart...")
                        flushLog()

                        // Restart Ollama via UserService XPC
                        _ = await userService
                            .execute(command: "pkill -f 'ollama serve' && sleep 2 && open /Applications/Ollama.app")
                        appendLog("🔄 Restart command executed")
                        flushLog()

                        // Wait longer for Ollama startup
                        let startupDelay = TimeInterval(min(10 * timeoutRetryCount, 30)) // Exponential backoff up to 30 seconds
                        let retryMessage =
                            """
                            \(errorSource) timeout detected \
                            (attempt \(timeoutRetryCount)/\(maxTimeoutRetries)) — \
                            Ollama restart attempted, \
                            waiting \(Int(startupDelay)) seconds...
                            """
                        appendLog(retryMessage)
                        flushLog()
                        if agentReplyHandle != nil {
                            sendProgressUpdate(retryMessage)
                        }

                        try? await Task.sleep(for: .seconds(startupDelay))
                        if Task.isCancelled { return .breakLoop }
                        return .continueLoop
                    } else {
                        appendLog("✅ Ollama server is running but API timed out")
                        flushLog()
                    }
                }

                let retryDelay = LLMRateLimiter.retryDelay(attempt: timeoutRetryCount) // jittered exponential, ≤32s (Tier 10.2)
                let retryMessage =
                    """
                    \(errorSource) timeout detected \
                    (attempt \(timeoutRetryCount)/\(maxTimeoutRetries)) — \
                    retrying in \(String(format: "%.1f", retryDelay)) seconds...
                    """
                appendLog(retryMessage)
                flushLog()
                if agentReplyHandle != nil {
                    sendProgressUpdate(retryMessage)
                }

                // Log to task log for debugging

                try? await Task.sleep(for: .seconds(retryDelay))
                if Task.isCancelled { return .breakLoop }
                return .continueLoop
            } else {
                // Max retries reached - try final Ollama restart if applicable
                if (errorSource == "Ollama API" || errorSource == "Local Ollama") && timeoutRetryCount == maxTimeoutRetries {
                    appendLog("🔄 Max retries reached. Attempting final Ollama restart...")
                    flushLog()

                    // Restart Ollama via UserService XPC
                    _ = await userService
                        .execute(command: "pkill -f 'ollama serve' && sleep 3 && open /Applications/Ollama.app && sleep 10")
                    appendLog("Ollama restart attempted. Please check Ollama application status.")
                    flushLog()
                }

                // Retry budget exhausted on the same provider — try fallback chain BEFORE giving up. Without this,
                // every timeout/exhaustion would skip past the fallback entirely and the user would never see it trigger.
                if let fallback = await tryFallbackChain(reason: "\(errorSource) timeout after \(maxTimeoutRetries) retries") {
                    timeoutRetryCount = 0
                    return fallback
                }

                let timeoutMessage =
                    """
                    \(errorSource) timeout after \(maxTimeoutRetries) \
                    retries. Please check your network connection \
                    or try a different LLM provider.
                    """
                appendLog(timeoutMessage)
                flushLog()
                recordError(error, context: "\(errorSource) timeout after \(maxTimeoutRetries) retries")
                if agentReplyHandle != nil {
                    sendProgressUpdate(timeoutMessage)
                }
                return .breakLoop
            }
        } else if let agentErr = error as? AgentError, agentErr.isRateLimited, timeoutRetryCount < maxTimeoutRetries {
            // 429 rate-limit / "service overloaded". Z.ai returns this with body code 1305 ("service may be
            // temporarily overloaded"); OpenAI/Anthropic return 429/529 with a Retry-After header that the service
            // already recorded in LLMRateLimiter. Delay = Retry-After if present, else jittered exponential (Tier 10.2).
            timeoutRetryCount += 1
            let apiBody: String
            if case .apiError(_, let msg) = error as? AgentError { apiBody = msg } else { apiBody = errMsg }
            // OpenRouter free-tier rate limits are shared across all OpenRouter
            // users and don't recover on the timescale of our retry loop. Bail
            // to fallback (or break) immediately instead of churning 20×10s.
            let isFreeQuotaExhausted = apiBody.contains("rate-limited upstream")
                || apiBody.contains("add your own key to accumulate")
            // Record every 429 with the fallback chain — it fires once its
            // own threshold is met (3 total failures across the task).
            if let fallback = await tryFallbackChain(reason: "429 (\(timeoutRetryCount))") {
                timeoutRetryCount = 0
                return fallback
            }
            if isFreeQuotaExhausted {
                appendLog(
                    """
                    ⏳ \(errorSource) free-tier upstream exhausted: \(apiBody.prefix(200))
                    No fallback available — giving up. Pick a paid model (drop the :free suffix) or configure a fallback chain.
                    """
                )
                flushLog()
                recordError(error, context: "\(errorSource) free-tier upstream exhausted")
                return .breakLoop
            }
            // Tier 10.2: Retry-After (already recorded in LLMRateLimiter by the
            // service, waited by enforce() on the next request) wins; otherwise
            // jittered exponential backoff. Sleep only the part enforce() won't.
            let pending = await LLMRateLimiter.shared.pendingWait(provider: limiterKey)
            let retryDelay = LLMRateLimiter.retryDelay(attempt: timeoutRetryCount, retryAfter: pending)
            appendLog(
                """
                ⏳ \(errorSource) 429: \(apiBody.prefix(200))
                Retrying in \(Int(retryDelay.rounded()))s\(pending > 0 ? " (Retry-After)" : "") (attempt \(timeoutRetryCount)/\(maxTimeoutRetries))
                """
            )
            flushLog()
            if agentReplyHandle != nil {
                sendProgressUpdate("\(errorSource) rate limited — waiting \(Int(retryDelay.rounded()))s")
            }
            try? await Task.sleep(for: .seconds(max(0, retryDelay - pending)))
            if Task.isCancelled { return .breakLoop }
            return .continueLoop
        } else if let agentErr = error as? AgentError, agentErr.isRecoverable, timeoutRetryCount < maxTimeoutRetries {
            // Server/network error — jittered exponential backoff (Tier 10.2)
            timeoutRetryCount += 1
            let retryDelay = LLMRateLimiter.retryDelay(attempt: timeoutRetryCount)
            appendLog(
                """
                \(errorSource) recoverable error \
                (attempt \(timeoutRetryCount)/\(maxTimeoutRetries)) — \
                retrying in \(String(format: "%.1f", retryDelay))s...
                \(errMsg)
                """
            )
            flushLog()
            try? await Task.sleep(for: .seconds(retryDelay))
            if Task.isCancelled { return .breakLoop }
            return .continueLoop
        } else if provider.apiProtocol == .ollama, let missing = Self.parseOllamaMissingModel(errMsg) {
            // Ollama 404 `{"error": "model 'X' not found"}` — the model isn't
            // pulled on that server (or the name is misspelled). Retrying can't
            // help: name the installed models and how to get this one, then
            // fall back or stop, instead of dumping the raw JSON body.
            let installed = (provider == .localOllama ? localOllamaModels : ollamaModels).map(\.name)
            let installedHint = installed.isEmpty ? "" : "\nInstalled models: \(installed.joined(separator: ", "))"
            appendLog(
                """
                ⚠️ \(errorSource): model '\(missing)' is not installed on the Ollama server.\(installedHint)
                Run `ollama pull \(missing)` or pick an installed model in Settings.
                """
            )
            flushLog()
            if let fallback = await tryFallbackChain(reason: "\(errorSource) model '\(missing)' not found") {
                timeoutRetryCount = 0
                return fallback
            }
            recordError(AgentError.notFound(item: "Ollama model '\(missing)' (not installed — `ollama pull \(missing)`)"), context: errorSource)
            return .breakLoop
        } else if errMsg.lowercased().contains("network")
            || errMsg.lowercased().contains("connection")
            || errMsg.lowercased().contains("internet")
            || (error as? URLError)?.code == .networkConnectionLost
            || (error as? URLError)?.code == .notConnectedToInternet
        {
            timeoutRetryCount += 1
            if timeoutRetryCount <= maxTimeoutRetries {
                let delay = networkRetryDelay
                appendLog(
                    """
                    🌐 Network connection lost — retrying in \(delay)s \
                    (attempt \(timeoutRetryCount)/\(maxTimeoutRetries))...
                    """
                )
                flushLog()
                try? await Task.sleep(for: .seconds(Double(delay)))
                if Task.isCancelled { return .breakLoop }
                return .continueLoop
            } else {
                // Network retry budget exhausted — try fallback chain before giving up.
                if let fallback = await tryFallbackChain(reason: "network connection lost after \(maxTimeoutRetries) retries") {
                    timeoutRetryCount = 0
                    return fallback
                }
                appendLog("🌐 Network connection lost after \(maxTimeoutRetries) retries.")
                flushLog()
                recordError(error, context: "\(errorSource) network lost after \(maxTimeoutRetries) retries")
                return .breakLoop
            }
        } else {
            // Try fallback chain before giving up
            if let fallback = await tryFallbackChain(reason: "\(errorSource) error: \(errMsg)") {
                timeoutRetryCount = 0
                return fallback
            }

            // Non-recoverable error — no fallback available
            appendLog("\(errorSource) Error: \(errMsg)")
            flushLog()
            recordError(error, context: errorSource)

            // Apple Intelligence error explanation
            let mediator = AppleIntelligenceMediator.shared
            if mediator.isEnabled && mediator.showAnnotationsToUser {
                if let errorAnnotation = await mediator.explainError(toolName: "LLM request", error: errMsg) {
                    appendLog(errorAnnotation.formatted)
                    flushLog()
                }
            }
            return .breakLoop
        }
    }

    /// / Shared helper used by every error branch in handleTaskLoopError. Records / a failure with FallbackChainService
    /// and, if the threshold is reached and / a fallback entry is available, returns the .fallbackRequested outcome / for the caller to act on. Returns nil if no fallback should fire (chain / disabled, threshold not yet reached, or no more entries).
    private func tryFallbackChain(reason: String) async -> TaskLoopErrorOutcome? {
        guard let fallback = FallbackChainService.shared.recordFailure() else { return nil }
        appendLog("🔄 Fallback triggered (\(reason))")
        appendLog("🔄 Switching to fallback: \(fallback.displayName)")
        flushLog()
        guard let fbProvider = APIProvider(rawValue: fallback.provider) else { return .continueLoop }
        var newIsVision = Self.isVisionModel(fallback.model)
        if forceVision { newIsVision = true }
        appendLog("✅ Now using \(fbProvider.displayName) / \(fallback.model)")
        flushLog()
        return .fallbackRequested(provider: fbProvider, modelName: fallback.model, isVision: newIsVision)
    }

    // MARK: - Tier 10.3: context-overflow classification

    /// First regex capture group `group` of `pattern` in `message` (case-insensitive).
    nonisolated private static func firstCapture(_ pattern: String, in message: String, group: Int = 1) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let m = re.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
              group < m.numberOfRanges,
              let r = Range(m.range(at: group), in: message) else { return nil }
        return String(message[r])
    }

    /// True when a provider error means "request doesn't fit the context
    /// window". Covers the phrasing of every supported backend:
    /// - Anthropic: "prompt is too long: X tokens > Y maximum",
    ///   "input length and `max_tokens` exceed context limit: A + B > C"
    /// - OpenAI / Codex: code `context_length_exceeded`, "This model's maximum
    ///   context length is N tokens", "Your input exceeds the context window"
    /// - vLLM: "maximum context length is N tokens … (B > C - A)"
    /// - LM Studio: "Trying to keep the first N tokens when context the
    ///   overflows … context length of only M tokens", "Context length exceeded"
    /// - Ollama / llama.cpp: "input length exceeds the context length",
    ///   "the request exceeds the available context size"
    /// Case-insensitive; requires an overflow phrase, never a bare keyword.
    nonisolated static func isContextOverflowMessage(_ message: String) -> Bool {
        let m = message.lowercased()
        let exceeds = m.contains("exceed") || m.contains("greater than") || m.contains("too long")
            || m.contains("too large") || m.contains("overflow")
        return m.contains("context_length_exceeded")
            || m.contains("prompt is too long")
            || m.contains("prompt too long")
            || m.contains("input is too long")
            || m.contains("too many tokens")
            || m.contains("maximum context length")
            || m.contains("tokens to keep")
            || m.contains("context overflow")
            || m.contains("available context size")
            || m.contains("reduce the length of the messages")
            || (m.contains("context window") && exceeds)
            || (m.contains("context length") && (exceeds || m.contains("only")))
            || (m.contains("context_length") && exceeds)
            || (m.contains("context limit") && exceeds)
            || (m.contains("input length") && m.contains("exceed"))
            || (m.contains("max_tokens") && (m.contains("exceed") || m.contains("greater than")))
    }

    /// Real context window stated inside an overflow error, or nil.
    nonisolated static func parseReportedContextWindow(_ message: String) -> Int? {
        let patterns = [
            #"maximum context length is\s*(\d+)"#,          // OpenAI / vLLM
            #"context length of (?:only\s+)?(\d+)"#,        // LM Studio
            #"context window of (?:only\s+)?(\d+)"#,
            #"tokens\s*>\s*(\d+)\s*maximum"#,                // Anthropic prompt too long
            #"context limit:\s*\d+\s*\+\s*\d+\s*>\s*(\d+)"#, // Anthropic input + max_tokens
            #"n_ctx"?\s*[:=]\s*(\d+)"#                       // llama.cpp / Ollama
        ]
        for p in patterns {
            if let n = firstCapture(p, in: message).flatMap(Int.init), n >= 1_000 { return n }
        }
        return nil
    }

    /// Parse an "input + output budget > window" overflow into its parts.
    /// Returns nil for any other overflow so those still go through compaction.
    /// - Anthropic: "input length and `max_tokens` exceed context limit: A + B > C"
    /// - vLLM: "… maximum context length is C tokens and your request has A
    ///   input tokens (B > C - A)"
    /// - OpenAI / older vLLM: "maximum context length is C tokens. However, you
    ///   requested T tokens (… B in the completion)" → A = T - B
    nonisolated static func parseInputPlusMaxTokensOverflow(_ message: String) -> (input: Int, maxTokens: Int, limit: Int)? {
        let lower = message.lowercased()
        if lower.contains("max_tokens"), lower.contains("exceed"),
           let a = firstCapture(#"(\d+)\s*\+\s*(\d+)\s*>\s*(\d+)"#, in: message, group: 1).flatMap(Int.init),
           let b = firstCapture(#"(\d+)\s*\+\s*(\d+)\s*>\s*(\d+)"#, in: message, group: 2).flatMap(Int.init),
           let c = firstCapture(#"(\d+)\s*\+\s*(\d+)\s*>\s*(\d+)"#, in: message, group: 3).flatMap(Int.init)
        {
            return (a, b, c)
        }
        let vllm = #"\((\d+)\s*>\s*(\d+)\s*-\s*(\d+)\)"#
        if let b = firstCapture(vllm, in: message, group: 1).flatMap(Int.init),
           let c = firstCapture(vllm, in: message, group: 2).flatMap(Int.init),
           let a = firstCapture(vllm, in: message, group: 3).flatMap(Int.init)
        {
            return (a, b, c)
        }
        if let c = firstCapture(#"maximum context length is\s*(\d+)"#, in: message).flatMap(Int.init),
           let t = firstCapture(#"you requested\s*(\d+)\s*tokens"#, in: message).flatMap(Int.init),
           let b = firstCapture(#"(\d+)\s*in the completion"#, in: message).flatMap(Int.init),
           t > b
        {
            return (t - b, b, c)
        }
        return nil
    }

    /// Model name from an Ollama "model not found" error, or nil.
    /// - `/api/chat` 404: `{"error": "model 'llama3:8b' not found"}`
    /// - older servers: `model "llama3:8b" not found, try pulling it first`
    nonisolated static func parseOllamaMissingModel(_ message: String) -> String? {
        guard message.lowercased().contains("not found") else { return nil }
        return firstCapture(#"model\s+['"]([^'"]+)['"]\s+not found"#, in: message)
    }

    /// Output budget that fits next to `input` inside `limit`, with a 1K
    /// safety margin and a 3K floor so the model can still finish a thought.
    nonisolated static func loweredMaxTokens(limit: Int, input: Int) -> Int {
        max(3_000, limit - input - 1_000)
    }

    /// Parse an output-budget-above-model-ceiling error. Returns the requested
    /// budget, the model's real ceiling, and the model id (empty when the
    /// message omits it).
    /// - Anthropic: "max_tokens: X > Y, which is the maximum allowed number of
    ///   output tokens for MODEL"
    /// - OpenAI / OpenAI-compatible: "max_tokens is too large: X. This model
    ///   supports at most Y completion tokens, whereas you provided X."
    nonisolated static func parseMaxOutputCap(_ message: String) -> (requested: Int, limit: Int, model: String)? {
        if message.contains("max_tokens"), message.contains("maximum allowed"),
           let a = firstCapture(#"max_tokens:\s*(\d+)\s*>\s*(\d+)"#, in: message, group: 1).flatMap(Int.init),
           let b = firstCapture(#"max_tokens:\s*(\d+)\s*>\s*(\d+)"#, in: message, group: 2).flatMap(Int.init)
        {
            let model = firstCapture(#"output tokens for\s+([A-Za-z0-9._:\-]+)"#, in: message) ?? ""
            return (a, b, model)
        }
        if let b = firstCapture(#"supports at most\s*(\d+)\s*(?:completion|output)\s*tokens"#, in: message).flatMap(Int.init) {
            let a = firstCapture(#"too large:\s*(\d+)"#, in: message).flatMap(Int.init)
                ?? firstCapture(#"you provided\s*(\d+)"#, in: message).flatMap(Int.init)
                ?? 0
            return (a, b, "")
        }
        return nil
    }
}
