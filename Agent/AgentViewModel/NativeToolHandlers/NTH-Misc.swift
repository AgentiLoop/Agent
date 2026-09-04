
@preconcurrency import Foundation
import AgentTools
import AgentMCP
import AgentD1F
import AgentSwift
import AgentAccess
import Cocoa

// MARK: - Native Tool Handler — Misc (discovery, memory, skills, agents, web_fetch, task_complete)

extension AgentViewModel {

    /// / Handles list_tools, memory, skills, spawn_agent, ask_user, visual_test, / git_pr, create_project, web_fetch,
    /// tell_agent, task_complete. / Returns `nil` if the name is not a misc-group tool.
    func handleMiscNativeTool(name: String, input: [String: Any]) async -> String? {
        switch name {
        // Tool discovery
        case "list_tools":
            let prefs = ToolPreferencesService.shared
            let enabledTools = AgentTools.tools(for: selectedProvider)
                .filter { prefs.isEnabled(selectedProvider, $0.name) }
                .sorted { $0.name < $1.name }
            let builtIn = enabledTools.map { tool -> String in
                if let actionProp = tool.properties["action"],
                   let desc = actionProp["description"] as? String {
                    return "\(tool.name) (actions: \(desc))"
                }
                return tool.name
            }
            let mcp = MCPService.shared
            let mcpTools = mcp.discoveredTools
                .filter { mcp.isToolEnabled(serverName: $0.serverName, toolName: $0.name) }
                .sorted { $0.name < $1.name }
                .map { "mcp_\($0.serverName)_\($0.name)" }
            let all = builtIn + (mcpTools.isEmpty ? [] : ["--- MCP Tools ---"] + mcpTools)
            return all.joined(separator: "\n")
        // Memory tool — Claude-compatible (memory_20250818) filesystem-shaped
        // tool scoped to /memories/*. Maps onto MemoryStore's directory
        // (~/Documents/AgentScript/memory/). Commands mirror Anthropic's
        // hosted memory tool so prompts and agents stay portable across
        // providers; we run it locally rather than server-side.
        case "memory":
            return handleMemoryTool(input: input)
        // Recover a tool result that compaction truncated. ToolResultCache spills
        // the full text to .agent/toolcache before the truncation happens.
        case "restore_tool_result":
            let id = input["tool_use_id"] as? String ?? ""
            guard !id.isEmpty else { return "Error: 'tool_use_id' is required." }
            if let restored = ToolResultCache.restore(toolUseID: id) {
                return restored
            }
            let available = ToolResultCache.availableIDs()
            if available.isEmpty {
                return "No spilled tool result for '\(id)'. Nothing has been compacted yet."
            }
            return "No spilled tool result for '\(id)'. Available ids:\n"
                + available.joined(separator: "\n")
        // Skills — reusable prompt templates
        case "invoke_skill":
            let action = input["action"] as? String ?? "invoke"
            switch action {
            case "list":
                return SkillsService.shared.manifest()
            case "invoke":
                let name = input["name"] as? String ?? ""
                guard let skill = SkillsService.shared.load(name: name) else {
                    return "Skill '\(name)' not found. Use action=list to see available skills."
                }
                return "SKILL PROMPT [\(skill.name)]:\n\(skill.content)"
            case "save":
                let id = input["id"] as? String ?? input["name"] as? String ?? "untitled"
                let name = input["name"] as? String ?? id
                let desc = input["description"] as? String ?? ""
                let whenToUse = input["when_to_use"] as? String ?? ""
                let content = input["content"] as? String ?? ""
                let skill = Skill(id: id, name: name, description: desc, whenToUse: whenToUse, content: content)
                SkillsService.shared.save(skill)
                return "Saved skill '\(name)'."
            case "delete":
                let id = input["id"] as? String ?? ""
                SkillsService.shared.delete(id: id)
                return "Deleted skill '\(id)'."
            default:
                return "Unknown skill action. Use: list, invoke, save, delete."
            }
        // Sub-agent spawning — isolated concurrent task execution
        case "spawn_agent":
            let name = input["name"] as? String ?? "agent-\(subAgents.count + 1)"
            let prompt = input["prompt"] as? String ?? ""
            guard !prompt.isEmpty else { return "Error: prompt is required for spawn_agent." }
            // Configurable tool groups: "all" or comma-separated group names. The legacy 'coding' / 'automation'
            // aliases are gone with the rest of the mode system; pass explicit group names like "Core,Code,User" if you want to narrow a sub-agent's tool list.
            var toolGroups: Set<String>? = nil
            if let mode = input["tools"] as? String {
                if mode == "all" {
                    toolGroups = Set(Tool.allGroups)
                } else {
                    toolGroups = Set(mode.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) })
                }
            }
            let maxIter = input["max_iterations"] as? Int ?? 15
            let model = (input["model"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            return spawnSubAgent(name: name, prompt: prompt, toolGroups: toolGroups, maxIterations: maxIter, model: model)
        // AskUserQuestion — mid-task dialog, waits for user answer
        case "ask_user":
            let question = input["question"] as? String ?? ""
            guard !question.isEmpty else { return "Error: 'question' is required." }
            appendLog("❓ \(question)")
            flushLog()
            let answer = await awaitUserAnswer(question)
            appendLog("💬 \(answer)")
            flushLog()
            return "User answered: \(answer)"
        // WebFetch — read content from any URL
        // Visual test assertion — click element, verify text appears (opt-in)
        case "visual_test":
            guard visualTestsEnabled else { return "Error: Visual tests disabled. Enable in Coding Preferences." }
            let action = input["action"] as? String ?? "assert"
            switch action {
            case "click_and_verify":
                let clickRole = input["click_role"] as? String
                let clickTitle = input["click_title"] as? String
                let expectRole = input["expect_role"] as? String
                let expectTitle = input["expect_title"] as? String
                let app = input["appBundleId"] as? String
                // Click
                let clickResult = AccessibilityService.shared.clickElement(role: clickRole, title: clickTitle, value: nil, appBundleId: app)
                // Verify (AccessibilityService.findElement retries internally up to timeout)
                let findResult = AccessibilityService.shared.findElement(
                    role: expectRole, title: expectTitle,
                    value: nil, appBundleId: app, timeout: 5)
                let passed = findResult.contains("\"success\":true") || findResult.contains("\"success\": true")
                return "VISUAL TEST: \(passed ? "PASS" : "FAIL")\nClick: \(clickResult.prefix(200))\nVerify: \(findResult.prefix(200))"
            case "assert_exists":
                let role = input["role"] as? String
                let title = input["title"] as? String
                let app = input["appBundleId"] as? String
                let result = AccessibilityService.shared.findElement(role: role, title: title, value: nil, appBundleId: app, timeout: 5)
                let passed = result.contains("\"success\":true") || result.contains("\"success\": true")
                return "ASSERTION: \(passed ? "PASS" : "FAIL") — \(role ?? "any") '\(title ?? "any")'\n\(result.prefix(200))"
            default:
                return "Unknown visual_test action. Use: click_and_verify, assert_exists."
            }
        // Git PR workflow — create branch, commit, push, open PR (opt-in)
        case "git_pr":
            guard autoPREnabled else { return "Error: Auto PR disabled. Enable in Coding Preferences." }
            let action = input["action"] as? String ?? "create"
            let branch = input["branch"] as? String ?? "feature/agent-changes"
            let title = input["title"] as? String ?? "Agent! automated changes"
            let body = input["body"] as? String ?? ""
            let dir = projectFolder
            guard !dir.isEmpty else { return "Error: project folder required." }
            switch action {
            case "create":
                let cmds = [
                    "git checkout -b \(branch)",
                    "git add -A",
                    "git commit -m '\(title)'",
                    "git push -u origin \(branch)",
                    "gh pr create --title '\(title)' --body '\(body)' 2>&1 || echo 'Install gh CLI to create PRs automatically'"
                ].joined(separator: " && ")
                let result = await executeViaUserAgent(command: cmds, workingDirectory: dir)
                return result.output.isEmpty ? "PR created on branch \(branch)" : result.output
            default:
                return "Unknown git_pr action. Use: create."
            }
        // Project template — scaffold new Xcode project (opt-in)
        case "create_project":
            guard autoScaffoldEnabled else { return "Error: Project templates disabled. Enable in Coding Preferences." }
            let name = input["name"] as? String ?? "NewApp"
            let template = input["template"] as? String ?? "swiftui"
            let path = input["path"] as? String ?? projectFolder
            guard !path.isEmpty else { return "Error: path required." }

            // Use xcrun to create project via template
            let createCmd: String
            switch template {
            case "swiftui":
                let srcCode =
                    "import SwiftUI\\n"
                    + "@main struct \(name)App: App { "
                    + "var body: some Scene { "
                    + "WindowGroup { Text(\"Hello\") } } }"
                createCmd = """
                mkdir -p "\(path)/\(name)" \
                && cd "\(path)/\(name)" \
                && swift package init --type executable --name \(name) \
                && echo '\(srcCode)' > Sources/\(name).swift
                """
            case "cli":
                createCmd = "mkdir -p \"\(path)/\(name)\" && cd \"\(path)/\(name)\" && swift package init --type executable --name \(name)"
            case "library":
                createCmd = "mkdir -p \"\(path)/\(name)\" && cd \"\(path)/\(name)\" && swift package init --type library --name \(name)"
            default:
                return "Unknown template. Use: swiftui, cli, library."
            }
            let result = await executeViaUserAgent(command: createCmd, workingDirectory: path)
            return result.status == 0 ? "Project '\(name)' created at \(path)/\(name) (template: \(template))" : result.output
        case "web_fetch":
            let urlStr = input["url"] as? String ?? ""
            guard !urlStr.isEmpty else { return "Error: url is required for web_fetch. Recovery: pass url:\"https://example.com\"." }
            guard let url = URL(string: urlStr) else { return "Error: invalid URL '\(urlStr)'. Recovery: must start with http:// or https://." }
            appendLog("🌐 Fetch: \(urlStr)")
            flushLog()
            do {
                // Use a real browser User-Agent so sites don't 403 / serve weird responses
                var request = URLRequest(url: url)
                request.setValue(
                    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                    + "AppleWebKit/605.1.15 (KHTML, like Gecko) "
                    + "Version/17.0 Safari/605.1.15",
                    forHTTPHeaderField: "User-Agent")
                request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
                request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
                let (data, response) = try await URLSession.shared.data(for: request)
                let httpResponse = response as? HTTPURLResponse
                let statusCode = httpResponse?.statusCode ?? 0
                guard (200..<400).contains(statusCode) else {
                    return "Error: HTTP \(statusCode) for \(urlStr). Recovery: URL may be down or require auth. Try a different URL or check manually."
                }
                let raw = String(data: data, encoding: .utf8) ?? "(binary data, \(data.count) bytes)"
                let cleaned = Self.cleanHTML(raw)
                if cleaned.isEmpty {
                    return "(no readable text content at \(urlStr))"
                }
                return LogLimits.trim(cleaned, cap: LogLimits.webFetchChars)
            } catch {
                return "Error fetching \(urlStr): \(error.localizedDescription)"
            }
        // Inter-agent messaging — send message to a running sub-agent
        case "tell_agent":
            let to = input["to"] as? String ?? ""
            let message = input["message"] as? String ?? ""
            guard !to.isEmpty && !message.isEmpty else { return "Error: 'to' and 'message' are required." }
            return sendMessageToAgent(name: to, message: message)
        // Persistent goal state — set/read/mark/clear verification criteria
        case "goal_state":
            return handleGoalState(input: input)
        // Task complete — signal via NativeToolContext so the task loop can detect it
        case "task_complete":
            let summary = input["summary"] as? String ?? "Done"

            // All four completion gates (goal / build / evidence / physical files)
            // live in completionGateBlocker() so the main task loop — which handles
            // task_complete inline in parseLLMResponseContent and never reaches this
            // dispatch path — can run the exact same checks.
            if let blocker = await completionGateBlocker() { return blocker }

            // Gates passed → the goal is verified; retire it so it can't block
            // the next task's completion (mirrors parseLLMResponseContent).
            if GoalStateStore.shared.current != nil {
                GoalStateStore.shared.clear()
                appendLog("🎯 Goal verified — cleared")
            }

            let touched = FileBackupService.shared.snapshottedFiles()

            NativeToolContext.taskCompleteSummary = summary
            // Surface which files the task actually mutated so the user sees the
            // blast radius without having to ask.
            let editSummary = FileBackupService.shared.taskEditSummary()
            if touched.isEmpty {
                return "Task complete: \(summary)"
            }
            return "Task complete: \(summary)\n\n\(editSummary)"
        default:
            return nil
        }
    }

    /// The four completion gates. Returns a `CANNOT COMPLETE — ...` string when the
    /// task must NOT be allowed to finish, or nil when completion is permitted.
    /// Called from both the `task_complete` dispatch path and the main task loop's
    /// inline handler in `parseLLMResponseContent`.
    /// Refusals are capped per task (`maxCompletionGateRefusals`): after that many
    /// the gates step aside and log it, so a criterion the model can't satisfy
    /// doesn't loop the task all the way to the iteration cap.
    /// `commandsRun` / `projectFolder` default to the main loop's state. The tab
    /// loop keeps its own local commandsRun and may have its own folder, so it
    /// passes both explicitly — otherwise the verify build never saw tab edits
    /// and the critic diffed the wrong folder.
    /// `skipGoalGates`: the goal store is a global singleton, so a tab task's
    /// task_complete would otherwise be blocked on criteria the MAIN task set.
    /// Tab tasks pass `true` (they also pass `openCriteria: []` to routeStopReason
    /// for the same reason). `log` routes the gate's log lines — tab tasks pass
    /// `tab.appendLog` so the refusal reason lands in the tab's log, not the main one.
    func completionGateBlocker(
        commandsRun overrideCommands: [String]? = nil,
        projectFolder overrideFolder: String? = nil,
        skipGoalGates: Bool = false,
        log: ((String) -> Void)? = nil
    ) async -> String? {
        let log: (String) -> Void = log ?? { [weak self] line in
            self?.appendLog(line)
            self?.flushLog()
        }
        guard completionGateRefusals < Self.maxCompletionGateRefusals else {
            log("⚠️ Completion gates refused \(completionGateRefusals)× this task — allowing task_complete")
            return nil
        }
        guard let blocker = await runCompletionGates(
            commandsRun: overrideCommands ?? commandsRun,
            projectFolder: overrideFolder ?? projectFolder,
            skipGoalGates: skipGoalGates,
            log: log
        ) else { return nil }
        completionGateRefusals += 1
        return blocker
    }

    private func runCompletionGates(
        commandsRun: [String],
        projectFolder: String,
        skipGoalGates: Bool,
        log: (String) -> Void
    ) async -> String? {
        // Goal gate: every verification criterion must be marked done
        if !skipGoalGates, let goal = GoalStateStore.shared.current, !goal.allCriteriaDone {
            let open = goal.openCriteria
                .enumerated()
                .map { "\($0.offset + 1). \($0.element.text)" }
                .joined(separator: "\n")
            log("🎯 Goal gate: \(goal.openCriteria.count) unverified criteria — blocking completion")
            return """
                CANNOT COMPLETE — the active goal still has unverified criteria:

                \(open)

                Verify each with a tool call (build, grep, read, etc.), then mark it done \
                via goal_state(action: "mark") and call task_complete again.
                """
        }

        // Verification gate: if Xcode project + auto-verify + edits were made,
        // build must pass before task_complete is allowed
        // Match the names FileTools actually records in commandsRun:
        // "write_file: …", "edit_file: …", "diff_and_apply: …" (file(action:"diff_apply")),
        // "apply_diff: …", "create_diff: …", "apply_patch: …". The old filter only
        // knew "diff_apply", so a task that edited solely via diff_apply/apply_diff
        // skipped the verify build and could complete with a broken build.
        let editPrefixes = ["write_file", "edit_file", "diff_apply", "diff_and_apply", "apply_diff", "create_diff", "apply_patch"]
        let editCommands = commandsRun.filter { cmd in editPrefixes.contains { cmd.hasPrefix($0) } }
        if autoVerifyEnabled && Self.isXcodeProject(projectFolder) && !editCommands.isEmpty {
            log("🔍 Verify gate: building before allowing completion...")
            let buildResult = await Self.offMain { XcodeService.shared.buildProject(projectPath: "") }
            if buildResult.contains("BUILD FAILED") || buildResult.contains("error:") {
                // Extract first 5 errors
                let errors = buildResult.components(separatedBy: "\n")
                    .filter { $0.contains("error:") }
                    .prefix(5)
                    .joined(separator: "\n")
                log("❌ Verify gate: build failed — sending errors back to LLM")
                return """
                    CANNOT COMPLETE — build failed. \
                    Fix these errors first:

                    \(errors)

                    After fixing, call task_complete again.
                    """
            }
            log("✅ Verify gate: build passed")
        }

        // Criteria marked done but with no evidence cited are self-reported,
        // not verified. Block completion the same way open criteria do.
        // Same global-store caveat as the goal gate above → skipped for tab tasks.
        let unevidenced = skipGoalGates ? [] : GoalStateStore.shared.unevidencedCriteria
        if !unevidenced.isEmpty {
            log("❌ Verify gate: \(unevidenced.count) criterion/criteria marked done without evidence")
            return """
                CANNOT COMPLETE — these criteria are marked done but cite no evidence:

                \(unevidenced.map { "  ? \($0.text)" }.joined(separator: "\n"))

                Re-mark each with goal_state(action: "mark", criterion: "...", \
                evidence: "<the tool result that proves it>") after verifying it \
                with an actual tool call.
                """
        }

        // Physical-evidence pass: every file this task edited must still exist
        // and be non-empty. Catches truncated writes and deleted-by-accident files.
        var brokenFiles: [String] = []
        for path in FileBackupService.shared.snapshottedFiles() {
            let attrs = try? FileManager.default.attributesOfItem(atPath: path)
            guard let attrs, let size = attrs[.size] as? Int, size > 0 else {
                brokenFiles.append(path)
                continue
            }
        }
        if !brokenFiles.isEmpty {
            log("❌ Verify gate: \(brokenFiles.count) edited file(s) missing or empty")
            return """
                CANNOT COMPLETE — these files were edited this task but are now \
                missing or empty:

                \(brokenFiles.map { "  ✗ \($0)" }.joined(separator: "\n"))

                Restore them with file(action: "rewind") or rewrite them, then \
                call task_complete again.
                """
        }

        // Critic gate (opt-in, one-shot): LLM review of the task's diff.
        if let criticBlock = await criticReviewBlocker(projectFolder: projectFolder) { return criticBlock }

        return nil
    }


    /// goal_state — read/update the persistent goal + verification criteria.
    private func handleGoalState(input: [String: Any]) -> String {
        let store = GoalStateStore.shared
        let action = input["action"] as? String ?? "get"
        switch action {
        case "set":
            let goal = input["goal"] as? String ?? ""
            guard !goal.isEmpty else { return "Error: 'goal' is required for action=set." }
            let criteria = input["criteria"] as? [String] ?? []
            let state = store.set(goal: goal, criteria: criteria)
            appendLog("🎯 Goal set: \(state.goal) (\(state.criteria.count) criteria)")
            flushLog()
            return "Goal recorded with \(state.criteria.count) criteria. Complete each one and mark it done before calling task_complete."
        case "get":
            guard store.current != nil else { return "No active goal." }
            return store.promptBlock.trimmingCharacters(in: .whitespacesAndNewlines)
        case "mark":
            let text = input["criterion"] as? String ?? ""
            guard !text.isEmpty else { return "Error: 'criterion' is required for action=mark." }
            let done = input["done"] as? Bool ?? true
            let evidence = (input["evidence"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            // Marking done without citing the tool result that proves it is
            // self-reporting — the exact failure this loop exists to catch.
            if done, evidence?.isEmpty ?? true {
                return """
                    Error: marking a criterion done requires `evidence` — the tool result \
                    that proves it (e.g. "xcode build succeeded", "grep shows 0 matches", \
                    "26 tests passed"). Verify it with a tool call first, then mark it.
                    """
            }
            guard let state = store.setCriterion(text: text, done: done, evidence: evidence) else {
                return "No criterion matching '\(text)'. Use goal_state(action: \"get\") to list them."
            }
            appendLog("🎯 Criterion '\(text.prefix(60))' marked \(done ? "done" : "open")")
            flushLog()
            return state.allCriteriaDone
                ? "All criteria verified. You may call task_complete."
                : "\(state.openCriteria.count) criteria still open."
        case "clear":
            store.clear()
            appendLog("🎯 Goal cleared")
            flushLog()
            return "Goal cleared."
        default:
            return "Unknown action. Use: set, get, mark, clear."
        }
    }
}
