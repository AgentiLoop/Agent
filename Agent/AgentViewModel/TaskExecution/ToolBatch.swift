
@preconcurrency import Foundation
import AgentTools
import AgentMCP
import AgentD1F
import AgentSwift
import Cocoa

// MARK: - Task Execution — Tool Batch Dispatch + Vision Verification

extension AgentViewModel {

    /// / Executes a set of pending tool calls from a single LLM turn. / / Consecutive read-only tools are partitioned
    /// into parallel batches that / pre-execute common shell reads off the main actor via a TaskGroup; the / results are stashed into `Self.precomputedResults` so the subsequent / `dispatchTool` calls return instantly. Write/mutating tools serialize. / Appends the tool results to `toolResults` via inout.
    func executePendingToolBatches(
        pendingTools: [(toolId: String, name: String, input: [String: Any])],
        toolResults: inout [[String: Any]]
    ) async {
        if !pendingTools.isEmpty {
            let maxConcurrency = 10
            // Partition into batches: consecutive read-only = parallel batch, write = serial batch
            var batches: [(parallel: Bool, tools: [(toolId: String, name: String, input: [String: Any])])] = []
            for tool in pendingTools {
                let isReadOnly = Self.readOnlyTools.contains(tool.name) || Self.isReadOnlyShellCall(tool.name, input: tool.input)
                if isReadOnly, let last = batches.last, last.parallel {
                    batches[batches.count - 1].tools.append(tool)
                } else {
                    batches.append((parallel: isReadOnly, tools: [tool]))
                }
            }

            for batch in batches {
                if batch.parallel && batch.tools.count > 1 {
                    // Parallel batch: pre-execute read-only tools off MainActor —
                    // INCLUDING read_file, which routes through the same lock-protected
                    // dedup/sha256 statics (dedupRead / recordReadEmission) that
                    // handleFileTool uses, so the read guards still run per-read.
                    let parallelTools: Set<String> = [
                        "read_file",
                        "list_files",
                        "search_files",
                        "read_dir",
                        "git_status",
                        "git_diff",
                        "git_log",
                        "git_diff_patch"
                    ]
                    let parallelBatch = batch.tools.filter {
                        parallelTools.contains($0.name) || Self.isReadOnlyShellCall($0.name, input: $0.input)
                    }
                    var preResults: [String: String] = [:]
                    if parallelBatch.count > 1 {
                        let capturedPF = projectFolder
                        let capturedTabID = selectedTabId ?? Self.mainTabID
                        let workDir = capturedPF.isEmpty ? NSHomeDirectory() : capturedPF
                        // Extract Sendable payloads on the main actor — the child
                        // task must not capture the non-Sendable [String: Any] input.
                        let payloads: [(toolId: String, readFile: (filePath: String, expanded: String, offset: Int?, limit: Int?)?, shellCmd: String?)] = parallelBatch.map { tool in
                            if tool.name == "read_file" {
                                let filePath = tool.input["file_path"] as? String ?? ""
                                return (
                                    tool.toolId,
                                    (
                                        filePath,
                                        (filePath as NSString).expandingTildeInPath,
                                        tool.input["offset"] as? Int,
                                        tool.input["limit"] as? Int
                                    ),
                                    nil
                                )
                            }
                            return (
                                tool.toolId,
                                nil,
                                Self.isReadOnlyShellCall(tool.name, input: tool.input)
                                    ? (tool.input["command"] as? String ?? "")
                                    : Self.buildReadOnlyCommand(name: tool.name, input: tool.input, projectFolder: capturedPF)
                            )
                        }
                        await withTaskGroup(of: (String, String).self) { group in
                            for (i, payload) in payloads.enumerated() where i < maxConcurrency {
                                let toolId = payload.toolId
                                let rf = payload.readFile
                                let cmd = payload.shellCmd
                                let tabID = capturedTabID
                                let workDirLocal = workDir
                                group.addTask {
                                    if let rf = rf {
                                        // Same guard sequence as handleFileTool's serial path.
                                        if let dedup = Self.dedupRead(
                                            tabID: tabID, expandedPath: rf.expanded,
                                            offset: rf.offset, limit: rf.limit)
                                        {
                                            return (toolId, dedup)
                                        }
                                        let out = CodingService.readFile(
                                            path: rf.filePath, offset: rf.offset, limit: rf.limit)
                                        Self.recordReadEmission(
                                            tabID: tabID, expandedPath: rf.expanded,
                                            offset: rf.offset, limit: rf.limit)
                                        return (toolId, out)
                                    }
                                    guard let cmd = cmd, !cmd.isEmpty else { return (toolId, "") }
                                    let pipe = Pipe(); let p = Process()
                                    p.executableURL = URL(fileURLWithPath: "/bin/zsh")
                                    p.arguments = ["-c", cmd]
                                    p.currentDirectoryURL = URL(fileURLWithPath: workDirLocal)
                                    var env = ProcessInfo.processInfo.environment
                                    env["HOME"] = NSHomeDirectory()
                                    // Match the AGENT_PROJECT_FOLDER contract used by every other
                                    // shell-execution path (executeTCC, UserService, HelperToolService).
                                    env["AGENT_PROJECT_FOLDER"] = workDirLocal
                                    env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:" +
                                        (env["PATH"] ?? "")
                                    p.environment = env; p.standardOutput = pipe; p.standardError = pipe
                                    try? p.run(); p.waitUntilExit()
                                    return (
                                        toolId,
                                        String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                                    )
                                }
                            }
                            for await (id, result) in group { preResults[id] = result }
                        }
                    }
                    // Consume the pre-executed results and dispatch everything else
                    // serially. This loop runs for EVERY parallel-eligible batch —
                    // including batches with <2 shell-parallelizable tools (e.g. two
                    // accessibility reads), which previously fell through the inner
                    // `parallelBatch.count > 1` check and were silently dropped,
                    // orphaning their tool_use ids.
                    for tool in batch.tools {
                        if let pre = preResults[tool.toolId] {
                            if let cmd = tool.input["command"] as? String, Self.userShellTools.contains(tool.name) {
                                appendLog("⚡ $ \(Self.collapseHeredocs(cmd)) (parallel, read-only)")
                            } else {
                                appendLog("⚡ \(tool.name) (parallel pre-exec)")
                            }
                            toolResults.append([
                                "type": "tool_result",
                                "tool_use_id": tool.toolId,
                                "content": pre
                            ])
                            continue
                        }
                        let ctx = ToolContext(
                            toolId: tool.toolId,
                            projectFolder: projectFolder,
                            selectedProvider: selectedProvider,
                            tavilyAPIKey: tavilyAPIKey
                        )
                        _ = await dispatchTool(name: tool.name, input: tool.input, ctx: ctx, toolResults: &toolResults)
                    }
                } else {
                    // Serial batch: execute one by one
                    for tool in batch.tools {
                        let ctx = ToolContext(
                            toolId: tool.toolId,
                            projectFolder: projectFolder,
                            selectedProvider: selectedProvider,
                            tavilyAPIKey: tavilyAPIKey
                        )
                        _ = await dispatchTool(name: tool.name, input: tool.input, ctx: ctx, toolResults: &toolResults)
                    }
                }
            }
            recordToolOutcomes(pendingTools: pendingTools, toolResults: &toolResults)
        }
    }

    /// Tier 9.2: user-shell tools whose command is a plain read (see
    /// `ShellSafetyService.isReadOnly`) join the parallel batch instead of
    /// serialising. `execute_daemon_command` (root) never does.
    nonisolated static let userShellTools: Set<String> = ["execute_agent_command", "run_shell_script"]

    nonisolated static func isReadOnlyShellCall(_ name: String, input: [String: Any]) -> Bool {
        guard userShellTools.contains(name), let cmd = input["command"] as? String else { return false }
        return ShellSafetyService.isReadOnly(cmd) && ShellSafetyService.check(cmd).allowed
    }

    /// Classify each executed tool's result and inject a one-shot advisory when
    /// a tool keeps failing this task, so the LLM changes approach instead of
    /// hammering the same broken call.
    func recordToolOutcomes(
        pendingTools: [(toolId: String, name: String, input: [String: Any])],
        toolResults: inout [[String: Any]]
    ) {
        var advisories: [String] = []
        for tool in pendingTools {
            guard let idx = toolResults.firstIndex(where: {
                ($0["type"] as? String) == "tool_result" && ($0["tool_use_id"] as? String) == tool.toolId
            }), let output = toolResults[idx]["content"] as? String else { continue }
            let isFailure = Self.isToolFailure(output: output)
            // Typed error annotation — append a stable error_code + recovery
            // hint directly onto the failing result so the model gets
            // structure instead of a bare string.
            if isFailure, let note = ToolErrorClassifier.annotation(tool: tool.name, output: output) {
                toolResults[idx]["content"] = output + note
            }
            ToolOutcomeStore.shared.record(
                tool: tool.name, output: output,
                isFailure: isFailure
            )
            if let advisory = ToolOutcomeStore.shared.advisory(for: tool.name) {
                advisories.append(advisory)
                appendLog(advisory)
            }
            // Tier 9.1: oversized output is spilled NOW, not only at compaction —
            // the model gets a preview + restore hint instead of 20K+ chars.
            if let full = toolResults[idx]["content"] as? String,
               let preview = Self.persistOversizedResult(tool: tool.name, toolUseID: tool.toolId, content: full)
            {
                toolResults[idx]["content"] = preview
                appendLog("💾 \(tool.name) output (\(full.count) chars) persisted — preview sent, restore_tool_result recovers it")
            }
        }
        // Plain text blocks — synthetic tool_results without a matching
        // tool_use would 400 at the API.
        for advisory in advisories {
            toolResults.append(["type": "text", "text": advisory])
        }
    }

    /// Tier 9.1: results longer than this are written to ToolResultCache at
    /// emission and replaced by a preview. read_file is exempt (it bounds
    /// itself and the model asked for exactly that range); restore_tool_result
    /// is exempt so recovering a persisted result doesn't persist it again.
    static let persistResultChars = 20_000
    static let persistPreviewChars = 2_000
    static let persistExemptTools: Set<String> = ["read_file", "restore_tool_result"]

    /// Spill `content` when it exceeds `persistResultChars` and return the
    /// preview block to send instead; nil when the result should go verbatim.
    static func persistOversizedResult(tool: String, toolUseID: String, content: String) -> String? {
        guard !persistExemptTools.contains(tool),
              content.count > persistResultChars,
              !content.hasPrefix("<persisted-output>") else { return nil }
        ToolResultCache.spill(toolUseID: toolUseID, content: content)
        guard ToolResultCache.restore(toolUseID: toolUseID) != nil else { return nil }
        let head = String(content.prefix(persistPreviewChars))
        return """
            <persisted-output>
            \(head)
            …
            [\(content.count) chars total — first \(persistPreviewChars) shown. \
            Full output preserved on disk: call restore_tool_result(tool_use_id:"\(toolUseID)") to read all of it. \
            Do NOT re-run the tool.]
            </persisted-output>
            """
    }

    /// / Vision verification: auto-screenshot after UI actions so the LLM can see the result. / OPT-IN via
    /// `visionAutoScreenshotEnabled` (Settings → Vision Auto-Screenshot). / Default OFF because it (1) hogs the main thread on every UI iteration, / (2) bloats every prompt with a base64 image even for non-vision models, / and (3) the next accessibility(find_element) query usually tells the LLM / what happened just as well, without the screenshot cost.
    func runVisionAutoScreenshotIfNeeded(
        pendingTools: [(toolId: String, name: String, input: [String: Any])],
        isVision: Bool,
        toolResults: inout [[String: Any]]
    ) async {
        if visionAutoScreenshotEnabled && isVision && !pendingTools.isEmpty {
            let uiActions: Set<String> = [
                "ax_click",
                "ax_click_element",
                "ax_perform_action",
                "ax_type_text",
                "ax_type_into_element",
                "ax_open_app",
                "ax_scroll",
                "ax_drag",
                "click",
                "click_element",
                "perform_action",
                "type_text",
                "open_app",
                "web_click",
                "web_type",
                "web_navigate"
            ]
            let hadUIAction = pendingTools.contains { uiActions.contains($0.name) }
            if hadUIAction {
                let screenshotResult = await Self.captureVerificationScreenshot()
                if let imageData = screenshotResult {
                    // Use plain text+image blocks rather than a synthetic `tool_result`:
                    // Anthropic rejects `tool_result` blocks whose `tool_use_id` has no
                    // matching `tool_use` in the prior assistant message.
                    toolResults.append([
                        "type": "text",
                        "text": "[Auto-screenshot after UI action — verify the action succeeded]"
                    ])
                    toolResults.append([
                        "type": "image",
                        "source": ["type": "base64", "media_type": "image/png", "data": imageData]
                    ])
                    appendLog("📸 Vision: auto-screenshot for verification")
                }
            }
        }
    }
}
