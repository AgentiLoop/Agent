import Foundation

// Typed tool errors — classify failing tool output into a stable error code
// plus an actionable recovery hint, appended to the tool_result so the model
// gets structure instead of a bare string. Complements ToolOutcomeStore
// (which tracks chronic failures) by making each individual failure
// self-describing on the turn it happens.

enum ToolErrorClassifier {

    struct TypedError {
        let code: String
        let hint: String
    }

    /// Ordered rules — first match wins. Matching is against the lowercased
    /// output; tool name narrows ambiguous cases.
    static func classify(tool: String, output: String) -> TypedError? {
        let lower = output.lowercased()

        // edit_file's exact-match failure — most common coding-loop error.
        if lower.contains("old_string") && (lower.contains("not found") || lower.contains("no match")) {
            return TypedError(
                code: "old_string_not_found",
                hint: "Re-read the file fresh (no offset/limit) and copy old_string verbatim — every space, tab, and newline. Or switch to diff_apply with start_line/end_line."
            )
        }
        if lower.contains("multiple matches") || lower.contains("more than one match") {
            return TypedError(
                code: "ambiguous_match",
                hint: "Add the `context` parameter with surrounding lines to disambiguate, or use diff_apply with start_line/end_line."
            )
        }
        if lower.contains("no such file") || lower.contains("does not exist")
            || (lower.contains("not found") && (tool.contains("file") || tool == "read_file" || tool == "write_file")) {
            return TypedError(
                code: "file_not_found",
                hint: "Verify the path with list_files before retrying — never guess paths. Bundles (.app/.xcodeproj) are directories."
            )
        }
        if lower.contains("permission denied") || lower.contains("operation not permitted") {
            return TypedError(
                code: "permission_denied",
                hint: "User-level access failed. Disk/system operations need execute_daemon_command (root); TCC-gated actions need agent_script or applescript_tool (in-process)."
            )
        }
        if lower.contains("build failed") || (lower.contains("error:") && tool.contains("build")) {
            return TypedError(
                code: "build_failed",
                hint: "Fix the FIRST error listed (file:line) — later errors are often cascades. Don't start over."
            )
        }
        if lower.contains("timed out") || lower.contains("timeout") {
            return TypedError(
                code: "timeout",
                hint: "Narrow the operation (smaller scope, specific path) or use a faster tool. Do not retry the identical call."
            )
        }
        if lower.contains("connection refused") || lower.contains("could not connect")
            || lower.contains("network connection") || lower.contains("offline") {
            return TypedError(
                code: "network_unreachable",
                hint: "The endpoint/service isn't reachable. Check it's running before retrying."
            )
        }
        if lower.contains("syntax error") && (tool.contains("applescript") || tool.contains("osascript") || tool.contains("javascript")) {
            return TypedError(
                code: "script_syntax_error",
                hint: "Do not guess vocabulary. Call lookup_sdef for the target app and rewrite using only documented terms."
            )
        }
        if lower.contains("rate limit") || lower.contains("429") {
            return TypedError(
                code: "rate_limited",
                hint: "Back off — the harness handles retry timing. Work on something else this turn."
            )
        }
        return nil
    }

    /// Structured annotation appended to a failing tool_result's content.
    static func annotation(tool: String, output: String) -> String? {
        guard let err = classify(tool: tool, output: output) else { return nil }
        return "\n\n[error_code: \(err.code)] \(err.hint)"
    }
}
