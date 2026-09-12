import SwiftUI
import AgentTools
import AgentLLM

struct SettingsView: View {
    @Bindable var viewModel: AgentViewModel

    /// Per-provider temperature binding so the slider always edits the active model's temp.
    private var llmTemperatureBinding: Binding<Double> {
        switch viewModel.selectedProvider {
        case .claude: return $viewModel.temperatures[.claude]
        case .codex: return $viewModel.temperatures[.openAI]
        case .ollama: return $viewModel.temperatures[.ollama]
        case .openAI: return $viewModel.temperatures[.openAI]
        case .deepSeek: return $viewModel.temperatures[.deepSeek]
        case .huggingFace: return $viewModel.temperatures[.huggingFace]
        case .localOllama: return $viewModel.temperatures[.localOllama]
        case .vLLM: return $viewModel.temperatures[.vLLM]
        case .lmStudio: return $viewModel.temperatures[.lmStudio]
        case .zAI: return $viewModel.temperatures[.zAI]
        case .bigModel: return $viewModel.temperatures[.zAI]
        case .miniMax: return $viewModel.temperatures[.miniMax]
        case .openRouter: return $viewModel.temperatures[.openAI]
        case .requesty: return $viewModel.temperatures[.openAI]
        case .qwen: return $viewModel.temperatures[.openAI]
        case .gemini: return $viewModel.temperatures[.gemini]
        case .grok: return $viewModel.temperatures[.grok]
        case .mistral: return $viewModel.temperatures[.openAI]
        case .vibe: return $viewModel.temperatures[.openAI]
        case .foundationModel: return $viewModel.temperatures[.claude] // unused
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Provider toggle
            VStack(alignment: .leading, spacing: 12) {
                Text("LLM Provider")
                    .font(.headline)

                Text("Configure your AI provider and API keys.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("AI", selection: $viewModel.selectedProvider) {
                    ForEach(APIProvider.selectableProviders, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .labelsHidden()

                Text("Ollama Pro is preferred")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if viewModel.selectedProvider == .claude {
                // Claude settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Claude API")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("API Key or OAuth Token").font(.caption).foregroundStyle(.secondary)
                            if ClaudeService.isOAuthToken(viewModel.apiKey) {
                                Text("OAuth (subscription)")
                                    .font(.caption2).bold()
                                    .padding(.horizontal, 6).padding(.vertical, 1)
                                    .background(Color.accentColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        LockedSecureField(text: $viewModel.apiKey, placeholder: "sk-ant-api… (key) or sk-ant-oat01… (OAuth)", lockKey: "lock.apiKeys[.claude]")
                        Text("Paste `sk-ant-api…` for pay-per-token billing, or run `claude setup-token` in Claude Code and paste the resulting `sk-ant-oat01…` to bill against your Claude subscription.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Picker("Model", selection: $viewModel.selectedModel) {
                                ForEach(viewModel.availableClaudeModels) { model in
                                    Text(model.formattedDisplayName).tag(model.id)
                                }
                            }
                            .labelsHidden()

                            Button {
                                viewModel.fetchModelsIfNeeded(for: .claude, force: true)
                            } label: {
                                if viewModel.fetchingModels.contains(.claude) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.claude))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .openAI {
                // OpenAI settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("OpenAI API")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.openAI], placeholder: "sk-...", lockKey: "lock.apiKeys[.openAI]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.openAI].isEmpty {
                                TextField("Model name", text: $viewModel.models[.openAI])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.openAI]) {
                                    ForEach(viewModel.modelLists[.openAI]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchModelsIfNeeded(for: .openAI, force: true)
                            } label: {
                                if viewModel.fetchingModels.contains(.openAI) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.openAI))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .deepSeek {
                // DeepSeek settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("DeepSeek API")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.deepSeek], placeholder: "sk-...", lockKey: "lock.apiKeys[.deepSeek]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.deepSeek].isEmpty {
                                TextField("Model name", text: $viewModel.models[.deepSeek])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.deepSeek]) {
                                    ForEach(viewModel.modelLists[.deepSeek]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchDeepSeekModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.deepSeek) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.deepSeek))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .huggingFace {
                // Hugging Face settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hugging Face Inference")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.huggingFace], placeholder: "hf_...", lockKey: "lock.apiKeys[.huggingFace]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.huggingFace].isEmpty {
                                TextField("Model name", text: $viewModel.models[.huggingFace])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.huggingFace]) {
                                    ForEach(viewModel.modelLists[.huggingFace]) { model in
                                        HStack(spacing: 4) {
                                            Text(model.name)
                                            if AgentViewModel.isVisionModel(model.id) {
                                                Image(systemName: "eye")
                                                    .foregroundStyle(.blue)
                                                    .font(.caption2)
                                            }
                                        }.tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchHuggingFaceModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.huggingFace) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.huggingFace))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .zAI {
                // Z.ai (ZhipuAI GLM) settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Z.ai API")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.zAI], placeholder: "Z.ai API key", lockKey: "lock.apiKeys[.zAI]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.zAI].isEmpty {
                                TextField("Model name", text: $viewModel.models[.zAI])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.zAI]) {
                                    ForEach(viewModel.modelLists[.zAI]) { model in
                                        HStack(spacing: 4) {
                                            Text(model.name)
                                            if model.id.hasSuffix(":v") {
                                                Image(systemName: "eye")
                                                    .foregroundStyle(.blue)
                                                    .font(.caption2)
                                            }
                                        }.tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchModelsIfNeeded(for: .zAI, force: true)
                            } label: {
                                if viewModel.fetchingModels.contains(.zAI) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.zAI))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .bigModel {
                VStack(alignment: .leading, spacing: 10) {
                    Text("BigModel (China)")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.bigModel], placeholder: "BigModel API key", lockKey: "lock.apiKeys[.bigModel]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        TextField("Model name", text: $viewModel.models[.bigModel])
                            .textFieldStyle(.roundedBorder)
                    }
                }
            } else if viewModel.selectedProvider == .miniMax {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MiniMax API")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.miniMax], placeholder: "MiniMax API key", lockKey: "lock.apiKeys[.miniMax]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.miniMax].isEmpty {
                                TextField("Model name", text: $viewModel.models[.miniMax])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.miniMax]) {
                                    ForEach(viewModel.modelLists[.miniMax]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchMiniMaxModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.miniMax) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.miniMax))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .openRouter {
                VStack(alignment: .leading, spacing: 10) {
                    Text("OpenRouter")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Protocol").font(.caption).foregroundStyle(.secondary)
                        Picker("Protocol", selection: $viewModel.openRouterProtocol) {
                            ForEach(APIProvider.openRouter.config.supportedProtocols, id: \.self) { proto in
                                Text(proto.displayName).tag(proto)
                            }
                        }
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.openRouter], placeholder: "sk-or-...", lockKey: "lock.apiKeys[.openRouter]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.openRouter].isEmpty {
                                TextField("e.g. anthropic/claude-opus-4", text: $viewModel.models[.openRouter])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.openRouter]) {
                                    ForEach(viewModel.modelLists[.openRouter]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchOpenRouterModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.openRouter) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.openRouter))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .requesty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Requesty")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.requesty], placeholder: "Requesty API key", lockKey: "lock.apiKeys[.requesty]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.requesty].isEmpty {
                                TextField("e.g. anthropic/claude-sonnet-4-5", text: $viewModel.models[.requesty])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.requesty]) {
                                    ForEach(viewModel.modelLists[.requesty]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchRequestyModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.requesty) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.requesty))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .qwen {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Qwen (DashScope)")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.qwen], placeholder: "DashScope API key", lockKey: "lock.apiKeys[.qwen]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.qwen].isEmpty {
                                TextField("Model name", text: $viewModel.models[.qwen])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.qwen]) {
                                    ForEach(viewModel.modelLists[.qwen]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchQwenModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.qwen) {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.borderless)
                            .disabled(viewModel.fetchingModels.contains(.qwen))
                        }
                    }
                }
            } else if viewModel.selectedProvider == .gemini {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Google Gemini API")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.gemini], placeholder: "Gemini API key", lockKey: "lock.apiKeys[.gemini]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.gemini].isEmpty {
                                TextField("Model name", text: $viewModel.models[.gemini])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.gemini]) {
                                    ForEach(viewModel.modelLists[.gemini]) { model in
                                        HStack(spacing: 4) {
                                            Text(model.name)
                                            if model.id.contains("gemini-") {
                                                Image(systemName: "eye")
                                                    .foregroundStyle(.blue)
                                                    .font(.caption2)
                                            }
                                        }.tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchGeminiModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.gemini) {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.gemini))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .grok {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Grok API (xAI)")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.grok], placeholder: "Grok API key", lockKey: "lock.apiKeys[.grok]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.grok].isEmpty {
                                TextField("Model name", text: $viewModel.models[.grok])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.grok]) {
                                    ForEach(viewModel.modelLists[.grok]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchGrokModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.grok) {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.grok))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .mistral {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mistral AI")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.mistral], placeholder: "Mistral API key", lockKey: "lock.apiKeys[.mistral]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.mistral].isEmpty {
                                TextField("Model name", text: $viewModel.models[.mistral])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.mistral]) {
                                    ForEach(viewModel.modelLists[.mistral]) { model in
                                        HStack(spacing: 4) {
                                            Text(model.name)
                                            if AgentViewModel.isVisionModel(model.id) {
                                                Image(systemName: "eye")
                                                    .foregroundStyle(.blue)
                                                    .font(.caption2)
                                            }
                                        }.tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }
                            Button {
                                viewModel.fetchMistralModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.mistral) {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.mistral))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .vibe {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Mistral Vibe")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.vibe], placeholder: "Vibe API key", lockKey: "lock.apiKeys[.vibe]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Picker("", selection: $viewModel.models[.vibe]) {
                                ForEach(viewModel.modelLists[.vibe], id: \.id) { model in
                                    Text(model.name.isEmpty ? model.id : model.name).tag(model.id)
                                }
                            }
                            .labelsHidden()

                            Button {
                                viewModel.fetchVibeModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.vibe) {
                                    ProgressView().controlSize(.mini)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.vibe))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .ollama {
                // Cloud Ollama settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ollama Cloud")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.ollama], placeholder: "Required for cloud", lockKey: "lock.apiKeys[.ollama]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.ollamaModels.isEmpty {
                                TextField("Model name", text: $viewModel.models[.ollama])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.ollama]) {
                                    ForEach(viewModel.ollamaModels) { model in
                                        HStack(spacing: 4) {
                                            Text(model.name)
                                            if model.supportsVision {
                                                Image(systemName: "eye")
                                                    .foregroundStyle(.blue)
                                                    .font(.caption2)
                                            }
                                        }
                                        .tag(model.name)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchModelsIfNeeded(for: .ollama, force: true)
                            } label: {
                                if viewModel.fetchingModels.contains(.ollama) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.ollama))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .lmStudio {
                // LM Studio settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("LM Studio")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Protocol").font(.caption).foregroundStyle(.secondary)
                        Picker("Protocol", selection: $viewModel.lmStudioProtocol) {
                            ForEach(LMStudioProtocol.allCases, id: \.self) { proto in
                                Text(proto.displayName).tag(proto)
                            }
                        }
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key (optional)").font(.caption).foregroundStyle(.secondary)
                        SecureField("Leave blank if not required", text: $viewModel.apiKeys[.lmStudio])
                            .textContentType(.oneTimeCode)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Endpoint").font(.caption).foregroundStyle(.secondary)
                        TextField(viewModel.lmStudioProtocol.defaultEndpoint, text: $viewModel.lmStudioEndpoint)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.lmStudio].isEmpty {
                                TextField("Model name", text: $viewModel.models[.lmStudio])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.lmStudio]) {
                                    ForEach(viewModel.modelLists[.lmStudio]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchLMStudioModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.lmStudio) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.lmStudio))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .vLLM {
                // vLLM settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("vLLM")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Endpoint").font(.caption).foregroundStyle(.secondary)
                        TextField("http://localhost:8000/v1/chat/completions", text: $viewModel.vLLMEndpoint)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key (optional)").font(.caption).foregroundStyle(.secondary)
                        LockedSecureField(text: $viewModel.apiKeys[.vLLM], placeholder: "Optional", lockKey: "lock.apiKeys[.vLLM]")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.vLLM].isEmpty {
                                TextField("Model name", text: $viewModel.models[.vLLM])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.vLLM]) {
                                    ForEach(viewModel.modelLists[.vLLM]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchVLLMModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.vLLM) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.vLLM))
                            .help("Fetch available models")
                        }
                    }
                }
            } else if viewModel.selectedProvider == .codex {
                // Codex — ChatGPT subscription OAuth via ~/.codex/auth.json
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Text("Codex")
                            .font(.headline)
                        Text("OAuth (ChatGPT subscription)")
                            .font(.caption2).bold()
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Authentication").font(.caption).foregroundStyle(.secondary)
                        if let auth = CodexAuthFile.load() {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                                Text("Signed in")
                                Spacer()
                                if let exp = CodexJWT.expiry(auth.accessToken) {
                                    let mins = Int(exp.timeIntervalSinceNow / 60)
                                    Text(mins > 0 ? "expires in \(mins)m" : "expired")
                                        .font(.caption2)
                                        .foregroundStyle(mins > 0 ? Color.secondary : Color.red)
                                }
                            }
                            HStack(spacing: 8) {
                                Button("Refresh Token") {
                                    Task.detached {
                                        _ = try? await CodexAuthRefresher.refresh(auth)
                                    }
                                }
                                .controlSize(.small)
                                Button("Sign In Again") {
                                    CodexLoginLauncher.launch()
                                }
                                .controlSize(.small)
                                Spacer()
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                                Text("Not signed in")
                                Spacer()
                                Button("Sign In via Codex CLI") {
                                    CodexLoginLauncher.launch()
                                }
                                .controlSize(.small)
                            }
                        }
                        Text("Codex uses your ChatGPT Plus/Pro/Business/Edu/Enterprise subscription for billing. Sign In launches `codex login` in Terminal — complete the browser OAuth flow, then return here. Agent! reads `~/.codex/auth.json`; tokens refresh automatically.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.modelLists[.codex].isEmpty {
                                TextField("Model id (e.g. gpt-5)", text: $viewModel.models[.codex])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.codex]) {
                                    ForEach(viewModel.modelLists[.codex]) { model in
                                        Text(model.name).tag(model.id)
                                    }
                                }
                                .labelsHidden()
                            }
                            Button {
                                viewModel.fetchModelsIfNeeded(for: .codex, force: true)
                            } label: {
                                if viewModel.fetchingModels.contains(.codex) {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.codex))
                            .help("Fetch available models from Codex")
                        }
                    }
                }
            } else {
                // Local Ollama settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Local Ollama")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Endpoint").font(.caption).foregroundStyle(.secondary)
                        TextField("http://localhost:11434/api/chat", text: $viewModel.localOllamaEndpoint)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Model").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            if viewModel.localOllamaModels.isEmpty {
                                TextField("Model name", text: $viewModel.models[.localOllama])
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Picker("Model", selection: $viewModel.models[.localOllama]) {
                                    ForEach(viewModel.localOllamaModels) { model in
                                        HStack(spacing: 4) {
                                            Text(model.name)
                                            if model.supportsVision {
                                                Image(systemName: "eye")
                                                    .foregroundStyle(.blue)
                                                    .font(.caption2)
                                            }
                                        }
                                        .tag(model.name)
                                    }
                                }
                                .labelsHidden()
                            }

                            Button {
                                viewModel.fetchLocalOllamaModels()
                            } label: {
                                if viewModel.fetchingModels.contains(.localOllama) {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(viewModel.fetchingModels.contains(.localOllama))
                            .help("Fetch available local models")
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Context Window").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            TextField("0 = auto", text: Binding(
                                get: { viewModel.localOllamaContextSize == 0 ? "" : "\(viewModel.localOllamaContextSize)" },
                                set: { viewModel.localOllamaContextSize = Int($0) ?? 0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)

                            Text(
                                viewModel
                                    .localOllamaContextSize == 0 ? "Model default" : "\(viewModel.localOllamaContextSize / 1024)K tokens"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Max Output Tokens — for providers that support it
            if viewModel.selectedProvider != .localOllama && viewModel.selectedProvider != .foundationModel {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max Output Tokens").font(.caption).foregroundStyle(.secondary)
                    HStack {
                        TextField(viewModel.selectedProvider == .claude ? "16384" : "0 = default", text: Binding(
                            get: { viewModel.maxTokens == 0 ? "" : "\(viewModel.maxTokens)" },
                            set: { viewModel.maxTokens = Int($0) ?? 0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)

                        Text(
                            viewModel
                                .maxTokens == 0 ? (viewModel.selectedProvider == .claude ? "Defaults to 16384" : "Provider default") :
                                "\(viewModel.maxTokens) tokens"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }

            // Reasoning effort — extended thinking for Claude, reasoning_effort
            // pass-through for OpenAI-compatible providers
            if viewModel.selectedProvider != .localOllama && viewModel.selectedProvider != .foundationModel {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reasoning").font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Picker("", selection: Binding(
                            get: { viewModel.reasoningEffort },
                            set: { viewModel.reasoningEffort = $0 }
                        )) {
                            Text("Off").tag("off")
                            Text("Low").tag("low")
                            Text("Medium").tag("medium")
                            Text("High").tag("high")
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 260)

                        Text(viewModel.reasoningEffort == "off"
                             ? "No extended thinking"
                             : "Thinking between tool calls")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Temperature — lives with the LLM since it's a per-provider setting
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Temperature").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel.selectedProvider.displayName).font(.caption).foregroundStyle(.secondary)
                    Text(String(format: "%.1f", llmTemperatureBinding.wrappedValue))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(viewModel.temperatureColor(llmTemperatureBinding.wrappedValue))
                        .frame(width: 28, alignment: .trailing)
                }
                Slider(value: llmTemperatureBinding, in: 0...2, step: 0.1)
                    .id(viewModel.selectedProvider)
                    .tint(viewModel.temperatureColor(llmTemperatureBinding.wrappedValue))
                    .onAppear {
                        // Force the slider thumb + tint color to redraw on first appear.
                        let current = llmTemperatureBinding.wrappedValue
                        llmTemperatureBinding.wrappedValue = max(0, current - 0.1)
                        DispatchQueue.main.async {
                            llmTemperatureBinding.wrappedValue = min(2, current + 0.1)
                            DispatchQueue.main.async {
                                llmTemperatureBinding.wrappedValue = current
                            }
                        }
                    }
            }

            // Web Search — available for all providers. Exa is preferred when
            // configured, then Tavily, with DuckDuckGo as the keyless fallback.
            VStack(alignment: .leading, spacing: 10) {
                Text("Web Search")
                    .font(.headline)
                Text("Exa or Tavily provides web search for all LLM providers. DuckDuckGo is used when neither key is set.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exa API Key").font(.caption).foregroundStyle(.secondary)
                    LockedSecureField(text: $viewModel.exaAPIKey, placeholder: "exa-...", lockKey: "lock.exaAPIKey")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tavily API Key").font(.caption).foregroundStyle(.secondary)
                    LockedSecureField(text: $viewModel.tavilyAPIKey, placeholder: "tvly-...", lockKey: "lock.tavilyAPIKey")
                }
            }

            // System Prompts Editor
            Button("Edit System Prompts...") {
                SystemPromptWindow.shared.show()
            }

            Divider()

            HStack {
                Text("Force Vision").font(.caption)
                Spacer()
                Toggle("", isOn: $viewModel.forceVision)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .help("Always send images to LLM, even for non-vision models")
            }

            HStack {
                Text("Auto-scroll Steps").font(.caption)
                Spacer()
                Toggle("", isOn: $viewModel.toolStepsAutoScroll)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .help("Keep the Steps list scrolled to the newest step while the mouse is not hovering over it")
            }

        }
        .padding(16)
        .padding(.bottom, 15)
        .frame(width: 360)
        .onAppear {
            refreshModelsForCurrentProvider()
        }
        .onChange(of: viewModel.selectedProvider) { _, _ in
            refreshModelsForCurrentProvider()
        }
    }

    private func refreshModelsForCurrentProvider() {
        viewModel.fetchModelsIfNeeded(for: viewModel.selectedProvider, force: true)
    }
}

// MARK: - Locked Secure Field

/// A SecureField with a lock/unlock button. When locked, the field is disabled.
/// Lock state persists in UserDefaults via the lockKey.
struct LockedSecureField: View {
    @Binding var text: String
    let placeholder: String
    let lockKey: String
    @State private var isLocked: Bool

    init(text: Binding<String>, placeholder: String, lockKey: String) {
        self._text = text
        self.placeholder = placeholder
        self.lockKey = lockKey
        _isLocked = State(initialValue: UserDefaults.standard.bool(forKey: lockKey))
    }

    var body: some View {
        HStack(spacing: 4) {
            SecureField(placeholder, text: $text)
                .textContentType(.oneTimeCode)
                .textFieldStyle(.roundedBorder)
                .disabled(isLocked)
                .opacity(isLocked ? 0.6 : 1)

            Button {
                isLocked.toggle()
                UserDefaults.standard.set(isLocked, forKey: lockKey)
            } label: {
                Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    .foregroundStyle(isLocked ? .orange : .secondary)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(isLocked ? "Unlock to edit" : "Lock to protect")
        }
    }
}
