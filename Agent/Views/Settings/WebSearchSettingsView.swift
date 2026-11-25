import SwiftUI

/// Web Search keys — available for every LLM provider. Users supply their own
/// keys, then drag the search tools into order (top = preferred); tools
/// without a key are skipped. Below the order: live stats from
/// WebSearchStatsStore — which backend served the last search, per-backend
/// usage and errors, and recent search/result history.
struct WebSearchSettingsView: View {
    @Bindable var viewModel: AgentViewModel
    @Environment(\.colorSchemeContrast) private var contrast

    private var captionStyle: HierarchicalShapeStyle { contrast == .increased ? .primary : .secondary }

    private var stats: WebSearchStatsStore { WebSearchStatsStore.shared }

    /// Backends that have actually served a search, in fallback-chain order.
    private var usedBackends: [WebSearchBackend] {
        WebSearchBackend.allCases.filter { stats.backendStats[$0] != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Web Search")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text("Web search works with every LLM provider. Drag the search tools below into the order you want. The top one is preferred and the rest are tried in order if it fails. Tools without a key are skipped.")
                .font(.caption)
                .foregroundStyle(captionStyle)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 4) {
                Text("SpecStream API Key").font(.caption).foregroundStyle(captionStyle).accessibilityHidden(true)
                LockedSecureField(text: $viewModel.specStreamAPIKey, placeholder: "SpecStream API key", lockKey: "lock.specStreamAPIKey", label: "SpecStream API Key")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Exa API Key").font(.caption).foregroundStyle(captionStyle).accessibilityHidden(true)
                LockedSecureField(text: $viewModel.exaAPIKey, placeholder: "exa-...", lockKey: "lock.exaAPIKey", label: "Exa API Key")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Tavily API Key").font(.caption).foregroundStyle(captionStyle).accessibilityHidden(true)
                LockedSecureField(text: $viewModel.tavilyAPIKey, placeholder: "tvly-...", lockKey: "lock.tavilyAPIKey", label: "Tavily API Key")
            }

            Divider()

            orderSection

            Divider()

            statsSection

            if !stats.history.isEmpty {
                Divider()
                Text("Recent Searches")
                    .font(.caption)
                    .foregroundStyle(captionStyle)
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(stats.history.prefix(10)) { record in
                            historyRow(record)
                        }
                    }
                }
                .frame(maxHeight: 170)
            }
        }
        .padding(16)
        .frame(width: 360)
    }

    // MARK: - Search Order

    /// Saved drag-and-drop order (comma-separated backend raw values).
    @AppStorage(WebSearchBackend.orderDefaultsKey) private var orderRaw = ""

    private var order: [WebSearchBackend] { WebSearchBackend.order(from: orderRaw) }

    /// The provider-hosted search for the current tab's LLM, if any: Claude's
    /// for Claude, OpenAI's for Codex. It runs inside the provider's API, so
    /// it replaces the app's own search tool and can't be reordered.
    private var builtInBackend: WebSearchBackend? {
        switch viewModel.selectedTab?.llmConfig?.provider ?? viewModel.selectedProvider {
        case .claude: return .claude
        case .codex: return .openAI
        default: return nil
        }
    }

    /// Whether a backend can run: it has a key, or is keyless DuckDuckGo.
    private func isAvailable(_ backend: WebSearchBackend) -> Bool {
        switch backend {
        case .specStream: return !viewModel.specStreamAPIKey.isEmpty
        case .exa: return !viewModel.exaAPIKey.isEmpty
        case .tavily: return !viewModel.tavilyAPIKey.isEmpty
        case .ollama, .zAI: return !(backend.storedKey ?? "").isEmpty
        case .duckDuckGo: return true
        case .claude, .openAI: return false
        }
    }

    /// Drag-and-drop list of every search tool. Top available row is the
    /// preferred tool; the rest are the fallback order.
    private var orderSection: some View {
        let preferred = order.first(where: isAvailable)
        return VStack(alignment: .leading, spacing: 4) {
            Text("Search Tool Order").font(.caption).foregroundStyle(captionStyle)
            List {
                // Fixed, non-draggable row: the provider's own search runs
                // inside its API, so it only appears when this tab's LLM has one.
                if let builtInBackend {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(captionStyle)
                            .accessibilityHidden(true)
                        Text(builtInBackend.displayName)
                            .font(.caption)
                        Spacer()
                        Text("Built in").font(.caption2).foregroundStyle(captionStyle)
                    }
                    .accessibilityElement(children: .combine)
                    .moveDisabled(true)
                }
                ForEach(Array(order.enumerated()), id: \.element) { index, backend in
                    let available = isAvailable(backend)
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal")
                            .font(.caption2)
                            .foregroundStyle(captionStyle)
                            .accessibilityHidden(true)
                        Text("\(index + 1). \(backend.displayName)")
                            .font(.caption)
                            .foregroundStyle(available ? AnyShapeStyle(.primary) : AnyShapeStyle(captionStyle))
                        Spacer()
                        if backend == preferred {
                            Text("Preferred").font(.caption2).foregroundStyle(Color.green)
                        } else if !available {
                            Text("No key — skipped").font(.caption2).foregroundStyle(captionStyle)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                .onMove { from, to in
                    var newOrder = order
                    newOrder.move(fromOffsets: from, toOffset: to)
                    orderRaw = newOrder.map(\.rawValue).joined(separator: ",")
                }
            }
            .listStyle(.bordered)
            .frame(height: CGFloat(WebSearchBackend.defaultOrder.count + (builtInBackend == nil ? 0 : 1)) * 24 + 8)
        }
    }

    // MARK: - Stats & Errors

    /// Summary line (last backend used, when, total searches) plus one
    /// usage/error row per backend that has served a search.
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let last = stats.lastBackend {
                Text("Last used: \(last.displayName)\(lastUsedSuffix) · \(stats.totalSearches) total search\(stats.totalSearches == 1 ? "" : "es")")
                    .font(.caption)
                    .foregroundStyle(captionStyle)
            } else {
                Text("No searches run yet")
                    .font(.caption)
                    .foregroundStyle(captionStyle)
            }

            ForEach(usedBackends, id: \.self) { backend in
                backendRow(backend)
            }
        }
    }

    private var lastUsedSuffix: String {
        guard let date = stats.lastSearchDate else { return "" }
        return " — " + date.formatted(.relative(presentation: .named))
    }

    /// One backend's usage line: name, ok/error counts, and its last error
    /// (in orange) when one has occurred.
    private func backendRow(_ backend: WebSearchBackend) -> some View {
        let s = stats.backendStats[backend] ?? WebSearchBackendStats()
        return VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text(backend.displayName)
                    .font(.caption)
                Spacer()
                Text("\(s.successCount) ok · \(s.errorCount) error\(s.errorCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(s.errorCount > 0 ? AnyShapeStyle(Color.orange) : AnyShapeStyle(captionStyle))
            }
            if let error = s.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(Color.orange)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - History

    /// One recent search: status icon, query, backend + time, then the top
    /// result laid out as title, clickable URL and a flowing snippet.
    private func historyRow(_ record: WebSearchRecord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(record.success ? Color.green : Color.red)
                    .accessibilityLabel(record.success ? "Succeeded" : "Failed")
                Text(record.query)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text("\(record.backend.displayName) · \(record.timestamp.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(captionStyle)
                    .lineLimit(1)
            }
            historyDetail(record)
                .padding(.leading, 14)
        }
        .padding(.vertical, 2)
    }

    /// Body of a history row: the error for failed searches, the parsed top
    /// result for successful ones, or the flattened preview if it can't be parsed.
    @ViewBuilder
    private func historyDetail(_ record: WebSearchRecord) -> some View {
        if !record.success {
            Text(Self.flattened(record.resultPreview.replacingOccurrences(of: "Error:", with: "")))
                .font(.caption2)
                .foregroundStyle(Color.red)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        } else if let top = Self.topResult(from: record.resultPreview) {
            VStack(alignment: .leading, spacing: 1) {
                if !top.title.isEmpty {
                    Text(top.title)
                        .font(.caption)
                        .lineLimit(1)
                }
                if let url = URL(string: top.url), url.scheme != nil {
                    Link(destination: url) {
                        Text(Self.displayURL(top.url))
                            .font(.caption2)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .help(top.url)
                }
                if !top.snippet.isEmpty {
                    Text(top.snippet)
                        .font(.caption2)
                        .foregroundStyle(captionStyle)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        } else {
            Text(Self.flattened(record.resultPreview))
                .font(.caption2)
                .foregroundStyle(captionStyle)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Top result pulled from a backend's numbered output
    /// ("1. Title" / "   url" / "   [meta]" / "   snippet"). A SpecStream
    /// "Answer:" line, when present, is used as the snippet.
    private static func topResult(from preview: String) -> (title: String, url: String, snippet: String)? {
        let lines = preview.components(separatedBy: .newlines)
        var answer = ""
        var title: String?
        var url = ""
        var snippetParts: [String] = []
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if title == nil {
                if line.hasPrefix("Answer:") {
                    answer = String(line.dropFirst("Answer:".count)).trimmingCharacters(in: .whitespaces)
                } else if let range = line.range(of: #"^\d+\.\s+"#, options: .regularExpression) {
                    title = String(line[range.upperBound...])
                }
                continue
            }
            // Stop at the end of the first result.
            if line.isEmpty || line.range(of: #"^\d+\.\s+"#, options: .regularExpression) != nil { break }
            if url.isEmpty, line.hasPrefix("http") {
                url = line
            } else if !(line.hasPrefix("[") && line.hasSuffix("]")) {
                snippetParts.append(line)
            }
        }
        guard let title else { return nil }
        let snippet = answer.isEmpty ? flattened(snippetParts.joined(separator: " ")) : answer
        return (title, url, snippet == title ? "" : snippet)
    }

    /// URL without scheme or "www." for compact display.
    private static func displayURL(_ url: String) -> String {
        var s = url
        for prefix in ["https://", "http://", "www."] where s.hasPrefix(prefix) {
            s.removeFirst(prefix.count)
        }
        return s.hasSuffix("/") ? String(s.dropLast()) : s
    }

    /// Collapse line breaks and runs of whitespace into single spaces.
    private static func flattened(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
