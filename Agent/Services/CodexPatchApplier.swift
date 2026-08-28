import AgentAudit
@preconcurrency import Foundation

// MARK: Patch applier — Codex freeform grammar

/// Applies Codex's "*** Begin Patch" freeform patch format. Supports:
/// - `*** Add File: <path>` followed by `+` prefixed content lines
/// - `*** Delete File: <path>`
/// - `*** Update File: <path>` with `@@` hunk markers and `+ /- / ` prefixed lines
/// - `*** Move File: <from>` with `*** To: <to>`
/// Relative paths are resolved against `baseFolder` (the project folder).
enum CodexPatchApplier {

    struct Result: Sendable {
        let summary: String
        let files: [String]
    }

    static func apply(patch: String, baseFolder: String) -> Result {
        let lines = patch.components(separatedBy: "\n")
        var idx = 0
        var files: [String] = []
        var notes: [String] = []

        // Skip any preamble before *** Begin Patch
        while idx < lines.count, !lines[idx].hasPrefix("*** Begin Patch") { idx += 1 }
        if idx < lines.count { idx += 1 } // consume Begin Patch

        while idx < lines.count {
            let line = lines[idx]
            if line.hasPrefix("*** End Patch") { break }

            if let path = stripPrefix(line, "*** Add File: ") {
                let (body, consumed) = readAddBody(lines, start: idx + 1)
                let full = resolvePath(path, base: baseFolder)
                do {
                    try FileManager.default.createDirectory(
                        at: URL(fileURLWithPath: full).deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                    try body.write(toFile: full, atomically: true, encoding: .utf8)
                    files.append(path)
                    notes.append("+ \(path) (\(body.components(separatedBy: "\n").count) lines)")
                } catch {
                    notes.append("! failed to add \(path): \(error.localizedDescription)")
                }
                idx = consumed
                continue
            }

            if let path = stripPrefix(line, "*** Delete File: ") {
                let full = resolvePath(path, base: baseFolder)
                if (try? FileManager.default.removeItem(atPath: full)) != nil {
                    files.append(path)
                    notes.append("- \(path)")
                } else {
                    notes.append("! failed to delete \(path)")
                }
                idx += 1
                continue
            }

            if let path = stripPrefix(line, "*** Update File: ") {
                let (updated, consumed, ok) = applyUpdate(lines, start: idx + 1, path: path, base: baseFolder)
                if ok {
                    files.append(path)
                    notes.append("~ \(path)")
                } else {
                    notes.append("! failed to update \(path): \(updated)")
                }
                idx = consumed
                continue
            }

            if let from = stripPrefix(line, "*** Move File: ") {
                // Expect next line to be "*** To: <dest>"
                var dest: String?
                if idx + 1 < lines.count, let to = stripPrefix(lines[idx + 1], "*** To: ") {
                    dest = to
                }
                if let to = dest {
                    let src = resolvePath(from, base: baseFolder)
                    let dst = resolvePath(to, base: baseFolder)
                    if (try? FileManager.default.moveItem(atPath: src, toPath: dst)) != nil {
                        files.append(from)
                        files.append(to)
                        notes.append("mv \(from) → \(to)")
                    } else {
                        notes.append("! failed to move \(from) → \(to)")
                    }
                    idx += 2
                    continue
                }
            }

            idx += 1
        }

        let summary = notes.isEmpty ? "Patch applied (no changes detected)." : notes.joined(separator: "\n")
        return Result(summary: summary, files: Array(Set(files)))
    }

    private static func stripPrefix(_ line: String, _ prefix: String) -> String? {
        guard line.hasPrefix(prefix) else { return nil }
        return String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
    }

    private static func resolvePath(_ path: String, base: String) -> String {
        let expanded = (path as NSString).expandingTildeInPath
        if expanded.hasPrefix("/") { return expanded }
        return (base as NSString).appendingPathComponent(expanded)
    }

    /// Read `+`-prefixed body lines after an Add File directive. Stops at the
    /// next `*** ` directive or End Patch.
    private static func readAddBody(_ lines: [String], start: Int) -> (body: String, nextIdx: Int) {
        var body: [String] = []
        var i = start
        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("*** ") { break }
            if line.hasPrefix("+") {
                body.append(String(line.dropFirst()))
            } else if line.isEmpty {
                body.append("")
            } else {
                body.append(line)
            }
            i += 1
        }
        return (body.joined(separator: "\n"), i)
    }

    /// Apply `@@` / `+` / `-` / ` ` hunks to an existing file. Reads the file,
    /// walks hunks sequentially, and writes back atomically.
    private static func applyUpdate(_ lines: [String], start: Int, path: String, base: String)
        -> (msg: String, nextIdx: Int, ok: Bool)
    {
        let full = resolvePath(path, base: base)
        guard var source = try? String(contentsOfFile: full, encoding: .utf8) else {
            // Advance past this block to not stall the outer loop
            var i = start
            while i < lines.count, !lines[i].hasPrefix("*** ") { i += 1 }
            return ("file not readable", i, false)
        }
        var sourceLines = source.components(separatedBy: "\n")
        var i = start
        var cursor = 0 // index into sourceLines

        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("*** ") { break }

            if line.hasPrefix("@@") {
                // Skip — we scan for context matches instead of parsing ranges.
                i += 1
                continue
            }

            if line.hasPrefix("+") {
                let inserted = String(line.dropFirst())
                sourceLines.insert(inserted, at: min(cursor, sourceLines.count))
                cursor += 1
            } else if line.hasPrefix("-") {
                let removed = String(line.dropFirst())
                // Find match at or after cursor
                if let found = sourceLines[cursor..<sourceLines.count].firstIndex(of: removed) {
                    sourceLines.remove(at: found)
                    cursor = found
                } else {
                    return ("context mismatch on removal: '\(removed.prefix(60))'", i, false)
                }
            } else if line.hasPrefix(" ") {
                let context = String(line.dropFirst())
                if let found = sourceLines[cursor..<sourceLines.count].firstIndex(of: context) {
                    cursor = found + 1
                } else {
                    return ("context mismatch: '\(context.prefix(60))'", i, false)
                }
            }
            i += 1
        }

        source = sourceLines.joined(separator: "\n")
        do {
            try source.write(toFile: full, atomically: true, encoding: .utf8)
            return ("ok", i, true)
        } catch {
            return (error.localizedDescription, i, false)
        }
    }
}
