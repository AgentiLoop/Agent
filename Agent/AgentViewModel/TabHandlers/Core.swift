@preconcurrency import Foundation
import AgentMCP
import AgentD1F
import Cocoa


extension AgentViewModel {

    /// Handle Core tool calls for tab tasks.
    func handleTabCoreTool(
        tab: ScriptTab, name: String, input: [String: Any], toolId: String
    ) async -> TabToolResult {

        switch name {
        case "task_complete":
            // Same completion gates the main loop runs (build / physical files /
            // critic). The goal gates are skipped: GoalStateStore is a global
            // singleton, so they'd block this tab on criteria the MAIN task set
            // (and the tab's routeStopReason already passes openCriteria: []).
            // For the same reason the tab never clears the store on success —
            // that would wipe a running main task's criteria out from under it.
            // Gate log lines go to THIS tab's log so the refusal reason is visible
            // next to the "⛔ refused" line instead of in the main log.
            // Blocked → feed the refusal back as this tool's result and keep the
            // tab task looping instead of ending it.
            let gateFolder = Self.resolvedWorkingDirectory(
                tab.projectFolder.isEmpty ? projectFolder : tab.projectFolder
            )
            if let blocker = await completionGateBlocker(
                commandsRun: tab.taskCommandsRun,
                projectFolder: gateFolder,
                skipGoalGates: true,
                log: { [weak tab] line in tab?.appendLog(line); tab?.flush() }
            ) {
                tab.appendLog("⛔ task_complete refused by completion gate")
                tab.flush()
                return TabToolResult(
                    toolResult: ["type": "tool_result", "tool_use_id": toolId, "content": blocker],
                    isComplete: false
                )
            }
            let summary = input["summary"] as? String ?? "Done"
            tab.appendLog("✅ Completed: \(summary)")
            tab.flush()

            // Apple Intelligence mediator summary (same as main task)
            let mediator = AppleIntelligenceMediator.shared
            if mediator.isEnabled && mediator.showAnnotationsToUser {
                if let summaryAnnotation = await mediator.summarizeCompletion(summary: summary, commandsRun: []) {
                    tab.appendLog(summaryAnnotation.formatted)
                    tab.flush()
                }
            }

            // If this is the Messages tab, reply to the iMessage sender
            if tab.isMessagesTab, let handle = tab.replyHandle {
                tab.replyHandle = nil
                sendMessagesTabReply(summary, handle: handle)
            }
            return TabToolResult(toolResult: nil, isComplete: true)

        case "plan_mode":
            let action = input["action"] as? String ?? "read"
            let output = Self.handlePlanMode(
                action: action, input: input,
                projectFolder: tab.projectFolder.isEmpty ? projectFolder : tab.projectFolder,
                tabName: tab.displayTitle, userPrompt: tab.currentTaskPrompt
            )
            tab.appendLog(output)
            tab.flush()
            return TabToolResult(
                toolResult: ["type": "tool_result", "tool_use_id": toolId, "content": output],
                isComplete: false
            )

        case "project_folder":
            let output = handleProjectFolder(tab: tab, input: input)
            tab.appendLog(output)
            tab.flush()
            return TabToolResult(
                toolResult: ["type": "tool_result", "tool_use_id": toolId, "content": output],
                isComplete: false
            )

        default:
            let output = await executeNativeTool(name, input: input)
            tab.appendLog(output); tab.flush()
            return tabResult(output, toolId: toolId)
        }
    }
}
