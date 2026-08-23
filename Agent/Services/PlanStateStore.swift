import Foundation

// Plan surfacing — inject the active plan's checklist into every system prompt
// so the model sees step status each turn instead of having to call
// plan_mode(action:"read"). Mirrors how GoalStateStore.promptBlock and
// ToolOutcomeStore.promptBlock are injected by the provider services.
// Pure file reads, no state — safe from any actor.

enum PlanStateStore {

    /// Walk up from `projectFolder` to the enclosing git repo root.
    /// Mirrors PlanMode.gitRoot (private to AgentViewModel).
    private static func gitRoot(_ projectFolder: String) -> String? {
        var dir = projectFolder.isEmpty ? NSHomeDirectory() : projectFolder
        let fm = FileManager.default
        while dir != "/" && !dir.isEmpty {
            if fm.fileExists(atPath: (dir as NSString).appendingPathComponent(".git")) {
                return dir
            }
            dir = (dir as NSString).deletingLastPathComponent
        }
        return nil
    }

    /// Most recently modified plan_*.md in the plans dir, or nil.
    private static func mostRecentPlanPath(_ projectFolder: String) -> String? {
        guard let root = gitRoot(projectFolder) else { return nil }
        let dir = AgentProjectPaths.path(in: root, .plans)
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: dir) else { return nil }
        let plans = files.filter { $0.hasPrefix("plan_") && $0.hasSuffix(".md") }
        guard !plans.isEmpty else { return nil }
        let sorted = plans.sorted { a, b in
            let pa = (dir as NSString).appendingPathComponent(a)
            let pb = (dir as NSString).appendingPathComponent(b)
            let da = (try? fm.attributesOfItem(atPath: pa)[.modificationDate] as? Date) ?? .distantPast
            let db = (try? fm.attributesOfItem(atPath: pb)[.modificationDate] as? Date) ?? .distantPast
            return da > db
        }
        return (dir as NSString).appendingPathComponent(sorted[0])
    }

    /// Compact checklist block for the system prompt. Empty string when there is
    /// no plan, the plan is fully completed (no noise after the work is done),
    /// or the plan file is stale (>24h old — likely from an abandoned task).
    static func promptBlock(projectFolder: String) -> String {
        guard let path = mostRecentPlanPath(projectFolder),
              let content = try? String(contentsOfFile: path, encoding: .utf8)
        else { return "" }

        // Stale-plan guard: a plan untouched for 24h belongs to a dead task.
        if let mtime = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date),
           Date().timeIntervalSince(mtime) > 24 * 3600 {
            return ""
        }

        let lines = content.components(separatedBy: "\n")
        let title = lines.first.flatMap { $0.hasPrefix("# ") ? String($0.dropFirst(2)) : nil } ?? "Plan"
        let steps = lines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("- [") }
        guard !steps.isEmpty else { return "" }

        let completed = steps.filter { $0.contains("- [✅]") }.count
        // Fully done — nothing to surface.
        guard completed < steps.count else { return "" }

        var block = "\n\nACTIVE PLAN — \(title) (\(completed)/\(steps.count) done):\n"
        block += steps.prefix(30).joined(separator: "\n")
        if steps.count > 30 { block += "\n… \(steps.count - 30) more steps" }
        block += "\nAfter finishing a step, mark it via plan_mode(action:\"update\", step:N, status:\"completed\") before moving on.\n"
        return block
    }
}
