import Testing
import Foundation
@testable import Agent_

@Suite("ToolErrorClassifier")
struct ToolErrorClassifierTests {

    // MARK: - Each rule matches (code + a non-empty hint)

    @Test("edit_file exact-match failure -> old_string_not_found")
    func oldStringNotFound() {
        let err = ToolErrorClassifier.classify(tool: "edit_file", output: "Error: old_string not found in file")
        #expect(err?.code == "old_string_not_found")
        #expect(!(err?.hint.isEmpty ?? true))
    }

    @Test("old_string with 'no match' also classifies as old_string_not_found")
    func oldStringNoMatch() {
        let err = ToolErrorClassifier.classify(tool: "edit_file", output: "old_string: no match")
        #expect(err?.code == "old_string_not_found")
    }

    @Test("multiple matches -> ambiguous_match")
    func ambiguousMatch() {
        #expect(ToolErrorClassifier.classify(tool: "edit_file", output: "Found multiple matches")?.code == "ambiguous_match")
        #expect(ToolErrorClassifier.classify(tool: "edit_file", output: "more than one match found")?.code == "ambiguous_match")
    }

    @Test("no such file -> file_not_found")
    func noSuchFile() {
        #expect(ToolErrorClassifier.classify(tool: "read_file", output: "No such file or directory")?.code == "file_not_found")
        #expect(ToolErrorClassifier.classify(tool: "shell", output: "path does not exist")?.code == "file_not_found")
    }

    @Test("generic 'not found' only classifies as file_not_found for file tools")
    func notFoundNarrowedByTool() {
        // A file tool with a bare "not found" -> file_not_found.
        #expect(ToolErrorClassifier.classify(tool: "read_file", output: "resource not found")?.code == "file_not_found")
        // A non-file tool with a bare "not found" should NOT be file_not_found
        // (no rule matches it) — this guards the tool-narrowing condition.
        #expect(ToolErrorClassifier.classify(tool: "web_search", output: "not found") == nil)
    }

    @Test("permission denied -> permission_denied")
    func permissionDenied() {
        #expect(ToolErrorClassifier.classify(tool: "shell", output: "Permission denied")?.code == "permission_denied")
        #expect(ToolErrorClassifier.classify(tool: "shell", output: "operation not permitted")?.code == "permission_denied")
    }

    @Test("build failed -> build_failed")
    func buildFailed() {
        #expect(ToolErrorClassifier.classify(tool: "xcode_build", output: "** BUILD FAILED **")?.code == "build_failed")
        #expect(ToolErrorClassifier.classify(tool: "build", output: "main.swift:10: error: expected ')'")?.code == "build_failed")
    }

    @Test("timeout -> timeout")
    func timeout() {
        #expect(ToolErrorClassifier.classify(tool: "shell", output: "Operation timed out")?.code == "timeout")
        #expect(ToolErrorClassifier.classify(tool: "shell", output: "request timeout")?.code == "timeout")
    }

    @Test("connection errors -> network_unreachable")
    func networkUnreachable() {
        #expect(ToolErrorClassifier.classify(tool: "http", output: "Connection refused")?.code == "network_unreachable")
        #expect(ToolErrorClassifier.classify(tool: "http", output: "could not connect to host")?.code == "network_unreachable")
        #expect(ToolErrorClassifier.classify(tool: "http", output: "You are offline")?.code == "network_unreachable")
    }

    @Test("script syntax error -> script_syntax_error (only for script tools)")
    func scriptSyntaxError() {
        #expect(ToolErrorClassifier.classify(tool: "applescript_tool", output: "Syntax Error: expected end of line")?.code == "script_syntax_error")
        // A syntax error from a non-script tool is not classified by this rule.
        #expect(ToolErrorClassifier.classify(tool: "read_file", output: "syntax error") == nil)
    }

    @Test("rate limit -> rate_limited")
    func rateLimited() {
        #expect(ToolErrorClassifier.classify(tool: "llm", output: "Rate limit exceeded")?.code == "rate_limited")
        #expect(ToolErrorClassifier.classify(tool: "llm", output: "HTTP 429 Too Many Requests")?.code == "rate_limited")
    }

    // MARK: - No match / fallback

    @Test("unrecognized output returns nil")
    func noMatchReturnsNil() {
        #expect(ToolErrorClassifier.classify(tool: "shell", output: "everything worked fine") == nil)
        #expect(ToolErrorClassifier.classify(tool: "shell", output: "") == nil)
    }

    // MARK: - Matching is case-insensitive

    @Test("classification is case-insensitive")
    func caseInsensitive() {
        #expect(ToolErrorClassifier.classify(tool: "shell", output: "PERMISSION DENIED")?.code == "permission_denied")
        #expect(ToolErrorClassifier.classify(tool: "shell", output: "Timed Out")?.code == "timeout")
    }

    // MARK: - First-match-wins ordering

    @Test("first matching rule wins when output hits several")
    func firstMatchWins() {
        // Contains both "old_string ... not found" (rule 1) and "permission denied"
        // (a later rule). Rule 1 is ordered first, so it must win.
        let err = ToolErrorClassifier.classify(
            tool: "edit_file",
            output: "old_string not found; also permission denied"
        )
        #expect(err?.code == "old_string_not_found")
    }

    // MARK: - annotation()

    @Test("annotation wraps code + hint for a classified error")
    func annotationForClassified() {
        let note = ToolErrorClassifier.annotation(tool: "shell", output: "Permission denied")
        #expect(note != nil)
        #expect(note?.contains("[error_code: permission_denied]") == true)
    }

    @Test("annotation returns nil for unclassified output")
    func annotationForUnclassified() {
        #expect(ToolErrorClassifier.annotation(tool: "shell", output: "all good") == nil)
    }
}
