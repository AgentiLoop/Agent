
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
    func criticReviewBlocker() async -> String? {
        guard criticReviewEnabled, !criticReviewDone else { return nil }
        guard !FileBackupService.shared.snapshottedFiles().isEmpty else { return nil }
        // One shot only — the next task_complete passes this gate regardless.
        criticReviewDone = true

        let folder = projectFolder.isEmpty ? NSHomeDirectory() : projectFolder
        let diff = await Self.offMain { Self.uncommittedDiff(folder: folder) }
        guard !diff.isEmpty else { return nil }

        appendLog("🧐 Critic review: analyzing task diff (\(diff.count) chars)...")
        flushLog()

        guard let verdict = await runCriticLLM(diff: diff) else {
            appendLog("🧐 Critic review skipped (no reviewer response)")
            flushLog()
            return nil
        }
        let trimmed = verdict.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.uppercased().hasPrefix("PASS") {
            appendLog("✅ Critic review: PASS")
            flushLog()
            return nil
        }
        appendLog("🧐 Critic review found issues — blocking completion once")
        flushLog()
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
    /// tool calls in the reply are ignored. Returns nil on any failure so the
    /// gate degrades to a no-op instead of blocking completion.
    private func runCriticLLM(diff: String) async -> String? {
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
        let services = buildTabLLMServices(
            provider: criticProvider,
            modelId: criticModel,
            historyContext: "",
            projectFolder: projectFolder,
            maxTokens: 2048
        )
        services.claude?.overrideSystemPrompt = criticSystemPrompt
        services.openAICompatible?.overrideSystemPrompt = criticSystemPrompt
        services.ollama?.overrideSystemPrompt = criticSystemPrompt

        do {
            let content: [[String: Any]]
            if let claude = services.claude {
                content = try await claude.send(messages: messages).content
            } else if let openAI = services.openAICompatible {
                content = try await openAI.send(messages: messages).content
            } else if let ollama = services.ollama {
                content = try await ollama.send(messages: messages).content
            } else {
                return nil
            }
            let text = content.compactMap { $0["text"] as? String }.joined(separator: "\n")
            return text.isEmpty ? nil : text
        } catch {
            return nil
        }
    }
}
