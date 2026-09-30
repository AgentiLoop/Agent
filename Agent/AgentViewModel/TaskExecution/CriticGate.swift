
@preconcurrency import Foundation

// MARK: - Critic Review Gate (opt-in)
//
// One-shot LLM review of the task's uncommitted diff before task_complete is
// accepted. Runs at most ONCE per task (criticReviewDone) so a stubborn
// review can never loop completion forever. Opt-in via criticReviewEnabled
// (Settings → Coding → Critic Review).

extension AgentViewModel {

    /// Returns a `CANNOT COMPLETE — ...` blocker when the critic finds issues,
    /// or nil when completion may proceed (disabled, no edits, already ran,
    /// clean diff, or critic passed / failed to answer).
    func criticReviewBlocker(projectFolder overrideFolder: String? = nil) async -> String? {
        let base = overrideFolder ?? projectFolder
        let folder = base.isEmpty ? NSHomeDirectory() : base
        // Follow-up on the next task_complete: tell the user whether the AI
        // changed the code after the critic blocked it.
        if criticReviewDone, let blockedDiff = criticBlockedDiff {
            criticBlockedDiff = nil
            let current = await Self.offMain { Self.uncommittedDiff(folder: folder) }
            appendLog(current == blockedDiff
                ? "🧐 Critic follow-up: no code changes after review — AI completed without addressing the issues"
                : "🧐 Critic follow-up: AI changed the code after review (fixes not re-checked — critic runs once per task)")
            flushLog()
            return nil
        }
        guard criticReviewEnabled, !criticReviewDone else { return nil }
        guard !FileBackupService.shared.snapshottedFiles().isEmpty else { return nil }
        // One shot only — the next task_complete passes this gate regardless.
        criticReviewDone = true

        let diff = await Self.offMain { Self.uncommittedDiff(folder: folder) }
        guard !diff.isEmpty else { return nil }

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
            appendLog("✅ Critic review: PASS")
            flushLog()
            return nil
        }
        criticBlockedDiff = diff
        let issues = verdict.trimmingCharacters(in: .whitespacesAndNewlines)
        appendLog("🧐 Critic review found issues — blocking completion once:\n\(String(issues.prefix(2000)))")
        flushLog()
        return blocker
    }

    /// Maps the reviewer's reply to a completion blocker. A reply starting with
    /// "PASS" (any case, surrounding whitespace ignored) returns nil; anything
    /// else is quoted (capped at 2000 chars) inside a `CANNOT COMPLETE` block.
    nonisolated static func criticVerdictBlocker(_ verdict: String) -> String? {
        let trimmed = verdict.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.uppercased().hasPrefix("PASS") { return nil }
        return """
            CANNOT COMPLETE — a critic review of your diff found issues:

            \(String(trimmed.prefix(2000)))

            Address the valid issues (ignore any that are out of scope), then \
            call task_complete again. The critic will not run a second time.
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
        return String(out.prefix(12_000))
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
