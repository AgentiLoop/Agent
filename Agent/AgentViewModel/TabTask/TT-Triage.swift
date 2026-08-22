
@preconcurrency import Foundation
import AgentAccess
import AgentTools
import AgentAudit
import AgentLLM
import AppKit
import AgentMCP
import AgentD1F


// MARK: - Tab Task Triage

extension AgentViewModel {

    /// / Outcome of pre-LLM triage for a tab task. When `.passThrough` the caller / should fall through to the cloud
    /// LLM loop; when `.done` the task has / already been handled and the caller should return immediately. When / `.llmWithContext` the caller should pass the provided context string / through to the LLM as an additional user message.
    enum TabTaskTriageOutcome {
        case done
        case passThrough
        case llmWithContext(String)
    }

    /// Run triage: direct commands, Apple AI conversation, accessibility agent.
    /// Mirrors the triage block in the old monolithic executeTabTask.
    func runTabTaskTriage(
        tab: ScriptTab,
        prompt: String,
        completionSummary: inout String
    ) async -> TabTaskTriageOutcome {
        // Skip Apple AI when the user attached screenshots. Apple AI Foundation
        // Models are text-only — with no vision it hallucinates responses from
        // prompt text alone. Screenshots mean the user wants a vision-capable
        // model to look at the image.
        let hadAttachments = !tab.attachedImagesBase64.isEmpty || !attachedImagesBase64.isEmpty
        if hadAttachments { return .passThrough }
        // Triage: Apple AI answers greetings on-device, or passes through to the cloud LLM.
        let mediator = AppleIntelligenceMediator.shared
        let triageResult = await mediator.triagePrompt(prompt, appendLog: { msg in tab.appendLog(msg); tab.flush() })
        switch triageResult {
        case .answered(let reply):
            // Show in LLM Output, not LogView
            tab.rawLLMOutput = reply
            tab.displayedLLMOutput = reply
            tab.dripDisplayIndex = reply.count
            tab.appendLog("✅ Completed: \(String(reply.prefix(200)))")
            tab.flush()
            completionSummary = String(reply.prefix(200))
            history.add(
                TaskRecord(prompt: prompt, summary: completionSummary, commandsRun: []),
                maxBeforeSummary: maxHistoryBeforeSummary,
                apiKey: apiKey,
                model: selectedModel
            )
            tab.flush()
            if tab.isMessagesTab, let handle = tab.replyHandle {
                tab.replyHandle = nil
                sendMessagesTabReply(completionSummary, handle: handle)
            }
            tab.isLLMRunning = false
            tab.isLLMThinking = false
            return .done
        case .passThrough:
            return .passThrough
        }
    }
}
