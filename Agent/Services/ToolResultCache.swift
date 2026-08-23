import Foundation

/// Disk spill for tool results that compaction is about to destroy.
///
/// `compressMessages` and `microcompact` rewrite old `tool_result` blocks to a
/// 3-line preview or `[cleared]`. That makes compaction *lossy* — the agent's own
/// earlier reads vanish mid-task and it re-reads the same files. This cache writes
/// the full text to `{project}/.agent/toolcache/<tool_use_id>.txt` **before** the
/// truncation happens, so the content is recoverable via `restore_tool_result`.
enum ToolResultCache {
    static let dirName = "toolcache"

    /// Only spill results big enough to be worth recovering.
    static let minSpillBytes = 200

    private static let queue = DispatchQueue(label: "agent.toolresultcache")

    /// Project folder used for spills. Set by the task loop; falls back to a temp dir
    /// so a spill never fails just because no project is selected.
    nonisolated(unsafe) private static var _root: String?

    static func setProjectFolder(_ folder: String?) {
        queue.sync { _root = folder }
    }

    private static func cacheDir() -> URL {
        let root = queue.sync { _root }
        let base: URL
        if let root, !root.isEmpty {
            base = URL(fileURLWithPath: root)
        } else {
            base = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AgentToolCache")
        }
        return base.appendingPathComponent(".agent").appendingPathComponent(dirName)
    }

    /// Sanitize an id into a safe single path component.
    private static func fileName(for id: String) -> String? {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let cleaned = String(id.unicodeScalars.filter { allowed.contains($0) })
        guard !cleaned.isEmpty else { return nil }
        return String(cleaned.prefix(120)) + ".txt"
    }

    /// Write the full tool result to disk. No-op for short content or a missing id.
    /// Never overwrites — the first (uncompressed) version is the one worth keeping.
    static func spill(toolUseID: String?, content: String) {
        guard let toolUseID, let name = fileName(for: toolUseID) else { return }
        guard content.utf8.count >= minSpillBytes else { return }

        let dir = cacheDir()
        let file = dir.appendingPathComponent(name)
        guard !FileManager.default.fileExists(atPath: file.path) else { return }

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try content.write(to: file, atomically: true, encoding: .utf8)
        } catch {
            // Spilling is best-effort — a failure must never break compaction.
        }
    }

    /// Read back a spilled tool result. Returns nil when it was never spilled.
    static func restore(toolUseID: String) -> String? {
        guard let name = fileName(for: toolUseID) else { return nil }
        return try? String(contentsOf: cacheDir().appendingPathComponent(name), encoding: .utf8)
    }

    /// Every spilled id currently on disk, for listing in the restore tool's error text.
    static func availableIDs() -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: cacheDir().path)) ?? []
        return files.filter { $0.hasSuffix(".txt") }.map { String($0.dropLast(4)) }.sorted()
    }

    /// Remove all spilled results for the current project.
    static func clear() {
        try? FileManager.default.removeItem(at: cacheDir())
    }
}
