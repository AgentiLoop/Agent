import Foundation

// MARK: - Auto-Pilot multi-tab coordination
//
// Several Auto-Pilot tabs may run on the same project at once. Each tab keeps
// its own state under `.agent/tabs/<key>/` (progress log) plus its own goal
// (GoalStateStore per tab) and plan (plan_<tab>.md). What they share:
//   - `.agent/memory/` and `.agent/index/` (project knowledge)
//   - `.agent/tabs/registry.json` — who is running, on what goal, in which
//     folder/branch, so each cycle's prompt can steer around the others' work.
// Source-code isolation: a session can run in its own git worktree
// (`.agent/worktrees/autopilot-<key>` on branch `autopilot/<key>-…`). By
// default a worktree is used automatically when another live session is
// already registered on the same project; `--worktree` / `--shared` force it.

struct AutoPilotRegistryEntry: Codable {
    var key: String
    var title: String
    var goal: String
    var workFolder: String
    var branch: String?
    var heartbeat: Date = Date()
}

enum AutoPilotRegistry {
    /// An entry not refreshed for this long belongs to a closed/crashed tab.
    static let staleAfter: TimeInterval = 2 * 3600

    static func tabDir(root: String, key: String) -> URL {
        AgentProjectPaths.url(in: root, .tabs).appendingPathComponent(key, isDirectory: true)
    }

    private static func registryURL(_ root: String) -> URL {
        AgentProjectPaths.url(in: root, .tabs).appendingPathComponent("registry.json")
    }

    /// Read-modify-write under an exclusive flock so tabs never drop each other's entries.
    private static func update(root: String, _ body: (inout [String: AutoPilotRegistryEntry]) -> Void) {
        let dir = AgentProjectPaths.url(in: root, .tabs)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fd = open(dir.appendingPathComponent("registry.lock").path, O_CREAT | O_RDWR, 0o644)
        guard fd >= 0 else { return }
        defer { flock(fd, LOCK_UN); close(fd) }
        flock(fd, LOCK_EX)
        let url = registryURL(root)
        var entries = (try? Data(contentsOf: url))
            .flatMap { try? JSONDecoder().decode([String: AutoPilotRegistryEntry].self, from: $0) } ?? [:]
        entries = entries.filter { Date().timeIntervalSince($0.value.heartbeat) < staleAfter }
        body(&entries)
        if let data = try? JSONEncoder().encode(entries) { try? data.write(to: url, options: .atomic) }
    }

    static func upsert(root: String, _ entry: AutoPilotRegistryEntry) {
        var e = entry
        e.heartbeat = Date()
        update(root: root) { $0[e.key] = e }
    }

    static func remove(root: String, key: String) {
        update(root: root) { $0[key] = nil }
    }

    /// Live sessions on this project other than `key`.
    static func others(root: String, excluding key: String) -> [AutoPilotRegistryEntry] {
        var result: [AutoPilotRegistryEntry] = []
        update(root: root) { result = $0.values.filter { $0.key != key }.sorted { $0.key < $1.key } }
        return result
    }

    // MARK: Git worktree

    @discardableResult
    private static func git(_ args: [String]) -> (ok: Bool, out: String) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return (false, error.localizedDescription) }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        let out = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return (p.terminationStatus == 0, out)
    }

    /// Top level of the git repo containing `folder`, or nil.
    static func gitRoot(_ folder: String) -> String? {
        let r = git(["-C", folder, "rev-parse", "--show-toplevel"])
        return r.ok && !r.out.isEmpty ? r.out : nil
    }

    /// Create (or reuse) this tab's worktree. Returns the folder matching
    /// `folder` inside the worktree (same subpath), and the branch.
    static func worktree(for folder: String, key: String) -> (folder: String, branch: String)? {
        guard let root = gitRoot(folder) else { return nil }
        let path = AgentProjectPaths.path(in: root, .worktrees) + "/autopilot-\(key)"
        if !FileManager.default.fileExists(atPath: path + "/.git") {
            let f = DateFormatter()
            f.dateFormat = "yyyyMMdd-HHmm"
            let branch = "autopilot/\(key)-\(f.string(from: Date()))"
            guard git(["-C", root, "worktree", "add", "-b", branch, path, "HEAD"]).ok else { return nil }
        }
        let branch = git(["-C", path, "rev-parse", "--abbrev-ref", "HEAD"]).out
        // realpath (not resolvingSymlinksInPath, which strips /private) to match git's toplevel.
        let resolved = realpath(folder, nil).map { p in defer { free(p) }; return String(cString: p) } ?? folder
        let sub = resolved.hasPrefix(root) ? String(resolved.dropFirst(root.count)) : ""
        return (path + sub, branch)
    }
}
