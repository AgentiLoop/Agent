
@preconcurrency import Foundation



// MARK: - Tab Task Stuck-File Guard

extension AgentViewModel {

    /// Detect consecutive edit failures on the same file and append a
    /// recovery nudge (at 2 failures) or give-up nudge (at 4 failures).
    /// Mirrors the stuck-file block in runOvernightCodingGuards but
    /// for the tab-task path. Thresholds match Guards.swift: nudge at 2,
    /// give up at 4.
    func appendStuckFileNudgeIfNeeded(
        tab: ScriptTab,
        name: String,
        input: [String: Any],
        toolResult: [String: Any],
        editTools: Set<String>,
        stuckFiles: inout [String: Int],
        toolResults: inout [[String: Any]]
    ) {
        guard editTools.contains(name),
              let path = input["file_path"] as? String ?? input["path"] as? String,
              let output = toolResult["content"] as? String
        else { return }
        let lower = output.lowercased()
        let isFailure = lower.hasPrefix("error") || lower.contains("error:") || lower.contains("failed") || lower
            .contains("not found") || lower.contains("rejected")
        if isFailure {
            stuckFiles[path, default: 0] += 1
            let count = stuckFiles[path]!
            if count == 2 {
                let nudge = """
                ⚠️ 2 consecutive edit failures on \(path). STOP retrying the same approach.

                Recovery checklist (do these in order):
                1. read_file(file_path:"\(path)") with NO offset/limit to get the FULL fresh content
                2. Find the EXACT lines you want to change in the new output. Do NOT trust the tool_result from earlier reads — the file may have been modified by your previous edits.
                3. For edit_file: copy old_string verbatim from the fresh read, including every space, tab, and newline.
                4. For diff_and_apply: pass start_line and end_line to scope the section.
                5. **REWIND**: file(action:"restore", file_path:"\(path)") recovers the most recent FileBackupService snapshot from before your edits. Backups are auto-created on every write_file/edit_file call.
                6. If you keep failing, switch tools — write_file to overwrite the whole file is a valid last resort.
                """
                toolResults.append(["type": "text", "text": nudge])
                tab.appendLog("⚠️ Stuck nudge: 2 failures on \((path as NSString).lastPathComponent)")
                tab.flush()
            } else if count >= 4 {
                let nudge = """
                    🛑 4 failures on \(path). Stop trying to edit \
                    this file. Move on to the next part of your task \
                    or call done with what you've completed so far.
                    """
                toolResults.append(["type": "text", "text": nudge])
                tab.appendLog("🛑 Stuck-out: 4 failures on \((path as NSString).lastPathComponent)")
                tab.flush()
                stuckFiles[path] = 0
            }
        } else {
            stuckFiles[path] = 0
        }
    }

    /// Tools where an identical repeat call is legitimate (polling, waiting,
    /// user dialog) and must NOT be flagged as a broken record.
    static let repeatExemptTools: Set<String> = [
        "task_complete",
        "send_message",
        "ask_user",
        "wait_for_element",
        "wait_adaptive",
        "find_element",
        "get_focused_element",
        "read_focused",
        "get_children",
        "list_windows",
        "screenshot",
        "get_properties"
    ]

    /// Deterministic fingerprint for a tool call: name + sorted-key JSON of the input.
    static func toolCallFingerprint(name: String, input: [String: Any]) -> String {
        let encoded: String
        if JSONSerialization.isValidJSONObject(input),
           let data = try? JSONSerialization.data(withJSONObject: input, options: [.sortedKeys]),
           let str = String(data: data, encoding: .utf8) {
            encoded = str
        } else {
            encoded = input.keys.sorted().map { "\($0)=\(String(describing: input[$0]!))" }.joined(separator: "&")
        }
        return "\(name)|\(encoded)"
    }

    /// Broken-record guard: the system prompt forbids repeating an identical tool
    /// call, but nothing enforced it for non-file tools (greps, builds, AppleScript).
    /// Fingerprints every call and nudges on the 2nd identical invocation, hard-stops
    /// nudging on the 3rd+.
    func appendRepeatedCallNudgeIfNeeded(
        tab: ScriptTab,
        name: String,
        input: [String: Any],
        repeatedCalls: inout [String: Int],
        toolResults: inout [[String: Any]]
    ) {
        guard !Self.repeatExemptTools.contains(name) else { return }
        let key = Self.toolCallFingerprint(name: name, input: input)
        repeatedCalls[key, default: 0] += 1
        let count = repeatedCalls[key]!
        guard count >= 2 else { return }
        let nudge: String
        if count == 2 {
            nudge = """
            🔁 BROKEN RECORD: you just called `\(name)` with the EXACT same input as a \
            previous call this task. The result will not change. Use the result you \
            already have in context, or change the input. Do NOT issue this call again.
            """
        } else {
            nudge = """
            🛑 `\(name)` has now been called \(count) times with identical input. You are \
            looping. Take a DIFFERENT action: make an edit, try a different tool, or call \
            task_complete and report what is still unknown.
            """
        }
        toolResults.append(["type": "text", "text": nudge])
        tab.appendLog("🔁 Repeat guard: \(name) ×\(count)")
        tab.flush()
    }
}
