import Testing
import Foundation
@testable import Agent_

/// Regression tests for the green task banner: one tab's task must never show on
/// another tab, and a prompt that starts with blank lines must not render empty.
@Suite("Task banner tab isolation")
@MainActor
struct TaskBannerTabIsolationTests {

    private func llmTab(running: Bool, prompt: String = "", appleAI: String = "") -> ScriptTab {
        let tab = ScriptTab(llmConfig: LLMConfig(provider: .claude, model: "test", displayName: "test"))
        tab.isLLMRunning = running
        tab.currentTaskPrompt = prompt
        tab.currentAppleAIPrompt = appleAI
        return tab
    }

    // MARK: - Spillage: main tab's task must not appear on an idle tab

    @Test("idle selected tab shows no banner while the main tab is running")
    func idleTabDoesNotShowMainTask() {
        let tab = llmTab(running: false)
        let shown = ContentView.bannerPrompt(selectedTab: tab, mainIsRunning: true,
                                             mainPrompt: "run benchmarks or die")
        #expect(shown == nil)
    }

    @Test("running selected tab shows its own prompt, not the main tab's")
    func runningTabShowsOwnPrompt() {
        let tab = llmTab(running: true, prompt: "tab task")
        let shown = ContentView.bannerPrompt(selectedTab: tab, mainIsRunning: true,
                                             mainPrompt: "main task")
        #expect(shown == "tab task")
    }

    @Test("main tab selected shows the main prompt only while it runs")
    func mainTabPrompt() {
        #expect(ContentView.bannerPrompt(selectedTab: nil, mainIsRunning: true, mainPrompt: "main task") == "main task")
        #expect(ContentView.bannerPrompt(selectedTab: nil, mainIsRunning: false, mainPrompt: "main task") == nil)
    }

    @Test("running script tab shows its script name")
    func scriptTabPrompt() {
        let tab = ScriptTab(scriptName: "Hello") // script tabs start isRunning = true
        let shown = ContentView.bannerPrompt(selectedTab: tab, mainIsRunning: true, mainPrompt: "main task")
        #expect(shown == "Running: Hello")
    }

    @Test("Apple AI annotation never spills from main onto a selected tab")
    func appleAIDoesNotSpill() {
        let idle = llmTab(running: false)
        #expect(ContentView.bannerAppleAIPrompt(selectedTab: idle, mainPrompt: "main AI") == nil)
        let own = llmTab(running: true, appleAI: "tab AI")
        #expect(ContentView.bannerAppleAIPrompt(selectedTab: own, mainPrompt: "main AI") == "tab AI")
        #expect(ContentView.bannerAppleAIPrompt(selectedTab: nil, mainPrompt: "main AI") == "main AI")
        #expect(ContentView.bannerAppleAIPrompt(selectedTab: nil, mainPrompt: "") == nil)
    }

    // MARK: - Lost task: multi-line prompt must not render blank

    @Test("prompt starting with blank lines collapses to visible text")
    func leadingNewlinesCollapse() {
        #expect(TaskBannerView.singleLine("\n\n3. Landing Page\n\nYour site") == "3. Landing Page Your site")
    }

    @Test("tabs and runs of spaces collapse to single spaces")
    func whitespaceCollapses() {
        #expect(TaskBannerView.singleLine("  a\t\tb   c  ") == "a b c")
        #expect(TaskBannerView.singleLine("plain prompt") == "plain prompt")
    }
}
