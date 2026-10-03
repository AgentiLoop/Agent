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

    /// This tab's plan file (`plan_<tab slug>.md`, the name plan_mode writes —
    /// "main" for the main tab). Scoped per tab so parallel tabs on the same
    /// project never surface each other's plans.
    private static func tabPlanPath(_ projectFolder: String, slug: String) -> String? {
        guard let root = gitRoot(projectFolder) else { return nil }
        let path = (AgentProjectPaths.path(in: root, .plans) as NSString)
            .appendingPathComponent("plan_\(slug).md")
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    /// Compact checklist block for the system prompt. Empty string when there is
    /// no plan, the plan is fully completed (no noise after the work is done),
    /// or the plan file is stale (>24h old — likely from an abandoned task).
    @MainActor
    static func promptBlock(projectFolder: String) -> String {
        let slug = AgentViewModel.sanitizeTabName(TabLogRouter.current?.displayTitle ?? "main")
        guard let path = tabPlanPath(projectFolder, slug: slug),
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
