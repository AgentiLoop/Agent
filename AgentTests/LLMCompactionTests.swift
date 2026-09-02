import Testing
import Foundation
@testable import Agent_

// Tier 7 compaction: provider-side LLM summary replaces the transcript middle
// with a frozen `[first prompt] + summary + "Understood" + tail` shape, the
// threshold follows `window − reserved output − buffer`, and real
// input_tokens drive the trigger.

@MainActor
struct LLMCompactionTests {

    private func sample(rounds: Int) -> [[String: Any]] {
        var messages: [[String: Any]] = [["role": "user", "content": "do the task"]]
        for i in 0..<rounds {
            messages.append([
                "role": "assistant",
                "content": [["type": "tool_use", "id": "toolu_\(i)", "name": "read_file", "input": ["path": "/tmp/f\(i)"]]]
            ])
            messages.append([
                "role": "user",
                "content": [["type": "tool_result", "tool_use_id": "toolu_\(i)",
                             "content": String(repeating: "content \(i)\n", count: 40)]]
            ])
        }
        return messages
    }

    @Test("threshold reserves output + buffer instead of 55%")
    func thresholdFormula() {
        // 128K, default reserved 8_192, buffer 12_800 → 107_008
        #expect(CompactionState.threshold(for: 128_000) == 128_000 - 8_192 - 12_800)
        // 200K with 16K max_tokens: reserved 16_000, buffer 13_000
        #expect(CompactionState.threshold(for: 200_000, maxTokens: 16_000) == 171_000)
        // 1M: reserved capped at 20K, buffer 13K — no 400K clamp any more
        #expect(CompactionState.threshold(for: 1_000_000, maxTokens: 64_000) == 967_000)
        // Tiny window floors at 2K
        #expect(CompactionState.threshold(for: 4_096) == 2_000)
    }

    @Test("reported input_tokens override the chars/4 estimate")
    func usageDrivesMeasure() {
        var state = CompactionState(contextWindow: 200_000)
        let messages = sample(rounds: 3)
        let estimate = state.measuredTokens(for: messages)
        state.recordUsage(inputTokens: 150_000, messageCount: messages.count)
        #expect(state.measuredTokens(for: messages) == 150_000)
        #expect(estimate < 150_000)
        // Zero usage is ignored
        state.recordUsage(inputTokens: 0, messageCount: 1)
        #expect(state.lastReportedInputTokens == 150_000)
    }

    @Test("compactWithLLM rebuilds a frozen summary + tail and spills the middle")
    func llmCompactRebuild() async {
        var messages = sample(rounds: 10)
        var requestSeen = 0
        let ok = await AgentViewModel.compactWithLLM(&messages, keepRecent: 5, summarizer: { request in
            requestSeen = request.count
            // Summary request = full transcript + one user prompt
            #expect((request.last?["content"] as? String) == AgentViewModel.compactSummaryPrompt)
            return "1. Primary Request: do the task\n9. Next Step: keep going"
        })
        #expect(ok)
        #expect(requestSeen == 22)
        // [first] + [summary user] + [assistant ack] + 5 tail
        #expect(messages.count == 8)
        #expect((messages[0]["content"] as? String) == "do the task")
        let summaryText = messages[1]["content"] as? String ?? ""
        #expect(summaryText.contains("continued from a previous conversation"))
        #expect(summaryText.contains("9. Next Step: keep going"))
        #expect((messages[2]["content"] as? String) == "Understood, continuing.")
        // Tail starts with a user tool_result whose tool_use was dropped → demoted to text
        let tailFirst = messages[3]["content"] as? [[String: Any]] ?? []
        #expect(tailFirst.first?["type"] as? String == "text")
        // Second compaction on the same shape is idempotent in structure
        let again = await AgentViewModel.compactWithLLM(&messages, keepRecent: 5, summarizer: { _ in "x" })
        #expect(!again) // 8 messages ≤ keepRecent + 4 → untouched
        #expect(messages.count == 8)
    }

    @Test("compactWithLLM leaves messages untouched when the summarizer fails")
    func llmCompactFailureIsNoOp() async {
        var messages = sample(rounds: 10)
        let before = (try? JSONSerialization.data(withJSONObject: messages, options: [.sortedKeys])) ?? Data()
        var calls = 0
        let ok = await AgentViewModel.compactWithLLM(&messages, keepRecent: 4, summarizer: { _ in
            calls += 1
            return nil
        })
        #expect(!ok)
        // One full attempt + one shorter retry, then give up
        #expect(calls == 2)
        let after = (try? JSONSerialization.data(withJSONObject: messages, options: [.sortedKeys])) ?? Data()
        #expect(before == after)
    }

    @Test("microcompact never clears protected tool results")
    func microcompactProtectsGoalState() {
        var messages: [[String: Any]] = [["role": "user", "content": "go"]]
        let big = String(repeating: "x", count: 500)
        for i in 0..<6 {
            let name = i == 0 ? "goal_state" : "read_file"
            messages.append(["role": "assistant", "content": [["type": "tool_use", "id": "t\(i)", "name": name, "input": [:]]]])
            messages.append(["role": "user", "content": [["type": "tool_result", "tool_use_id": "t\(i)", "content": big]]])
        }
        AgentViewModel.microcompact(&messages, keepRecent: 2)
        let goalResult = (messages[2]["content"] as? [[String: Any]])?.first?["content"] as? String ?? ""
        #expect(goalResult == big)
        let oldRead = (messages[4]["content"] as? [[String: Any]])?.first?["content"] as? String ?? ""
        #expect(oldRead.hasPrefix("[cleared"))
    }

    @Test("7.6: continuation idle >60 min clears all but the last 5 tool results; fresh one untouched")
    func timeBasedMicrocompact() {
        let now = Date()
        var fresh = sample(rounds: 8)
        #expect(AgentViewModel.microcompactIfStale(&fresh, lastActivity: now.addingTimeInterval(-30 * 60), now: now) == false)
        let freshFirst = (fresh[2]["content"] as? [[String: Any]])?.first?["content"] as? String ?? ""
        #expect(freshFirst.hasPrefix("content 0"))
        // No prior task → nothing to do
        #expect(AgentViewModel.microcompactIfStale(&fresh, lastActivity: nil, now: now) == false)

        var stale = sample(rounds: 8)
        #expect(AgentViewModel.microcompactIfStale(&stale, lastActivity: now.addingTimeInterval(-61 * 60), now: now))
        let cleared = (0..<8).filter { i in
            ((stale[2 + i * 2]["content"] as? [[String: Any]])?.first?["content"] as? String ?? "").hasPrefix("[cleared")
        }
        #expect(cleared == [0, 1, 2])
    }
}
