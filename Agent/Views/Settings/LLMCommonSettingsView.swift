import SwiftUI
import AgentTools
import AgentLLM

/// Settings that are shared by every LLM provider — web search keys, the Jev
/// decision layer and the system prompts. They used to sit at the bottom of
/// `SettingsView`, below the per-provider key/model/temperature controls, where
/// they read as if they belonged to the selected provider. They don't.
struct LLMCommonSettingsView: View {
    @Bindable var viewModel: AgentViewModel

    /// Web Search — available for all providers. Exa is preferred when
    /// configured, then Tavily, with DuckDuckGo as the keyless fallback.
    @ViewBuilder
    private var webSearchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Web Search")
                .font(.headline)
            Text("Exa or Tavily provides web search for all LLM providers. DuckDuckGo is used when neither key is set.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Exa API Key").font(.caption).foregroundStyle(.secondary)
                LockedSecureField(text: $viewModel.exaAPIKey, placeholder: "exa-...", lockKey: "lock.exaAPIKey")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Tavily API Key").font(.caption).foregroundStyle(.secondary)
                LockedSecureField(text: $viewModel.tavilyAPIKey, placeholder: "tvly-...", lockKey: "lock.tavilyAPIKey")
            }
        }
    }

    /// Jev (TypeSafe System One) — a decision layer, not an LLM provider, so it
    /// lives here rather than in the provider picker. Jev returns typed
    /// Choice/Score/Noul answers and cannot generate text or tool arguments;
    /// Agent! consults it to gate and route the existing loop.
    @ViewBuilder
    private var jevSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Jev (TypeSafe)")
                    .font(.headline)
                Text("Decision layer")
                    .font(.caption2).bold()
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text("Jev is a System One model: it answers typed yes/no, choice and rating questions about the current state instead of generating text. It advises Agent!'s tool loop — it does not replace your LLM provider.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("API Key").font(.caption).foregroundStyle(.secondary)
                LockedSecureField(text: $viewModel.jevAPIKey, placeholder: "TypeSafe API key", lockKey: "lock.jevAPIKey")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Model").font(.caption).foregroundStyle(.secondary)
                HStack {
                    if viewModel.jevModels.isEmpty {
                        TextField("e.g. \(JevConfiguration.defaultModel)", text: $viewModel.jevModel)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Picker("Model", selection: $viewModel.jevModel) {
                            if !viewModel.jevModels.contains(where: { $0.name == viewModel.jevModel }) {
                                Text(viewModel.jevModel).tag(viewModel.jevModel)
                            }
                            ForEach(viewModel.jevModels, id: \.name) { model in
                                Text(model.name).tag(model.name)
                            }
                        }
                        .labelsHidden()
                    }

                    Button {
                        viewModel.fetchJevModels()
                    } label: {
                        if viewModel.fetchingJevModels {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(viewModel.fetchingJevModels || viewModel.jevAPIKey.isEmpty)
                    .help("Fetch available models")
                }

                if let error = viewModel.jevModelsError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack {
                Text("Consult Jev before tools").font(.caption)
                Spacer()
                Toggle("", isOn: $viewModel.jevAdvisoryEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(.green)
                    .help("Ask Jev for a second opinion before running a shell command. Requires an API key.")
            }
            .disabled(viewModel.jevAPIKey.isEmpty)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Reject at").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(viewModel.jevBlockPercent))% destructive")
                        .font(.caption).monospacedDigit()
                }
                Slider(value: $viewModel.jevBlockPercent, in: 0...100, step: 10)
                    .controlSize(.small)
                    .tint(.green)
                Text("Jev blocks a command it rates this likely — or more — to irreversibly destroy data. 0% rejects everything Jev is asked about; 100% only certainties.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .disabled(viewModel.jevAPIKey.isEmpty || !viewModel.jevAdvisoryEnabled)
        }
        .task { viewModel.autoFetchJevModels() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("LLM Common Settings")
                    .font(.headline)
                Text("Applies to every provider, whichever one is selected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            webSearchSection

            Divider()

            jevSection

            Divider()

            Button("Edit System Prompts...") {
                SystemPromptWindow.shared.show()
            }
        }
        .padding(16)
        .padding(.bottom, 15)
        .frame(width: 360)
    }
}
