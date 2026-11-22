import SwiftUI

/// Web Search keys — available for every LLM provider. Users supply their own
/// keys. SpecStream is tried first when set, then Exa, then Tavily, with
/// DuckDuckGo as the keyless fallback. Below the keys: live stats from
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
            Text("SpecStream, Exa or Tavily provides web search for all LLM providers, tried in that order. Ollama and Z.AI use their own web search first when their key is set. DuckDuckGo is used when no key is set.")
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

    /// One recent search: status icon, query, backend + time, result preview.
    private func historyRow(_ record: WebSearchRecord) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(record.success ? Color.green : Color.red)
                Text(record.query)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                Text("\(record.backend.displayName) · \(record.timestamp.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(captionStyle)
            }
            Text(record.resultPreview)
                .font(.caption2)
                .foregroundStyle(captionStyle)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
