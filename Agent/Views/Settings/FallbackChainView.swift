import SwiftUI
import AgentTools

/// Editor for the model fallback chain — users pick ordered provider/model pairs.
struct FallbackChainView: View {
    @Bindable var viewModel: AgentViewModel
    @State private var selectedProvider: APIProvider
    @State private var selectedModel: String = ""
    @Environment(\.colorSchemeContrast) private var contrast
    /// Increase Contrast: promote faint captions to primary text and drop faded fills.
    private var highContrast: Bool { contrast == .increased }
    private var captionStyle: HierarchicalShapeStyle { highContrast ? .primary : .secondary }
    private var detailStyle: HierarchicalShapeStyle { highContrast ? .primary : .tertiary }
    private var removeColor: Color { highContrast ? .red : .red.opacity(0.7) }

    init(viewModel: AgentViewModel) {
        self.viewModel = viewModel
        // Default the picker to the user's currently-active provider — never hard-code.
        _selectedProvider = State(initialValue: viewModel.selectedProvider)
    }

    private var service: FallbackChainService { FallbackChainService.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Fallback Chain")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { service.enabled },
                        set: { service.enabled = $0 }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Enable Fallback Chain")
                }
                Text("When the primary LLM fails 3 times, auto-switch to the next provider. Drag to reorder.")
                    .font(.caption)
                    .foregroundStyle(captionStyle)
            }
            .padding()

            Divider()

            // Chain entries
            if service.chain.isEmpty {
                VStack(spacing: 8) {
                    Text("No fallback providers configured.")
                        .font(.caption)
                        .foregroundStyle(detailStyle)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            } else {
                ForEach(Array(service.chain.enumerated()), id: \.element.id) { index, entry in
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(captionStyle)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(APIProvider(rawValue: entry.provider)?.displayName ?? entry.provider)
                                    .font(.subheadline.weight(.medium))
                                HStack(spacing: 4) {
                                    Text(shortModel(entry.model))
                                        .font(.caption)
                                        .foregroundStyle(captionStyle)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    if let p = APIProvider(rawValue: entry.provider),
                                       viewModel.showsVisionBadge(provider: p, modelId: entry.model) {
                                        Image(systemName: "eye")
                                            .foregroundStyle(.blue)
                                            .font(.caption2)
                                            .accessibilityLabel("Vision")
                                    }
                                }
                            }

                            Spacer()

                            // Active indicator
                            if service.currentIndex == index {
                                Text("active")
                                    .font(.caption2)
                                    .foregroundStyle(contrast == .increased ? AnyShapeStyle(.primary) : AnyShapeStyle(.green))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(highContrast ? 0.3 : 0.15))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(Color.green, lineWidth: highContrast ? 1 : 0))
                            }

                            Toggle("", isOn: Binding(
                                get: { entry.enabled },
                                set: { _ in service.toggle(id: entry.id) }
                            ))
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                            .accessibilityLabel("Enable \(APIProvider(rawValue: entry.provider)?.displayName ?? entry.provider) \(shortModel(entry.model))")

                            Button {
                                service.remove(id: entry.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(removeColor)
                            }
                            .buttonStyle(.plain)
                            .help("Remove from Fallback Chain")
                            .accessibilityLabel("Remove \(APIProvider(rawValue: entry.provider)?.displayName ?? entry.provider) \(shortModel(entry.model))")
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal)
                    }
                }
            }

            // Add new entry
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 8) {
                    Picker("", selection: $selectedProvider) {
                        ForEach(APIProvider.selectableProviders, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .labelsHidden()
                    .accessibilityLabel("Provider")
                    .frame(width: 110)
                    .onAppear { viewModel.fetchModelsIfNeeded(for: selectedProvider) }
                    .onChange(of: selectedProvider) { _, newP in
                        viewModel.fetchModelsIfNeeded(for: newP)
                        selectedModel = modelsForProvider(newP).first ?? defaultModel(for: newP)
                    }

                    Picker("", selection: $selectedModel) {
                        let models = modelOptionsForProvider(selectedProvider)
                        if models.isEmpty {
                            let def = defaultModel(for: selectedProvider)
                            Text(shortModel(def)).tag(def)
                        } else {
                            ForEach(models, id: \.id) { model in
                                HStack(spacing: 4) {
                                    Text(shortModel(model.display))
                                    if viewModel.showsVisionBadge(provider: selectedProvider, modelId: model.id) {
                                        Image(systemName: "eye")
                                            .foregroundStyle(.blue)
                                            .font(.caption2)
                                            .accessibilityLabel("Vision")
                                    }
                                }.tag(model.id)
                            }
                        }
                    }
                    .labelsHidden()
                    .accessibilityLabel("Model")
                    .frame(width: 160)
                    .onAppear {
                        if selectedModel
                            .isEmpty { selectedModel = modelsForProvider(selectedProvider).first ?? defaultModel(for: selectedProvider) } }

                    Button {
                        guard !selectedModel.isEmpty else { return }
                        service.add(provider: selectedProvider.rawValue, model: selectedModel)
                        selectedModel = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    .help("Add to Fallback Chain")
                    .accessibilityLabel("Add to Fallback Chain")
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }

            // Footer
            if !service.chain.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Text("\(service.chain.filter(\.enabled).count) of \(service.chain.count) enabled")
                            .font(.caption)
                            .foregroundStyle(captionStyle)
                        Spacer()
                        Button("Clear All") {
                            service.clear()
                            announceForAccessibility("Fallback providers cleared")
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundStyle(removeColor)
                        .accessibilityLabel("Clear All Fallback Providers")
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 15)
        .frame(width: 380)
    }

    /// (id, display) pairs for the model picker, from the view model's per-provider catalog.
    private func modelOptionsForProvider(_ provider: APIProvider) -> [(id: String, display: String)] {
        viewModel.modelOptions(for: provider).map { ($0.id, $0.name) }
    }

    private func modelsForProvider(_ provider: APIProvider) -> [String] {
        modelOptionsForProvider(provider).map(\.id)
    }

    private func shortModel(_ model: String) -> String {
        let clean = model.replacingOccurrences(of: ":v", with: "")
        let parts = clean.components(separatedBy: "-")
        if parts.count > 3, let last = parts.last, last.count == 8, Int(last) != nil {
            return parts.dropLast().joined(separator: "-")
        }
        return clean
    }

    /// Default model for a provider — the model the user is actively using for that provider,
    /// falling back to the first dynamically-fetched model. Never hardcoded.
    private func defaultModel(for provider: APIProvider) -> String {
        let current = viewModel.models[provider]
        if !current.isEmpty { return current }
        return modelsForProvider(provider).first ?? ""
    }

}
