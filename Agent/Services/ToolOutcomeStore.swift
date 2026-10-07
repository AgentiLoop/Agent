import Foundation

/// Tracks per-tool success/failure outcomes so the agent stops repeating a
/// failing tool. Two layers:
/// - Task-scoped counts drive an in-task advisory after repeated failures.
/// - Per-project persisted counts ({project}/.agent/tool_outcomes.json) flag
///   chronically failing tools (missing TCC grant, dead selenium session) in
///   the system prompt at task start.
@MainActor
final class ToolOutcomeStore {
    static let shared = ToolOutcomeStore()

    struct Outcome: Codable {
        var successes: Int = 0
        var failures: Int = 0
        var lastError: String = ""
    }

    /// Failures of one tool within the current task before an advisory fires.
    static let advisoryThreshold = 3
    /// Persisted failures with zero successes that mark a tool as chronic.
    static let chronicThreshold = 5

    private(set) var taskFailures: [String: Int] = [:]
    private(set) var taskLastError: [String: String] = [:]
    private var advisedTools: Set<String> = []
    private var persisted: [String: Outcome] = [:]
    private var projectFolder: String = ""

    /// Frozen at task start so the system prompt stays byte-stable mid-task
    /// (mutating it per-turn would break prompt-cache prefix stability).
    private(set) var promptBlock: String = ""

    private var fileURL: URL? {
        guard !projectFolder.isEmpty else { return nil }
        return URL(fileURLWithPath: projectFolder)
            .appendingPathComponent(".agent/tool_outcomes.json")
    }

    /// Call at task start: resets task counts, loads the project's persisted
    /// outcomes, and freezes the chronic-failure prompt block for this task.
    func startTask(projectFolder: String) {
        self.projectFolder = projectFolder
        taskFailures = [:]
        taskLastError = [:]
        advisedTools = []
        persisted = [:]
        if let url = fileURL, let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: Outcome].self, from: data)
        {
            persisted = decoded
        }
        let chronic = persisted.filter {
            $0.value.failures >= Self.chronicThreshold && $0.value.successes == 0
        }
        if chronic.isEmpty {
            promptBlock = ""
        } else {
            let lines = chronic
                .sorted { $0.key < $1.key }
                .map { "- \($0.key): failed \($0.value.failures)x in this project (last: \(String($0.value.lastError.prefix(120))))" }
            promptBlock = "\n\nCHRONICALLY FAILING TOOLS IN THIS PROJECT — prefer alternatives:\n"
                + lines.joined(separator: "\n") + "\n"
        }
    }

    /// Record one tool call's outcome, classified by the shared failure check.
    func record(tool: String, output: String, isFailure: Bool) {
        var entry = persisted[tool] ?? Outcome()
        if isFailure {
            taskFailures[tool, default: 0] += 1
            taskLastError[tool] = String(output.prefix(300))
            entry.failures += 1
            entry.lastError = String(output.prefix(300))
        } else {
            entry.successes += 1
            // A success clears chronic status — reset the failure streak so a
            // fixed TCC grant or revived session stops being flagged.
            entry.failures = 0
        }
        persisted[tool] = entry
        save()
    }

    /// App-automation tools whose failures have an accessibility fallback. After
    /// two failures the third try should be accessibility, so a UI task works
    /// within three tries instead of retrying scripting until the budget runs out.
    static let accessibilityFallbackTools: Set<String> = [
        "applescript", "run_applescript", "run_osascript", "run_apple_script",
        "javascript", "execute_javascript", "run_javascript",
        "agent_script", "run_agent",
        "safari", "selenium", "web_open", "web_find", "web_click", "web_type",
    ]
    static let accessibilityFallbackThreshold = 2

    /// One-shot advisory once a tool crosses the in-task failure threshold.
    /// Returns nil when below threshold or already advised this task.
    func advisory(for tool: String) -> String? {
        let fallback = Self.accessibilityFallbackTools.contains(tool)
        guard let failures = taskFailures[tool],
              failures >= (fallback ? Self.accessibilityFallbackThreshold : Self.advisoryThreshold),
              !advisedTools.contains(tool) else { return nil }
        advisedTools.insert(tool)
        let lastError = taskLastError[tool] ?? ""
        if fallback {
            return "⚠️ \(tool) has failed \(failures)x this task (last: \(lastError)). "
                + "Do NOT try it a third time — do it with accessibility instead, which works on any app's UI: "
                + "accessibility(action:\"click_element\"|\"type_into_element\"|\"select_option\"|\"select_row\"|\"click_menu_item\"|\"press_key\"|\"read_text\", appBundleId:\"<app>\", title:\"<visible name>\"). "
                + "Not sure of the name? accessibility(action:\"read_text\", appBundleId:\"<app>\") lists what the window shows."
        }
        if tool == "accessibility" {
            return "⚠️ accessibility has failed \(failures)x this task (last: \(lastError)). "
                + "Do NOT repeat the same call — read the window first (action:\"read_text\" or \"get_children\") and address the element by the exact name "
                + "or the AppleScript-style reference it returns (title:\"button 2 of toolbar 1 of window 1\"), or use the app's AppleScript dictionary."
        }
        return "⚠️ \(tool) has failed \(failures)x this task (last: \(lastError)). "
            + "Do NOT repeat the same call — follow the error's recovery hint, "
            + "use a different tool, or tell the user why it cannot be done."
    }

    private func save() {
        guard let url = fileURL else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(persisted) {
            try? data.write(to: url, options: .atomic)
        }
    }
}
