import Foundation

// MARK: - Auto-Pilot
//
// `/auto [<N>h|<N>m] [goal…]` runs the main task loop in cycles until the goal
// is reached, the time budget runs out, or the user presses Stop. Each cycle
// is a normal main-tab task; between cycles the summary is appended to
// `.agent/autopilot/progress.md` in the project folder and fed back into the
// next cycle's prompt so work carries over even across context compaction.
//
//   /auto <goal>              run until the LLM reports the goal reached
//   /auto 4h <goal>           same, but stop after 4 hours (30m, 1.5h also work)
//   /auto                     review the project, then ask the user for the goal
//   /auto add <folder>        add a parity folder (changes get mirrored there)
//   /auto remove <folder>     remove a parity folder
//   /auto status              show the active session
//   /auto stop                end the session after the current cycle

struct AutoPilotSession {
    var goal: String
    var startedAt: Date = Date()
    var deadline: Date?
    var cycle: Int = 0
    /// Consecutive cycles that ended without a completion summary (cancelled,
    /// iteration-capped, provider failure). Three in a row ends the session.
    var idleCycles: Int = 0
    /// Set by `/auto stop` — finishes the running cycle, then ends.
    var stopRequested = false

    var isDiscovery: Bool { goal.isEmpty }
}

extension AgentViewModel {
    /// Marker the LLM puts at the start of its done/task_complete summary when
    /// it judges the goal fully reached. Case-insensitive.
    static let autoPilotGoalReachedMarker = "AUTOPILOT: GOAL REACHED"

    // MARK: Slash command

    /// Handle `/auto …`. Returns true when the input was consumed.
    func handleAutoCommand(_ task: String) -> Bool {
        guard task.lowercased() == "/auto" || task.lowercased().hasPrefix("/auto ") else { return false }
        taskInput = ""
        let arg = task.dropFirst(5).trimmingCharacters(in: .whitespaces)
        let lower = arg.lowercased()

        if lower == "stop" {
            if autoPilot != nil {
                autoPilot?.stopRequested = true
                appendLog("🛩️ Auto-pilot will stop after the current cycle.")
            } else {
                appendLog("🛩️ Auto-pilot is not running.")
            }
            flushLog()
            return true
        }
        if lower == "status" {
            appendLog(autoPilotStatusLine())
            flushLog()
            return true
        }
        if lower.hasPrefix("add ") || lower.hasPrefix("remove ") {
            let isAdd = lower.hasPrefix("add ")
            let raw = arg.dropFirst(isAdd ? 4 : 7).trimmingCharacters(in: .whitespaces)
            let folder = (raw as NSString).expandingTildeInPath
            if isAdd {
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: folder, isDirectory: &isDir), isDir.boolValue else {
                    appendLog("🛩️ Not a folder: \(folder)")
                    flushLog()
                    return true
                }
                if !autoPilotParityFolders.contains(folder) { autoPilotParityFolders.append(folder) }
                appendLog("🛩️ Parity folder added: \(folder)")
            } else {
                autoPilotParityFolders.removeAll { $0 == folder }
                appendLog("🛩️ Parity folder removed: \(folder)")
            }
            appendLog("🛩️ Parity folders: \(autoPilotParityFolders.isEmpty ? "(none)" : autoPilotParityFolders.joined(separator: ", "))")
            flushLog()
            return true
        }
        if lower == "help" || lower == "?" {
            appendLog("Usage: /auto [<N>h|<N>m] [goal] | /auto add <folder> | /auto remove <folder> | /auto status | /auto stop")
            flushLog()
            return true
        }
        if autoPilot != nil {
            appendLog("🛩️ Auto-pilot already running — \(autoPilotStatusLine()). Use /auto stop first.")
            flushLog()
            return true
        }
        guard !projectFolder.isEmpty else {
            appendLog("🛩️ Set a project folder before starting auto-pilot.")
            flushLog()
            return true
        }

        let (hours, goal) = Self.parseAutoPilotArgs(arg)
        startAutoPilot(goal: goal, hours: hours)
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

    func startAutoPilot(goal: String, hours: Double?) {
        var session = AutoPilotSession(goal: goal)
        if let hours { session.deadline = Date().addingTimeInterval(hours * 3600) }
        autoPilot = session
        let budget = hours.map { Self.autoPilotFormatHours($0) } ?? "until the goal is reached"
        appendLog("🛩️ Auto-pilot started — \(budget). Goal: \(goal.isEmpty ? "(will ask you after reviewing the project)" : goal)")
        if !autoPilotParityFolders.isEmpty {
            appendLog("🛩️ Parity folders: \(autoPilotParityFolders.joined(separator: ", "))")
        }
        appendLog("🛩️ Progress log: \(autoPilotProgressURL().path). Press Stop or type /auto stop to end.")
        flushLog()
        appendAutoPilotProgress("# Auto-pilot session — \(Self.autoPilotTimestamp())\nGoal: \(goal.isEmpty ? "(pending — asked during cycle 1)" : goal)\nBudget: \(budget)\n")
        if let next = nextAutoPilotPrompt() { startMainTask(next) }
    }

    /// Called from `startMainTask` after each main task finishes. Returns the
    /// next cycle's prompt, or nil (and ends the session) when auto-pilot is
    /// off, the goal was reported reached, the deadline passed, or the loop stalled.
    func nextAutoPilotPrompt() -> String? {
        guard var session = autoPilot, !isCancelled else { return nil }

        // Outcome of the cycle that just ended (cycle 0 = nothing ran yet).
        if session.cycle > 0 {
            let summary = lastTaskCompletionSummary.trimmingCharacters(in: .whitespacesAndNewlines)
            appendAutoPilotProgress("## Cycle \(session.cycle) — \(Self.autoPilotTimestamp())\n\(summary.isEmpty ? "(no summary — cycle ended without task_complete)" : summary)\n")
            if summary.uppercased().hasPrefix(Self.autoPilotGoalReachedMarker) {
                endAutoPilot(reason: "goal reached after \(session.cycle) cycle(s)")
                return nil
            }
            session.idleCycles = summary.isEmpty ? session.idleCycles + 1 : 0
            if session.idleCycles >= 3 {
                endAutoPilot(reason: "3 consecutive cycles ended without a summary")
                return nil
            }
            if session.stopRequested {
                endAutoPilot(reason: "stopped by /auto stop after \(session.cycle) cycle(s)")
                return nil
            }
        }
        if let deadline = session.deadline, Date() >= deadline {
            endAutoPilot(reason: "time budget used up after \(session.cycle) cycle(s)")
            return nil
        }

        session.cycle += 1
        autoPilot = session
        appendLog("🛩️ Auto-pilot cycle \(session.cycle) — \(autoPilotStatusLine())")
        flushLog()
        return buildAutoPilotPrompt(session)
    }

    func endAutoPilot(reason: String) {
        guard let session = autoPilot else { return }
        autoPilot = nil
        let elapsed = Self.autoPilotFormatHours(Date().timeIntervalSince(session.startedAt) / 3600)
        appendLog("🛩️ Auto-pilot ended — \(reason). Ran \(elapsed).")
        flushLog()
        appendAutoPilotProgress("Session ended — \(reason) (\(Self.autoPilotTimestamp()))\n")
    }

    func autoPilotStatusLine() -> String {
        guard let s = autoPilot else { return "🛩️ Auto-pilot is not running." }
        let elapsed = Self.autoPilotFormatHours(Date().timeIntervalSince(s.startedAt) / 3600)
        let remaining = s.deadline.map { "\(Self.autoPilotFormatHours(max(0, $0.timeIntervalSinceNow) / 3600)) left" } ?? "no time limit"
        return "cycle \(s.cycle) · \(elapsed) elapsed · \(remaining) · goal: \(s.goal.isEmpty ? "(pending)" : s.goal)"
    }

    // MARK: Prompt

    private func buildAutoPilotPrompt(_ session: AutoPilotSession) -> String {
        let remaining = session.deadline.map { "\(Self.autoPilotFormatHours(max(0, $0.timeIntervalSinceNow) / 3600)) remaining" } ?? "no time limit — run until the goal is reached"
        var p = "[AUTO-PILOT cycle \(session.cycle) · \(remaining) · unattended session, the user is not watching]\n"
        p += "PRIMARY PROJECT FOLDER: \(projectFolder)\n"
        if !autoPilotParityFolders.isEmpty {
            p += "PARITY FOLDERS (must end every cycle matching the primary — port each change you make in the primary to every one of these, build each, commit each):\n"
            for f in autoPilotParityFolders { p += "  - \(f)\n" }
        }
        if session.isDiscovery {
            p += """

            There is no goal yet. FIRST review the primary project folder (index, README, git log, open TODO/STATUS docs) so you understand it. \
            THEN call ask_user with ONE question: what the goal of this auto-pilot session should be. \
            Once you have the answer, record it with goal_state (goal + verifiable criteria) and start working on it. \
            Call done at the end of this cycle with a summary of what you learned and what you did.
            """
            return p
        }
        p += "GOAL: \(session.goal)\n"
        let progress = recentAutoPilotProgress()
        if !progress.isEmpty {
            p += "\nPROGRESS FROM PREVIOUS CYCLES (newest last):\n\(progress)\n"
        }
        p += """

        INSTRUCTIONS FOR THIS CYCLE:
        1. Re-orient: read \(autoPilotProgressURL().path), git status/log, and the project index. Do not redo finished work.
        2. Pick the single most valuable next step toward the GOAL. Implement it fully: edit → build → fix → commit.
        3. Parity: every change made in the primary folder must be mirrored into each parity folder before this cycle ends.
        4. Do not ask the user questions — decide and proceed; note assumptions in your summary.
        5. When this cycle's step is done and committed, call done with: what you did, what remains, and any blockers.
        6. If the GOAL is fully reached and verified (build green, criteria checked with tool evidence), start your done summary with the exact text "\(Self.autoPilotGoalReachedMarker)". Never write that text otherwise.
        """
        return p
    }

    // MARK: Progress log

    func autoPilotProgressURL() -> URL {
        AgentProjectPaths.url(in: projectFolder, .autopilot).appendingPathComponent("progress.md")
    }

    private func appendAutoPilotProgress(_ text: String) {
        let url = autoPilotProgressURL()
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        try? (existing + text + "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    /// Last ~3K chars of the progress log — enough for the most recent cycles
    /// without bloating every prompt.
    private func recentAutoPilotProgress() -> String {
        guard let text = try? String(contentsOf: autoPilotProgressURL(), encoding: .utf8) else { return "" }
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
