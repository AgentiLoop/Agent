import Foundation

// MARK: - stop_reason-driven loop control

extension AgentViewModel {

    /// What to do with a turn after parsing its content blocks.
    enum StopRoute: Equatable {
        /// Continue normal processing (tool dispatch / completion detection).
        case proceed
        /// Bounce the turn back to the LLM with a corrective user message.
        case retry(correction: String, log: String)
    }

    /// Route a turn using the API-reported stop_reason (authoritative) instead
    /// of phrase-matching the text. All provider services normalize to
    /// Anthropic-style reasons: "tool_use", "end_turn", "max_tokens".
    /// `retriesUsed` caps corrective bounces so a stubborn model can't loop.
    /// `maxTokensRetriesUsed` is the separate counter for output-truncation
    /// continuations (Tier 10.1) so one malformed call plus two truncations
    /// no longer exhausts the shared cap. Defaults to the shared counter.
    nonisolated static func routeStopReason(
        stopReason: String,
        hasToolUse: Bool,
        hasPendingTools: Bool,
        responseText: String,
        openCriteria: [String],
        retriesUsed: Int,
        maxTokensRetriesUsed: Int? = nil
    ) -> StopRoute {
        // Output truncated mid-thought. Treating this as a finished answer is
        // wrong — continue instead of completing. Own cap, own counter.
        if stopReason == "max_tokens" && !hasToolUse {
            guard (maxTokensRetriesUsed ?? retriesUsed) < maxTokensContinuations else { return .proceed }
            return .retry(
                correction: maxTokensContinuationMessage,
                log: "⚠️ Response truncated at max_tokens — continuing"
            )
        }

        guard retriesUsed < 3 else { return .proceed }

        // Model stopped to call a tool but nothing parsable arrived — malformed
        // tool JSON or a block the parser rejected. Ask for a clean re-issue.
        if stopReason == "tool_use" && !hasToolUse && !hasPendingTools {
            return .retry(
                correction: "No tool was executed — your tool call was malformed or empty. "
                    + "Re-issue the call using the proper tool-use format with all required parameters.",
                log: "⚠️ tool_use stop with no parsable tool call — asking LLM to re-issue"
            )
        }

        if (stopReason == "end_turn" || stopReason.isEmpty) && !hasToolUse {
            // Ending the turn while goal criteria are still open — remind the
            // model exactly what remains instead of silently completing.
            if !openCriteria.isEmpty {
                return .retry(
                    correction: "You stopped but the goal has open criteria:\n- "
                        + openCriteria.joined(separator: "\n- ")
                        + "\nContinue working on them, or call task_complete with evidence if they are already satisfied.",
                    log: "⚠️ end_turn with open goal criteria — nudging with the remaining list"
                )
            }
            // Fallback phrase heuristic for models that narrate actions they
            // never performed (mostly small local models).
            let lower = responseText.lowercased()
            let actionClaims = ["i searched", "i opened", "i clicked", "i ran ", "i executed",
                                "i found the", "i read the file", "i checked the", "i listed"]
            if actionClaims.contains(where: { lower.contains($0) }) {
                return .retry(
                    correction: "action not performed — you claimed to perform an action but made no tool call. "
                        + "Use the appropriate tool or say you cannot do it.",
                    log: "⚠️ action claimed without a tool call — asking for the real tool call"
                )
            }
        }

        return .proceed
    }

    // MARK: - Tier 10.4: periodic goal-state reminder

    /// Turns between reminders of the open goal criteria.
    nonisolated static let goalReminderInterval = 10

    /// A model that keeps calling tools never hits the end_turn nudge, so
    /// re-surface the open criteria every `interval` iterations unless it
    /// touched `goal_state` (or was reminded) more recently. Returns the text
    /// block to append, or nil.
    nonisolated static func goalReminderBlock(
        openCriteria: [String],
        iteration: Int,
        lastGoalActivity: Int,
        interval: Int = goalReminderInterval
    ) -> String? {
        guard !openCriteria.isEmpty, iteration - lastGoalActivity >= interval else { return nil }
        return "🎯 Goal reminder — these criteria are still open:\n- "
            + openCriteria.joined(separator: "\n- ")
            + "\nMark each one done with goal_state(action:\"mark\", evidence:\"…\") as you verify it. "
            + "task_complete is refused while any remain open."
    }

    // MARK: - Tier 10.5: prompt-cache warmth reminder for ≥1M windows

    /// Windows this large get the reminder; smaller ones compact long before
    /// cache warmth matters.
    nonisolated static let cacheWarmthMinWindow = 1_000_000
    /// Fraction of the window after which the reminder fires (once per task).
    nonisolated static let cacheWarmthFraction = 0.25

    /// On a ≥1M window, once real input usage passes 25% of it, tell the model
    /// once that the prefix is big enough that re-reads and bulky outputs cost
    /// real money — prefer restore_tool_result and small tool calls so the
    /// cached prefix stays warm and compaction stays far away. Nil when the
    /// window is small, usage is under the line, or it was already sent.
    nonisolated static func cacheWarmthReminderBlock(
        contextWindow: Int,
        inputTokens: Int,
        alreadySent: Bool
    ) -> String? {
        guard !alreadySent, contextWindow >= cacheWarmthMinWindow, inputTokens > 0 else { return nil }
        guard Double(inputTokens) >= Double(contextWindow) * cacheWarmthFraction else { return nil }
        let pct = Int((Double(inputTokens) / Double(contextWindow) * 100).rounded())
        return "📦 Context note: this task is using \(inputTokens / 1_000)K of the \(contextWindow / 1_000_000)M-token window (\(pct)%). "
            + "The cached prefix is large — do not re-read files already in context (use restore_tool_result for truncated results), "
            + "keep tool outputs narrow (offset/limit, targeted search), and finish with task_complete rather than exploring further. "
            + "Compaction will summarize the transcript if usage keeps growing."
    }

    // MARK: - Tier 10.1: max_tokens recovery

    /// Continuation messages allowed after the escalation retry.
    nonisolated static let maxTokensContinuations = 3

    nonisolated static let maxTokensContinuationMessage =
        "Output token limit hit. Resume directly from where you stopped — no apology, no recap, "
        + "do not repeat anything already written. Break the remaining work into smaller pieces: "
        + "one file / one edit / one tool call per turn."

    /// Output budget to retry the SAME request with after the first
    /// truncation: double the current budget, cap 64K, but never past what the
    /// context window can still hold after the input. Small windows get a
    /// proportionate bump (32K → ~16K, 16K → whatever is left) and a 4K
    /// window gets nil — the retry would just overflow. `current` is the
    /// effective budget (pass the provider default when the user left 0).
    nonisolated static func escalatedMaxTokens(current: Int, contextWindow: Int, lastInputTokens: Int) -> Int? {
        guard current > 0 else { return nil }
        let room = contextWindow - max(lastInputTokens, 0) - 1_000
        let target = min(64_000, current * 2, room)
        return target > current ? target : nil
    }
}
