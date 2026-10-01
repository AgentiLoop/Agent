import Testing
import Foundation
@testable import Agent_

// Critic review gate (CriticGate.swift): the opt-in one-shot LLM review of the
// task diff that runs before task_complete is accepted. Everything here is
// offline — the gate's pre-LLM short-circuits, the git diff capture, and the
// verdict → blocker mapping. The network call itself (runCriticLLM) is not
// exercised; it uses the same provider + API key as the active task.

@MainActor
struct CriticGateTests {

    // MARK: - Fixtures

    private func tempDir() -> String {
        let dir = NSTemporaryDirectory() + "critic-\(UUID().uuidString)"
        try! FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return dir
    }

    @discardableResult
    private func git(_ args: [String], in dir: String) -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        p.arguments = args
        p.currentDirectoryURL = URL(fileURLWithPath: dir)
        p.standardOutput = Pipe()
        p.standardError = Pipe()
        try! p.run()
        p.waitUntilExit()
        return p.terminationStatus
    }

    /// A git repo with one committed file `a.txt` containing "one\n".
    private func repoWithCommit() -> String {
        let dir = tempDir()
        git(["init", "-q"], in: dir)
        git(["config", "user.email", "t@t"], in: dir)
        git(["config", "user.name", "t"], in: dir)
        try! "one\n".write(toFile: dir + "/a.txt", atomically: true, encoding: .utf8)
        git(["add", "a.txt"], in: dir)
        git(["commit", "-q", "-m", "init"], in: dir)
        return dir
    }

    /// Runs `body` with the critic toggle set, restoring the persisted
    /// UserDefaults value and task snapshots afterwards.
    private func withCritic(enabled: Bool, _ body: (AgentViewModel) async -> Void) async {
        let saved = UserDefaults.standard.bool(forKey: "codingCriticReview")
        let vm = AgentViewModel()
        vm.criticReviewEnabled = enabled
        vm.criticReviewDone = false
        FileBackupService.shared.clearTaskSnapshots()
        await body(vm)
        FileBackupService.shared.clearTaskSnapshots()
        UserDefaults.standard.set(saved, forKey: "codingCriticReview")
    }

    // MARK: - Verdict parsing

    @Test("PASS (any case, padded) → no blocker")
    func passVerdict() {
        #expect(AgentViewModel.criticVerdictBlocker("PASS") == nil)
        #expect(AgentViewModel.criticVerdictBlocker("  pass\n") == nil)
        #expect(AgentViewModel.criticVerdictBlocker("PASS — looks good.") == nil)
    }

    @Test("ISSUES reply → CANNOT COMPLETE blocker quoting the issues")
    func issuesVerdict() {
        let blocker = AgentViewModel.criticVerdictBlocker("ISSUES:\n- foo() is never called")
        #expect(blocker?.hasPrefix("CANNOT COMPLETE") == true)
        #expect(blocker?.contains("- foo() is never called") == true)
        #expect(blocker?.contains("diff unchanged will be refused") == true)
    }

    @Test("a reply that only mentions PASS mid-text is not a pass")
    func passMustBePrefix() {
        #expect(AgentViewModel.criticVerdictBlocker("ISSUES: this does not PASS") != nil)
        #expect(AgentViewModel.criticVerdictBlocker("") != nil)
    }

    @Test("verdict body is capped at 2000 chars")
    func verdictCapped() {
        let long = "ISSUES:\n" + String(repeating: "x", count: 5000)
        let blocker = AgentViewModel.criticVerdictBlocker(long)!
        #expect(blocker.count < 2300)
        #expect(blocker.contains(String(repeating: "x", count: 1900)))
        #expect(!blocker.contains(String(repeating: "x", count: 2100)))
    }

    // MARK: - Diff capture

    @Test("uncommittedDiff: not a git repo → empty")
    func diffNonRepo() {
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(atPath: dir) }
        #expect(AgentViewModel.uncommittedDiff(folder: dir) == "")
    }

    @Test("uncommittedDiff: clean tree → empty; edited tracked file → diff; staged too")
    func diffTrackedChange() {
        let dir = repoWithCommit()
        defer { try? FileManager.default.removeItem(atPath: dir) }
        #expect(AgentViewModel.uncommittedDiff(folder: dir) == "")

        try! "one\ntwo\n".write(toFile: dir + "/a.txt", atomically: true, encoding: .utf8)
        let unstaged = AgentViewModel.uncommittedDiff(folder: dir)
        #expect(unstaged.contains("+two"))
        #expect(unstaged.contains("a/a.txt"))

        git(["add", "a.txt"], in: dir)
        #expect(AgentViewModel.uncommittedDiff(folder: dir).contains("+two"))
    }

    @Test("uncommittedDiff: untracked files are not part of the diff")
    func diffIgnoresUntracked() {
        let dir = repoWithCommit()
        defer { try? FileManager.default.removeItem(atPath: dir) }
        try! "new\n".write(toFile: dir + "/b.txt", atomically: true, encoding: .utf8)
        #expect(AgentViewModel.uncommittedDiff(folder: dir) == "")
    }

    @Test("uncommittedDiff: capped at 12_000 chars")
    func diffCapped() {
        let dir = repoWithCommit()
        defer { try? FileManager.default.removeItem(atPath: dir) }
        let big = (0..<2000).map { "line \($0) padding padding padding" }.joined(separator: "\n")
        try! big.write(toFile: dir + "/a.txt", atomically: true, encoding: .utf8)
        #expect(AgentViewModel.uncommittedDiff(folder: dir).count == 12_000)
    }

    // MARK: - Gate short-circuits (no LLM call)

    @Test("disabled → nil, and the one-shot flag is untouched")
    func gateDisabled() async {
        await withCritic(enabled: false) { vm in
            let dir = repoWithCommit()
            defer { try? FileManager.default.removeItem(atPath: dir) }
            try! "one\ntwo\n".write(toFile: dir + "/a.txt", atomically: true, encoding: .utf8)
            FileBackupService.shared.snapshot(filePath: dir + "/a.txt", tabID: UUID())
            #expect(await vm.criticReviewBlocker(projectFolder: dir) == nil)
            #expect(vm.criticReviewDone == false)
        }
    }

    @Test("enabled but no files edited this task → nil, flag untouched")
    func gateNoEdits() async {
        await withCritic(enabled: true) { vm in
            let dir = repoWithCommit()
            defer { try? FileManager.default.removeItem(atPath: dir) }
            try! "one\ntwo\n".write(toFile: dir + "/a.txt", atomically: true, encoding: .utf8)
            #expect(await vm.criticReviewBlocker(projectFolder: dir) == nil)
            #expect(vm.criticReviewDone == false)
        }
    }

    @Test("enabled + edits + clean diff → nil, but the one shot is consumed")
    func gateCleanDiffConsumesShot() async {
        await withCritic(enabled: true) { vm in
            let dir = repoWithCommit()
            defer { try? FileManager.default.removeItem(atPath: dir) }
            FileBackupService.shared.snapshot(filePath: dir + "/a.txt", tabID: UUID())
            #expect(await vm.criticReviewBlocker(projectFolder: dir) == nil)
            #expect(vm.criticReviewDone == true)
        }
    }

    @Test("already ran this task → nil without touching the log")
    func gateOneShot() async {
        await withCritic(enabled: true) { vm in
            let dir = repoWithCommit()
            defer { try? FileManager.default.removeItem(atPath: dir) }
            try! "one\ntwo\n".write(toFile: dir + "/a.txt", atomically: true, encoding: .utf8)
            FileBackupService.shared.snapshot(filePath: dir + "/a.txt", tabID: UUID())
            vm.criticReviewDone = true
            let before = vm.activityLog
            #expect(await vm.criticReviewBlocker(projectFolder: dir) == nil)
            #expect(vm.activityLog == before)
        }
    }

    @Test("a failed reviewer request never blocks completion and logs the reason")
    func gateFailureDegradesToNoop() async {
        await withCritic(enabled: true) { vm in
            // Point the review at a provider whose OpenAI-compatible URL is a
            // dead localhost port so the request fails fast and offline.
            // Both settings persist to UserDefaults — restore them after.
            let defaults = UserDefaults.standard
            let saved = ["agentProvider", "mainTabProvider", "vLLMEndpoint"]
                .map { ($0, defaults.string(forKey: $0)) }
            defer { for (key, value) in saved { defaults.set(value, forKey: key) } }
            vm.selectedProvider = .vLLM
            vm.vLLMEndpoint = "http://127.0.0.1:9/v1"
            let dir = repoWithCommit()
            defer { try? FileManager.default.removeItem(atPath: dir) }
            try! "one\ntwo\n".write(toFile: dir + "/a.txt", atomically: true, encoding: .utf8)
            FileBackupService.shared.snapshot(filePath: dir + "/a.txt", tabID: UUID())
            #expect(await vm.criticReviewBlocker(projectFolder: dir) == nil)
            #expect(vm.criticReviewDone == true)
            #expect(vm.activityLog.contains("Critic review: analyzing task diff"))
            #expect(vm.activityLog.contains("Critic review skipped (reviewer request failed:"))
        }
    }
}
