@preconcurrency import Foundation

extension AgentViewModel {
    /// The selected tab, or nil for Main.
    private var selectedScriptTab: ScriptTab? { selectedTabId.flatMap { tab(for: $0) } }

    /// Prompt history for whichever tab is currently selected.
    var currentTabPromptHistory: [String] { promptHistory(for: selectedScriptTab) }

    /// Prompt history of `tab` (nil = Main).
    func promptHistory(for tab: ScriptTab?) -> [String] {
        tab?.promptHistory ?? promptHistory
    }

    /// Display name for the currently selected tab.
    var currentTabName: String {
        if let selectedId = selectedTabId,
           let tab = tab(for: selectedId)
        {
            return tab.displayTitle
        }
        return "Main"
    }

    /// Error history for UI display — per-tab when a tab is selected, global for main
    var errorHistory: [String] { errorHistory(for: selectedScriptTab) }

    /// Error history of `tab` (nil = Main): per-tab for script tabs, global for Main and LLM tabs.
    func errorHistory(for tab: ScriptTab?) -> [String] {
        if let tab, !tab.isMainTab {
            return tab.tabErrors
        }
        return ErrorHistory.shared.recentErrors(limit: 50).map { error in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let time = formatter.string(from: error.timestamp)
            let message = error.message.truncate(to: 100)
            return "[\(time)] \(error.errorType): \(message)"
        }
    }

    /// Task summaries for UI display — per-tab when a tab is selected, global for main
    var taskSummaries: [String] { taskSummaries(for: selectedScriptTab) }

    /// Task summaries of `tab` (nil = Main): per-tab for script tabs, global for Main and LLM tabs.
    func taskSummaries(for tab: ScriptTab?) -> [String] {
        if let tab, !tab.isMainTab {
            return tab.tabTaskSummaries
        }
        return history.records.suffix(50).map { record in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            let time = formatter.string(from: record.date)
            return "[\(time)] \(record.prompt) → \(record.summary)"
        }
    }

    /// Clear prompt history for whichever tab is currently selected.
    func clearCurrentTabPromptHistory() { clearPromptHistory(of: selectedScriptTab) }

    /// Clear prompt history of `tab` (nil = Main).
    func clearPromptHistory(of tab: ScriptTab?) {
        if let tab {
            tab.promptHistory.removeAll()
            tab.historyIndex = -1
            tab.savedInput = ""
        } else {
            promptHistory.removeAll()
            historyIndex = -1
            savedInput = ""
            UserDefaults.standard.removeObject(forKey: "agentPromptHistory")
        }
    }

    /// Clear history by type: "Prompts", "Error History", or "Task Summaries".
    func clearHistory(type: String) { clearHistory(type: type, of: selectedScriptTab) }

    /// Clear `tab`'s history (nil = Main) by type: "Prompts", "Error History", or "Task Summaries".
    func clearHistory(type: String, of tab: ScriptTab?) {
        if let tab, !tab.isMainTab {
            switch type {
            case "Prompts":
                clearPromptHistory(of: tab)
            case "Error History":
                tab.tabErrors.removeAll()
            case "Task Summaries":
                tab.tabTaskSummaries.removeAll()
            default:
                break
            }
        } else {
            switch type {
            case "Prompts":
                clearPromptHistory(of: tab)
            case "Error History":
                ErrorHistory.shared.clear()
            case "Task Summaries":
                history.clearAll()
            default:
                break
            }
        }
    }
}
