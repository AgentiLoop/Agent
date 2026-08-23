
@preconcurrency import Foundation
import AgentTools
import AgentMCP
import AgentD1F
import AgentSwift
import Cocoa

// MARK: - Task Execution — Overnight Coding Guards + Stuck-File Detection

extension AgentViewModel {

    /// Tracks the set of files edited in the last N turns for cycle detection.
    /// When the same 2-3 files keep alternating, the LLM is stuck in an edit cycle.
    private static var recentEditFiles: [[String]] = []
    private static let cycleDetectionWindow = 6 // Number of turns to look back

    /// Detect cyclic edit patterns across multiple files. If the same 2-3 files
    /// keep alternating, emit a nudge to break the cycle.
    static func detectEditCycle(filePath: String, toolResults: inout [[String: Any]], appendNudge: (String, inout [[String: Any]]) -> Void) {
        recentEditFiles.append([filePath])
        if recentEditFiles.count > cycleDetectionWindow {
            recentEditFiles.removeFirst()
        }
        guard recentEditFiles.count >= 4 else { return }

        // Flatten all files edited in the window
        let allFiles = Set(recentEditFiles.flatMap { $0 })
        guard allFiles.count >= 2, allFiles.count <= 3 else { return }

        // Check that all files appear at least twice in the window
        let flatList = recentEditFiles.flatMap { $0 }
        let counts = Dictionary(flatList.map { ($0, 1) }, uniquingKeysWith: +)
        let allAppearMultipleTimes = counts.values.allSatisfy { $0 >= 2 }
        guard allAppearMultipleTimes else { return }

        let fileList = allFiles.sorted().map { ($0 as NSString).lastPathComponent }.joined(separator: ", ")
        let nudge = """
            🔄 You've edited \(fileList) in a cycle — alternating between the same \
            files without making progress. Step back: re-read ALL affected files, \
            plan your changes holistically, then make targeted edits. If the files \
            keep conflicting, consider whether the architecture needs a larger change.
            """
        appendNudge(nudge, &toolResults)
        // Reset to avoid repeated nudges
        recentEditFiles.removeAll()
    }

    /// Overnight coding guardrails — track runaway loops and nudge/stop. Returns true when error budget triggers.
    func runOvernightCodingGuards(
        pendingTools: [(toolId: String, name: String, input: [String: Any])],
        toolResults: inout [[String: Any]],
        consecutiveReadOnlyCount: inout Int,
        unbuiltEditCount: inout Int,
        consecutiveBuildFailures: inout Int,
        stuckFiles: inout [String: Int],
        isXcode: Bool
    ) -> Bool {
        // MARK: Overnight coding guards
        if !pendingTools.isEmpty {
            let editTools: Set<String> = ["write_file", "edit_file", "diff_apply", "apply_diff", "create_diff", "diff_and_apply"]
            let buildTools: Set<String> = ["xcode_build", "xc_build"]
            let actionTools: Set<String> = editTools.union(buildTools).union([
                "git_commit",
                "run_shell_script",
                "execute_agent_command",
                "execute_daemon_command",
                "task_complete"
            ])
            let automationPrefixes = ["ax_", "web_", "selenium_"]
            let automationTools: Set<String> = [
                "accessibility",
                "run_applescript",
                "run_osascript",
                "execute_javascript",
                "lookup_sdef",
                "ax",
                "web",
                "sel"
            ]
            let hadAction = pendingTools.contains { tool in
                actionTools.contains(tool.name)
                    || automationPrefixes.contains(where: { tool.name.hasPrefix($0) })
                    || automationTools.contains(tool.name)
            }
            let hadEdit = pendingTools.contains { editTools.contains($0.name) }
            let hadBuild = pendingTools.contains { buildTools.contains($0.name) }

              // Read guard removed — LLMs need freedom to research entire projects without interruption.
            if hadAction { consecutiveReadOnlyCount = 0 } else { consecutiveReadOnlyCount += pendingTools.count }

            // 2. Build enforcement — only for Xcode projects
            if isXcode {
                if hadEdit { unbuiltEditCount += 1 }
                if hadBuild { unbuiltEditCount = 0 }
                if unbuiltEditCount >= 3 {
                    let nudge = """
                        ⚠️ You've edited \(unbuiltEditCount) times \
                        without building. Run xc(action:"build") now \
                        to catch errors early.
                        """
                    appendNudgeToLastToolResult(&toolResults, nudge: nudge)
                }
            }

            // 3. Error budget — track consecutive build failures (Xcode only)
            for tool in pendingTools where isXcode && buildTools.contains(tool.name) {
                let buildOutput = resultContent(for: tool.toolId, in: toolResults)
                if buildOutput.contains("BUILD FAILED") || buildOutput.contains("error:") {
                    consecutiveBuildFailures += 1
                    // Offer the task-scoped rewind once, at 3 failures. The model
                    // has snapshots of every file it edited this task, so it can
                    // undo the whole failed attempt instead of patching blindly.
                    if consecutiveBuildFailures == 3 {
                        let touched = FileBackupService.shared.snapshottedFiles()
                        if !touched.isEmpty {
                            let nudge = """
                                🔄 3 consecutive build failures across \(touched.count) \
                                edited file(s). If the current approach isn't converging, \
                                call file(action:"rewind") to restore EVERY file this task \
                                touched to its pre-task state and start over with a \
                                different approach. Otherwise fix the specific error above.
                                """
                            appendNudge(&toolResults, toolId: tool.toolId, nudge: nudge)
                            appendLog("🔄 Offered task rewind after 3 build failures")
                            flushLog()
                        }
                    }
                    if consecutiveBuildFailures >= 5 {
                        appendLog("⚠️ Auto-stopping: 5 consecutive build failures")
                        flushLog()
                        break
                    }
                } else {
                    consecutiveBuildFailures = 0
                }
            }
            if consecutiveBuildFailures >= 5 { return true }

            // Stuck detection — track edit failures per file. Nudge at 2, give up at 4.
            for tool in pendingTools where editTools.contains(tool.name) {
                guard let path = tool.input["file_path"] as? String ?? tool.input["path"] as? String else { continue }
                let output = resultContent(for: tool.toolId, in: toolResults)
                // Shared with StuckGuard — see AgentViewModel.isToolFailure.
                let isFailure = Self.isToolFailure(output: output)
                if isFailure {
                    stuckFiles[path, default: 0] += 1
                    let count = stuckFiles[path]!
                    if count == 2 {
                        // First nudge — actionable recovery guidance
                        let nudge = """
                        ⚠️ 2 consecutive edit failures on \(path). STOP retrying the same approach.

                        Recovery checklist (do these in order):
                        1. read_file(file_path:"\(path)") with NO offset/limit to get the FULL fresh content
                        2. Find the EXACT lines you want to change in the new output. \
                        Do NOT trust the tool_result from earlier reads — the file may \
                        have been modified by your previous edits or by other code.
                        3. For edit_file: copy old_string verbatim from the fresh read, \
                        including every space, tab, and newline. Even one wrong character \
                        causes 'old_string not found'.
                        4. For diff_and_apply: pass start_line and end_line of the section \
                        you're editing so the section is small and unambiguous.
                        5. **If your edits look wrong, REWIND**: file(action:"restore", \
                        file_path:"\(path)") recovers the most recent FileBackupService snapshot \
                        of this file from before your edits. Backups are auto-created on every \
                        write_file/edit_file/diff_and_apply call.
                        6. If you keep failing, switch tools — write_file to overwrite \
                        the whole file is a valid last resort.
                        """
                        appendNudge(&toolResults, toolId: tool.toolId, nudge: nudge)
                        appendLog("⚠️ Stuck nudge: 2 failures on \((path as NSString).lastPathComponent)")
                        flushLog()
                    } else if count >= 4 {
                        // Second nudge — give up on this file
                        let nudge = """
                            🛑 4 failures on \(path). Stop trying to edit \
                            this file. Move on to the next part of your task \
                            or call done with what you've completed so far.
                            """
                        appendNudge(&toolResults, toolId: tool.toolId, nudge: nudge)
                        appendLog("🛑 Stuck-out: 4 failures on \((path as NSString).lastPathComponent)")
                        flushLog()
                        stuckFiles[path] = 0
                    }
                } else {
                    stuckFiles[path] = 0
                    // Cycle detection: track successful edits per file
                    Self.detectEditCycle(filePath: path, toolResults: &toolResults) { nudge, results in
                        appendNudge(&results, toolId: tool.toolId, nudge: nudge)
                        appendLog("🔄 Edit cycle detected")
                        flushLog()
                    }
                }
            }
        }
        return false
    }

    /// Content of the tool_result matching `toolId`. Guards must look results up
    /// by tool_use_id, not `toolResults.last` — on a batched turn (read_file +
    /// edit_file in one response) the last result belongs to a different tool and
    /// the guard would score the wrong output. Mirrors the id-matching in
    /// `recordToolOutcomes`.
    func resultContent(for toolId: String, in toolResults: [[String: Any]]) -> String {
        guard let match = toolResults.first(where: { $0["tool_use_id"] as? String == toolId }) else { return "" }
        return match["content"] as? String ?? ""
    }

    /// Append a nudge onto the tool_result for `toolId` so the guidance lands next
    /// to the output that triggered it. Falls back to the last result when the id
    /// isn't present (pre-executed batches, synthesized results).
    func appendNudge(_ toolResults: inout [[String: Any]], toolId: String, nudge: String) {
        guard let idx = toolResults.firstIndex(where: { $0["tool_use_id"] as? String == toolId }) else {
            appendNudgeToLastToolResult(&toolResults, nudge: nudge)
            return
        }
        let existing = (toolResults[idx]["content"] as? String) ?? ""
        toolResults[idx]["content"] = existing.isEmpty ? nudge : existing + "\n\n" + nudge
    }

    /// Append a nudge string onto the last tool_result's content so the LLM
    /// sees it alongside its tool output. Falls back to a `text` block (NOT a
    /// synthetic `tool_result` — Anthropic rejects `tool_use_id` values that
    /// have no matching `tool_use` in the prior assistant message).
    func appendNudgeToLastToolResult(_ toolResults: inout [[String: Any]], nudge: String) {
        if let lastIdx = toolResults.indices.last {
            let existing = (toolResults[lastIdx]["content"] as? String) ?? ""
            toolResults[lastIdx]["content"] = existing.isEmpty ? nudge : existing + "\n\n" + nudge
        } else {
            toolResults.append(["type": "text", "text": nudge])
        }
    }
}
