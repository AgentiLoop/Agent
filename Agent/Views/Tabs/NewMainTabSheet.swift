import SwiftUI
import AgentTools

/// Sheet for creating a new main tab with a specific LLM provider and model.
struct NewMainTabSheet: View {
    @Bindable var viewModel: AgentViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var provider: APIProvider
    @State private var selectedModelId: String = ""

    init(viewModel: AgentViewModel) {
        self.viewModel = viewModel
        // Ensure we never start with foundationModel - it's not a selectable provider
        let initialProvider = APIProvider.selectableProviders.contains(viewModel.selectedProvider)
            ? viewModel.selectedProvider
            : .ollama
        self._provider = State(initialValue: initialProvider)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New LLM Tab")
                .font(.headline)

            // Provider picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Provider").font(.caption).foregroundStyle(.secondary)
                Picker("Provider", selection: $provider) {
                    ForEach(APIProvider.selectableProviders, id: \.self) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .labelsHidden()
                .onChange(of: provider) { _, newProvider in
                    ensureModelsLoaded(for: newProvider)
                    selectedModelId = defaultModelId(for: newProvider)
                }
            }

            // Model picker (adapts per provider)
            VStack(alignment: .leading, spacing: 4) {
                Text("Model").font(.caption).foregroundStyle(.secondary)
                modelPicker
            }

            // Validation message
            if !canCreate {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Create Tab") {
                    // Tab label uses the raw model ID so it matches whatever case the LLM provider
                    // publishes (e.g., "glm-5.1", "mistral-large-latest") — no formatting applied.
                    let config = LLMConfig(provider: provider, model: selectedModelId, displayName: selectedModelId)
                    viewModel.createMainTab(config: config)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!canCreate)
            }
        }
        .padding(20)
        .frame(minWidth: 360)
        .onAppear {
            ensureModelsLoaded(for: provider)
            selectedModelId = defaultModelId(for: provider)
        }
    }

    // MARK: - Model Picker

    @ViewBuilder
    private var modelPicker: some View {
        switch provider {
        case .claude:
            Picker("Model", selection: $selectedModelId) {
                ForEach(viewModel.availableClaudeModels) { model in
                    Text(model.formattedDisplayName).tag(model.id)
                }
            }
            .labelsHidden()

        case .ollama:
            ollamaModelPicker(models: viewModel.ollamaModels, fetch: { viewModel.fetchModelsIfNeeded(for: .ollama, force: true) })

        case .localOllama:
            ollamaModelPicker(models: viewModel.localOllamaModels, fetch: { viewModel.fetchModelsIfNeeded(for: .localOllama, force: true) })

        case .bigModel:
            // No /models endpoint — free-form id.
            TextField("Model (e.g. glm-4.7)", text: $selectedModelId)
                .textFieldStyle(.roundedBorder)

        case .foundationModel:
            HStack {
                Text("Apple Intelligence")
                    .foregroundStyle(.secondary)
                Spacer()
            }

        default:
            modelPickerWithFetch(
                models: viewModel.modelLists[provider],
                fallbackBinding: $selectedModelId,
                isFetching: viewModel.fetchingModels.contains(provider),
                fetch: { [provider] in viewModel.fetchModelsIfNeeded(for: provider, force: true) }
            )
        }
    }

    @ViewBuilder
    private func modelPickerWithFetch(
        models: [AgentViewModel.OpenAIModelInfo],
        fallbackBinding: Binding<String>,
        isFetching: Bool,
        fetch: @escaping () -> Void
    ) -> some View {
        HStack {
            if models.isEmpty {
                TextField("Model name", text: fallbackBinding)
                    .textFieldStyle(.roundedBorder)
            } else {
                Picker("Model", selection: $selectedModelId) {
                    ForEach(models) { model in
                        HStack(spacing: 4) {
                            Text(model.name)
                            if viewModel.showsVisionBadge(provider: provider, modelId: model.id) {
                                Image(systemName: "eye")
                                    .foregroundStyle(.blue)
                                    .font(.caption2)
                            }
                        }.tag(model.id)
                    }
                }
                .labelsHidden()
            }
            Button(action: fetch) {
                if isFetching {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isFetching)
            .help("Refresh Models")
        }
    }

    @ViewBuilder
    private func ollamaModelPicker(models: [AgentViewModel.OllamaModelInfo], fetch: @escaping () -> Void) -> some View {
        HStack {
            if models.isEmpty {
                TextField("Model name", text: $selectedModelId)
                    .textFieldStyle(.roundedBorder)
            } else {
                Picker("Model", selection: $selectedModelId) {
                    ForEach(models) { model in
                        HStack(spacing: 4) {
                            Text(model.name)
                            if model.supportsVision {
                                Image(systemName: "eye")
                                    .foregroundStyle(.blue)
                                    .font(.caption2)
                            }
                        }.tag(model.id)
                    }
                }
                .labelsHidden()
            }
            Button(action: fetch) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Refresh Ollama Models")
        }
    }

    // MARK: - Helpers

    private var canCreate: Bool {
        // Apple Intelligence always has a valid model
        if provider == .foundationModel { return true }
        return !selectedModelId.isEmpty
    }

    private var validationMessage: String {
        if selectedModelId.isEmpty {
            return "Select a model to continue"
        }
        return ""
    }

    /// The model the user last picked for this provider, falling back to the registry default.
    private func defaultModelId(for provider: APIProvider) -> String {
        let current = viewModel.models[provider]
        return current.isEmpty ? provider.config.model : current
    }

    private func ensureModelsLoaded(for provider: APIProvider) {
        viewModel.fetchModelsIfNeeded(for: provider)
    }
}
