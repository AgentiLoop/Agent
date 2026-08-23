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
    nonisolated static func routeStopReason(
        stopReason: String,
        hasToolUse: Bool,
        hasPendingTools: Bool,
        responseText: String,
        openCriteria: [String],
        retriesUsed: Int
    ) -> StopRoute {
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

        // Output truncated mid-thought. Treating this as a finished answer is
        // wrong — continue instead of completing.
        if stopReason == "max_tokens" && !hasToolUse {
            return .retry(
                correction: "Your response hit the max_tokens limit and was truncated. "
                    + "Continue exactly where you left off.",
                log: "⚠️ Response truncated at max_tokens — continuing"
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
}
