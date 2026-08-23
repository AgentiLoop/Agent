import Testing
import Foundation
@testable import Agent_

// Coverage for the agentic-loop core: goal state persistence + the gate
// condition that blocks task_complete, and the broken-record tool-call
// fingerprint / repeat-exemption logic in StuckGuard.

// MARK: - GoalStateStore

@MainActor
struct GoalStateStoreTests {
    /// Fresh store in a temp dir so tests never touch the real goal.json.
    private func makeStore() -> GoalStateStore {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AgentGoalTests-\(UUID().uuidString)", isDirectory: true)
        return GoalStateStore(directory: dir)
    }

    @Test("set() stores the goal and trims/filters criteria")
    func setStoresGoalAndCriteria() {
        let store = makeStore()
        let state = store.set(goal: "  Ship the feature  ", criteria: ["  builds  ", "", "   ", "tests pass"])
        #expect(state.goal == "Ship the feature")
        #expect(state.criteria.count == 2)
        #expect(state.criteria[0].text == "builds")
        #expect(state.criteria[1].text == "tests pass")
        #expect(state.criteria.allSatisfy { !$0.done })
    }

    @Test("allCriteriaDone is false while any criterion is open")
    func gateBlocksWhileOpen() {
        let store = makeStore()
        store.set(goal: "G", criteria: ["a", "b"])
        #expect(store.current?.allCriteriaDone == false)
        #expect(store.isVerified == false)

        store.setCriterion(text: "a", done: true)
        #expect(store.current?.allCriteriaDone == false)

        store.setCriterion(text: "b", done: true)
        #expect(store.current?.allCriteriaDone == true)
        #expect(store.isVerified == true)
    }

    @Test("an empty criteria list never counts as verified")
    func emptyCriteriaIsNotDone() {
        let store = makeStore()
        let state = store.set(goal: "G", criteria: [])
        // allCriteriaDone requires a non-empty list — a goal with no criteria
        // must not silently satisfy the task_complete gate.
        #expect(state.allCriteriaDone == false)
    }

    @Test("setCriterion(text:) matches case-insensitively and only the first match")
    func criterionMatchIsCaseInsensitive() {
        let store = makeStore()
        store.set(goal: "G", criteria: ["Build Succeeds", "build artifacts uploaded"])
        store.setCriterion(text: "BUILD", done: true)
        let criteria = store.current?.criteria ?? []
        #expect(criteria[0].done == true)
        #expect(criteria[1].done == false)
    }

    @Test("setCriterion returns nil when no goal or no match")
    func criterionMissReturnsNil() {
        let store = makeStore()
        #expect(store.setCriterion(text: "nope", done: true) == nil)
        store.set(goal: "G", criteria: ["a"])
        #expect(store.setCriterion(text: "zzz", done: true) == nil)
        #expect(store.setCriterion(id: UUID(), done: true) == nil)
    }

    @Test("state survives a new store instance over the same directory")
    func statePersistsAcrossInstances() {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AgentGoalTests-\(UUID().uuidString)", isDirectory: true)
        let first = GoalStateStore(directory: dir)
        first.set(goal: "Persisted", criteria: ["one"])

        let second = GoalStateStore(directory: dir)
        #expect(second.current?.goal == "Persisted")
        #expect(second.current?.criteria.count == 1)
    }

    @Test("clear() removes the goal and reopens the gate")
    func clearResetsState() {
        let store = makeStore()
        store.set(goal: "G", criteria: ["a"])
        store.clear()
        #expect(store.current == nil)
        // No goal means nothing to verify — the gate must not deadlock.
        #expect(store.isVerified == true)
        #expect(store.promptBlock.isEmpty)
    }

    @Test("promptBlock lists criteria and warns only while incomplete")
    func promptBlockReflectsProgress() {
        let store = makeStore()
        store.set(goal: "Ship it", criteria: ["builds", "committed"])

        let open = store.promptBlock
        #expect(open.contains("Ship it"))
        #expect(open.contains("1. [ ] builds"))
        #expect(open.contains("2. [ ] committed"))
        #expect(open.contains("may NOT call task_complete"))

        store.setCriterion(text: "builds", done: true)
        store.setCriterion(text: "committed", done: true)
        let done = store.promptBlock
        #expect(done.contains("1. [x] builds"))
        #expect(!done.contains("may NOT call task_complete"))
    }
}

// MARK: - StuckGuard fingerprinting

@MainActor
struct StuckGuardFingerprintTests {
    @Test("identical calls produce an identical fingerprint")
    func identicalCallsMatch() {
        let a = AgentViewModel.toolCallFingerprint(name: "search_files", input: ["pattern": "foo", "path": "/tmp"])
        let b = AgentViewModel.toolCallFingerprint(name: "search_files", input: ["pattern": "foo", "path": "/tmp"])
        #expect(a == b)
    }

    @Test("key order does not affect the fingerprint")
    func keyOrderIsNormalized() {
        let a = AgentViewModel.toolCallFingerprint(name: "t", input: ["z": 1, "a": 2, "m": 3])
        let b = AgentViewModel.toolCallFingerprint(name: "t", input: ["a": 2, "m": 3, "z": 1])
        #expect(a == b)
    }

    @Test("a different value or tool name changes the fingerprint")
    func differencesAreDetected() {
        let base = AgentViewModel.toolCallFingerprint(name: "search_files", input: ["pattern": "foo"])
        let otherValue = AgentViewModel.toolCallFingerprint(name: "search_files", input: ["pattern": "bar"])
        let otherName = AgentViewModel.toolCallFingerprint(name: "list_files", input: ["pattern": "foo"])
        #expect(base != otherValue)
        #expect(base != otherName)
    }

    @Test("an extra key changes the fingerprint")
    func extraKeyIsDetected() {
        let a = AgentViewModel.toolCallFingerprint(name: "t", input: ["a": 1])
        let b = AgentViewModel.toolCallFingerprint(name: "t", input: ["a": 1, "b": 2])
        #expect(a != b)
    }

    @Test("the fingerprint is prefixed with the tool name")
    func fingerprintCarriesToolName() {
        let fp = AgentViewModel.toolCallFingerprint(name: "xcode", input: ["action": "build"])
        #expect(fp.hasPrefix("xcode|"))
    }

    @Test("empty input still fingerprints deterministically")
    func emptyInputIsStable() {
        let a = AgentViewModel.toolCallFingerprint(name: "git", input: [:])
        let b = AgentViewModel.toolCallFingerprint(name: "git", input: [:])
        #expect(a == b)
        #expect(a.hasPrefix("git|"))
    }

    @Test("polling and dialog tools are exempt from the repeat guard")
    func pollingToolsAreExempt() {
        // These legitimately repeat with identical input and must never be
        // flagged as a broken record.
        #expect(AgentViewModel.repeatExemptTools.contains("wait_for_element"))
        #expect(AgentViewModel.repeatExemptTools.contains("find_element"))
        #expect(AgentViewModel.repeatExemptTools.contains("ask_user"))
        #expect(AgentViewModel.repeatExemptTools.contains("task_complete"))
    }

    @Test("mutating tools are NOT exempt from the repeat guard")
    func mutatingToolsAreGuarded() {
        #expect(!AgentViewModel.repeatExemptTools.contains("edit_file"))
        #expect(!AgentViewModel.repeatExemptTools.contains("write_file"))
        #expect(!AgentViewModel.repeatExemptTools.contains("search_files"))
        #expect(!AgentViewModel.repeatExemptTools.contains("xcode"))
    }
}
