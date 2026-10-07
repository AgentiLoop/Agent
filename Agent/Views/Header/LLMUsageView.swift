import SwiftUI

/// Per-model token usage popover with cost estimates.
/// Scope picker: All tabs (aggregate), Current tab, or any individual tab that produced usage this session.
struct LLMUsageView: View {
    @Bindable var viewModel: AgentViewModel
    @Environment(\.colorSchemeContrast) private var contrast
    private var highContrast: Bool { contrast == .increased }

    private var store: TokenUsageStore { TokenUsageStore.shared }

    enum Scope: Hashable {
        case all
        case current
        case tab(UUID)
    }

    @State private var scope: Scope = .current
    /// Measured height of the model rows; drives the scroll area's height.
    @State private var rowsHeight: CGFloat = 480

    /// Usage dictionary selected by the current scope.
    private var scopedUsage: [String: TokenUsageStore.ModelUsage] {
        switch scope {
        case .all:
            return store.modelUsage
        case .current:
            let key = viewModel.selectedTabId ?? TokenUsageStore.mainTabKey
            return store.tabModelUsage[key] ?? [:]
        case .tab(let id):
            return store.tabModelUsage[id] ?? [:]
        }
    }

    /// Tabs that have recorded usage this session, sorted by label. Main first.
    private var tabsWithUsage: [(id: UUID, label: String)] {
        let main = TokenUsageStore.mainTabKey
        return store.tabModelUsage.keys.compactMap { id -> (UUID, String)? in
            guard !(store.tabModelUsage[id]?.isEmpty ?? true) else { return nil }
            let label = store.tabLabel[id] ?? (id == main ? "Main" : id.uuidString.prefix(6).description)
            return (id, label)
        }
        .sorted { lhs, rhs in
            if lhs.0 == main { return true }
            if rhs.0 == main { return false }
            return lhs.1.localizedCaseInsensitiveCompare(rhs.1) == .orderedAscending
        }
        .map { (id: $0.0, label: $0.1) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("LLM Usage")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    if !store.modelUsage.isEmpty {
                        Button("Reset") {
                            store.resetModelUsage()
                            store.resetCacheMetrics()
                            announceForAccessibility("LLM usage reset")
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundStyle(highContrast ? .primary : .secondary)
                        .accessibilityHint("Clears all token usage and cache counts")
                    }
                }
                Text("Token usage per model since last Reset.")
                    .font(.caption)
                    .foregroundStyle(highContrast ? .primary : .secondary)

                scopePicker
            }
            .padding()
            .padding(.bottom, 4)

            let usage = scopedUsage
            if usage.isEmpty {
                VStack(spacing: 8) {
                    Divider()
                    Text(emptyMessage)
                        .font(.caption)
                        .foregroundStyle(highContrast ? .primary : .tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            } else {
                let sorted = usage.sorted { $0.value.totalTokens > $1.value.totalTokens }
                let maxTokens = sorted.first?.value.totalTokens ?? 1

                // Model rows scroll; header and totals stay pinned. Height tracks
                // the measured content, capped so the popover fits on screen.
                ScrollView {
                VStack(spacing: 0) {
                ForEach(sorted, id: \.key) { model, usage in
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(shortModel(model))
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Text("\(usage.callCount) call\(usage.callCount == 1 ? "" : "s")")
                                    .font(.caption2)
                                    .foregroundStyle(highContrast ? .primary : .tertiary)
                            }
                            .frame(width: 120, alignment: .leading)
                            .help(store.modelProvider[model].map { "Provider: \($0)\nModel: \(model)" } ?? model)

                            VStack(alignment: .leading, spacing: 4) {
                                // Input bar
                                HStack(spacing: 4) {
                                    Text("↑")
                                        .font(.caption2)
                                        .foregroundStyle(highContrast ? Color.primary : Color.blue)
                                        .frame(width: 12)
                                    GeometryReader { geo in
                                        let frac = CGFloat(usage.inputTokens) / CGFloat(max(maxTokens, 1))
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.blue.opacity(highContrast ? 1 : 0.6))
                                            .frame(width: geo.size.width * frac)
                                    }
                                    .frame(height: 8)
                                    Text(fmt(usage.inputTokens))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(highContrast ? .primary : .secondary)
                                        .frame(width: 45, alignment: .trailing)
                                }
                                // Output bar
                                HStack(spacing: 4) {
                                    Text("↓")
                                        .font(.caption2)
                                        .foregroundStyle(highContrast ? Color.primary : Color.green)
                                        .frame(width: 12)
                                    GeometryReader { geo in
                                        let frac = CGFloat(usage.outputTokens) / CGFloat(max(maxTokens, 1))
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.green.opacity(highContrast ? 1 : 0.6))
                                            .frame(width: geo.size.width * frac)
                                    }
                                    .frame(height: 8)
                                    Text(fmt(usage.outputTokens))
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(highContrast ? .primary : .secondary)
                                        .frame(width: 45, alignment: .trailing)
                                }
                            }

                            // Cost — "Included" for OAuth (billed against the
                            // subscription), "free" for local models, $ for API-key.
                            if isSubscriptionBilled(model: model) {
                                Text("Included")
                                    .font(.caption)
                                    .foregroundStyle(highContrast ? Color.primary : Color.green)
                                    .frame(width: 62, alignment: .trailing)
                                    .help("Billed against your ChatGPT / Claude subscription — no per-token cost.")
                            } else {
                                let cost = store.estimatedCost(model: model, inputTokens: usage.inputTokens, outputTokens: usage.outputTokens)
                                if cost > 0 {
                                    Text(String(format: "$%.3f", cost))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(highContrast ? Color.primary : Color.orange)
                                        .frame(width: 62, alignment: .trailing)
                                } else {
                                    Text("free")
                                        .font(.caption)
                                        .foregroundStyle(highContrast ? .primary : .tertiary)
                                        .frame(width: 62, alignment: .trailing)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(shortModel(model))
                        .accessibilityValue(rowSummary(model: model, usage: usage))
                    }
                }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { rowsHeight = $0 }
                }
                .frame(height: min(rowsHeight, 480))

                // Totals
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Text("Total")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        let totalIn = usage.values.reduce(0) { $0 + $1.inputTokens }
                        let totalOut = usage.values.reduce(0) { $0 + $1.outputTokens }
                        let nonSubCost = usage.reduce(0.0) { acc, entry in
                            isSubscriptionBilled(model: entry.key) ? acc : acc + store.estimatedCost(model: entry.key, inputTokens: entry.value.inputTokens, outputTokens: entry.value.outputTokens)
                        }
                        let hasSub = usage.contains(where: { isSubscriptionBilled(model: $0.key) })
                        HStack(spacing: 8) {
                            Text("↑ \(fmt(totalIn))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(highContrast ? Color.primary : Color.blue)
                                .accessibilityLabel("Input \(fmt(totalIn))")
                            Text("↓ \(fmt(totalOut))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(highContrast ? Color.primary : Color.green)
                                .accessibilityLabel("Output \(fmt(totalOut))")
                            if nonSubCost > 0 {
                                Text(String(format: "$%.3f", nonSubCost))
                                    .font(.caption.monospacedDigit().weight(.semibold))
                                    .foregroundStyle(highContrast ? Color.primary : Color.orange)
                            } else if hasSub {
                                Text("Included")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(highContrast ? Color.primary : Color.green)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .accessibilityElement(children: .combine)
                }

                // Cache metrics (session-wide, not scoped per tab yet)
                if store.sessionCacheReadTokens > 0 || store.sessionCacheCreationTokens > 0 {
                    VStack(spacing: 0) {
                        Divider()
                        HStack {
                            Text("Cache")
                                .font(.subheadline)
                            Spacer()
                            HStack(spacing: 8) {
                                Text("Hit: \(fmt(store.sessionCacheReadTokens))")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(highContrast ? Color.primary : Color.cyan)
                                Text("Miss: \(fmt(store.sessionCacheCreationTokens))")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(highContrast ? .primary : .secondary)
                                Text("\(store.cacheHitRate)%")
                                    .font(.caption.monospacedDigit().weight(.medium))
                                    .foregroundStyle(store.cacheHitRate > 70 ? .green : store.cacheHitRate > 30 ? .yellow : .red)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Cache")
                        .accessibilityValue("Hit \(fmt(store.sessionCacheReadTokens)), Miss \(fmt(store.sessionCacheCreationTokens)), \(store.cacheHitRate) percent hit rate")
                    }
                }
            }
        }
        .padding(.bottom, 15)
        .frame(width: 420)
    }

    @ViewBuilder
    private var scopePicker: some View {
        let tabs = tabsWithUsage
        if tabs.count > 1 || (tabs.count == 1 && scope == .all) {
            Picker("Scope", selection: $scope) {
                Text("Current tab").tag(Scope.current)
                Text("All tabs").tag(Scope.all)
                Divider()
                ForEach(tabs, id: \.id) { tab in
                    Text(tab.label).tag(Scope.tab(tab.id))
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .accessibilityLabel("Usage Scope")
        }
    }

    private var emptyMessage: String {
        switch scope {
        case .all: return "No LLM calls yet."
        case .current: return "No LLM calls on this tab yet."
        case .tab: return "No LLM calls recorded for this tab."
        }
    }

    /// True when the model's usage is billed against a subscription (Claude
    /// OAuth or Codex OAuth) rather than per-token. Renders as "Included"
    /// instead of a dollar amount in the popover. Prefer the per-call flag
    /// recorded at usage time; fall back to provider+current-credential
    /// detection for legacy rows recorded before the flag was added.
    private func isSubscriptionBilled(model: String) -> Bool {
        if store.subscriptionModels.contains(model) { return true }
        let provider = store.modelProvider[model] ?? ""
        if provider == "Codex" || provider == "Muse Code" { return true }
        if provider == "Claude", ClaudeService.isOAuthToken(viewModel.apiKey) { return true }
        return false
    }

    private func fmt(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }

    /// Spoken summary of one model row for VoiceOver.
    private func rowSummary(model: String, usage: TokenUsageStore.ModelUsage) -> String {
        let calls = "\(usage.callCount) call\(usage.callCount == 1 ? "" : "s")"
        let cost: String
        if isSubscriptionBilled(model: model) {
            cost = "Included"
        } else {
            let c = store.estimatedCost(model: model, inputTokens: usage.inputTokens, outputTokens: usage.outputTokens)
            cost = c > 0 ? String(format: "$%.3f", c) : "free"
        }
        return "\(calls), Input \(fmt(usage.inputTokens)), Output \(fmt(usage.outputTokens)), \(cost)"
    }

    private func shortModel(_ model: String) -> String {
        let parts = model.components(separatedBy: "-")
        if parts.count > 3, let last = parts.last, last.count == 8, Int(last) != nil {
            return parts.dropLast().joined(separator: "-")
        }
        return model
    }
}
