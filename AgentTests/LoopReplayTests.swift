import Testing
import Foundation
@testable import Agent_

// Fixture-replay coverage for the task loop's decision layer: routeStopReason
// (stop_reason-driven control) and turnDecision (completion detection), plus
// end-to-end scripted scenarios driven through the same decision order the
// real loop uses. Pure functions only — no UI, no stores, no user data.

// MARK: - Scripted turn fixtures

/// One scripted LLM turn as the loop's decision layer sees it.
private struct ScriptedTurn {
    var stopReason: String
    var text: String = ""
    var hasToolUse: Bool = false
    /// Tools parsed AND executed successfully this turn.
    var hasToolResults: Bool = false
}

/// What the replay driver concluded for a turn.
private enum ReplayEvent: Equatable {
    case retried(log: String)
    case continued
    case completed
}

/// Mirrors the real loop's decision order: routeStopReason first (corrective
/// bounce), then turnDecision (completion detection).
@MainActor
private func replay(_ turns: [ScriptedTurn], openCriteria: [String] = []) -> [ReplayEvent] {
    var events: [ReplayEvent] = []
    var retries = 0
    for turn in turns {
        let route = AgentViewModel.routeStopReason(
            stopReason: turn.stopReason,
            hasToolUse: turn.hasToolUse,
            hasPendingTools: turn.hasToolResults,
            responseText: turn.text,
            openCriteria: openCriteria,
            retriesUsed: retries
        )
        if case .retry(_, let log) = route {
            retries += 1
            events.append(.retried(log: log))
            continue
        }
        switch AgentViewModel.turnDecision(
            responseText: turn.text,
            hasToolUse: turn.hasToolUse,
            hasToolResults: turn.hasToolResults
        ) {
        case .continueLoop:
            events.append(.continued)
        default:
            events.append(.completed)
        }
    }
    return events
}

// MARK: - routeStopReason

@MainActor
struct RouteStopReasonTests {

    @Test("tool_use stop with nothing parsed asks for a re-issue")
    func malformedToolCall() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "tool_use", hasToolUse: false, hasPendingTools: false,
            responseText: "", openCriteria: [], retriesUsed: 0)
        guard case .retry(let correction, _) = route else { Issue.record("expected retry"); return }
        #expect(correction.contains("Re-issue"))
    }

    @Test("max_tokens truncation continues instead of completing")
    func maxTokensContinues() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "max_tokens", hasToolUse: false, hasPendingTools: false,
            responseText: "half an ans", openCriteria: [], retriesUsed: 0)
        guard case .retry(let correction, _) = route else { Issue.record("expected retry"); return }
        #expect(correction.contains("truncated"))
    }

    @Test("end_turn with open goal criteria nudges with the specific list")
    func endTurnWithOpenCriteria() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "end_turn", hasToolUse: false, hasPendingTools: false,
            responseText: "All done!", openCriteria: ["build succeeds", "tests pass"], retriesUsed: 0)
        guard case .retry(let correction, _) = route else { Issue.record("expected retry"); return }
        #expect(correction.contains("build succeeds"))
        #expect(correction.contains("tests pass"))
    }

    @Test("action claims without a tool call get the fallback correction")
    func actionClaimsFallback() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "end_turn", hasToolUse: false, hasPendingTools: false,
            responseText: "I searched the codebase and found the bug.", openCriteria: [], retriesUsed: 0)
        guard case .retry(let correction, _) = route else { Issue.record("expected retry"); return }
        #expect(correction.contains("action not performed"))
    }

    @Test("a clean text answer proceeds untouched")
    func cleanAnswerProceeds() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "end_turn", hasToolUse: false, hasPendingTools: false,
            responseText: "The answer is 42.", openCriteria: [], retriesUsed: 0)
        #expect(route == .proceed)
    }

    @Test("normal tool turns proceed")
    func toolTurnProceeds() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "tool_use", hasToolUse: true, hasPendingTools: true,
            responseText: "", openCriteria: [], retriesUsed: 0)
        #expect(route == .proceed)
    }

    @Test("the retry cap prevents an infinite correction loop")
    func retryCap() {
        let route = AgentViewModel.routeStopReason(
            stopReason: "tool_use", hasToolUse: false, hasPendingTools: false,
            responseText: "", openCriteria: [], retriesUsed: 3)
        #expect(route == .proceed)
    }
}

// MARK: - turnDecision

@MainActor
struct TurnDecisionTests {

    @Test("tool results continue the loop")
    func toolResultsContinue() {
        #expect(AgentViewModel.turnDecision(
            responseText: "", hasToolUse: true, hasToolResults: true) == .continueLoop)
    }

    @Test("task_complete written as text extracts the summary")
    func textCommandExtractsSummary() {
        let d = AgentViewModel.turnDecision(
            responseText: #"I'm done. task_complete(summary: "Fixed the crash")"#,
            hasToolUse: false, hasToolResults: false)
        #expect(d == .completeTextCommand(summary: "Fixed the crash"))
    }

    @Test("done-signal phrasing completes with a summary")
    func doneSignalCompletes() {
        let d = AgentViewModel.turnDecision(
            responseText: "Everything builds now, so the task is complete.",
            hasToolUse: false, hasToolResults: false)
        guard case .completeDoneSignal = d else { Issue.record("expected doneSignal, got \(d)"); return }
    }

    @Test("plain text answers complete as text-only")
    func plainTextCompletes() {
        let d = AgentViewModel.turnDecision(
            responseText: "The build setting lives in project.pbxproj.",
            hasToolUse: false, hasToolResults: false)
        #expect(d == .completeTextOnly(summary: "The build setting lives in project.pbxproj."))
    }

    @Test("stop phrase alongside tool calls completes silently")
    func stopPhraseWithTools() {
        let d = AgentViewModel.turnDecision(
            responseText: "Nothing more to do here.",
            hasToolUse: true, hasToolResults: false)
        #expect(d == .completeStopPhrase)
    }
}

// MARK: - Scenario replays

@MainActor
struct LoopReplayScenarioTests {

    @Test("happy path: tool turns then explicit completion")
    func happyPath() {
        let events = replay([
            ScriptedTurn(stopReason: "tool_use", hasToolUse: true, hasToolResults: true),
            ScriptedTurn(stopReason: "tool_use", hasToolUse: true, hasToolResults: true),
            ScriptedTurn(stopReason: "end_turn",
                         text: #"task_complete(summary: "Refactored and built")"#)
        ])
        #expect(events == [.continued, .continued, .completed])
    }

    @Test("malformed tool call recovers on the next turn")
    func toolErrorRecovery() {
        let events = replay([
            ScriptedTurn(stopReason: "tool_use"), // nothing parsed
            ScriptedTurn(stopReason: "tool_use", hasToolUse: true, hasToolResults: true),
            ScriptedTurn(stopReason: "end_turn", text: #"done(summary: "ok")"#)
        ])
        guard case .retried = events[0] else { Issue.record("expected retry first"); return }
        #expect(Array(events.dropFirst()) == [.continued, .completed])
    }

    @Test("max_tokens truncation is not treated as completion")
    func truncationScenario() {
        let events = replay([
            ScriptedTurn(stopReason: "max_tokens", text: "Here is the first half of"),
            ScriptedTurn(stopReason: "end_turn", text: "the rest of the answer.")
        ])
        guard case .retried = events[0] else { Issue.record("expected retry"); return }
        #expect(events[1] == .completed)
    }

    @Test("open criteria bounce premature completion, then the cap releases it")
    func goalCriteriaScenario() {
        let stubborn = Array(repeating: ScriptedTurn(stopReason: "end_turn", text: "I'm done!"), count: 5)
        let events = replay(stubborn, openCriteria: ["tests pass"])
        let retryCount = events.filter { if case .retried = $0 { return true }; return false }.count
        #expect(retryCount == 3) // capped
        #expect(events.last == .completed)
    }

    @Test("tool-outcome advisory fires once at the failure threshold and chronic tools surface at task start")
    func toolOutcomeLearning() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AgentOutcomeTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let store = ToolOutcomeStore.shared
        store.startTask(projectFolder: dir.path)

        for _ in 0..<2 { store.record(tool: "selenium", output: "Error: no session", isFailure: true) }
        #expect(store.advisory(for: "selenium") == nil) // below threshold
        store.record(tool: "selenium", output: "Error: no session", isFailure: true)
        let advisory = store.advisory(for: "selenium")
        #expect(advisory?.contains("selenium has failed 3x") == true)
        #expect(store.advisory(for: "selenium") == nil) // one-shot per task

        // Push to chronic and verify the frozen prompt block on next task start.
        for _ in 0..<3 { store.record(tool: "selenium", output: "Error: no session", isFailure: true) }
        store.startTask(projectFolder: dir.path)
        #expect(store.promptBlock.contains("selenium"))
        #expect(store.advisory(for: "selenium") == nil) // task counters reset

        // A success clears chronic status.
        store.record(tool: "selenium", output: "OK", isFailure: false)
        store.startTask(projectFolder: dir.path)
        #expect(store.promptBlock.isEmpty)
        try? FileManager.default.removeItem(at: dir)
    }

    @Test("continuation sanitizer leaves no orphaned tool blocks")
    func sanitizerDropsOrphans() {
        let stale: [[String: Any]] = [
            ["role": "user", "content": "task"],
            ["role": "assistant", "content": [
                ["type": "tool_use", "id": "toolu_1", "name": "read_file", "input": [:]]
            ]],
            // tool_result missing → orphaned tool_use above; trailing assistant turn
            ["role": "assistant", "content": [["type": "text", "text": "hm"]]]
        ]
        let clean = AgentViewModel.sanitizeMessagesForContinuation(stale)
        for (i, msg) in clean.enumerated() {
            guard let blocks = msg["content"] as? [[String: Any]] else { continue }
            for block in blocks where (block["type"] as? String) == "tool_use" {
                let id = block["id"] as? String ?? ""
                let next = i + 1 < clean.count ? clean[i + 1] : [:]
                let results = (next["content"] as? [[String: Any]] ?? [])
                    .filter { ($0["type"] as? String) == "tool_result" }
                    .compactMap { $0["tool_use_id"] as? String }
                #expect(results.contains(id), "tool_use \(id) has no matching tool_result")
            }
        }
    }
}
