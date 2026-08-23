import Foundation

// Feature #1 — Persistent Goal State + Self-Verifying Autonomy Loop.
// The agent records the active goal and its verifiable success criteria here.
// The state survives restarts (file-backed) and is injected into every system
// prompt so the model always knows what it is trying to achieve and what is
// left to verify. `task_complete` bounces back while criteria remain unverified.

/// A single verifiable success criterion for the active goal.
struct GoalCriterion: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String
    var done: Bool = false
    /// How this criterion was verified — the tool call or observation that
    /// proves it. Marking done without evidence is self-reporting, which is
    /// exactly what the verification loop exists to prevent.
    var evidence: String?
}

/// The persistent goal state for the autonomous loop.
struct GoalState: Codable, Equatable {
    var goal: String
    var criteria: [GoalCriterion] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var openCriteria: [GoalCriterion] { criteria.filter { !$0.done } }
    var allCriteriaDone: Bool { !criteria.isEmpty && openCriteria.isEmpty }
}

@MainActor
final class GoalStateStore {
    static let shared = GoalStateStore()

    private let url: URL
    private var cache: GoalState?

    init(directory: URL? = nil) {
        let dir = directory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Agent/GoalState", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("goal.json")
    }

    // MARK: - Persistence

    private func read() -> GoalState? {
        if let cache { return cache }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let state = try? JSONDecoder().decode(GoalState.self, from: data)
        cache = state
        return state
    }

    private func write(_ state: GoalState?) {
        cache = state
        guard let state, let data = try? JSONEncoder().encode(state) else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - API

    /// The active goal, if one has been set.
    var current: GoalState? { read() }

    /// Set (or replace) the active goal and its success criteria.
    @discardableResult
    func set(goal: String, criteria: [String]) -> GoalState {
        var state = GoalState(
            goal: goal.trimmingCharacters(in: .whitespacesAndNewlines),
            criteria: criteria
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .map { GoalCriterion(text: $0) }
        )
        state.updatedAt = Date()
        write(state)
        return state
    }

    /// Mark one criterion done/open by id.
    @discardableResult
    func setCriterion(id: UUID, done: Bool, evidence: String? = nil) -> GoalState? {
        guard var state = read(),
              let index = state.criteria.firstIndex(where: { $0.id == id }) else { return nil }
        state.criteria[index].done = done
        state.criteria[index].evidence = done ? evidence : nil
        state.updatedAt = Date()
        write(state)
        return state
    }

    /// Mark the first criterion matching `text` (case-insensitive contains).
    @discardableResult
    func setCriterion(text: String, done: Bool, evidence: String? = nil) -> GoalState? {
        guard var state = read(),
              let index = state.criteria.firstIndex(where: {
                  $0.text.localizedCaseInsensitiveContains(text)
              }) else { return nil }
        state.criteria[index].done = done
        state.criteria[index].evidence = done ? evidence : nil
        state.updatedAt = Date()
        write(state)
        return state
    }

    /// Criteria marked done with no evidence cited — self-reported, unproven.
    var unevidencedCriteria: [GoalCriterion] {
        (read()?.criteria ?? []).filter {
            $0.done && ($0.evidence?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }
    }

    /// Clear the goal (task fully complete).
    func clear() {
        write(nil)
    }

    /// Retire a goal nobody has touched in `maxAge` — it belongs to an
    /// abandoned task (cancelled, iteration-capped, or crashed before
    /// clearing) and would otherwise block every future task_complete via
    /// the completion gates. Returns the cleared goal's text, or nil.
    @discardableResult
    func clearIfStale(maxAge: TimeInterval = 86_400) -> String? {
        guard let state = read(),
              Date().timeIntervalSince(state.updatedAt) > maxAge else { return nil }
        clear()
        return state.goal
    }

    /// True when every criterion has been verified — the gate condition.
    var isVerified: Bool { read()?.allCriteriaDone ?? true }

    // MARK: - Prompt Injection

    /// Goal progress block injected into every system prompt.
    var promptBlock: String {
        guard let state = read(), !state.goal.isEmpty else { return "" }
        var block = "\n\nACTIVE GOAL (persist across turns until verified):\n\(state.goal)\n"
        if !state.criteria.isEmpty {
            block += "VERIFICATION CRITERIA (all must be checked before task_complete is accepted):\n"
            for (i, c) in state.criteria.enumerated() {
                block += "\(i + 1). [\(c.done ? "x" : " ")] \(c.text)\n"
                if c.done, let ev = c.evidence, !ev.isEmpty {
                    block += "     ↳ evidence: \(ev)\n"
                }
            }
            if !state.allCriteriaDone {
                block += "You may NOT call task_complete until every criterion above is [x]. Verify each with a tool call (build, grep, read) and mark it via goal_state, passing `evidence` describing the tool result that proves it.\n"
            }
        }
        return block
    }
}
