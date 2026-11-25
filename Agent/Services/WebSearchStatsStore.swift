import Foundation
import Observation

// MARK: - Web Search Backend Identity & Stats

/// The backend that actually served a web search. performWebSearchForTask
/// tries backends in the user's drag-and-drop order (`order`, top =
/// preferred), skipping any without a key. DuckDuckGo needs no key.
/// `claude` is Anthropic's server-side web search: it runs inside the
/// Claude API call, so it is recorded but never part of the order.
/// `openAI` is the same for OpenAI's hosted web search (Codex provider).
enum WebSearchBackend: String, Codable, CaseIterable {
    case ollama
    case zAI
    case specStream
    case exa
    case tavily
    case duckDuckGo
    case claude
    case openAI

    var displayName: String {
        switch self {
        case .ollama: return "Ollama Web Search"
        case .zAI: return "Z.AI Web Search"
        case .specStream: return "SpecStream"
        case .exa: return "Exa"
        case .tavily: return "Tavily"
        case .duckDuckGo: return "DuckDuckGo"
        case .claude: return "Claude Web Search"
        case .openAI: return "OpenAI Web Search"
        }
    }

    /// UserDefaults key holding the comma-separated search order.
    nonisolated static let orderDefaultsKey = "webSearchOrder"

    /// Order used before the user rearranges anything.
    nonisolated static let defaultOrder: [WebSearchBackend] = [.specStream, .exa, .tavily, .ollama, .zAI, .duckDuckGo]

    /// Parse a stored order string; unknown names (and the non-orderable
    /// Claude search) are dropped and any missing backends are appended in
    /// default order.
    nonisolated static func order(from raw: String) -> [WebSearchBackend] {
        var result: [WebSearchBackend] = []
        for name in raw.split(separator: ",") {
            if let b = WebSearchBackend(rawValue: String(name)), defaultOrder.contains(b), !result.contains(b) { result.append(b) }
        }
        return result + defaultOrder.filter { !result.contains($0) }
    }

    /// The user's saved search order, top = preferred.
    nonisolated static var order: [WebSearchBackend] {
        order(from: UserDefaults.standard.string(forKey: orderDefaultsKey) ?? "")
    }

    // MARK: - Tool schema fixes (AgentTools is a remote package)

    /// Accurate description for the app's own `search` tool — the package
    /// still calls it "Web search via Tavily", which misleads the model.
    nonisolated static let searchToolDescription =
        "Web search. Use this for any request to search or look something up on the web. "
        + "The app picks the search service (the user's Search Tool Order) — do not use Safari for this."

    /// Apply `edit` to the description of the tool named `name`, for both
    /// Claude-format ({name, description}) and OpenAI-format
    /// ({function: {name, description}}) tool schemas.
    nonisolated private static func editingDescription(
        _ tools: [[String: Any]], of name: String, _ edit: (String) -> String
    ) -> [[String: Any]] {
        tools.map { tool in
            var tool = tool
            if tool["name"] as? String == name {
                tool["description"] = edit(tool["description"] as? String ?? "")
            } else if var fn = tool["function"] as? [String: Any], fn["name"] as? String == name {
                fn["description"] = edit(fn["description"] as? String ?? "")
                tool["function"] = fn
            }
            return tool
        }
    }

    /// Replace the stale "via Tavily" description on the `search` tool.
    nonisolated static func describingSearchTool(_ tools: [[String: Any]]) -> [[String: Any]] {
        editingDescription(tools, of: "search") { _ in searchToolDescription }
    }

    /// Tell the model Safari is not for plain web searches.
    nonisolated static func steeringSafari(_ tools: [[String: Any]], searchTool: String) -> [[String: Any]] {
        editingDescription(tools, of: "safari") {
            "Only use Safari when the user explicitly asks for Safari or a browser. "
                + "For a plain web search use the \(searchTool) tool instead. " + $0
        }
    }

    /// Keychain key for this backend; nil for keyless DuckDuckGo and Claude.
    nonisolated var storedKey: String? {
        switch self {
        case .ollama: return KeychainService.shared.get(.ollama)
        case .zAI: return KeychainService.shared.get(.zAI)
        case .specStream: return KeychainService.shared.get(.specStream)
        case .exa: return KeychainService.shared.get(.exa)
        case .tavily: return KeychainService.shared.get(.tavily)
        case .duckDuckGo, .claude, .openAI: return nil
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
    static let previewLength = 600

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

    /// Record Claude's server-side web search from a `web_search_tool_result`
    /// block. Results are rendered in the same numbered format as the other
    /// backends; an error object becomes an "Error:" result.
    func recordClaudeSearch(query: String, resultBlock: [String: Any]) {
        let result: String
        if let results = resultBlock["content"] as? [[String: Any]] {
            let hits = results.filter { $0["type"] as? String == "web_search_result" }
            result = hits.isEmpty
                ? "No results found for: \(query)"
                : hits.enumerated().map { i, hit in
                    let title = hit["title"] as? String ?? "Untitled"
                    let url = hit["url"] as? String ?? ""
                    let age = hit["page_age"] as? String ?? ""
                    return "\(i + 1). \(title)\n   \(url)" + (age.isEmpty ? "" : "\n   [\(age)]")
                }.joined(separator: "\n\n")
        } else if let error = resultBlock["content"] as? [String: Any] {
            result = "Error: \(error["error_code"] as? String ?? "unknown error")"
        } else {
            return
        }
        record(query: query, backend: .claude, result: result, isFinal: true)
    }

    /// Record OpenAI's hosted web search from a finished `web_search_call`
    /// output item (Responses API). Only `search` actions are recorded — page
    /// opens and in-page finds are not searches. The item carries the queries
    /// but no result list; results are cited in the model's reply.
    func recordOpenAISearch(item: [String: Any]) {
        guard let action = item["action"] as? [String: Any],
              action["type"] as? String == "search" else { return }
        let queries = (action["queries"] as? [String] ?? []).filter { !$0.isEmpty }
        guard let query = (action["query"] as? String).flatMap({ $0.isEmpty ? nil : $0 }) ?? queries.first else { return }
        let result: String
        if item["status"] as? String == "failed" {
            result = "Error: search failed"
        } else if queries.count > 1 {
            result = "Also searched: " + queries.filter { $0 != query }.joined(separator: "; ")
        } else {
            result = "Results are cited in the reply"
        }
        record(query: query, backend: .openAI, result: result, isFinal: true)
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
