import Foundation

// MARK: - Auto-Pilot
//
// `/auto [<N>h|<N>m] [goal…]` runs the task loop in cycles until the goal is
// reached, the (optional) time budget runs out, or the user presses Stop.
// There is NO cycle limit and NO per-cycle iteration cap while a session is
// active: whenever a cycle's task ends (done, error, stall) and the goal is not
// reached, the next cycle starts automatically — only after the previous task
// has fully ended. Works on the main tab and on any LLM tab (session is per tab).
// Between cycles the summary is appended to this tab's `.agent/tabs/<key>/progress.md`
// in the project folder and fed back into the next cycle's prompt. Several tabs
// can run Auto-Pilot on the same project — see AutoPilotRegistry.swift.
//
//   /auto <goal>              run until the LLM reports the goal reached
//   /auto 4h <goal>           same, but stop after 4 hours (30m, 1.5h also work)
//   /auto --worktree <goal>   work in an isolated git worktree/branch (-w); --shared
//                             forces the shared checkout. Default: worktree only when
//                             another Auto-Pilot tab is already live on the project.
//   /auto                     review the project, then ask the user for the goal
//   /auto history             list previous auto-pilot goals
//   /auto last | /auto #N     restart the most recent / Nth goal from history
//   /auto add <folder>        add a parity folder (changes get mirrored there)
//   /auto remove <folder>     remove a parity folder
//   /auto status              show the active session
//   /auto stop                end the session after the current cycle

struct AutoPilotSession: Codable {
    var goal: String
    var startedAt: Date = Date()
    var deadline: Date?
    var cycle: Int = 0
    /// Consecutive cycles that ended without a completion summary (cancelled,
    /// provider failure). Never ends the session — only lengthens the pause
    /// before the next cycle so a failing provider isn't hammered.
    var idleCycles: Int = 0
    /// Set by `/auto stop` — finishes the running cycle, then ends.
    var stopRequested = false
    /// Project folder the session was started in. Shared state (registry,
    /// progress log, memory) lives here even when working in a worktree.
    var projectRoot: String?
    /// Isolated git worktree folder + branch this session works in (nil = shared checkout).
    var worktree: String?
    var branch: String?
    /// Tab/main folder before switching to the worktree — restored when the session ends.
    var originalFolder: String?

    var isDiscovery: Bool { goal.isEmpty }
}

extension AgentViewModel {
    /// Marker the LLM puts at the start of its done/task_complete summary when
    /// it judges the goal fully reached. Case-insensitive.
    static let autoPilotGoalReachedMarker = "AUTOPILOT: GOAL REACHED"
    private static let autoPilotGoalHistoryKey = "autoPilotGoalHistory"
    /// Active sessions persisted across app restarts: [tab UUID string or "main": JSON].
    private static let autoPilotSessionsKey = "autoPilotSessions"
    private static let autoPilotMainKey = "main"

    // MARK: Per-tab session access (tab == nil → main tab)

    func autoPilotSession(_ tab: ScriptTab?) -> AutoPilotSession? {
        tab == nil ? autoPilot : tab?.autoPilot
    }

    func setAutoPilotSession(_ session: AutoPilotSession?, _ tab: ScriptTab?) {
        if let tab { tab.autoPilot = session } else { autoPilot = session }
        // Mirror to disk so the session survives an app restart.
        let key = tab?.id.uuidString ?? Self.autoPilotMainKey
        var stored = UserDefaults.standard.dictionary(forKey: Self.autoPilotSessionsKey) as? [String: Data] ?? [:]
        stored[key] = session.flatMap { try? JSONEncoder().encode($0) }
        UserDefaults.standard.set(stored, forKey: Self.autoPilotSessionsKey)
    }

    /// Relaunch sessions that were active when the app last quit (or crashed).
    /// Called once at startup after script tabs are restored.
    func resumeAutoPilotSessions() {
        let stored = UserDefaults.standard.dictionary(forKey: Self.autoPilotSessionsKey) as? [String: Data] ?? [:]
        for (key, data) in stored {
            var tab: ScriptTab?
            if key != Self.autoPilotMainKey {
                tab = scriptTabs.first { $0.id.uuidString == key }
                guard tab != nil else {
                    // Tab was closed — drop its orphaned session.
                    var s = UserDefaults.standard.dictionary(forKey: Self.autoPilotSessionsKey) as? [String: Data] ?? [:]
                    s[key] = nil
                    UserDefaults.standard.set(s, forKey: Self.autoPilotSessionsKey)
                    continue
                }
            }
            guard autoPilotSession(tab) == nil,
                  let session = try? JSONDecoder().decode(AutoPilotSession.self, from: data) else { continue }
            setAutoPilotSession(session, tab)
            apLog("🛩️ Auto-pilot resumed after app restart — \(autoPilotStatusLine(tab))", tab)
            appendAutoPilotProgress("Resumed after app restart (\(Self.autoPilotTimestamp()))\n", tab)
            // The interrupted cycle is recorded as ended without a summary.
            guard let next = nextAutoPilotPrompt(tab: tab) else { continue }
            if let tab { startTabTask(tab: tab, prompt: next) } else { startMainTask(next) }
        }
    }


    private func apLog(_ message: String, _ tab: ScriptTab?) {
        if let tab {
            tab.appendLog(message)
            tab.flush()
        } else {
            appendLog(message)
            flushLog()
        }
    }

    private func autoPilotFolder(_ tab: ScriptTab?) -> String {
        guard let tab, !tab.projectFolder.isEmpty else { return projectFolder }
        return Self.resolvedWorkingDirectory(tab.projectFolder)
    }

    /// Per-tab key for `.agent/tabs/<key>/` and the registry: "main" or the tab's short id.
    private func autoPilotKey(_ tab: ScriptTab?) -> String {
        tab.map { String($0.id.uuidString.prefix(8)).lowercased() } ?? Self.autoPilotMainKey
    }

    /// Where shared per-project state (registry, progress) lives — the
    /// session's repo root, never its worktree.
    private func autoPilotHome(_ tab: ScriptTab?) -> String {
        autoPilotSession(tab)?.projectRoot ?? autoPilotFolder(tab)
    }

    private func setAutoPilotWorkFolder(_ folder: String, _ tab: ScriptTab?) {
        if let tab { tab.projectFolder = folder } else { projectFolder = folder }
    }

    /// Advertise this session (and refresh its heartbeat) to the other tabs.
    private func registerAutoPilot(_ session: AutoPilotSession, _ tab: ScriptTab?) {
        AutoPilotRegistry.upsert(root: autoPilotHome(tab), AutoPilotRegistryEntry(
            key: autoPilotKey(tab), title: tab?.displayTitle ?? "main", goal: session.goal,
            workFolder: autoPilotFolder(tab), branch: session.branch
        ))
    }

    private func autoPilotTaskIsRunning(_ tab: ScriptTab?) -> Bool {
        tab.map { $0.isLLMRunning } ?? isRunning
    }

    // MARK: Goal history

    var autoPilotGoalHistory: [String] {
        UserDefaults.standard.stringArray(forKey: Self.autoPilotGoalHistoryKey) ?? []
    }

    func recordAutoPilotGoal(_ goal: String) {
        let g = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !g.isEmpty else { return }
        var list = autoPilotGoalHistory.filter { $0 != g }
        list.append(g)
        UserDefaults.standard.set(Array(list.suffix(50)), forKey: Self.autoPilotGoalHistoryKey)
    }

    // MARK: Slash command

    /// Handle `/auto …` typed on the main tab (tab == nil) or an LLM tab.
    /// Returns true when the input was consumed.
    func handleAutoCommand(_ task: String, tab: ScriptTab? = nil) -> Bool {
        guard task.lowercased() == "/auto" || task.lowercased().hasPrefix("/auto ") else { return false }
        // Record the command as a prompt so arrow-up history can replay it.
        if let tab {
            tab.addToHistory(task)
            tab.taskInput = ""
        } else {
            promptHistory.append(task)
            UserDefaults.standard.set(promptHistory, forKey: "agentPromptHistory")
            historyIndex = -1
            savedInput = ""
            taskInput = ""
        }
        let arg = task.dropFirst(5).trimmingCharacters(in: .whitespaces)
        let lower = arg.lowercased()

        // /auto stop all | stopall | stop-all — same as the Stop All button.
        if ["stop all", "stopall", "stop-all"].contains(lower.split(separator: " ").joined(separator: " ")) {
            stopAll()
            return true
        }
        if lower == "stop" {
            if autoPilotSession(tab) == nil {
                apLog("🛩️ Auto-pilot is not running.", tab)
            } else if autoPilotTaskIsRunning(tab) {
                var s = autoPilotSession(tab)
                s?.stopRequested = true
                setAutoPilotSession(s, tab)
                apLog("🛩️ Auto-pilot will stop after the current cycle.", tab)
            } else {
                // Between cycles (pause/backoff) — end now and drop the pending cycle.
                endAutoPilot(reason: "stopped by /auto stop", tab: tab)
                if let tab { tab.runningLLMTask?.cancel() } else { runningTask?.cancel() }
            }
            return true
        }
        if lower == "status" {
            apLog(autoPilotStatusLine(tab), tab)
            return true
        }
        if lower == "history" {
            let goals = autoPilotGoalHistory
            if goals.isEmpty {
                apLog("🛩️ No auto-pilot goals yet.", tab)
            } else {
                let lines = goals.enumerated().reversed().map { "  #\($0.offset + 1)  \($0.element)" }
                apLog("🛩️ Auto-pilot goal history (newest first) — rerun with /auto #N or /auto last:\n" + lines.joined(separator: "\n"), tab)
            }
            return true
        }
        if lower.hasPrefix("add ") || lower.hasPrefix("remove ") {
            let isAdd = lower.hasPrefix("add ")
            let raw = arg.dropFirst(isAdd ? 4 : 7).trimmingCharacters(in: .whitespaces)
            let folder = (raw as NSString).expandingTildeInPath
            if isAdd {
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: folder, isDirectory: &isDir), isDir.boolValue else {
                    apLog("🛩️ Not a folder: \(folder)", tab)
                    return true
                }
                if !autoPilotParityFolders.contains(folder) { autoPilotParityFolders.append(folder) }
                apLog("🛩️ Parity folder added: \(folder)", tab)
            } else {
                autoPilotParityFolders.removeAll { $0 == folder }
                apLog("🛩️ Parity folder removed: \(folder)", tab)
            }
            apLog("🛩️ Parity folders: \(autoPilotParityFolders.isEmpty ? "(none)" : autoPilotParityFolders.joined(separator: ", "))", tab)
            return true
        }
        if lower == "help" || lower == "?" {
            apLog("Usage: /auto [<N>h|<N>m] [--worktree|--shared] [goal] | /auto history | /auto last | /auto #N | /auto add <folder> | /auto remove <folder> | /auto status | /auto stop", tab)
            return true
        }
        if autoPilotSession(tab) != nil {
            apLog("🛩️ Auto-pilot already running — \(autoPilotStatusLine(tab)). Use /auto stop first.", tab)
            return true
        }
        guard !autoPilotFolder(tab).isEmpty else {
            apLog("🛩️ Set a project folder before starting auto-pilot.", tab)
            return true
        }

        // --worktree / -w forces an isolated git worktree, --shared forces the shared
        // checkout; default: isolate only when another Auto-Pilot tab is live on this project.
        var isolate: Bool?
        let argTokens = arg.split(separator: " ").map(String.init).filter { token in
            switch token.lowercased() {
            case "--worktree", "-w", "--isolate": isolate = true; return false
            case "--shared": isolate = false; return false
            default: return true
            }
        }
        let (hours, parsedGoal) = Self.parseAutoPilotArgs(argTokens.joined(separator: " "))
        var goal = parsedGoal
        // `/auto last` / `/auto #N` — rerun a goal from history.
        let history = autoPilotGoalHistory
        if goal.lowercased() == "last" {
            guard let last = history.last else {
                apLog("🛩️ No auto-pilot goals in history yet.", tab)
                return true
            }
            goal = last
        } else if goal.hasPrefix("#"), let n = Int(goal.dropFirst()) {
            guard n >= 1, n <= history.count else {
                apLog("🛩️ No goal #\(n) — /auto history lists \(history.count) goal(s).", tab)
                return true
            }
            goal = history[n - 1]
        }
        recordAutoPilotGoal(goal)
        startAutoPilot(goal: goal, hours: hours, tab: tab, isolate: isolate)
        return true
    }

    /// Split a leading duration token (`4h`, `30m`, `1.5h`, `--hours 4`) from the goal text.
    nonisolated static func parseAutoPilotArgs(_ arg: String) -> (hours: Double?, goal: String) {
        var tokens = arg.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard let first = tokens.first?.lowercased() else { return (nil, "") }
        var hours: Double?
        if first == "--hours", tokens.count >= 2, let h = Double(tokens[1]) {
            hours = h
            tokens.removeFirst(2)
        } else if first.hasSuffix("h"), let h = Double(first.dropLast()) {
            hours = h
            tokens.removeFirst()
        } else if first.hasSuffix("m"), let m = Double(first.dropLast()) {
            hours = m / 60
            tokens.removeFirst()
        }
        if let h = hours, h <= 0 { hours = nil }
        return (hours, tokens.joined(separator: " ").trimmingCharacters(in: .whitespaces))
    }

    // MARK: Session lifecycle

    func startAutoPilot(goal: String, hours: Double?, tab: ScriptTab? = nil, isolate: Bool? = nil) {
        var session = AutoPilotSession(goal: goal)
        if let hours { session.deadline = Date().addingTimeInterval(hours * 3600) }
        let folder = autoPilotFolder(tab)
        let gitRoot = AutoPilotRegistry.gitRoot(folder)
        session.projectRoot = gitRoot ?? folder
        let others = AutoPilotRegistry.others(root: gitRoot ?? folder, excluding: autoPilotKey(tab))
        if isolate ?? !others.isEmpty {
            if gitRoot != nil, let wt = AutoPilotRegistry.worktree(for: folder, key: autoPilotKey(tab)) {
                session.worktree = wt.folder
                session.branch = wt.branch
                session.originalFolder = tab?.projectFolder ?? projectFolder
                setAutoPilotWorkFolder(wt.folder, tab)
                apLog("🛩️ Isolated worktree: \(wt.folder) on branch \(wt.branch). Uncommitted changes in the primary checkout are not included.", tab)
            } else {
                apLog("🛩️ No git worktree available (not a git repo, or `git worktree add` failed) — using the shared checkout.", tab)
            }
        }
        if !others.isEmpty {
            apLog("🛩️ Other Auto-Pilot tabs on this project: " + others.map { "\($0.title) (\($0.branch ?? "shared checkout"))" }.joined(separator: ", "), tab)
        }
        setAutoPilotSession(session, tab)
        let budget = hours.map { Self.autoPilotFormatHours($0) } ?? "no time limit, unlimited cycles"
        apLog("🛩️ Auto-pilot started — \(budget). Goal: \(goal.isEmpty ? "(will ask you after reviewing the project)" : goal)", tab)
        if !autoPilotParityFolders.isEmpty {
            apLog("🛩️ Parity folders: \(autoPilotParityFolders.joined(separator: ", "))", tab)
        }
        apLog("🛩️ Progress log: \(autoPilotProgressURL(tab).path). Press Stop or type /auto stop to end.", tab)
        appendAutoPilotProgress("# Auto-pilot session — \(Self.autoPilotTimestamp())\nGoal: \(goal.isEmpty ? "(pending — asked during cycle 1)" : goal)\nBudget: \(budget)\n", tab)
        // A previous Stop / Stop All leaves isCancelled set, which makes nextAutoPilotPrompt bail.
        if tab == nil, !isRunning { isCancelled = false }
        guard let next = nextAutoPilotPrompt(tab: tab) else { return }
        if let tab {
            if tab.isLLMRunning {
                // A normal task is in flight — the cycle chains after it ends.
                tab.taskQueue.append(next)
            } else {
                startTabTask(tab: tab, prompt: next)
            }
        } else {
            startMainTask(next)
        }
    }

    /// Called after a cycle's task has returned. Waits until the task has truly
    /// ended, pauses (longer after idle cycles), then returns the next cycle's
    /// prompt — or nil when auto-pilot is off, was stopped, or finished.
    func continueAutoPilot(tab: ScriptTab?) async -> String? {
        guard let session = autoPilotSession(tab), !Task.isCancelled else { return nil }
        // Make sure the previous task on this tab has fully ended.
        var waited = 0
        while autoPilotTaskIsRunning(tab), waited < 600 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            waited += 1
            if Task.isCancelled { return nil }
        }
        let summary = (tab?.lastTaskCompletionSummary ?? lastTaskCompletionSummary)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let reached = summary.uppercased().hasPrefix(Self.autoPilotGoalReachedMarker)
        if !reached, !session.stopRequested, session.cycle > 0 {
            // Idle cycles back off 15s, 30s, 60s… capped at 5 min; otherwise a short settle.
            let idle = summary.isEmpty ? session.idleCycles + 1 : 0
            let seconds = idle == 0 ? 2 : min(300, 15 << min(idle - 1, 5))
            if idle > 0 {
                apLog("🛩️ Cycle \(session.cycle) ended without a summary — next cycle in \(seconds)s (/auto stop to end).", tab)
            }
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            if Task.isCancelled || autoPilotSession(tab) == nil { return nil }
        }
        return nextAutoPilotPrompt(tab: tab)
    }

    /// Records the outcome of the cycle that just ended and returns the next
    /// cycle's prompt, or nil (and ends the session) when the goal was reported
    /// reached, the deadline passed, or /auto stop was requested.
    func nextAutoPilotPrompt(tab: ScriptTab? = nil) -> String? {
        guard var session = autoPilotSession(tab) else { return nil }
        if tab == nil, isCancelled { return nil }

        // Outcome of the cycle that just ended (cycle 0 = nothing ran yet).
        if session.cycle > 0 {
            let summary = (tab?.lastTaskCompletionSummary ?? lastTaskCompletionSummary)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            appendAutoPilotProgress("## Cycle \(session.cycle) — \(Self.autoPilotTimestamp())\n\(summary.isEmpty ? "(no summary — cycle ended without task_complete)" : summary)\n", tab)
            if summary.uppercased().hasPrefix(Self.autoPilotGoalReachedMarker) {
                endAutoPilot(reason: "goal reached after \(session.cycle) cycle(s)", tab: tab)
                return nil
            }
            session.idleCycles = summary.isEmpty ? session.idleCycles + 1 : 0
            if session.stopRequested {
                endAutoPilot(reason: "stopped by /auto stop after \(session.cycle) cycle(s)", tab: tab)
                return nil
            }
        }
        if let deadline = session.deadline, Date() >= deadline {
            endAutoPilot(reason: "time budget used up after \(session.cycle) cycle(s)", tab: tab)
            return nil
        }

        session.cycle += 1
        setAutoPilotSession(session, tab)
        registerAutoPilot(session, tab)
        apLog("🛩️ Auto-pilot cycle \(session.cycle) — \(autoPilotStatusLine(tab))", tab)
        return buildAutoPilotPrompt(session, tab: tab)
    }

    /// Esc / Stop cancels only the running cycle. Keep the session alive and
    /// schedule the next cycle; Stop All is what ends auto-pilot.
    func continueAutoPilotAfterCancel(_ tab: ScriptTab?) {
        guard autoPilotSession(tab) != nil, !autoPilotAppQuitting else { return }
        apLog("🛩️ Cycle cancelled — Auto-Pilot continues. Use Stop All to end it.", tab)
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            // stop() left isCancelled set; clear it so nextAutoPilotPrompt can run (a new user task would reset it too).
            if tab == nil, !isRunning { isCancelled = false }
            guard let next = await continueAutoPilot(tab: tab), !autoPilotTaskIsRunning(tab) else { return }
            if let tab { startTabTask(tab: tab, prompt: next) } else { startMainTask(next) }
        }
    }

    func endAutoPilot(reason: String, tab: ScriptTab? = nil) {
        guard let session = autoPilotSession(tab) else { return }
        if autoPilotAppQuitting {
            // App is quitting — keep the persisted session so it resumes on next launch.
            apLog("🛩️ Auto-pilot paused for app quit — resumes on next launch.", tab)
            appendAutoPilotProgress("Paused for app quit (\(Self.autoPilotTimestamp()))\n", tab)
            return
        }
        appendAutoPilotProgress("Session ended — \(reason) (\(Self.autoPilotTimestamp()))\n", tab)
        AutoPilotRegistry.remove(root: autoPilotHome(tab), key: autoPilotKey(tab))
        setAutoPilotSession(nil, tab)
        if let original = session.originalFolder { setAutoPilotWorkFolder(original, tab) }
        let elapsed = Self.autoPilotFormatHours(Date().timeIntervalSince(session.startedAt) / 3600)
        apLog("🛩️ Auto-pilot ended — \(reason). Ran \(elapsed), \(session.cycle) cycle(s).", tab)
        if let wt = session.worktree, let branch = session.branch {
            apLog("🛩️ Work is on branch \(branch) (worktree \(wt)). Review and merge it with `git merge \(branch)`, then `git worktree remove \(wt)`.", tab)
        }
    }

    func autoPilotStatusLine(_ tab: ScriptTab? = nil) -> String {
        guard let s = autoPilotSession(tab) else { return "🛩️ Auto-pilot is not running." }
        let elapsed = Self.autoPilotFormatHours(Date().timeIntervalSince(s.startedAt) / 3600)
        let remaining = s.deadline.map { "\(Self.autoPilotFormatHours(max(0, $0.timeIntervalSinceNow) / 3600)) left" } ?? "no time limit"
        let where_ = s.branch.map { " · branch \($0)" } ?? ""
        return "cycle \(s.cycle) · \(elapsed) elapsed · \(remaining)\(where_) · goal: \(s.goal.isEmpty ? "(pending)" : s.goal)"
    }

    // MARK: Prompt

    /// Multi-tab context: this session's worktree (if isolated), the other
    /// live Auto-Pilot tabs on the same project, and what is shared.
    private func autoPilotCoordinationBlock(_ session: AutoPilotSession, _ tab: ScriptTab?) -> String {
        var p = ""
        if let wt = session.worktree {
            p += "ISOLATED WORKTREE: this tab works in \(wt) on branch \(session.branch ?? "?"). Edit, build and commit there only — never in \(session.originalFolder ?? "the primary checkout"), and do not merge; the user merges the branch.\n"
        }
        let others = AutoPilotRegistry.others(root: autoPilotHome(tab), excluding: autoPilotKey(tab))
        if !others.isEmpty {
            p += "OTHER AUTO-PILOT TABS ON THIS PROJECT (running in parallel — don't duplicate their work\(session.worktree == nil ? ", and don't edit files they are working on" : "")):\n"
            for o in others {
                p += "  - \(o.title): \(o.goal.isEmpty ? "(goal pending)" : o.goal) — \(o.branch.map { "branch \($0)" } ?? "shared checkout")\n"
            }
        }
        p += "SHARED vs PER-TAB: project memory (memory tool, scope project) and the index are shared with every tab — record durable findings there. Your goal_state, plan and progress log belong to this tab only.\n"
        return p
    }

    private func buildAutoPilotPrompt(_ session: AutoPilotSession, tab: ScriptTab?) -> String {
        let remaining = session.deadline.map { "\(Self.autoPilotFormatHours(max(0, $0.timeIntervalSinceNow) / 3600)) remaining" } ?? "no time limit — run until the goal is reached"
        var p = "[AUTO-PILOT cycle \(session.cycle) · \(remaining) · unattended session, the user is not watching]\n"
        p += "PRIMARY PROJECT FOLDER: \(autoPilotFolder(tab))\n"
        if !autoPilotParityFolders.isEmpty {
            p += "PARITY FOLDERS (must end every cycle matching the primary — port each change you make in the primary to every one of these, build each, commit each):\n"
            for f in autoPilotParityFolders { p += "  - \(f)\n" }
        }
        p += autoPilotCoordinationBlock(session, tab)
        if session.isDiscovery {
            let recent = autoPilotGoalHistory.suffix(5)
            let past = recent.isEmpty ? "" : "\nPrevious auto-pilot goals (offer these as options):\n" + recent.map { "  - \($0)" }.joined(separator: "\n") + "\n"
            p += """
            \(past)
            There is no goal yet. FIRST review the primary project folder (index, README, git log, open TODO/STATUS docs) so you understand it. \
            THEN call ask_user with ONE question: what the goal of this auto-pilot session should be. \
            Once you have the answer, record it with goal_state (goal + verifiable criteria) and start working on it. \
            Call done at the end of this cycle with a summary of what you learned and what you did.
            """
            return p
        }
        p += "GOAL: \(session.goal)\n"
        let progress = recentAutoPilotProgress(tab)
        if !progress.isEmpty {
            p += "\nPROGRESS FROM PREVIOUS CYCLES (newest last):\n\(progress)\n"
        }
        p += """

        INSTRUCTIONS FOR THIS CYCLE:
        1. Re-orient: read \(autoPilotProgressURL(tab).path), git status/log, and the project index. Do not redo finished work.
        2. Pick the single most valuable next step toward the GOAL. Implement it fully: edit → build → fix → commit. There is no iteration limit — keep working until the step is done.
        3. Parity: every change made in the primary folder must be mirrored into each parity folder before this cycle ends.
        4. Do not ask the user questions — decide and proceed; note assumptions in your summary.
        5. When this cycle's step is done and committed, call done with: what you did, what remains, and any blockers. A new cycle starts automatically.
        6. If the GOAL is fully reached and verified (build green, criteria checked with tool evidence), start your done summary with the exact text "\(Self.autoPilotGoalReachedMarker)". Never write that text otherwise.
        """
        return p
    }

    // MARK: Progress log

    /// This tab's own progress log: `.agent/tabs/<key>/progress.md` in the
    /// project root. The pre-multi-tab `.agent/autopilot/progress.md` is moved
    /// into the main tab's folder the first time it is needed.
    func autoPilotProgressURL(_ tab: ScriptTab? = nil) -> URL {
        let home = autoPilotHome(tab)
        let url = AutoPilotRegistry.tabDir(root: home, key: autoPilotKey(tab)).appendingPathComponent("progress.md")
        let legacy = AgentProjectPaths.url(in: home, .autopilot).appendingPathComponent("progress.md")
        let fm = FileManager.default
        if tab == nil, !fm.fileExists(atPath: url.path), fm.fileExists(atPath: legacy.path) {
            try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? fm.moveItem(at: legacy, to: url)
        }
        return url
    }

    private func appendAutoPilotProgress(_ text: String, _ tab: ScriptTab?) {
        let url = autoPilotProgressURL(tab)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        try? (existing + text + "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    /// Last ~3K chars of the progress log — enough for the most recent cycles
    /// without bloating every prompt.
    private func recentAutoPilotProgress(_ tab: ScriptTab?) -> String {
        guard let text = try? String(contentsOf: autoPilotProgressURL(tab), encoding: .utf8) else { return "" }
        let cycles = text.components(separatedBy: "\n## Cycle ").dropFirst()
        guard !cycles.isEmpty else { return "" }
        let recent = cycles.suffix(6).map { "## Cycle " + $0 }.joined(separator: "\n")
        return String(recent.suffix(3000)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Formatting

    nonisolated static func autoPilotFormatHours(_ hours: Double) -> String {
        let totalMinutes = Int((hours * 60).rounded())
        let h = totalMinutes / 60, m = totalMinutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    nonisolated static func autoPilotTimestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: Date())
    }
}
