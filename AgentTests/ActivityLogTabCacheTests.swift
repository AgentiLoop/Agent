import Testing
import AppKit
@testable import Agent_

/// Regression tests for the activity log cross-tab bleed (one tab's output showing in another
/// tab's log). Drives `ActivityLogView.Coordinator.performRender()` directly against a real
/// TextKit 1 text view — the same path tab switches take in the app.
@Suite("ActivityLog tab cache")
@MainActor
struct ActivityLogTabCacheTests {

    /// Holds the views strongly (the coordinator only keeps weak refs).
    @MainActor
    final class Harness {
        let coord = ActivityLogView.Coordinator()
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        let textView = NSTextView(usingTextLayoutManager: false)

        init() {
            textView.frame = scrollView.bounds
            textView.isRichText = true
            scrollView.documentView = textView
            coord.latestTextView = textView
            coord.latestScrollView = scrollView
        }

        /// Mimics updateNSView + the debounced render for `tab` showing `text`.
        func show(_ tab: UUID?, _ text: String) {
            if tab != coord.latestTabID { coord.forceTabSwitch = true }
            coord.latestTabID = tab
            coord.latestText = text
            coord.performRender()
        }

        var displayed: String { textView.textStorage?.string ?? "" }
    }

    private let placeholder = "Ready. Enter a task below to begin."

    private func expectOnly(_ h: Harness, contains mine: [String], not others: [String], _ note: Comment) {
        for m in mine { #expect(h.displayed.contains(m), note) }
        for o in others { #expect(!h.displayed.contains(o), note) }
    }

    // MARK: - Tests

    @Test("Switching A → B → A shows each tab's own log")
    func basicSwitch() {
        let h = Harness()
        let a = UUID(), b = UUID()
        h.show(a, "alpha one\n")
        h.show(b, "bravo one\n")
        expectOnly(h, contains: ["bravo one"], not: ["alpha"], "B after switch")
        h.show(a, "alpha one\n")
        expectOnly(h, contains: ["alpha one"], not: ["bravo"], "A after switch back")
    }

    @Test("Background growth is appended on cache swap without duplication")
    func backgroundGrowthDelta() {
        let h = Harness()
        let a = UUID(), b = UUID()
        h.show(a, "alpha one\n")
        h.show(b, "bravo one\n")
        h.show(a, "alpha one\nalpha two\n")
        expectOnly(h, contains: ["alpha one", "alpha two"], not: ["bravo"], "A with delta")
        #expect(h.displayed.components(separatedBy: "alpha one").count == 2, "alpha one duplicated")
    }

    @Test("Regression: empty tab render must not write into another tab's cached storage")
    func emptyTabDoesNotPolluteCache() {
        let h = Harness()
        let a = UUID(), b = UUID(), c = UUID()
        h.show(a, "alpha one\n")
        h.show(b, "bravo one\n")
        h.show(a, "alpha one\n")          // A's cached storage swapped in and becomes live
        h.show(c, "")                      // empty tab → placeholder written into live storage
        #expect(h.displayed == placeholder)
        h.show(c, "charlie one\n")         // C's first output
        expectOnly(h, contains: ["charlie one"], not: ["alpha", "bravo"], "C")
        h.show(a, "alpha one\n")
        expectOnly(h, contains: ["alpha one"], not: ["charlie", "bravo", placeholder], "A after C")
        h.show(b, "bravo one\n")
        expectOnly(h, contains: ["bravo one"], not: ["charlie", "alpha", placeholder], "B after C")
    }

    @Test("A live (swapped-in) storage is never left in tabCaches")
    func swappedStorageNotAliased() {
        let h = Harness()
        let a = UUID(), b = UUID()
        h.show(a, "alpha one\n")
        h.show(b, "bravo one\n")
        h.show(a, "alpha one\n")
        let live = h.textView.textStorage
        for (_, cache) in h.coord.tabCaches {
            #expect(cache.textStorage !== live, "live storage still owned by tabCaches")
        }
    }

    @Test("Streaming into the current tab doesn't leak into other tabs' caches")
    func streamingAfterSwap() {
        let h = Harness()
        let a = UUID(), b = UUID()
        h.show(a, "alpha one\n")
        h.show(b, "bravo one\n")
        h.show(a, "alpha one\n")
        h.show(a, "alpha one\nalpha two\n")  // incremental append on live storage
        h.show(b, "bravo one\n")
        expectOnly(h, contains: ["bravo one"], not: ["alpha"], "B after A streamed")
        h.show(a, "alpha one\nalpha two\nalpha three\n")
        expectOnly(h, contains: ["alpha one", "alpha two", "alpha three"], not: ["bravo"], "A")
    }

    @Test("Tab cleared then refilled shows only new content")
    func clearedTab() {
        let h = Harness()
        let a = UUID(), b = UUID()
        h.show(a, "alpha old\n")
        h.show(b, "bravo one\n")
        h.show(a, "")
        #expect(h.displayed == placeholder)
        h.show(a, "alpha new\n")
        expectOnly(h, contains: ["alpha new"], not: ["alpha old", "bravo"], "A refilled")
        h.show(b, "bravo one\n")
        expectOnly(h, contains: ["bravo one"], not: ["alpha"], "B")
    }

    @Test("Main log (nil tab) and script tabs stay isolated")
    func mainLogIsolation() {
        let h = Harness()
        let a = UUID()
        h.show(nil, "main one\n")
        h.show(a, "alpha one\n")
        h.show(nil, "main one\nmain two\n")
        expectOnly(h, contains: ["main one", "main two"], not: ["alpha"], "main")
        h.show(a, "alpha one\n")
        expectOnly(h, contains: ["alpha one"], not: ["main"], "A")
    }

    @Test("Randomized tab switching never shows another tab's content")
    func fuzzSwitching() {
        let h = Harness()
        let tabs: [UUID?] = [nil, UUID(), UUID(), UUID()]
        let names = ["main", "tabone", "tabtwo", "tabthree"]
        var logs = Array(repeating: "", count: tabs.count)
        var rng = SeededRNG(seed: 42)
        // Start from real content: a fresh coordinator's first empty render leaves the view
        // blank (showingPlaceholder starts true), which isn't what this test is about.
        logs[0] = "main line start\n"
        h.show(tabs[0], logs[0])
        for step in 0..<400 {
            let i = Int.random(in: 0..<tabs.count, using: &rng)
            switch Int.random(in: 0..<10, using: &rng) {
            case 0: logs[i] = ""                                          // clear
            case 1...5: logs[i] += "\(names[i]) line \(step)\n"           // grow
            default: break                                                // just switch
            }
            h.show(tabs[i], logs[i])
            if logs[i].isEmpty {
                #expect(h.displayed == placeholder, "step \(step): tab \(i) should show placeholder")
            } else {
                let others = names.indices.filter { $0 != i }.map { names[$0] }
                for o in others {
                    #expect(!h.displayed.contains(o), "step \(step): tab \(names[i]) shows \(o)")
                }
                #expect(h.displayed.contains("\(names[i]) line"), "step \(step): tab \(names[i]) missing content")
                #expect(!h.displayed.contains(placeholder), "step \(step): stale placeholder")
            }
        }
    }
}

/// Deterministic xorshift RNG so fuzz failures are reproducible.
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
