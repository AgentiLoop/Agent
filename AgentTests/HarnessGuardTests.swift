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
        #expect(correction.contains("truncated"))
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

    // MARK: - ToolErrorClassifier (typed tool errors)

    @Test("old_string not found → old_string_not_found")
    func classifyOldString() {
        let err = ToolErrorClassifier.classify(
            tool: "edit_file", output: "Error: old_string not found in file")
        #expect(err?.code == "old_string_not_found")
    }

    @Test("Multiple matches → ambiguous_match")
    func classifyAmbiguous() {
        let err = ToolErrorClassifier.classify(
            tool: "edit_file", output: "Error: multiple matches for old_string")
        #expect(err?.code == "ambiguous_match")
    }

    @Test("No such file → file_not_found")
    func classifyFileNotFound() {
        let err = ToolErrorClassifier.classify(
            tool: "read_file", output: "Error: no such file or directory")
        #expect(err?.code == "file_not_found")
    }

    @Test("Permission denied → permission_denied")
    func classifyPermission() {
        let err = ToolErrorClassifier.classify(
            tool: "run_shell_script", output: "Error: Permission denied")
        #expect(err?.code == "permission_denied")
    }

    @Test("BUILD FAILED → build_failed")
    func classifyBuildFailed() {
        let err = ToolErrorClassifier.classify(
            tool: "xcode_build", output: "BUILD FAILED\nfoo.swift:10: error: ...")
        #expect(err?.code == "build_failed")
    }

    @Test("Timeout → timeout")
    func classifyTimeout() {
        let err = ToolErrorClassifier.classify(
            tool: "web", output: "Error: request timed out after 30s")
        #expect(err?.code == "timeout")
    }

    @Test("Connection refused → network_unreachable")
    func classifyNetwork() {
        let err = ToolErrorClassifier.classify(
            tool: "web_fetch", output: "Error: connection refused")
        #expect(err?.code == "network_unreachable")
    }

    @Test("AppleScript syntax error → script_syntax_error")
    func classifyScriptSyntax() {
        let err = ToolErrorClassifier.classify(
            tool: "run_applescript", output: "Error: syntax error: expected end of line")
        #expect(err?.code == "script_syntax_error")
    }

    @Test("Success output classifies as nil")
    func classifySuccessNil() {
        #expect(ToolErrorClassifier.classify(tool: "read_file", output: "line 1\nline 2") == nil)
        #expect(ToolErrorClassifier.annotation(tool: "read_file", output: "ok") == nil)
    }

    @Test("Annotation carries the error code inline")
    func annotationFormat() {
        let note = ToolErrorClassifier.annotation(
            tool: "edit_file", output: "Error: old_string not found")
        #expect(note?.contains("[error_code: old_string_not_found]") == true)
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
