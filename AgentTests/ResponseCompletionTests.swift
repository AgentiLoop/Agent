import Testing
import Foundation
@testable import Agent_

// Regression coverage for the same-turn task_complete fix (Response.swift):
// when the model answers with a tool call (e.g. a final status/handoff
// document write) AND task_complete in the SAME turn, the pending tools must
// execute BEFORE completion finalizes. The old early return silently dropped
// them — the status document never got written.
//
// Runs hosted in Agent!.app: AgentViewModel() skips startup work via the
// _started guard, so instantiating a bare view model here is cheap.
@MainActor
struct ResponseCompletionTests {

    private func makeContent(statusPath: String, summary: String) -> [[String: Any]] {
        [
            [
                "type": "tool_use",
                "id": "toolu_write_1",
                "name": "write_file",
                "input": [
                    "file_path": statusPath,
                    "content": "# Status\nStep 3 of 5 complete. Next: refactor TabTask."
                ] as [String: Any]
            ],
            [
                "type": "tool_use",
                "id": "toolu_complete_1",
                "name": "task_complete",
                "input": ["summary": summary] as [String: Any]
            ]
        ]
    }

    @Test("Same-turn status write executes before task_complete finalizes")
    func sameTurnWriteExecutesBeforeCompletion() async throws {
        // An active goal with open criteria would trip the completion gates and
        // block task_complete — clear it so the gates pass deterministically.
        GoalStateStore.shared.clear()

        let vm = AgentViewModel()
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("response-completion-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        let statusPath = tmpDir.appendingPathComponent("STATUS.md").path

        var annotations: [AppleIntelligenceMediator.Annotation] = []
        var filesEdited: Set<String> = []
        var summary = ""
        let result = await vm.parseLLMResponseContent(
            makeContent(statusPath: statusPath, summary: "Wrote handoff status"),
            prompt: "test: write status then complete",
            mediator: AppleIntelligenceMediator.shared,
            appleAIAnnotations: &annotations,
            filesEditedThisTask: &filesEdited,
            completionSummary: &summary
        )

        // Completion still finalizes...
        #expect(result.taskCompleted)
        #expect(summary == "Wrote handoff status")
        // ...but the same-turn write_file MUST have executed first (the bug was
        // that it was silently dropped by the early return).
        #expect(FileManager.default.fileExists(atPath: statusPath))
        let written = try String(contentsOfFile: statusPath, encoding: .utf8)
        #expect(written.contains("Step 3 of 5 complete"))
    }

    @Test("Pending tools are consumed — not handed back for double execution")
    func pendingToolsConsumedOnCompletion() async throws {
        GoalStateStore.shared.clear()

        let vm = AgentViewModel()
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("response-completion-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }
        let statusPath = tmpDir.appendingPathComponent("STATUS.md").path

        var annotations: [AppleIntelligenceMediator.Annotation] = []
        var filesEdited: Set<String> = []
        var summary = ""
        let result = await vm.parseLLMResponseContent(
            makeContent(statusPath: statusPath, summary: "Done"),
            prompt: "test: no double execution",
            mediator: AppleIntelligenceMediator.shared,
            appleAIAnnotations: &annotations,
            filesEditedThisTask: &filesEdited,
            completionSummary: &summary
        )

        // The tools already ran inside parseLLMResponseContent — the result must
        // not carry them back to the loop, or they would execute twice.
        #expect(result.taskCompleted)
        #expect(result.pendingTools.isEmpty)
    }
}
