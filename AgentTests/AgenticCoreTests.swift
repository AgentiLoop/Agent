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

    @Test("criteria marked done without evidence are reported as unevidenced")
    func unevidencedCriteriaAreTracked() {
        let store = makeStore()
        store.set(goal: "G", criteria: ["builds", "tests pass"])
        store.setCriterion(text: "builds", done: true)
        store.setCriterion(text: "tests pass", done: true, evidence: "26 tests passed")

        let unevidenced = store.unevidencedCriteria
        #expect(unevidenced.count == 1)
        #expect(unevidenced.first?.text == "builds")
    }

    @Test("re-opening a criterion clears its evidence")
    func reopeningClearsEvidence() {
        let store = makeStore()
        store.set(goal: "G", criteria: ["builds"])
        store.setCriterion(text: "builds", done: true, evidence: "xcode build succeeded")
        #expect(store.unevidencedCriteria.isEmpty)

        store.setCriterion(text: "builds", done: false)
        #expect(store.current?.criteria.first?.evidence == nil)
    }

    @Test("whitespace-only evidence does not count as evidence")
    func blankEvidenceIsRejected() {
        let store = makeStore()
        store.set(goal: "G", criteria: ["builds"])
        store.setCriterion(text: "builds", done: true, evidence: "   \n  ")
        #expect(store.unevidencedCriteria.count == 1)
    }

    @Test("promptBlock renders evidence for verified criteria")
    func promptBlockShowsEvidence() {
        let store = makeStore()
        store.set(goal: "G", criteria: ["builds"])
        store.setCriterion(text: "builds", done: true, evidence: "xcode build succeeded")
        #expect(store.promptBlock.contains("evidence: xcode build succeeded"))
    }
}

/// Regression coverage for AgentViewModel.isToolFailure(output:).
///
/// This logic has been wrong TWICE: it originally lowercased the entire tool
/// output and searched for "error:" / "failed" / "not found" anywhere in it.
/// A successful edit_file echoes a preview of the file's new content, so
/// editing any file whose SOURCE contains those words (XcodeService.swift,
/// Guards.swift) reported phantom failures and fired the stuck guards.
@MainActor
struct ToolFailureDetectionTests {
    @Test("a successful edit whose body contains failure words is NOT a failure")
    func successfulEditWithFailureWordsInBody() {
        // The exact shape that caused the bug: success status line, echoed
        // source code below it containing every trigger word.
        let output = """
        Replaced 1 occurrence in /path/XcodeService.swift [verified: true]

        📎
        let isFailure = lower.contains("error:") || lower.contains("failed")
        if buildResult == "not found" { return "rejected" }
        """
        #expect(AgentViewModel.isToolFailure(output: output) == false)
    }

    @Test("a write whose content mentions errors is NOT a failure")
    func successfulWriteWithErrorText() {
        let output = "Wrote 181 lines to /tmp/x.swift\n\nerror: this is file content, not a status"
        #expect(AgentViewModel.isToolFailure(output: output) == false)
    }

    @Test("real failures are still detected from the status line")
    func realFailuresDetected() {
        #expect(AgentViewModel.isToolFailure(output: "Error: file not writable"))
        #expect(AgentViewModel.isToolFailure(output: "error: no such file"))
        #expect(AgentViewModel.isToolFailure(output: "❌ edit rejected"))
        #expect(AgentViewModel.isToolFailure(output: "warning: nothing matched"))
        #expect(AgentViewModel.isToolFailure(output: "String not found in file"))
        #expect(AgentViewModel.isToolFailure(output: "Edit rejected — ambiguous match"))
        #expect(AgentViewModel.isToolFailure(output: "No changes made to the file"))
    }

    @Test("detection is case-insensitive and ignores leading whitespace")
    func detectionNormalizesStatusLine() {
        #expect(AgentViewModel.isToolFailure(output: "   ERROR: boom"))
        #expect(AgentViewModel.isToolFailure(output: "  Not Found  "))
    }

    @Test("ordinary success output is not a failure")
    func plainSuccessIsNotFailure() {
        #expect(AgentViewModel.isToolFailure(output: "Build succeeded") == false)
        #expect(AgentViewModel.isToolFailure(output: "Applied diff to /tmp/a.swift") == false)
        #expect(AgentViewModel.isToolFailure(output: "") == false)
    }

    @Test("the bare word 'failed' in a status line does not trigger detection")
    func bareFailedIsNotATrigger() {
        // "failed" was dropped as a trigger precisely because it matches
        // ordinary prose and source text. Build failures are caught by the
        // separate consecutiveBuildFailures counter, not this helper.
        #expect(AgentViewModel.isToolFailure(output: "3 tests failed in DiffToolsTests") == false)
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

// MARK: - FallbackChainService

/// Coverage for the user-configured model fallback state machine.
/// The singleton persists to UserDefaults, so every test snapshots and
/// restores the persisted state to avoid leaking fake providers between tests.
@Suite(.serialized)
@MainActor
struct FallbackChainServiceTests {
    private static let chainKey = "agent.fallbackChain"
    private static let enabledKey = "agent.fallbackEnabled"

    private func withIsolatedService(_ body: (FallbackChainService) -> Void) {
        let defaults = UserDefaults.standard
        let originalData = defaults.data(forKey: Self.chainKey)
        let originalEnabled = defaults.object(forKey: Self.enabledKey)
        let service = FallbackChainService.shared
        let originalChain = service.chain
        let originalEnabledValue = service.enabled

        service.clear()
        service.enabled = true

        defer {
            service.clear()
            for entry in originalChain {
                service.add(provider: entry.provider, model: entry.model)
                if !entry.enabled {
                    let restored = service.chain.last
                    if let restored {
                        service.toggle(id: restored.id)
                    }
                }
            }
            service.enabled = originalEnabledValue

            if let originalData {
                defaults.set(originalData, forKey: Self.chainKey)
            } else {
                defaults.removeObject(forKey: Self.chainKey)
            }
            if let originalEnabled {
                defaults.set(originalEnabled, forKey: Self.enabledKey)
            } else {
                defaults.removeObject(forKey: Self.enabledKey)
            }
        }

        body(service)
    }

    @Test("first failure does not trigger fallback")
    func firstFailureDoesNotFallback() {
        withIsolatedService { service in
            service.add(provider: "provider-a", model: "model-a")
            let result = service.recordFailure()
            #expect(result == nil)
            #expect(service.currentIndex == -1)
            #expect(service.consecutiveFailures == 1)
            #expect(service.activeFallback == nil)
        }
    }

    @Test("second failure selects the first enabled fallback")
    func secondFailureSelectsFirstFallback() {
        withIsolatedService { service in
            service.add(provider: "provider-a", model: "model-a")
            _ = service.recordFailure()
            let result = service.recordFailure()
            #expect(result?.provider == "provider-a")
            #expect(result?.model == "model-a")
            #expect(service.currentIndex == 0)
            #expect(service.consecutiveFailures == 0)
            #expect(service.activeFallback?.model == "model-a")
        }
    }

    @Test("fallback chain advances to the next enabled entry")
    func advancesThroughFallbackChain() {
        withIsolatedService { service in
            service.add(provider: "provider-a", model: "model-a")
            service.add(provider: "provider-b", model: "model-b")
            _ = service.recordFailure()
            _ = service.recordFailure()
            _ = service.recordFailure()
            let result = service.recordFailure()
            #expect(result?.provider == "provider-b")
            #expect(result?.model == "model-b")
            #expect(service.currentIndex == 1)
            #expect(service.activeFallback?.model == "model-b")
        }
    }

    @Test("disabled fallback entries are skipped")
    func skipsDisabledEntries() {
        withIsolatedService { service in
            service.add(provider: "provider-disabled", model: "model-disabled")
            service.add(provider: "provider-enabled", model: "model-enabled")
            let entries = service.chain
            service.toggle(id: entries[0].id)
            _ = service.recordFailure()
            let result = service.recordFailure()
            #expect(result?.provider == "provider-enabled")
            #expect(result?.model == "model-enabled")
            #expect(service.currentIndex == 0)
        }
    }

    @Test("disabled fallback feature never switches providers")
    func disabledFallbackFeature() {
        withIsolatedService { service in
            service.enabled = false
            service.add(provider: "provider-a", model: "model-a")
            _ = service.recordFailure()
            let result = service.recordFailure()
            #expect(result == nil)
            #expect(service.currentIndex == -1)
            #expect(service.consecutiveFailures == 2)
            #expect(service.activeFallback == nil)
        }
    }

    @Test("successful call returns service to primary provider")
    func successReturnsToPrimary() {
        withIsolatedService { service in
            service.add(provider: "provider-a", model: "model-a")
            _ = service.recordFailure()
            _ = service.recordFailure()
            #expect(service.activeFallback != nil)
            service.recordSuccess()
            #expect(service.currentIndex == -1)
            #expect(service.consecutiveFailures == 0)
            #expect(service.activeFallback == nil)
        }
    }

    @Test("reset clears fallback state without removing chain")
    func resetClearsState() {
        withIsolatedService { service in
            service.add(provider: "provider-a", model: "model-a")
            _ = service.recordFailure()
            _ = service.recordFailure()
            service.reset()
            #expect(service.currentIndex == -1)
            #expect(service.consecutiveFailures == 0)
            #expect(service.activeFallback == nil)
            #expect(service.chain.count == 1)
        }
    }

    @Test("clear removes the chain and resets state")
    func clearResetsEverything() {
        withIsolatedService { service in
            service.add(provider: "provider-a", model: "model-a")
            _ = service.recordFailure()
            _ = service.recordFailure()
            service.clear()
            #expect(service.chain.isEmpty)
            #expect(service.currentIndex == -1)
            #expect(service.consecutiveFailures == 0)
            #expect(service.activeFallback == nil)
            #expect(service.summary == "No fallback chain configured.")
        }
    }

    @Test("summary marks the active fallback")
    func summaryMarksActiveFallback() {
        withIsolatedService { service in
            service.add(provider: "provider-a", model: "model-a")
            service.add(provider: "provider-b", model: "model-b")
            let initialSummary = service.summary
            #expect(initialSummary.contains("1. provider-a / model-a"))
            #expect(initialSummary.contains("2. provider-b / model-b"))
            _ = service.recordFailure()
            _ = service.recordFailure()
            #expect(service.summary.contains("→ 1. provider-a / model-a"))
        }
    }

    @Test("FallbackEntry keeps an unknown provider raw value in its display name")
    func unknownProviderDisplayName() {
        withIsolatedService { _ in
            let entry = FallbackEntry(provider: "unknown-provider", model: "model-x")
            #expect(entry.displayName == "unknown-provider / model-x")
            #expect(entry.enabled)
        }
    }
}
