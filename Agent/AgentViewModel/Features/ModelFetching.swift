@preconcurrency import Foundation
import AppKit
import SwiftUI
import AgentAudit
import AgentTools

// MARK: - Model Fetching Extension
extension AgentViewModel {

    func fetchClaudeModels() async {
        await MainActor.run { self.fetchingModels.insert(.claude) }
        defer { Task { @MainActor in self.fetchingModels.remove(.claude) } }

        guard !apiKey.isEmpty else {
            await MainActor.run {
                self.availableClaudeModels = Self.defaultClaudeModels
            }
            return
        }

        do {
            let models = try await Self.fetchClaudeModelsFromAPI(apiKey: apiKey)
            await MainActor.run {
                self.availableClaudeModels = models.isEmpty ? Self.defaultClaudeModels : models
            }
        } catch {
            AuditLog.log(.api, "Error fetching Claude models: \(error)")
            await MainActor.run {
                self.availableClaudeModels = Self.defaultClaudeModels
            }
        }
    }

    private static func fetchClaudeModelsFromAPI(apiKey: String) async throws -> [ClaudeModelInfo] {
        guard let url = URL(string: "https://api.anthropic.com/v1/models") else {
            throw AgentError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let clean = ClaudeService.sanitizedCredential(apiKey)
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        if ClaudeService.isOAuthToken(clean) {
            request.setValue("Bearer \(clean)", forHTTPHeaderField: "Authorization")
            request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        } else {
            request.setValue(clean, forHTTPHeaderField: "x-api-key")
        }
        request.timeoutInterval = llmAPITimeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else
        {
            throw AgentError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "API error")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsData = json["data"] as? [[String: Any]] else
        {
            return defaultClaudeModels
        }

        let models = modelsData.compactMap { modelData -> ClaudeModelInfo? in
            guard let id = modelData["id"] as? String else { return nil }
            let displayName = modelData["display_name"] as? String ?? id
            let createdAt = modelData["created_at"] as? String
            let description = modelData["description"] as? String

            return ClaudeModelInfo(
                id: id,
                name: displayName,
                displayName: displayName,
                createdAt: createdAt,
                description: description
            )
        }

        return models.isEmpty ? defaultClaudeModels : models
    }

    func fetchOllamaModels() {
        let endpoint = ollamaEndpoint
        let apiKey = apiKeys[.ollama]
        fetchingModels.insert(.ollama)
        Task {
            defer { fetchingModels.remove(.ollama) }
            do {
                let models = try await Self.fetchModels(endpoint: endpoint, apiKey: apiKey)
                ollamaModels = models.isEmpty ? Self.defaultOllamaModels : models
                // Auto-select first model if current selection is empty or not in list
                let names = ollamaModels.map(\.name)
                if self.models[.ollama].isEmpty || (!names.isEmpty && !names.contains(self.models[.ollama])) {
                    self.models[.ollama] = names.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch models: \(error.localizedDescription)")
                ollamaModels = Self.defaultOllamaModels
            }
            // Best-effort real context length per model — drives the compaction
            // threshold instead of the hardcoded 32K fallback.
            let names = ollamaModels.map(\.name)
            if let windows = try? await Self.fetchOllamaContextWindows(
                endpoint: endpoint, apiKey: apiKey, models: names
            ) {
                modelContextWindows[.ollama].merge(windows) { _, new in new }
            }
        }
    }

    func fetchLocalOllamaModels() {
        let endpoint = localOllamaEndpoint
        fetchingModels.insert(.localOllama)
        Task {
            defer { fetchingModels.remove(.localOllama) }
            do {
                let models = try await Self.fetchModels(endpoint: endpoint, apiKey: "")
                localOllamaModels = models.isEmpty ? Self.defaultOllamaModels : models
                let names = localOllamaModels.map(\.name)
                if self.models[.localOllama].isEmpty || (!names.isEmpty && !names.contains(self.models[.localOllama])) {
                    self.models[.localOllama] = names.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch local models: \(error.localizedDescription)")
                localOllamaModels = Self.defaultOllamaModels
            }
            // Best-effort real context length per model — drives the compaction
            // threshold instead of the hardcoded 32K fallback.
            let names = localOllamaModels.map(\.name)
            if let windows = try? await Self.fetchOllamaContextWindows(
                endpoint: endpoint, apiKey: "", models: names
            ) {
                modelContextWindows[.localOllama].merge(windows) { _, new in new }
            }
        }
    }

    /// Fetch Codex models via ChatGPT OAuth. Falls back silently to an empty
    /// list if not signed in (user should run `codex login` or click Sign In).
    func fetchCodexModels() {
        guard CodexAuthFile.load() != nil else {
            modelLists[.codex] = []
            return
        }
        fetchingModels.insert(.codex)
        Task {
            defer { fetchingModels.remove(.codex) }
            do {
                let models = try await CodexService.fetchModels()
                modelLists[.codex] = models.map { OpenAIModelInfo(id: $0.id, name: $0.display) }
                modelContextWindows[.codex] = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0.contextWindow) })
                let ids = models.map(\.id)
                if self.models[.codex].isEmpty || (!ids.isEmpty && !ids.contains(self.models[.codex])) {
                    self.models[.codex] = ids.first ?? "gpt-5"
                }
            } catch {
                appendLog("Failed to fetch Codex models: \(error.localizedDescription)")
            }
        }
    }

    /// Generic fetcher for providers exposing an OpenAI-compatible /models
    /// endpoint (URL from the provider's registry config). Handles the shared
    /// fetch → filter → defaults-fallback → auto-select flow.
    private func fetchProviderModels(
        _ provider: APIProvider,
        defaults: [OpenAIModelInfo],
        filter: (([OpenAIModelInfo]) -> [OpenAIModelInfo])? = nil
    ) {
        let key = apiKeys[provider]
        let endpoint = provider.config.endpoint.modelsURL
        let fallbackModel = provider.config.model
        fetchingModels.insert(provider)
        Task {
            defer { fetchingModels.remove(provider) }
            guard !key.isEmpty else {
                modelLists[provider] = defaults
                return
            }
            do {
                let catalog = try await Self.fetchOpenAICompatibleModels(apiKey: key, endpoint: endpoint)
                let all = catalog.models
                modelVisionSupport[provider] = catalog.vision
                var fetched = all
                if let filter {
                    let filtered = filter(all)
                    fetched = filtered.isEmpty ? all : filtered
                }
                modelLists[provider] = fetched.isEmpty ? defaults : fetched
                let current = models[provider]
                if current.isEmpty || !modelLists[provider].contains(where: { $0.id == current }) {
                    models[provider] = modelLists[provider].first?.id ?? fallbackModel
                }
            } catch {
                appendLog("Failed to fetch \(provider.displayName) models: \(error.localizedDescription)")
                modelLists[provider] = defaults
            }
        }
    }


    func fetchOpenRouterModels() {
        fetchingModels.insert(.openRouter)
        Task {
            defer { fetchingModels.remove(.openRouter) }
            do {
                let catalog = try await Self.fetchOpenRouterCatalog(apiKey: apiKeys[.openRouter])
                modelLists[.openRouter] = catalog.models
                modelVisionSupport[.openRouter] = catalog.vision
                let ids = catalog.models.map(\.id)
                if self.models[.openRouter].isEmpty || (!ids.isEmpty && !ids.contains(self.models[.openRouter])) {
                    self.models[.openRouter] = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch OpenRouter models: \(error.localizedDescription)")
                modelLists[.openRouter] = []
            }
        }
    }

    /// Fetch OpenRouter's /models catalog and keep only entries Agent! can actually drive:
    /// nonzero context_length AND supports the "tools" parameter. Strips out preview,
    /// embedding, image-only, and legacy chat-only entries that would just confuse the picker.
    /// Display name uses OpenRouter's human-friendly "name" field instead of the raw id.
    /// `architecture.input_modalities` feeds the per-model vision map.
    private nonisolated static func fetchOpenRouterCatalog(apiKey: String) async throws -> (models: [OpenAIModelInfo], vision: [String: Bool]) {
        guard let url = URL(string: "https://openrouter.ai/api/v1/models") else { throw AgentError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = llmAPITimeout

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AgentError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "OpenRouter /models error")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["data"] as? [[String: Any]] else { return ([], [:]) }

        var vision: [String: Bool] = [:]
        let filtered = entries.compactMap { entry -> OpenAIModelInfo? in
            guard let id = entry["id"] as? String, !id.isEmpty else { return nil }
            // Require a real context window — strips preview/placeholder rows.
            let ctx = entry["context_length"] as? Int ?? 0
            guard ctx > 0 else { return nil }
            // Require tool-calling support — Agent!'s loop is tool-driven, so
            // chat-only / embedding / image-only models would just dead-end.
            let params = entry["supported_parameters"] as? [String] ?? []
            guard params.contains("tools") else { return nil }
            if let inputs = (entry["architecture"] as? [String: Any])?["input_modalities"] as? [String] {
                vision[id] = inputs.contains("image")
            }
            let displayName = (entry["name"] as? String).map { $0.isEmpty ? id : $0 } ?? id
            return OpenAIModelInfo(id: id, name: displayName)
        }
        return (filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }, vision)
    }

    func fetchRequestyModels() {
        fetchingModels.insert(.requesty)
        Task {
            defer { fetchingModels.remove(.requesty) }
            do {
                let catalog = try await Self.fetchRequestyCatalog(apiKey: apiKeys[.requesty])
                modelLists[.requesty] = catalog.models
                modelVisionSupport[.requesty] = catalog.vision
                let ids = catalog.models.map(\.id)
                if self.models[.requesty].isEmpty || (!ids.isEmpty && !ids.contains(self.models[.requesty])) {
                    self.models[.requesty] = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch Requesty models: \(error.localizedDescription)")
                modelLists[.requesty] = []
            }
        }
    }

    /// Fetch Requesty's /models catalog and keep only entries Agent! can actually drive:
    /// nonzero context_window AND supports_tool_calling. Requesty ids are already
    /// `provider/model` (e.g. openai/gpt-4o-mini), so the id doubles as the display name.
    /// `supports_vision` feeds the per-model vision map.
    private nonisolated static func fetchRequestyCatalog(apiKey: String) async throws -> (models: [OpenAIModelInfo], vision: [String: Bool]) {
        guard let url = URL(string: "https://router.requesty.ai/v1/models") else { throw AgentError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = llmAPITimeout

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AgentError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "Requesty /models error")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["data"] as? [[String: Any]] else { return ([], [:]) }

        var vision: [String: Bool] = [:]
        let filtered = entries.compactMap { entry -> OpenAIModelInfo? in
            guard let id = entry["id"] as? String, !id.isEmpty else { return nil }
            let ctx = entry["context_window"] as? Int ?? 0
            guard ctx > 0 else { return nil }
            // Agent!'s loop is tool-driven, so skip models that cannot call tools.
            guard entry["supports_tool_calling"] as? Bool == true else { return nil }
            if let v = entry["supports_vision"] as? Bool { vision[id] = v }
            return OpenAIModelInfo(id: id, name: id)
        }
        return (filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }, vision)
    }

    func fetchA2AgentModels() {
        fetchingModels.insert(.a2Agent)
        Task {
            defer { fetchingModels.remove(.a2Agent) }
            do {
                let models = try await Self.fetchA2AgentCatalog(apiKey: apiKeys[.a2Agent])
                modelLists[.a2Agent] = models
                let ids = models.map(\.id)
                if self.models[.a2Agent].isEmpty || (!ids.isEmpty && !ids.contains(self.models[.a2Agent])) {
                    self.models[.a2Agent] = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch A2Agent models: \(error.localizedDescription)")
                modelLists[.a2Agent] = []
            }
        }
    }

    /// Fetch A2Agent's /models catalog. The list is plain OpenAI shape (`data[].id`) plus an
    /// optional `display_name`; there is no context/tool metadata to filter on, and the
    /// gateway only returns models the account can call. Non-200 responses are surfaced
    /// in the log (bad key, rate limit) instead of silently yielding an empty picker.
    private nonisolated static func fetchA2AgentCatalog(apiKey: String) async throws -> [OpenAIModelInfo] {
        guard let url = URL(string: "https://api.a2agent.me/v1/models") else { throw AgentError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = llmAPITimeout

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8)?.prefix(200) ?? ""
            throw AgentError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "A2Agent /models error \(body)")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["data"] as? [[String: Any]] else { return [] }

        let parsed = entries.compactMap { entry -> OpenAIModelInfo? in
            guard let id = entry["id"] as? String, !id.isEmpty else { return nil }
            let displayName = (entry["display_name"] as? String).map { $0.isEmpty ? id : $0 } ?? id
            return OpenAIModelInfo(id: id, name: displayName)
        }
        return parsed.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func fetchOrcaRouterModels() {
        fetchingModels.insert(.orcaRouter)
        Task {
            defer { fetchingModels.remove(.orcaRouter) }
            do {
                let catalog = try await Self.fetchOrcaRouterCatalog(apiKey: apiKeys[.orcaRouter])
                modelLists[.orcaRouter] = catalog.models
                modelVisionSupport[.orcaRouter] = catalog.vision
                let ids = catalog.models.map(\.id)
                if self.models[.orcaRouter].isEmpty || (!ids.isEmpty && !ids.contains(self.models[.orcaRouter])) {
                    self.models[.orcaRouter] = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch OrcaRouter models: \(error.localizedDescription)")
                modelLists[.orcaRouter] = []
            }
        }
    }

    /// Fetch OrcaRouter's /models catalog. Plain OpenAI shape (`data[].id`) with an
    /// optional human-friendly `name`, plus `architecture.output_modalities` — used
    /// to drop video-only entries (kling/minimax-h3/orca dub) the chat picker can't
    /// drive. `architecture.input_modalities` feeds the per-model vision map (only
    /// entries that carry the field are recorded, so the name heuristic still applies
    /// to the rest). Non-200 responses are surfaced in the log (bad key, out of
    /// credits) instead of silently yielding an empty picker.
    private nonisolated static func fetchOrcaRouterCatalog(apiKey: String) async throws -> (models: [OpenAIModelInfo], vision: [String: Bool]) {
        guard let url = URL(string: "https://api.orcarouter.ai/v1/models") else { throw AgentError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = llmAPITimeout

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8)?.prefix(200) ?? ""
            throw AgentError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "OrcaRouter /models error \(body)")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json["data"] as? [[String: Any]] else { return ([], [:]) }

        var vision: [String: Bool] = [:]
        let parsed = entries.compactMap { entry -> OpenAIModelInfo? in
            guard let id = entry["id"] as? String, !id.isEmpty else { return nil }
            let arch = entry["architecture"] as? [String: Any]
            // Video-only models can't serve the chat/tool loop.
            let modalities = arch?["output_modalities"] as? [String] ?? []
            if !modalities.isEmpty && !modalities.contains("text") { return nil }
            if let inputs = arch?["input_modalities"] as? [String] {
                vision[id] = inputs.contains("image")
            }
            let displayName = (entry["name"] as? String).map { $0.isEmpty ? id : $0 } ?? id
            return OpenAIModelInfo(id: id, name: displayName)
        }
        // Free-tier variants (e.g. z-ai/glm-5.3-flash-free) ship without `architecture`;
        // they are the same model as the base id, so inherit its vision flag.
        for model in parsed where vision[model.id] == nil && model.id.hasSuffix("-free") {
            if let base = vision[String(model.id.dropLast(5))] { vision[model.id] = base }
        }
        return (parsed.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }, vision)
    }

    func fetchHuggingFaceModels() {
        guard !apiKeys[.huggingFace].isEmpty else {
            modelLists[.huggingFace] = Self.defaultHuggingFaceModels
            return
        }
        fetchingModels.insert(.huggingFace)
        Task {
            defer { fetchingModels.remove(.huggingFace) }
            do {
                let models = try await Self.fetchHuggingFaceModelsFromAPI(apiKey: apiKeys[.huggingFace])
                modelLists[.huggingFace] = models.isEmpty ? Self.defaultHuggingFaceModels : models
                let ids = modelLists[.huggingFace].map(\.id)
                if self.models[.huggingFace].isEmpty || (!ids.isEmpty && !ids.contains(self.models[.huggingFace])) {
                    self.models[.huggingFace] = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch HuggingFace models: \(error.localizedDescription)")
                modelLists[.huggingFace] = Self.defaultHuggingFaceModels
            }
        }
    }

    // MARK: - Static API Fetch Helpers

    private nonisolated static func fetchHuggingFaceModelsFromAPI(apiKey: String) async throws -> [OpenAIModelInfo] {
        // Use the router endpoint which returns inference-ready models (OpenAI-compatible)
        guard let url = URL(string: "https://router.huggingface.co/v1/models") else {
            throw AgentError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = llmAPITimeout

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AgentError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "HuggingFace API error")
        }

        // Router returns OpenAI-compatible format: {"data": [{"id": "model-id", ...}]}
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataArray = json["data"] as? [[String: Any]]
        {
            let models = dataArray.compactMap { model -> OpenAIModelInfo? in
                guard let id = model["id"] as? String else { return nil }
                // Use last path component as display name
                let name = id.components(separatedBy: "/").last ?? id
                return OpenAIModelInfo(id: id, name: name)
            }.sorted { $0.name < $1.name }
            return models
        }

        // Fallback: old format (array of objects)
        if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            let models = json.compactMap { model -> OpenAIModelInfo? in
                guard let id = model["id"] as? String else { return nil }
                return OpenAIModelInfo(id: id, name: id)
            }.sorted { $0.name < $1.name }
            return models
        }

        return defaultHuggingFaceModels
    }

    private nonisolated static func fetchModels(endpoint: String, apiKey: String) async throws -> [OllamaModelInfo] {
        let effectiveEndpoint = endpoint.isEmpty ? "http://localhost:11434/api/chat" : endpoint
        guard let chatURL = URL(string: effectiveEndpoint) else { throw AgentError.invalidResponse }
        let baseDir = chatURL.deletingLastPathComponent().absoluteString

        guard let tagsURL = URL(string: baseDir + "tags") else { throw AgentError.invalidResponse }
        guard let showURL = URL(string: baseDir + "show") else { throw AgentError.invalidResponse }

        // 1. Fetch model list
        var tagsRequest = URLRequest(url: tagsURL)
        tagsRequest.httpMethod = "GET"
        tagsRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        if !apiKey.isEmpty {
            tagsRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        tagsRequest.timeoutInterval = llmAPITimeout

        let (data, response) = try await URLSession.shared.data(for: tagsRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else
        {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AgentError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else
        {
            throw AgentError.invalidResponse
        }

        let names = models.compactMap { $0["name"] as? String }.sorted()

        // 2. Check capabilities for each model via /api/show (in parallel)
        return await withTaskGroup(of: OllamaModelInfo?.self) { group in
            for name in names {
                group.addTask {
                    let hasVision = await Self.checkVision(model: name, showURL: showURL, apiKey: apiKey)
                    return OllamaModelInfo(id: name, name: name, supportsVision: hasVision)
                }
            }
            var results: [OllamaModelInfo] = []
            for await info in group {
                if let info { results.append(info) }
            }
            return results.sorted { $0.name < $1.name }
        }
    }

    /// Check if a model has "vision" in its capabilities via /api/show
    private nonisolated static func checkVision(model: String, showURL: URL, apiKey: String) async -> Bool {
        do {
            let body = try JSONSerialization.data(withJSONObject: ["model": model])
            var request = URLRequest(url: showURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            if !apiKey.isEmpty {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            request.httpBody = body
            request.timeoutInterval = llmAPITimeout

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let capabilities = json["capabilities"] as? [String] else
            {
                return false
            }
            return capabilities.contains("vision")
        } catch {
            return false
        }
    }

    /// Query Ollama's `/api/show` for each model's context length. Prefers the
    /// Modelfile's `num_ctx` (what the model actually loads with) over the
    /// architecture's `<arch>.context_length` in model_info (what it supports).
    /// Best-effort: failures for individual models are skipped.
    private nonisolated static func fetchOllamaContextWindows(
        endpoint: String, apiKey: String, models: [String]
    ) async throws -> [String: Int] {
        let effectiveEndpoint = endpoint.isEmpty ? "http://localhost:11434/api/chat" : endpoint
        guard let chatURL = URL(string: effectiveEndpoint) else { return [:] }
        let baseDir = chatURL.deletingLastPathComponent().absoluteString
        guard let showURL = URL(string: baseDir + "show") else { return [:] }

        return await withTaskGroup(of: (String, Int)?.self) { group in
            for model in models {
                group.addTask {
                    guard let body = try? JSONSerialization.data(withJSONObject: ["model": model]) else { return nil }
                    var request = URLRequest(url: showURL)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "content-type")
                    if !apiKey.isEmpty {
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    }
                    request.httpBody = body
                    request.timeoutInterval = llmAPITimeout
                    guard let (data, response) = try? await URLSession.shared.data(for: request),
                          let http = response as? HTTPURLResponse, http.statusCode == 200,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else
                    {
                        return nil
                    }
                    var ctx = 0
                    // Modelfile parameters — one "num_ctx <value>" line when set.
                    if let params = json["parameters"] as? String {
                        for line in params.split(separator: "\n") {
                            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                            if parts.count >= 2, parts[0] == "num_ctx", let n = Int(parts[1]) { ctx = n }
                        }
                    }
                    // Architecture max, e.g. "qwen3.context_length": 131072.
                    if ctx == 0, let info = json["model_info"] as? [String: Any] {
                        for (key, value) in info where key.hasSuffix(".context_length") {
                            if let n = value as? Int, n > 0 { ctx = n }
                        }
                    }
                    return ctx > 0 ? (model, ctx) : nil
                }
            }
            var windows: [String: Int] = [:]
            for await pair in group {
                if let (model, ctx) = pair { windows[model] = ctx }
            }
            return windows
        }
    }

    // MARK: - Z.ai Models

    func fetchZAIModels() {
        fetchingModels.insert(.zAI)
        let key = apiKeys[.zAI]
        Task {
            defer { fetchingModels.remove(.zAI) }
            guard !key.isEmpty else { return }
            let models = await Self.fetchZAIModelsFromAPI(apiKey: key)
            if !models.isEmpty {
                modelLists[.zAI] = models
                if self.models[.zAI].isEmpty || !modelLists[.zAI].contains(where: { $0.id == self.models[.zAI] }) {
                    self.models[.zAI] = modelLists[.zAI].first?.id ?? ""
                }
            }
        }
    }

    private nonisolated static func fetchZAIModelsFromAPI(apiKey: String) async -> [OpenAIModelInfo] {
        // Fetch ALL models dynamically from Z.ai's OpenAPI spec
        // The /models endpoint only returns ~7, but the spec has all model enums
        let coding = (try? await fetchZAIEndpoint(apiKey: apiKey, urlString: "https://api.z.ai/api/coding/paas/v4/models")) ?? []
        let specModels = await fetchZAIModelsFromSpec()

        var seen = Set<String>()
        var result: [OpenAIModelInfo] = []

        // Coding models first (no suffix — use coding endpoint, name tagged -Code)
        for m in coding {
            if seen.insert(m.id).inserted {
                result.append(OpenAIModelInfo(id: m.id, name: "\(m.name)-Code"))
            }
        }
        // All spec models — text as coding, vision/image/audio as :v
        for m in specModels {
            if seen.insert(m.id).inserted { result.append(m) }
        }
        return result
    }

    /// Fetch all Z.ai model IDs from the OpenAPI spec at docs.z.ai/openapi.json
    /// Parses enum arrays from schema definitions — fully dynamic, no hardcoding.
    private nonisolated static func fetchZAIModelsFromSpec() async -> [OpenAIModelInfo] {
        guard let url = URL(string: "https://docs.z.ai/openapi.json") else { return [] }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let components = json["components"] as? [String: Any],
              let schemas = components["schemas"] as? [String: Any] else { return [] }

        var seen = Set<String>()
        var result: [OpenAIModelInfo] = []

        // Text models (coding endpoint)
        let textSchemas = ["ChatCompletionTextRequest"]
        // Vision/non-coding models (general endpoint, tagged :v)
        let visionSchemas = [
            "ChatCompletionVisionRequest",
            "CreateImageRequest",
            "AsyncCreateImageRequest",
            "LayoutParsingRequest",
            "AudioTranscriptionRequest"
        ]

        for name in textSchemas {
            if let schema = schemas[name] as? [String: Any],
               let props = schema["properties"] as? [String: Any],
               let model = props["model"] as? [String: Any],
               let enums = model["enum"] as? [String]
            {
                for id in enums {
                    if seen.insert(id).inserted {
                        result.append(OpenAIModelInfo(id: id, name: id))
                    }
                }
            }
        }
        for name in visionSchemas {
            if let schema = schemas[name] as? [String: Any],
               let props = schema["properties"] as? [String: Any],
               let model = props["model"] as? [String: Any],
               let enums = model["enum"] as? [String]
            {
                for id in enums {
                    let vid = "\(id):v"
                    if seen.insert(vid).inserted {
                        result.append(OpenAIModelInfo(id: vid, name: id))
                    }
                }
            }
        }
        return result
    }

    private nonisolated static func fetchZAIEndpoint(apiKey: String, urlString: String) async throws -> [OpenAIModelInfo] {
        guard let url = URL(string: urlString) else { return [] }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = llmAPITimeout
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [] }
        let modelsData: [[String: Any]]
        if let d = json["data"] as? [[String: Any]] { modelsData = d }
        else if let m = json["models"] as? [[String: Any]] { modelsData = m }
        else { return [] }
        return modelsData.compactMap { model -> OpenAIModelInfo? in
            guard let id = model["id"] as? String else { return nil }
            return OpenAIModelInfo(id: id, name: id)
        }.sorted { $0.name < $1.name }
    }

    // MARK: - Qwen (DashScope) Models

    func fetchQwenModels() {
        fetchingModels.insert(.qwen)
        let key = apiKeys[.qwen]
        Task {
            defer { fetchingModels.remove(.qwen) }
            guard !key.isEmpty else {
                modelLists[.qwen] = Self.defaultQwenModels
                return
            }
            // Try international endpoint first, then China mainland
            let endpoints = [
                "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/models",
                "https://dashscope.aliyuncs.com/compatible-mode/v1/models",
            ]
            for endpoint in endpoints {
                do {
                    let catalog = try await Self.fetchOpenAICompatibleModels(apiKey: key, endpoint: endpoint)
                    let models = catalog.models
                    if !models.isEmpty {
                        modelVisionSupport[.qwen] = catalog.vision
                        // Filter to chat/reasoning models (skip embedding, tts, asr, etc.)
                        let chatModels = models.filter { id in
                            let lower = id.id.lowercased()
                            let skip = [
                                "embed",
                                "tts",
                                "asr",
                                "rerank",
                                "paraformer",
                                "sambert",
                                "cosyvoice",
                                "sensevoice",
                                "farui",
                                "wanx",
                                "flux"
                            ]
                            return !skip.contains(where: { lower.contains($0) })
                        }
                        modelLists[.qwen] = chatModels.isEmpty ? models : chatModels
                        if self.models[.qwen].isEmpty || !modelLists[.qwen].contains(where: { $0.id == self.models[.qwen] }) {
                            self.models[.qwen] = modelLists[.qwen].first?.id ?? "qwen-plus"
                        }
                        return
                    }
                } catch {
                    AuditLog.log(.api, "Failed to fetch Qwen models from \(endpoint): \(error.localizedDescription)")
                }
            }
            modelLists[.qwen] = Self.defaultQwenModels
        }
    }

    /// Image-input support from a /models catalog entry, across the shapes providers
    /// actually publish. nil when the entry carries no capability metadata so callers
    /// fall through to the name heuristic instead of recording a false negative.
    ///   - `architecture.input_modalities` / `input_modalities` — OpenRouter, OrcaRouter, xAI
    ///   - `capabilities.vision` (Bool) — Mistral, Mistral Vibe
    ///   - `capabilities` (["completion","vision",…]) — Ollama /api/show
    ///   - `supports_vision` (Bool) — Requesty
    ///   - `type == "vlm"` — LM Studio /api/v0/models
    nonisolated static func catalogVisionFlag(_ entry: [String: Any]) -> Bool? {
        if let inputs = (entry["architecture"] as? [String: Any])?["input_modalities"] as? [String]
            ?? entry["input_modalities"] as? [String] {
            return inputs.contains("image")
        }
        if let caps = entry["capabilities"] as? [String: Any], let v = caps["vision"] as? Bool { return v }
        if let caps = entry["capabilities"] as? [String] { return caps.contains("vision") }
        if let v = entry["supports_vision"] as? Bool { return v }
        if let type = entry["type"] as? String { return type == "vlm" }
        return nil
    }

    /// Shared OpenAI-compatible model list fetcher. Also records any per-model vision
    /// metadata the catalog happens to carry (`catalogVisionFlag`).
    private nonisolated static func fetchOpenAICompatibleModels(apiKey: String, endpoint: String) async throws -> (models: [OpenAIModelInfo], vision: [String: Bool]) {
        guard let url = URL(string: endpoint) else { throw AgentError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = llmAPITimeout
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return ([], [:]) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsData = json["data"] as? [[String: Any]] else { return ([], [:]) }
        var vision: [String: Bool] = [:]
        let models = modelsData.compactMap { model -> OpenAIModelInfo? in
            guard let id = model["id"] as? String else { return nil }
            if let v = catalogVisionFlag(model) { vision[id] = v }
            return OpenAIModelInfo(id: id, name: id)
        }.sorted { $0.name < $1.name }
        return (models, vision)
    }

    // MARK: - vLLM Models

    func fetchVLLMModels() {
        fetchingModels.insert(.vLLM)
        let endpoint = vLLMEndpoint
        let key = apiKeys[.vLLM]
        Task {
            defer { fetchingModels.remove(.vLLM) }
            do {
                let (models, windows) = try await Self.fetchVLLMModelsFromAPI(endpoint: endpoint, apiKey: key)
                modelLists[.vLLM] = models
                modelContextWindows[.vLLM] = windows
                let ids = models.map(\.id)
                if self.models[.vLLM].isEmpty || (!ids.isEmpty && !ids.contains(self.models[.vLLM])) {
                    self.models[.vLLM] = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch vLLM models: \(error.localizedDescription)")
            }
        }
    }

    /// Fetch vLLM's `/v1/models` list. vLLM includes each model's real context
    /// window as `max_model_len` — captured so the compaction threshold scales
    /// to the served model instead of the hardcoded 32K fallback.
    private nonisolated static func fetchVLLMModelsFromAPI(endpoint: String, apiKey: String) async throws -> ([OpenAIModelInfo], [String: Int]) {
        let modelsURL: URL
        if let range = endpoint.range(of: "/v1/") {
            let base = String(endpoint[endpoint.startIndex..<range.upperBound])
            guard let url = URL(string: base + "models") else { throw AgentError.invalidURL }
            modelsURL = url
        } else {
            guard let url = URL(string: endpoint) else { throw AgentError.invalidURL }
            modelsURL = url.deletingLastPathComponent().appendingPathComponent("models")
        }
        var request = URLRequest(url: modelsURL)
        request.httpMethod = "GET"
        if !apiKey.isEmpty { request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
        request.timeoutInterval = llmAPITimeout
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsData = json["data"] as? [[String: Any]] else { return ([], [:]) }
        var windows: [String: Int] = [:]
        let models = modelsData.compactMap { model -> OpenAIModelInfo? in
            guard let id = model["id"] as? String else { return nil }
            if let maxLen = model["max_model_len"] as? Int, maxLen > 0 {
                windows[id] = maxLen
            }
            return OpenAIModelInfo(id: id, name: id)
        }.sorted { $0.name < $1.name }
        return (models, windows)
    }

    // MARK: - LM Studio Models

    func fetchLMStudioModels() {
        fetchingModels.insert(.lmStudio)
        let proto = lmStudioProtocol
        let modelsEndpoint: String
        switch proto {
        case .lmStudio: modelsEndpoint = "http://localhost:1234/api/v1/models"
        default: modelsEndpoint = "http://localhost:1234/v1/models"
        }
        Task {
            defer { fetchingModels.remove(.lmStudio) }
            do {
                let models = try await Self.fetchLMStudioModelsFromAPI(modelsURL: modelsEndpoint)
                modelLists[.lmStudio] = models
                let ids = models.map(\.id)
                if self.models[.lmStudio].isEmpty || (!ids.isEmpty && !ids.contains(self.models[.lmStudio])) {
                    self.models[.lmStudio] = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch LM Studio models: \(error.localizedDescription)")
            }
            // Real context length per model from LM Studio's REST API — drives the
            // compaction threshold. Best-effort: older LM Studio versions without
            // /api/v0/models just keep the 32K fallback.
            if let windows = try? await Self.fetchLMStudioContextWindows() {
                modelContextWindows[.lmStudio] = windows
            }
        }
    }

    /// Query LM Studio's REST API (`/api/v0/models`) for per-model context lengths.
    /// Prefers `loaded_context_length` (what the model was actually loaded with)
    /// over `max_context_length` (what it supports).
    private nonisolated static func fetchLMStudioContextWindows() async throws -> [String: Int] {
        guard let url = URL(string: "http://localhost:1234/api/v0/models") else { throw AgentError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = llmAPITimeout
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsData = json["data"] as? [[String: Any]] else { return [:] }
        var windows: [String: Int] = [:]
        for model in modelsData {
            guard let id = model["id"] as? String else { continue }
            let loaded = model["loaded_context_length"] as? Int ?? 0
            let maxCtx = model["max_context_length"] as? Int ?? 0
            let ctx = loaded > 0 ? loaded : maxCtx
            if ctx > 0 { windows[id] = ctx }
        }
        return windows
    }

    private nonisolated static func fetchLMStudioModelsFromAPI(modelsURL: String) async throws -> [OpenAIModelInfo] {
        guard let url = URL(string: modelsURL) else { throw AgentError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = llmAPITimeout
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsData = json["data"] as? [[String: Any]] else { return [] }
        return modelsData.compactMap { model -> OpenAIModelInfo? in
            guard let id = model["id"] as? String else { return nil }
            return OpenAIModelInfo(id: id, name: id)
        }.sorted { $0.name < $1.name }
    }

    /// Trigger model fetch for a provider if its list is empty. `force: true` skips the empty check.
    func fetchModelsIfNeeded(for provider: APIProvider, force: Bool = false) {
        let isEmpty: Bool
        switch provider {
        case .claude: isEmpty = availableClaudeModels.isEmpty
        case .ollama: isEmpty = ollamaModels.isEmpty
        case .localOllama: isEmpty = localOllamaModels.isEmpty
        default: isEmpty = modelLists[provider].isEmpty
        }
        guard force || isEmpty else { return }
        fetchModels(for: provider)
    }

    /// Fetch the model catalog for a provider (unconditionally). Providers with a plain
    /// OpenAI-compatible /models endpoint go through `fetchProviderModels`; the rest have
    /// bespoke catalog shapes and keep their own fetchers.
    func fetchModels(for provider: APIProvider) {
        switch provider {
        case .claude: Task { await fetchClaudeModels() }
        case .codex: fetchCodexModels()
        case .ollama: fetchOllamaModels()
        case .localOllama: fetchLocalOllamaModels()
        case .huggingFace: fetchHuggingFaceModels()
        case .vLLM: fetchVLLMModels()
        case .lmStudio: fetchLMStudioModels()
        case .zAI: fetchZAIModels()
        case .qwen: fetchQwenModels()
        case .openRouter: fetchOpenRouterModels()
        case .requesty: fetchRequestyModels()
        case .a2Agent: fetchA2AgentModels()
        case .orcaRouter: fetchOrcaRouterModels()
        case .vibe:
            // Vibe key only works with *-latest models, not dated versions like devstral-small-2507
            fetchProviderModels(.vibe, defaults: [],
                filter: { $0.filter { $0.id.lowercased().contains("devstral") && $0.id.contains("latest") } })
        case .openAI, .deepSeek, .gemini, .grok, .mistral, .miniMax:
            fetchProviderModels(provider, defaults: [])
        case .bigModel, .foundationModel: break
        }
    }
}
