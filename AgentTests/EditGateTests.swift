import Testing
import Foundation
@testable import Agent_

// Tier 8 edit safety: an existing file may only be edited after it was read
// this task, and only while its bytes match what the model last saw.

@MainActor
struct EditGateTests {

    private func tempFile(_ text: String) -> String {
        let path = NSTemporaryDirectory() + "editgate-\(UUID().uuidString).txt"
        try! text.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    @Test("edit of an unread existing file is refused; new file is allowed")
    func unreadFileRefused() {
        let tab = UUID()
        let path = tempFile("hello\n")
        defer { try? FileManager.default.removeItem(atPath: path) }
        let err = AgentViewModel.editGateError(tabID: tab, expandedPath: path, requireRead: true)
        #expect(err?.contains("has not been read yet") == true)
        // write_file may overwrite an unread file
        #expect(AgentViewModel.editGateError(tabID: tab, expandedPath: path, requireRead: false) == nil)
        // A path with nothing on disk is always allowed (file creation)
        #expect(AgentViewModel.editGateError(tabID: tab, expandedPath: path + ".missing", requireRead: true) == nil)
    }

    @Test("read → edit allowed; external change → refused; own edit → allowed again")
    func staleDetection() {
        let tab = UUID()
        let path = tempFile("line one\n")
        defer { try? FileManager.default.removeItem(atPath: path) }

        AgentViewModel.recordReadEmission(tabID: tab, expandedPath: path, offset: nil, limit: nil)
        #expect(AgentViewModel.editGateError(tabID: tab, expandedPath: path, requireRead: true) == nil)

        // Someone else (formatter / user / other tab) rewrites the file
        try! "line one\nline two\n".write(toFile: path, atomically: true, encoding: .utf8)
        let err = AgentViewModel.editGateError(tabID: tab, expandedPath: path, requireRead: true)
        #expect(err?.contains("modified since you last read it") == true)

        // The model re-reads → allowed; then its own edit refreshes the gate
        AgentViewModel.recordReadEmission(tabID: tab, expandedPath: path, offset: nil, limit: nil)
        #expect(AgentViewModel.editGateError(tabID: tab, expandedPath: path, requireRead: true) == nil)
        try! "line one\nline two\nline three\n".write(toFile: path, atomically: true, encoding: .utf8)
        AgentViewModel.recordFileEdit(tabID: tab, filePath: path)
        #expect(AgentViewModel.editGateError(tabID: tab, expandedPath: path, requireRead: true) == nil)

        // A different tab never read it
        #expect(AgentViewModel.editGateError(tabID: UUID(), expandedPath: path, requireRead: true) != nil)

        // Task start forgets everything for the tab
        AgentViewModel.clearEditGateForTab(tabID: tab)
        #expect(AgentViewModel.editGateError(tabID: tab, expandedPath: path, requireRead: true) != nil)
    }
}
