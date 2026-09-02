import Testing
import Foundation
@testable import Agent_

// Eval suite for the agentic harness guards: failure classification,
// broken-record fingerprinting, stop_reason routing, typed tool errors,
// goal-state evidence gating, and plan surfacing. These are the mechanisms
// that keep the autonomous loop honest — regressions here silently degrade
// every task, so each guard gets deterministic coverage.

@Suite("HarnessGuards")
@MainActor
struct HarnessGuardTests {

    // MARK: - isToolFailure (status-line-only classification)

    @Test("Error status line is a failure")
    func errorPrefixIsFailure() {
        #expect(AgentViewModel.isToolFailure(output: "Error: old_string not found in file"))
        #expect(AgentViewModel.isToolFailure(output: "❌ build failed"))
        #expect(AgentViewModel.isToolFailure(output: "warning: something went sideways"))
        #expect(AgentViewModel.isToolFailure(output: "edit rejected by user"))
        #expect(AgentViewModel.isToolFailure(output: "no changes made"))
    }

    @Test("Success output mentioning 'error:' later is NOT a failure")
    func errorInBodyIsNotFailure() {
        // A successful edit echoes file content — if that content contains
        // "error:" the guard must not trip (the original false-positive bug).
        let output = "Replaced 1 occurrence in XcodeService.swift\nif result.contains(\"error:\") { return }"
        #expect(!AgentViewModel.isToolFailure(output: output))
    }

    @Test("Plain success output is not a failure")
    func successIsNotFailure() {
        #expect(!AgentViewModel.isToolFailure(output: "Wrote 42 lines to /tmp/x.swift"))
        #expect(!AgentViewModel.isToolFailure(output: "Build succeeded"))
    }

    // MARK: - toolCallFingerprint (broken-record guard)

    @Test("Fingerprint is deterministic regardless of key insertion order")
    func fingerprintDeterministic() {
        let a: [String: Any] = ["path": "/tmp/x", "limit": 10]
        let b: [String: Any] = ["limit": 10, "path": "/tmp/x"]
        #expect(AgentViewModel.toolCallFingerprint(name: "read_file", input: a)
             == AgentViewModel.toolCallFingerprint(name: "read_file", input: b))
    }

    @Test("Fingerprint differs on different input or tool name")
    func fingerprintDiffers() {
        let a: [String: Any] = ["path": "/tmp/x"]
        let b: [String: Any] = ["path": "/tmp/y"]
        #expect(AgentViewModel.toolCallFingerprint(name: "read_file", input: a)
             != AgentViewModel.toolCallFingerprint(name: "read_file", input: b))
        #expect(AgentViewModel.toolCallFingerprint(name: "read_file", input: a)
             != AgentViewModel.toolCallFingerprint(name: "list_files", input: a))
    }

    @Test("Polling/wait tools are exempt from the repeat guard")
    func repeatExemptions() {
        #expect(AgentViewModel.repeatExemptTools.contains("wait_for_element"))
        #expect(AgentViewModel.repeatExemptTools.contains("task_complete"))
        #expect(AgentViewModel.repeatExemptTools.contains("ask_user"))
        #expect(!AgentViewModel.repeatExemptTools.contains("edit_file"))
    }

    // MARK: - routeStopReason (loop control)

    @Test("tool_use stop with no parsable tool call → retry")
    func malformedToolCallRetries() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "tool_use", hasToolUse: false, hasPendingTools: false,
            responseText: "", openCriteria: [], retriesUsed: 0)
        guard case .retry(let correction, _) = route else {
            Issue.record("Expected .retry, got .proceed"); return
        }
        #expect(correction.contains("malformed") || correction.contains("Re-issue"))
    }

    @Test("max_tokens truncation without tool use → retry to continue")
    func maxTokensRetries() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "max_tokens", hasToolUse: false, hasPendingTools: false,
            responseText: "half a thought", openCriteria: [], retriesUsed: 0)
        guard case .retry(let correction, _) = route else {
            Issue.record("Expected .retry, got .proceed"); return
        }
        #expect(correction.contains("Output token limit hit"))
        #expect(correction.contains("smaller pieces"))
    }

    @Test("10.1: max_tokens continuations use their own counter and cap")
    func maxTokensOwnCounter() {
        // Shared counter exhausted (3 malformed bounces) — truncation still continues
        let route = AgentViewModel.routeStopReason(
            stopReason: "max_tokens", hasToolUse: false, hasPendingTools: false,
            responseText: "", openCriteria: [], retriesUsed: 3, maxTokensRetriesUsed: 0)
        guard case .retry = route else { Issue.record("Expected .retry"); return }
        // Own cap reached → proceed even with the shared counter fresh
        let capped = AgentViewModel.routeStopReason(
            stopReason: "max_tokens", hasToolUse: false, hasPendingTools: false,
            responseText: "", openCriteria: [], retriesUsed: 0, maxTokensRetriesUsed: 3)
        #expect(capped == .proceed)
    }

    @Test("10.1: escalation doubles to 64K but never past the context window; tiny windows get none")
    func maxTokensEscalationBounds() {
        // 1M window: plain doubling
        #expect(AgentViewModel.escalatedMaxTokens(current: 16_384, contextWindow: 1_000_000, lastInputTokens: 50_000) == 32_768)
        // Cap at 64K
        #expect(AgentViewModel.escalatedMaxTokens(current: 48_000, contextWindow: 1_000_000, lastInputTokens: 50_000) == 64_000)
        // 32K window with 10K input: room = 21K → 16384 fits
        #expect(AgentViewModel.escalatedMaxTokens(current: 8_192, contextWindow: 32_000, lastInputTokens: 10_000) == 16_384)
        // 16K window with 6K input: room 9K < 16384 → bumped only to what fits
        #expect(AgentViewModel.escalatedMaxTokens(current: 8_192, contextWindow: 16_000, lastInputTokens: 6_000) == 9_000)
        // 16K window with 8K input: room 7K < current → nothing to gain
        #expect(AgentViewModel.escalatedMaxTokens(current: 8_192, contextWindow: 16_000, lastInputTokens: 8_000) == nil)
        // 4K window: never
        #expect(AgentViewModel.escalatedMaxTokens(current: 8_192, contextWindow: 4_096, lastInputTokens: 0) == nil)
        #expect(AgentViewModel.escalatedMaxTokens(current: 0, contextWindow: 200_000, lastInputTokens: 0) == nil)
    }

    @Test("end_turn with open goal criteria → retry listing the criteria")
    func openCriteriaRetries() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "end_turn", hasToolUse: false, hasPendingTools: false,
            responseText: "all done!", openCriteria: ["build passes"], retriesUsed: 0)
        guard case .retry(let correction, _) = route else {
            Issue.record("Expected .retry, got .proceed"); return
        }
        #expect(correction.contains("build passes"))
    }

    @Test("end_turn claiming an action without a tool call → retry")
    func actionClaimRetries() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "end_turn", hasToolUse: false, hasPendingTools: false,
            responseText: "I searched the repo and found nothing.",
            openCriteria: [], retriesUsed: 0)
        guard case .retry(let correction, _) = route else {
            Issue.record("Expected .retry, got .proceed"); return
        }
        #expect(correction.contains("action not performed"))
    }

    @Test("Retry cap: 3 retries used → always proceed")
    func retryCapProceeds() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "tool_use", hasToolUse: false, hasPendingTools: false,
            responseText: "", openCriteria: ["x"], retriesUsed: 3)
        #expect(route == .proceed)
    }

    @Test("Normal tool_use turn → proceed")
    func normalTurnProceeds() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "tool_use", hasToolUse: true, hasPendingTools: true,
            responseText: "", openCriteria: [], retriesUsed: 0)
        #expect(route == .proceed)
    }

    // MARK: - GoalStateStore (evidence-gated completion)

    private func freshGoalStore() -> GoalStateStore {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HarnessGuardTests-\(UUID().uuidString)", isDirectory: true)
        return GoalStateStore(directory: dir)
    }

    @Test("New goal starts with all criteria open")
    func goalStartsOpen() {
        let store = freshGoalStore()
        let state = store.set(goal: "Ship feature", criteria: ["builds", "tests pass"])
        #expect(state.openCriteria.count == 2)
        #expect(!state.allCriteriaDone)
        #expect(!store.isVerified)
    }

    @Test("Criterion marked done WITHOUT evidence is flagged unevidenced")
    func unevidencedFlagged() {
        let store = freshGoalStore()
        store.set(goal: "g", criteria: ["builds"])
        _ = store.setCriterion(text: "builds", done: true, evidence: nil)
        #expect(store.unevidencedCriteria.count == 1)
    }

    @Test("Criterion marked done WITH evidence verifies the goal")
    func evidencedVerifies() {
        let store = freshGoalStore()
        store.set(goal: "g", criteria: ["builds"])
        _ = store.setCriterion(text: "builds", done: true, evidence: "xcode build succeeded")
        #expect(store.unevidencedCriteria.isEmpty)
        #expect(store.isVerified)
    }

    @Test("Prompt block lists open criteria and blocks task_complete")
    func goalPromptBlock() {
        let store = freshGoalStore()
        store.set(goal: "Ship it", criteria: ["builds"])
        let block = store.promptBlock
        #expect(block.contains("Ship it"))
        #expect(block.contains("[ ] builds"))
        #expect(block.contains("may NOT call task_complete"))
    }

    @Test("Clear removes the goal entirely")
    func goalClear() {
        let store = freshGoalStore()
        store.set(goal: "g", criteria: ["c"])
        store.clear()
        #expect(store.current == nil)
        #expect(store.isVerified) // no goal = nothing to verify
    }

    // MARK: - PlanStateStore (plan surfacing)

    /// Create a temp "git repo" with a plan file; returns the repo root.
    private func makePlanRepo(planMarkdown: String?) throws -> String {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlanRepo-\(UUID().uuidString)", isDirectory: true)
        let fm = FileManager.default
        try fm.createDirectory(at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
        if let md = planMarkdown {
            let plans = root.appendingPathComponent(".agent/plans", isDirectory: true)
            try fm.createDirectory(at: plans, withIntermediateDirectories: true)
            try md.write(to: plans.appendingPathComponent("plan_main.md"), atomically: true, encoding: .utf8)
        }
        return root.path
    }

    @Test("Active plan with open steps is surfaced in the prompt block")
    func planSurfaced() throws {
        let md = """
        # My Plan

        - [✅] 1. Done step
        - [ ] 2. Open step

        ---
        *Status: 1 done*
        """
        let root = try makePlanRepo(planMarkdown: md)
        let block = PlanStateStore.promptBlock(projectFolder: root)
        #expect(block.contains("ACTIVE PLAN — My Plan (1/2 done)"))
        #expect(block.contains("Open step"))
        #expect(block.contains("plan_mode"))
    }

    @Test("Fully completed plan produces no prompt block")
    func completedPlanSilent() throws {
        let md = "# Done Plan\n\n- [✅] 1. a\n- [✅] 2. b\n"
        let root = try makePlanRepo(planMarkdown: md)
        #expect(PlanStateStore.promptBlock(projectFolder: root).isEmpty)
    }

    @Test("No plan file produces no prompt block")
    func noPlanSilent() throws {
        let root = try makePlanRepo(planMarkdown: nil)
        #expect(PlanStateStore.promptBlock(projectFolder: root).isEmpty)
    }

    @Test("Folder outside a git repo produces no prompt block")
    func noGitRepoSilent() {
        #expect(PlanStateStore.promptBlock(projectFolder: "/tmp").isEmpty)
    }

    // MARK: - Tier 10.4: periodic goal-state reminder

    @Test("10.4: open criteria are re-listed every 10 turns unless goal_state was touched")
    func goalReminderCadence() {
        let open = ["build passes", "tests green"]
        // Not yet 10 turns since last activity
        #expect(AgentViewModel.goalReminderBlock(openCriteria: open, iteration: 9, lastGoalActivity: 0) == nil)
        // 10 turns → reminder listing every open criterion
        let block = AgentViewModel.goalReminderBlock(openCriteria: open, iteration: 10, lastGoalActivity: 0)
        #expect(block?.contains("- build passes") == true)
        #expect(block?.contains("- tests green") == true)
        #expect(block?.contains("goal_state") == true)
        // goal_state call at iteration 8 resets the clock
        #expect(AgentViewModel.goalReminderBlock(openCriteria: open, iteration: 15, lastGoalActivity: 8) == nil)
        #expect(AgentViewModel.goalReminderBlock(openCriteria: open, iteration: 18, lastGoalActivity: 8) != nil)
        // Nothing open → never
        #expect(AgentViewModel.goalReminderBlock(openCriteria: [], iteration: 50, lastGoalActivity: 0) == nil)
    }

    // MARK: - Tier 10.5: cache-warmth reminder for ≥1M windows

    @Test("10.5: cache-warmth note fires once past 25% of a ≥1M window, never on small windows")
    func cacheWarmthReminder() {
        // 200K window → never, even at 90%
        #expect(AgentViewModel.cacheWarmthReminderBlock(contextWindow: 200_000, inputTokens: 180_000, alreadySent: false) == nil)
        // 1M window under 25% → nil
        #expect(AgentViewModel.cacheWarmthReminderBlock(contextWindow: 1_000_000, inputTokens: 249_000, alreadySent: false) == nil)
        // 1M window at 26% → note with usage and the restore_tool_result hint
        let note = AgentViewModel.cacheWarmthReminderBlock(contextWindow: 1_000_000, inputTokens: 260_000, alreadySent: false)
        #expect(note?.contains("260K of the 1M-token window (26%)") == true)
        #expect(note?.contains("restore_tool_result") == true)
        // Already sent → nil
        #expect(AgentViewModel.cacheWarmthReminderBlock(contextWindow: 1_000_000, inputTokens: 600_000, alreadySent: true) == nil)
        // No reported usage (estimate-only providers) → nil
        #expect(AgentViewModel.cacheWarmthReminderBlock(contextWindow: 1_000_000, inputTokens: 0, alreadySent: false) == nil)
    }

    // MARK: - Tier 10.3: input + max_tokens overflow

    @Test("10.3: 'A + B > C' overflow parses and lowers max_tokens instead of pruning")
    func inputPlusMaxTokensOverflow() {
        let msg = "invalid_request_error: input length and `max_tokens` exceed context limit: 28500 + 8192 > 32768"
        let parsed = AgentViewModel.parseInputPlusMaxTokensOverflow(msg)
        #expect(parsed?.input == 28_500)
        #expect(parsed?.maxTokens == 8_192)
        #expect(parsed?.limit == 32_768)
        // 32768 - 28500 - 1000 = 3268 → still above the 3000 floor
        #expect(AgentViewModel.loweredMaxTokens(limit: 32_768, input: 28_500) == 3_268)
        // Floor at 3000 even when nothing really fits
        #expect(AgentViewModel.loweredMaxTokens(limit: 16_000, input: 15_500) == 3_000)
        // Other overflow messages don't match → compaction path
        #expect(AgentViewModel.parseInputPlusMaxTokensOverflow("prompt is too long: 210000 tokens > 200000 maximum") == nil)
        #expect(AgentViewModel.parseInputPlusMaxTokensOverflow("max_tokens must be a positive integer") == nil)
    }

    // MARK: - Tier 10.2: retry delay

    @Test("10.2: retry delay is exponential with 25% jitter, capped at 32s; Retry-After wins")
    func retryDelayLadder() {
        #expect(LLMRateLimiter.retryDelay(attempt: 1, jitter: 0) == 0.5)
        #expect(LLMRateLimiter.retryDelay(attempt: 2, jitter: 0) == 1.0)
        #expect(LLMRateLimiter.retryDelay(attempt: 5, jitter: 0) == 8.0)
        #expect(LLMRateLimiter.retryDelay(attempt: 10, jitter: 0) == 32.0)
        #expect(LLMRateLimiter.retryDelay(attempt: 3, jitter: 0.25) == 2.5)
        // Random jitter stays within [base, base*1.25]
        let d = LLMRateLimiter.retryDelay(attempt: 4)
        #expect(d >= 4.0 && d <= 5.0)
        // Server-supplied Retry-After overrides the ladder
        #expect(LLMRateLimiter.retryDelay(attempt: 1, retryAfter: 17) == 17)
        #expect(LLMRateLimiter.parseRetryAfter("17") == 17)
    }

    // MARK: - Tier 9.1: oversized tool results persisted at emission

    @Test("Oversized shell output → preview + restore hint; small/read_file/restore pass through")
    func persistOversizedResult() {
        let big = (0..<3_000).map { "line \($0)" }.joined(separator: "\n") // > 20K chars
        let id = "toolu_persist_\(UUID().uuidString.prefix(8))"
        let preview = AgentViewModel.persistOversizedResult(tool: "user_shell", toolUseID: id, content: big)
        #expect(preview?.hasPrefix("<persisted-output>") == true)
        #expect(preview?.contains("restore_tool_result(tool_use_id:\"\(id)\")") == true)
        #expect((preview?.count ?? 0) < 3_000)
        #expect(ToolResultCache.restore(toolUseID: id) == big)
        // Already-persisted preview never persists again
        #expect(AgentViewModel.persistOversizedResult(tool: "user_shell", toolUseID: id, content: preview!) == nil)
        // Under threshold → verbatim
        #expect(AgentViewModel.persistOversizedResult(tool: "user_shell", toolUseID: id + "s", content: "short") == nil)
        // Exempt tools → verbatim even when huge
        #expect(AgentViewModel.persistOversizedResult(tool: "read_file", toolUseID: id + "r", content: big) == nil)
        #expect(AgentViewModel.persistOversizedResult(tool: "restore_tool_result", toolUseID: id + "x", content: big) == nil)
    }

    // MARK: - Critic gate plumbing

    @Test("uncommittedDiff returns empty for a non-repo folder")
    func criticDiffEmptyOutsideRepo() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NotARepo-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        #expect(AgentViewModel.uncommittedDiff(folder: dir.path).isEmpty)
    }
}
