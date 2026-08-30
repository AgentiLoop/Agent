import Testing
import Foundation
@testable import Agent_

@Suite("FallbackChainService")
@MainActor
struct FallbackChainServiceTests {
    private func makeService() -> FallbackChainService {
        let service = FallbackChainService.shared
        service.clear()
        service.enabled = true
        return service
    }

    @Test("First failure does not trigger fallback")
    func firstFailureDoesNotFallback() {
        let service = makeService()
        service.add(provider: "provider-a", model: "model-a")

        let result = service.recordFailure()

        #expect(result == nil)
        #expect(service.currentIndex == -1)
        #expect(service.consecutiveFailures == 1)
        #expect(service.activeFallback == nil)
    }

    @Test("Second failure selects the first enabled fallback")
    func secondFailureSelectsFirstFallback() {
        let service = makeService()
        service.add(provider: "provider-a", model: "model-a")

        _ = service.recordFailure()
        let result = service.recordFailure()

        #expect(result?.provider == "provider-a")
        #expect(result?.model == "model-a")
        #expect(service.currentIndex == 0)
        #expect(service.consecutiveFailures == 0)
        #expect(service.activeFallback?.model == "model-a")
    }

    @Test("Fallback chain advances to the next enabled entry")
    func advancesThroughFallbackChain() {
        let service = makeService()
        service.add(provider: "provider-a", model: "model-a")
        service.add(provider: "provider-b", model: "model-b")

        _ = service.recordFailure()
        _ = service.recordFailure()
        #expect(service.activeFallback?.model == "model-a")

        _ = service.recordFailure()
        let result = service.recordFailure()

        #expect(result?.provider == "provider-b")
        #expect(result?.model == "model-b")
        #expect(service.currentIndex == 1)
        #expect(service.activeFallback?.model == "model-b")
    }

    @Test("Disabled fallback entries are skipped")
    func skipsDisabledEntries() {
        let service = makeService()
        service.add(provider: "provider-disabled", model: "model-disabled")
        service.add(provider: "provider-enabled", model: "model-enabled")

        let entries = service.chainForTesting
        service.toggle(id: entries[0].id)

        _ = service.recordFailure()
        let result = service.recordFailure()

        #expect(result?.provider == "provider-enabled")
        #expect(result?.model == "model-enabled")
        #expect(service.currentIndex == 0)
    }

    @Test("Disabled fallback feature never switches providers")
    func disabledFallbackFeature() {
        let service = makeService()
        service.enabled = false
        service.add(provider: "provider-a", model: "model-a")

        _ = service.recordFailure()
        let result = service.recordFailure()

        #expect(result == nil)
        #expect(service.currentIndex == -1)
        #expect(service.consecutiveFailures == 2)
        #expect(service.activeFallback == nil)
    }

    @Test("Successful call returns service to primary provider")
    func successReturnsToPrimary() {
        let service = makeService()
        service.add(provider: "provider-a", model: "model-a")

        _ = service.recordFailure()
        _ = service.recordFailure()
        #expect(service.activeFallback != nil)

        service.recordSuccess()

        #expect(service.currentIndex == -1)
        #expect(service.consecutiveFailures == 0)
        #expect(service.activeFallback == nil)
    }

    @Test("Reset clears fallback state without removing chain")
    func resetClearsState() {
        let service = makeService()
        service.add(provider: "provider-a", model: "model-a")

        _ = service.recordFailure()
        _ = service.recordFailure()
        service.reset()

        #expect(service.currentIndex == -1)
        #expect(service.consecutiveFailures == 0)
        #expect(service.activeFallback == nil)
        #expect(service.chainForTesting.count == 1)
    }

    @Test("Clear removes the chain and resets state")
    func clearResetsEverything() {
        let service = makeService()
        service.add(provider: "provider-a", model: "model-a")
        _ = service.recordFailure()
        _ = service.recordFailure()

        service.clear()

        #expect(service.chainForTesting.isEmpty)
        #expect(service.currentIndex == -1)
        #expect(service.consecutiveFailures == 0)
        #expect(service.activeFallback == nil)
        #expect(service.summary == "No fallback chain configured.")
    }

    @Test("Summary marks the active fallback")
    func summaryMarksActiveFallback() {
        let service = makeService()
        service.add(provider: "provider-a", model: "model-a")
        service.add(provider: "provider-b", model: "model-b")

        let initialSummary = service.summary
        #expect(initialSummary.contains("1. provider-a / model-a"))
        #expect(initialSummary.contains("2. provider-b / model-b"))

        _ = service.recordFailure()
        _ = service.recordFailure()

        #expect(service.summary.contains("→ 1. provider-a / model-a"))
    }

    @Test("FallbackEntry keeps an unknown provider raw value in its display name")
    func unknownProviderDisplayName() {
        let entry = FallbackEntry(provider: "unknown-provider", model: "model-x")

        #expect(entry.displayName == "unknown-provider / model-x")
        #expect(entry.enabled)
    }
}

private extension FallbackChainService {
    /// Test-only read access without changing production visibility.
    var chainForTesting: [FallbackEntry] {
        Mirror(reflecting: self).children
            .first(where: { $0.label == "chain" })?.value as? [FallbackEntry] ?? []
    }
}
