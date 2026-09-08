import Foundation

/// Disk spill for tool results that compaction is about to destroy.
///
/// `tieredCompact` and `microcompact` rewrite old `tool_result` blocks to a
/// 3-line preview or `[cleared]`. That makes compaction *lossy* — the agent's own
/// earlier reads vanish mid-task and it re-reads the same files. This cache writes
/// the full text to `{project}/.agent/toolcache/<tool_use_id>.txt` **before** the
/// truncation happens, so the content is recoverable via `restore_tool_result`.
enum ToolResultCache {
    static let dirName = "toolcache"

    /// Only spill results big enough to be worth recovering.
    static let minSpillBytes = 200

    /// Cap on total spill size per cache dir — oldest files evicted first.
    /// Without this the dir grew unbounded (clear() has no callers).
    static let maxCacheBytes = 50_000_000

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
    /// `toolUse` is the originating `tool_use` block (name + input); when given,
    /// a `.meta` sidecar records provenance so `restore` can report what
    /// produced the result and whether the source file changed since.
    static func spill(toolUseID: String?, content: String, toolUse: [String: Any]? = nil) {
        guard let toolUseID, let name = fileName(for: toolUseID) else { return }
        guard content.utf8.count >= minSpillBytes else { return }

        let dir = cacheDir()
        let file = dir.appendingPathComponent(name)
        guard !FileManager.default.fileExists(atPath: file.path) else { return }

        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try content.write(to: file, atomically: true, encoding: .utf8)
            if let toolUse {
                var meta: [String: Any] = ["spilled": Date().timeIntervalSince1970]
                if let tool = toolUse["name"] as? String { meta["tool"] = tool }
                if let input = toolUse["input"] as? [String: Any],
                   JSONSerialization.isValidJSONObject(input) { meta["input"] = input }
                if let data = try? JSONSerialization.data(withJSONObject: meta) {
                    try? data.write(to: metaURL(for: name))
                }
            }
            evictIfNeeded(dir: dir)
        } catch {
            // Spilling is best-effort — a failure must never break compaction.
        }
    }

    private static func metaURL(for name: String) -> URL {
        cacheDir().appendingPathComponent(String(name.dropLast(4)) + ".meta")
    }

    /// Evict oldest spill files until the cache is back under maxCacheBytes.
    private static func evictIfNeeded(dir: URL) {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: keys) else { return }
        var entries: [(url: URL, size: Int, date: Date)] = []
        var total = 0
        for f in files where f.pathExtension == "txt" {
            let vals = try? f.resourceValues(forKeys: Set(keys))
            let size = vals?.fileSize ?? 0
            entries.append((f, size, vals?.contentModificationDate ?? .distantPast))
            total += size
        }
        guard total > maxCacheBytes else { return }
        for e in entries.sorted(by: { $0.date < $1.date }) {
            try? fm.removeItem(at: e.url)
            try? fm.removeItem(at: e.url.deletingPathExtension().appendingPathExtension("meta"))
            total -= e.size
            if total <= maxCacheBytes { break }
        }
    }

    /// Read back a spilled tool result. Returns nil when it was never spilled.
    static func restore(toolUseID: String) -> String? {
        guard let name = fileName(for: toolUseID) else { return nil }
        return try? String(contentsOf: cacheDir().appendingPathComponent(name), encoding: .utf8)
    }

    /// Age + provenance line(s) for a spilled result, for the model to judge
    /// freshness: when it was captured, which tool produced it, and — for file
    /// reads — whether the file on disk changed after the capture. A restored
    /// result preserves bytes, not currency; this header keeps the model from
    /// presenting an old read as current evidence.
    static func provenanceHeader(toolUseID: String) -> String? {
        guard let name = fileName(for: toolUseID) else { return nil }
        let txt = cacheDir().appendingPathComponent(name)
        let spilledAt = (try? txt.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate
        var tool = "unknown tool"
        var input: [String: Any] = [:]
        var captured = spilledAt
        if let data = try? Data(contentsOf: metaURL(for: name)),
           let meta = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            if let t = meta["tool"] as? String { tool = t }
            if let i = meta["input"] as? [String: Any] { input = i }
            if let s = meta["spilled"] as? Double { captured = Date(timeIntervalSince1970: s) }
        }
        var lines: [String] = []
        var desc = "[restored tool result \(toolUseID) — produced by \(tool)"
        if let path = input["file_path"] as? String ?? input["path"] as? String { desc += " on \(path)" }
        if let captured { desc += ", captured \(ageString(since: captured))" }
        lines.append(desc + "]")

        if let captured,
           let path = input["file_path"] as? String ?? input["path"] as? String,
           let mtime = (try? FileManager.default.attributesOfItem(atPath: path))?[.modificationDate] as? Date,
           mtime > captured
        {
            lines.append("[⚠️ STALE: \(path) was modified \(ageString(since: mtime)), AFTER this result was captured. "
                + "The content below is the OLD version — re-read the file if you need current contents.]")
        }
        return lines.joined(separator: "\n")
    }

    private static func ageString(since date: Date) -> String {
        let secs = Int(Date().timeIntervalSince(date))
        if secs < 60 { return "\(secs)s ago" }
        if secs < 3_600 { return "\(secs / 60)m ago" }
        return "\(secs / 3_600)h \(secs % 3_600 / 60)m ago"
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
