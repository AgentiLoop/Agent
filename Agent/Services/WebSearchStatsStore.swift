import Foundation
import Observation

// MARK: - Web Search Backend Identity & Stats

/// The backend that actually served a web search. Case order matches the
/// fallback chain in performWebSearchForTask: Ollama → Z.AI → SpecStream →
/// Exa → Tavily → DuckDuckGo (keyless, always last).
enum WebSearchBackend: String, Codable, CaseIterable {
    case ollama
    case zAI
    case specStream
    case exa
    case tavily
    case duckDuckGo

    var displayName: String {
        switch self {
        case .ollama: return "Ollama"
        case .zAI: return "Z.AI"
        case .specStream: return "SpecStream"
        case .exa: return "Exa"
        case .tavily: return "Tavily"
        case .duckDuckGo: return "DuckDuckGo"
        }
    }
}

/// One completed search: the query, the backend that served it, whether it
/// succeeded, and a short preview of the result.
struct WebSearchRecord: Codable, Identifiable {
    var id = UUID()
    var query: String
    var backend: WebSearchBackend
    var success: Bool
    var resultPreview: String
    var timestamp: Date
}

/// Per-backend counters plus the most recent error, if any.
struct WebSearchBackendStats: Codable {
    var successCount = 0
    var errorCount = 0
    var lastError: String?
    var lastUsed: Date?
}

/// Persistent web search stats: which backend was last used, how often each
/// backend runs, per-backend errors, and recent search/result history.
/// Mirrors TokenUsageStore — @MainActor @Observable singleton backed by JSON
/// in ~/Library/Application Support/Agent/web_search_stats.json.
@MainActor @Observable
final class WebSearchStatsStore {
    static let shared = WebSearchStatsStore()

    /// Cap on retained search history entries.
    static let historyLimit = 50
    /// Characters of result kept per history entry.
    static let previewLength = 240

    private(set) var backendStats: [WebSearchBackend: WebSearchBackendStats] = [:]
    private(set) var lastBackend: WebSearchBackend?
    private(set) var lastSearchDate: Date?
    private(set) var history: [WebSearchRecord] = []
    private(set) var totalSearches = 0

    private let fileURL: URL

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Agent", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("web_search_stats.json")
        load()
    }

    /// Record one backend attempt from the fallback chain. Updates the
    /// backend's counters and last error; when `isFinal` (the result actually
    /// returned to the caller) also updates the last-used marker, totals, and
    /// search history. "No results found for:" counts as success — the
    /// backend worked, the query just had no hits.
    func record(query: String, backend: WebSearchBackend, result: String, isFinal: Bool) {
        var stats = backendStats[backend] ?? WebSearchBackendStats()
        if result.hasPrefix("Error:") {
            stats.errorCount += 1
            stats.lastError = String(result.dropFirst("Error:".count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            stats.successCount += 1
        }
        stats.lastUsed = Date()
        backendStats[backend] = stats

        if isFinal {
            lastBackend = backend
            lastSearchDate = Date()
            totalSearches += 1
            history.insert(
                WebSearchRecord(
                    query: query,
                    backend: backend,
                    success: !result.hasPrefix("Error:"),
                    resultPreview: String(result.prefix(Self.previewLength)),
                    timestamp: Date()
                ),
                at: 0
            )
            if history.count > Self.historyLimit {
                history.removeLast(history.count - Self.historyLimit)
            }
        }
        save()
    }

    // MARK: - Persistence

    private struct Persisted: Codable {
        var backendStats: [WebSearchBackend: WebSearchBackendStats] = [:]
        var lastBackend: WebSearchBackend?
        var lastSearchDate: Date?
        var history: [WebSearchRecord] = []
        var totalSearches = 0

        init(backendStats: [WebSearchBackend: WebSearchBackendStats], lastBackend: WebSearchBackend?, lastSearchDate: Date?, history: [WebSearchRecord], totalSearches: Int) {
            self.backendStats = backendStats
            self.lastBackend = lastBackend
            self.lastSearchDate = lastSearchDate
            self.history = history
            self.totalSearches = totalSearches
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            backendStats = try c.decodeIfPresent([WebSearchBackend: WebSearchBackendStats].self, forKey: .backendStats) ?? [:]
            lastBackend = try c.decodeIfPresent(WebSearchBackend.self, forKey: .lastBackend)
            lastSearchDate = try c.decodeIfPresent(Date.self, forKey: .lastSearchDate)
            history = try c.decodeIfPresent([WebSearchRecord].self, forKey: .history) ?? []
            totalSearches = try c.decodeIfPresent(Int.self, forKey: .totalSearches) ?? 0
        }
    }

    private func save() {
        let payload = Persisted(
            backendStats: backendStats,
            lastBackend: lastBackend,
            lastSearchDate: lastSearchDate,
            history: history,
            totalSearches: totalSearches
        )
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder().decode(Persisted.self, from: data)
        else { return }
        backendStats = payload.backendStats
        lastBackend = payload.lastBackend
        lastSearchDate = payload.lastSearchDate
        history = payload.history
        totalSearches = payload.totalSearches
    }
}
