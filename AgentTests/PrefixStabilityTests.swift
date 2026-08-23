import Testing
import Foundation
@testable import Agent_

// Prompt-cache prefix stability: between compaction events the message array
// must never change, so consecutive requests share a byte-identical prefix and
// provider prompt caches hit. Compaction may only mutate past the token
// threshold inside tieredCompact.

@MainActor
struct PrefixStabilityTests {

    private func serialize(_ messages: [[String: Any]]) -> Data {
        (try? JSONSerialization.data(withJSONObject: messages, options: [.sortedKeys])) ?? Data()
    }

    private func sampleMessages(toolResults: Int = 5, resultSize: Int = 400) -> [[String: Any]] {
        var messages: [[String: Any]] = [["role": "user", "content": "do the task"]]
        for i in 0..<toolResults {
            messages.append([
                "role": "assistant",
                "content": [
                    ["type": "text", "text": "calling tool \(i)"],
                    ["type": "tool_use", "id": "toolu_\(i)", "name": "read_file", "input": ["path": "/tmp/f\(i)"]]
                ]
            ])
            messages.append([
                "role": "user",
                "content": [
                    ["type": "tool_result", "tool_use_id": "toolu_\(i)",
                     "content": String(repeating: "line \(i)\n", count: resultSize / 8)]
                ]
            ])
        }
        return messages
    }

    private func withCompressionEnabled(_ body: () async -> Void) async {
        let saved = AppleIntelligenceMediator.shared.tokenCompressionEnabled
        AppleIntelligenceMediator.shared.tokenCompressionEnabled = true
        await body()
        AppleIntelligenceMediator.shared.tokenCompressionEnabled = saved
    }

    @Test("tieredCompact below threshold leaves messages byte-identical")
    func belowThresholdIsByteStable() async {
        await withCompressionEnabled {
            var messages = sampleMessages()
            let before = serialize(messages)
            var state = CompactionState()
            // Sample is a few KB — far below the 30K-token threshold.
            let compacted = await AgentViewModel.tieredCompact(&messages, state: &state)
            #expect(compacted == false)
            #expect(serialize(messages) == before)
        }
    }

    @Test("repeated sends without compaction produce an identical serialized prefix")
    func appendOnlyPrefixIsStable() async {
        await withCompressionEnabled {
            var messages = sampleMessages()
            var state = CompactionState()
            let turn1 = serialize(messages)
            _ = await AgentViewModel.tieredCompact(&messages, state: &state)
            // Simulate the next turn: the loop appends, never rewrites.
            let prefixCount = messages.count
            messages.append(["role": "assistant", "content": [["type": "text", "text": "next turn"]]])
            _ = await AgentViewModel.tieredCompact(&messages, state: &state)
            let turn2Prefix = serialize(Array(messages.prefix(prefixCount)))
            #expect(turn2Prefix == turn1)
        }
    }

    @Test("microcompact keeps the newest tool results intact and clears older ones")
    func microcompactKeepsRecent() async {
        await withCompressionEnabled {
            var messages = sampleMessages(toolResults: 6)
            AgentViewModel.microcompact(&messages, keepRecent: 3)

            var contents: [String] = []
            for msg in messages {
                guard let blocks = msg["content"] as? [[String: Any]] else { continue }
                for block in blocks where block["type"] as? String == "tool_result" {
                    contents.append(block["content"] as? String ?? "")
                }
            }
            #expect(contents.count == 6)
            #expect(contents.prefix(3).allSatisfy { $0 == "[cleared]" })
            #expect(contents.suffix(3).allSatisfy { $0 != "[cleared]" })
        }
    }

    @Test("microcompact is idempotent — a second pass changes nothing")
    func microcompactIdempotent() async {
        await withCompressionEnabled {
            var messages = sampleMessages(toolResults: 6)
            AgentViewModel.microcompact(&messages, keepRecent: 3)
            let after = serialize(messages)
            AgentViewModel.microcompact(&messages, keepRecent: 3)
            #expect(serialize(messages) == after)
        }
    }
}
