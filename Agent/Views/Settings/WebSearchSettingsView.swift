import SwiftUI

/// Web Search keys — available for every LLM provider. Users supply their own
/// keys. SpecStream is tried first when set, then Exa, then Tavily, with
/// DuckDuckGo as the keyless fallback.
struct WebSearchSettingsView: View {
    @Bindable var viewModel: AgentViewModel
    @Environment(\.colorSchemeContrast) private var contrast

    private var captionStyle: HierarchicalShapeStyle { contrast == .increased ? .primary : .secondary }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Web Search")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text("SpecStream, Exa or Tavily provides web search for all LLM providers, tried in that order. DuckDuckGo is used when no key is set.")
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
        }
        .padding(16)
        .frame(width: 360)
    }
}
