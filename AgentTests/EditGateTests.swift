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

    @Test("8.3: external change surfaces once as a diff snippet, then the edit gate accepts the new bytes")
    func externalChangeBlocks() {
        let tab = UUID()
        let path = tempFile("a\nb\nc\n")
        defer { try? FileManager.default.removeItem(atPath: path) }
        AgentViewModel.recordReadEmission(tabID: tab, expandedPath: path, offset: nil, limit: nil)

        // Nothing changed → nothing reported
        #expect(AgentViewModel.externalChangeBlocks(tabID: tab).isEmpty)

        // Our own edit is not "external"
        try! "a\nb\nc\nd\n".write(toFile: path, atomically: true, encoding: .utf8)
        AgentViewModel.recordFileEdit(tabID: tab, filePath: path)
        #expect(AgentViewModel.externalChangeBlocks(tabID: tab).isEmpty)

        // Someone else rewrites line b → B
        try! "a\nB\nc\nd\n".write(toFile: path, atomically: true, encoding: .utf8)
        let blocks = AgentViewModel.externalChangeBlocks(tabID: tab)
        #expect(blocks.count == 1)
        #expect(blocks.first?.contains(path) == true)
        #expect(blocks.first?.contains("@@ -2,1 +2,1 @@\n-b\n+B") == true)

        // Reported once; the gate now accepts the new content without a re-read
        #expect(AgentViewModel.externalChangeBlocks(tabID: tab).isEmpty)
        #expect(AgentViewModel.editGateError(tabID: tab, expandedPath: path, requireRead: true) == nil)

        // Deleted file is evicted silently
        try? FileManager.default.removeItem(atPath: path)
        #expect(AgentViewModel.externalChangeBlocks(tabID: tab).isEmpty)
        #expect(AgentViewModel._lastSeenHash["\(tab.uuidString):\(path)"] == nil)
    }

    @Test("diffSnippet caps output")
    func diffSnippetCap() {
        let old = (1...100).map { "line \($0)" }.joined(separator: "\n")
        let new = (1...100).map { "LINE \($0)" }.joined(separator: "\n")
        let snippet = AgentViewModel.diffSnippet(old: old, new: new, maxLines: 10)
        let lines = snippet.components(separatedBy: "\n")
        #expect(lines.count == 12) // header + 10 + truncation marker
        #expect(lines.last?.contains("190 more") == true)
        // Identical → header only
        #expect(AgentViewModel.diffSnippet(old: "x\ny", new: "x\ny", maxLines: 10) == "@@ -3,0 +3,0 @@")
    }
}
