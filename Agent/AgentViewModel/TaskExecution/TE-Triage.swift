
@preconcurrency import Foundation
import AgentTools
import AgentMCP
import AgentD1F
import AgentSwift
import Cocoa

// MARK: - Task Execution — Triage Result Handling

extension AgentViewModel {

    /// Outcome of triage result processing.
    /// - `completed`: the triage handler fully finished the task; caller should
    ///   return from executeTask immediately without touching cleanup.
    /// - `fallThroughToLLM`: triage did not fully handle the prompt; caller
    ///   should proceed into the cloud-LLM while-loop.
    enum TriageOutcome {
        case completed
        case fallThroughToLLM
    }

    /// Processes the result of `AppleIntelligenceMediator.triagePrompt`, mirroring the
    /// original inline switch: direct commands, Apple AI answers, accessibility-tool
    /// handoffs, and passthrough. Mutates `messages`, `completionSummary`, and
    /// `commandsRun` inout where needed and performs all side effects
    /// (history, logging, progress updates) exactly as the original inline code did.
    func handleTriageOutcome(
        _ triageResult: AppleIntelligenceMediator.TriageResult,
        prompt: String,
        cloudModelLogLine: String,
        messages: inout [[String: Any]],
        completionSummary: inout String
    ) async -> TriageOutcome {
        switch triageResult {
        case .answered(let reply):
            // Show in LLM Output, not LogView
            rawLLMOutput = reply
            displayedLLMOutput = reply
            dripDisplayIndex = reply.count
            appendLog("✅ Completed: \(String(reply.prefix(200)))")
            flushLog()
            completionSummary = String(reply.prefix(200))
            history.add(
                TaskRecord(prompt: prompt, summary: completionSummary, commandsRun: []),
                maxBeforeSummary: maxHistoryBeforeSummary,
                apiKey: apiKey,
                model: selectedModel
            )
            ChatHistoryStore.shared.endCurrentTask(summary: completionSummary)
            stopProgressUpdates()
            if agentReplyHandle != nil { sendProgressUpdate(reply) }
            flushLog()
            persistLogNow()
            isRunning = false
            isThinking = false
            return .completed
        case .passThrough:
            // Apple AI didn't handle the request — log the cloud LLM model now so the user sees which provider is
            // actually doing the work.
            appendLog(cloudModelLogLine)
            flushLog()
            return .fallThroughToLLM
        }
    }
}
