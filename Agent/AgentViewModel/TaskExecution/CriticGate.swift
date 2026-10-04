
@preconcurrency import Foundation

// MARK: - Critic Review Gate (opt-in)
//
// LLM review of the task's uncommitted diff before task_complete is accepted.
// Once the critic blocks, it keeps blocking: an unchanged diff is refused
// again and a changed diff is re-reviewed. The per-task completion-gate
// refusal cap (maxCompletionGateRefusals) is what ends a stubborn loop.
// Opt-in via criticReviewEnabled (Settings → Coding → Critic Review).

extension AgentViewModel {

    /// Returns a `CANNOT COMPLETE — ...` blocker when the critic finds issues
    /// (or the AI ignored them), or nil when completion may proceed (disabled,
    /// no edits, clean diff, flagged changes reverted, or critic passed /
    /// failed to answer).
    func criticReviewBlocker(projectFolder overrideFolder: String? = nil) async -> String? {
        let base = overrideFolder ?? projectFolder
        let folder = base.isEmpty ? NSHomeDirectory() : base
        // Follow-up after a block: the AI must have changed the flagged diff.
        if criticReviewDone, let blockedDiff = criticBlockedDiff {
            let current = await Self.offMain { Self.uncommittedDiff(folder: folder) }
            if current == blockedDiff {
                appendLog("🧐 Critic follow-up: no code changes after review — refusing completion again")
                flushLog()
                return Self.criticIgnoredBlocker
            }
            criticBlockedDiff = nil
            guard !current.isEmpty else {
                appendLog("\u{2705} Critic follow-up: flagged changes reverted")
                flushLog()
                return nil
            }
            appendLog("🧐 Critic follow-up: code changed after review — re-checking")
            flushLog()
            return await criticReview(diff: current)
        }
        guard criticReviewEnabled, !criticReviewDone else { return nil }
        guard !FileBackupService.shared.snapshottedFiles().isEmpty else { return nil }
        criticReviewDone = true

        let diff = await Self.offMain { Self.uncommittedDiff(folder: folder) }
        guard !diff.isEmpty else { return nil }
        return await criticReview(diff: diff)
    }

    /// Runs the reviewer on `diff`. On issues, records the diff in
    /// `criticBlockedDiff` and returns the blocker.
    private func criticReview(diff: String) async -> String? {
        appendLog("🧐 Critic review: analyzing task diff (\(diff.count) chars)...")
        flushLog()

        let verdict: String
        do {
            guard let text = try await runCriticLLM(diff: diff) else {
                appendLog("🧐 Critic review skipped (reviewer replied with no text — tool call or empty reply)")
                flushLog()
                return nil
            }
            verdict = text
        } catch {
            appendLog("🧐 Critic review skipped (reviewer request failed: \(error.localizedDescription))")
            flushLog()
            return nil
        }
        guard let blocker = Self.criticVerdictBlocker(verdict) else {
            appendLog("\u{2705} Critic review: PASS")
            flushLog()
            return nil
        }
        criticBlockedDiff = diff
        let issues = verdict.trimmingCharacters(in: .whitespacesAndNewlines)
        appendLog("🧐 Critic review found issues — blocking completion:\n\(String(issues.prefix(2000)))")
        flushLog()
        return blocker
    }

    /// Refusal when task_complete is called again without touching the diff
    /// the critic flagged.
    nonisolated static let criticIgnoredBlocker = """
        CANNOT COMPLETE — the critic flagged issues and the uncommitted diff has \
        NOT changed since. You may not dismiss the critic's issues as "out of \
        scope" or "from an earlier task": everything in `git diff HEAD` is \
        reviewed. Fix each issue, or revert the flagged change (e.g. \
        `git checkout -- <file>`), then call task_complete again. If a flagged \
        change looks like the user's own work in progress, call ask_user before \
        reverting it.
        """

    /// Maps the reviewer's reply to a completion blocker. A reply starting with
    /// "PASS" (any case, surrounding whitespace ignored) returns nil; anything
    /// else is quoted (capped at 2000 chars) inside a `CANNOT COMPLETE` block.
    nonisolated static func criticVerdictBlocker(_ verdict: String) -> String? {
        let trimmed = verdict.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.uppercased().hasPrefix("PASS") { return nil }
        return """
            CANNOT COMPLETE — a critic review of your diff found issues:

            \(String(trimmed.prefix(2000)))

            You MUST address every issue before completing: fix it, or revert \
            the flagged change. The diff is ALL uncommitted changes (`git diff \
            HEAD`), including leftovers from earlier tasks, so "this task didn't \
            touch that file" is not a reason to skip an issue. Calling \
            task_complete with the diff unchanged will be refused; changed code \
            is re-reviewed.
            """
    }

    /// `git diff HEAD` (staged + unstaged) capped for the critic prompt.
    nonisolated static func uncommittedDiff(folder: String) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        p.arguments = ["diff", "HEAD"]
        p.currentDirectoryURL = URL(fileURLWithPath: folder)
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = Pipe()
        do { try p.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        guard p.terminationStatus == 0,
              let out = String(data: data, encoding: .utf8)?
                  .trimmingCharacters(in: .whitespacesAndNewlines),
              !out.isEmpty
        else { return "" }
        return capDiff(out)
    }

    /// Marker appended when the diff exceeds the cap. The critic prompt tells the
    /// reviewer not to report the cut as truncated or missing code.
    nonisolated static let diffTruncatedMarker = "[DIFF TRUNCATED BY AGENT — remaining changes omitted for length]"

    /// Caps `diff` at `limit` chars on a line boundary (file boundary when one is
    /// in reach) and appends `diffTruncatedMarker`, so the critic never sees a
    /// line cut in half and flags it as broken code.
    nonisolated static func capDiff(_ diff: String, limit: Int = 12_000) -> String {
        guard diff.count > limit else { return diff }
        let budget = limit - diffTruncatedMarker.count - 1
        let head = String(diff.prefix(budget))
        var cut = head.endIndex
        if let file = head.range(of: "\ndiff --git ", options: .backwards),
           head.distance(from: head.startIndex, to: file.lowerBound) > budget / 2 {
            cut = file.lowerBound
        } else if let nl = head.lastIndex(of: "\n") {
            cut = nl
        }
        return String(head[..<cut]) + "\n" + diffTruncatedMarker
    }

    /// One-shot review call on the currently selected provider. Text-only —
    /// tool calls in the reply are ignored. Returns nil when the reply has no
    /// text; throws on request failure. The caller logs either and degrades to
    /// a no-op instead of blocking completion.
    private func runCriticLLM(diff: String) async throws -> String? {
        let criticSystemPrompt = """
            You are a strict code reviewer. You will receive a git diff of changes \
            an autonomous coding agent just made. Review ONLY the diff. Reply with \
            exactly "PASS" if the changes look correct and complete. Otherwise reply \
            "ISSUES:" followed by a short bulleted list of concrete problems \
            (bugs, truncated code, leftover debug output, broken syntax, changes \
            that contradict each other). Do NOT nitpick style. Do NOT use tools. \
            If the diff ends with "\(Self.diffTruncatedMarker)", the agent shortened it: \
            do NOT report truncation, cut-off hunks, or code "missing" past that \
            point — review only what is shown. \
            Reply in plain text only.
            """
        let userMessage = "Review this diff:\n\n```diff\n\(diff)\n```"
        let messages: [[String: Any]] = [["role": "user", "content": userMessage]]

        let (criticProvider, criticModel, _) = resolveInitialProviderConfig()
        let services = buildLLMServiceBundle(
            provider: criticProvider,
            modelName: criticModel,
            historyContext: "",
            projectFolder: projectFolder,
            maxTokens: 2048
        )
        services.claude?.overrideSystemPrompt = criticSystemPrompt
        services.openAICompatible?.overrideSystemPrompt = criticSystemPrompt
        services.ollama?.overrideSystemPrompt = criticSystemPrompt

        let content: [[String: Any]]
        if let claude = services.claude {
            content = try await claude.send(messages: messages).content
        } else if let openAI = services.openAICompatible {
            content = try await openAI.send(messages: messages).content
        } else if let ollama = services.ollama {
            content = try await ollama.send(messages: messages).content
        } else if let codex = services.codex {
            // Codex locks `instructions` to its fixed prefix — put the critic prompt in the message.
            content = try await codex.send(messages: [["role": "user", "content": criticSystemPrompt + "\n\n" + userMessage]]).content
        } else if let fm = services.foundationModel {
            content = try await fm.send(messages: [["role": "user", "content": criticSystemPrompt + "\n\n" + userMessage]]).content
        } else {
            throw AgentError.invalidResponse
        }
        let text = content.compactMap { $0["text"] as? String }.joined(separator: "\n")
        return text.isEmpty ? nil : text
    }
}
