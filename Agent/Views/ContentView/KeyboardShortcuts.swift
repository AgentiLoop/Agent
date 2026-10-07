//  KeyboardShortcuts.swift Agent  Keyboard shortcut handlers for ContentView 

import Foundation

// MARK: - Keyboard Shortcuts

/// Keyboard tab switches leave focus in the task field, so VoiceOver gets no cue — speak the new tab.
@MainActor
private func announceSelectedTab(viewModel: AgentViewModel) {
    let total = viewModel.scriptTabs.count + 1
    guard let id = viewModel.selectedTabId,
          let index = viewModel.scriptTabs.firstIndex(where: { $0.id == id }) else {
        announceForAccessibility("Main tab, 1 of \(total)")
        return
    }
    announceForAccessibility("\(viewModel.scriptTabs[index].displayTitle) tab, \(index + 2) of \(total)")
}

/// Navigate to next tab (cycle right)
@MainActor
func nextTab(viewModel: AgentViewModel) {
    if viewModel.scriptTabs.isEmpty { return }
    guard let currentId = viewModel.selectedTabId else {
        // On main tab - go to first script tab
        if let firstTab = viewModel.scriptTabs.first {
            viewModel.selectedTabId = firstTab.id
            announceSelectedTab(viewModel: viewModel)
        }
        return
    }

    guard let currentIndex = viewModel.scriptTabs.firstIndex(where: { $0.id == currentId }) else { return }
    let nextIndex = (currentIndex + 1) % viewModel.scriptTabs.count
    viewModel.selectedTabId = viewModel.scriptTabs[nextIndex].id
    viewModel.persistScriptTabs()
    announceSelectedTab(viewModel: viewModel)
}

/// Navigate to previous tab (cycle left)
@MainActor
func previousTab(viewModel: AgentViewModel) {
    if viewModel.scriptTabs.isEmpty { return }
    guard let currentId = viewModel.selectedTabId else {
        // On main tab - go to last script tab
        if let lastTab = viewModel.scriptTabs.last {
            viewModel.selectedTabId = lastTab.id
            announceSelectedTab(viewModel: viewModel)
        }
        return
    }

    guard let currentIndex = viewModel.scriptTabs.firstIndex(where: { $0.id == currentId }) else { return }
    let prevIndex = (currentIndex - 1 + viewModel.scriptTabs.count) % viewModel.scriptTabs.count
    viewModel.selectedTabId = viewModel.scriptTabs[prevIndex].id
    viewModel.persistScriptTabs()
    announceSelectedTab(viewModel: viewModel)
}

/// Navigate to tab by number (1-9)
@MainActor
func selectTab(viewModel: AgentViewModel, number: Int) {
    guard number >= 1, number <= 9 else { return }
    if number == 1 {
        // Cmd+1 = Main tab
        viewModel.selectMainTab()
        announceSelectedTab(viewModel: viewModel)
        return
    }

    // Cmd+2-9 = Script tabs (0-indexed from index 1)
    let tabIndex = number - 2
    guard tabIndex < viewModel.scriptTabs.count else { return }
    viewModel.selectedTabId = viewModel.scriptTabs[tabIndex].id
    viewModel.persistScriptTabs()
    announceSelectedTab(viewModel: viewModel)
}
