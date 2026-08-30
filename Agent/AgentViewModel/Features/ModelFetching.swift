@preconcurrency import Foundation
import AppKit
import SwiftUI
import AgentAudit
import AgentTools

// MARK: - Model Fetching Extension
extension AgentViewModel {

    func fetchClaudeModels() async {
        await MainActor.run { self.isFetchingClaudeModels = true }
        defer { Task { @MainActor in self.isFetchingClaudeModels = false } }

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
        let apiKey = ollamaAPIKey
        isFetchingModels = true
        Task {
            defer { isFetchingModels = false }
            do {
                let models = try await Self.fetchModels(endpoint: endpoint, apiKey: apiKey)
                ollamaModels = models.isEmpty ? Self.defaultOllamaModels : models
                // Auto-select first model if current selection is empty or not in list
                let names = ollamaModels.map(\.name)
                if ollamaModel.isEmpty || (!names.isEmpty && !names.contains(ollamaModel)) {
                    ollamaModel = names.first ?? ""
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
                ollamaContextWindows.merge(windows) { _, new in new }
            }
        }
    }

    func fetchLocalOllamaModels() {
        let endpoint = localOllamaEndpoint
        isFetchingLocalModels = true
        Task {
            defer { isFetchingLocalModels = false }
            do {
                let models = try await Self.fetchModels(endpoint: endpoint, apiKey: "")
                localOllamaModels = models.isEmpty ? Self.defaultOllamaModels : models
                let names = localOllamaModels.map(\.name)
                if localOllamaModel.isEmpty || (!names.isEmpty && !names.contains(localOllamaModel)) {
                    localOllamaModel = names.first ?? ""
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
                ollamaContextWindows.merge(windows) { _, new in new }
            }
        }
    }

    // MARK: - OpenAI Model Fetching

    func fetchOpenAIModels() {
        guard !openAIAPIKey.isEmpty else {
            openAIModels = Self.defaultOpenAIModels
            return
        }
        isFetchingOpenAIModels = true
        Task {
            defer { isFetchingOpenAIModels = false }
            do {
                let models = try await Self.fetchOpenAIModelsFromAPI(apiKey: openAIAPIKey)
                openAIModels = models.isEmpty ? Self.defaultOpenAIModels : models
                let ids = openAIModels.map(\.id)
                if openAIModel.isEmpty || (!ids.isEmpty && !ids.contains(openAIModel)) {
                    openAIModel = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch OpenAI models: \(error.localizedDescription)")
                openAIModels = Self.defaultOpenAIModels
            }
        }
    }

    /// Fetch Codex models via ChatGPT OAuth. Falls back silently to an empty
    /// list if not signed in (user should run `codex login` or click Sign In).
    func fetchCodexModels() {
        guard CodexAuthFile.load() != nil else {
            codexModels = []
            return
        }
        isFetchingCodexModels = true
        Task {
            defer { isFetchingCodexModels = false }
            do {
                let models = try await CodexService.fetchModels()
                codexModels = models.map { OpenAIModelInfo(id: $0.id, name: $0.display) }
                codexContextWindows = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0.contextWindow) })
                let ids = models.map(\.id)
                if codexModel.isEmpty || (!ids.isEmpty && !ids.contains(codexModel)) {
                    codexModel = ids.first ?? "gpt-5"
                }
            } catch {
                appendLog("Failed to fetch Codex models: \(error.localizedDescription)")
            }
        }
    }

    func fetchDeepSeekModels() {
        fetchProviderModels(
            key: deepSeekAPIKey,
            endpoint: "https://api.deepseek.com/v1/models",
            defaults: Self.defaultDeepSeekModels,
            fallbackModel: "",
            isFetching: \.isFetchingDeepSeekModels,
            models: \.deepSeekModels,
            selected: \.deepSeekModel,
            providerName: "DeepSeek"
        )
    }

    /// Generic fetcher for providers exposing an OpenAI-compatible /models
    /// endpoint. Handles the shared fetch → filter → defaults-fallback →
    /// auto-select flow that was previously duplicated per provider.
    private func fetchProviderModels(
        key: String,
        endpoint: String,
        defaults: [OpenAIModelInfo],
        fallbackModel: String,
        isFetching: ReferenceWritableKeyPath<AgentViewModel, Bool>,
        models modelsPath: ReferenceWritableKeyPath<AgentViewModel, [OpenAIModelInfo]>,
        selected selectedPath: ReferenceWritableKeyPath<AgentViewModel, String>,
        providerName: String,
        filter: (([OpenAIModelInfo]) -> [OpenAIModelInfo])? = nil
    ) {
        self[keyPath: isFetching] = true
        Task {
            defer { self[keyPath: isFetching] = false }
            guard !key.isEmpty else {
                self[keyPath: modelsPath] = defaults
                return
            }
            do {
                let all = try await Self.fetchOpenAICompatibleModels(apiKey: key, endpoint: endpoint)
                var models = all
                if let filter {
                    let filtered = filter(all)
                    models = filtered.isEmpty ? all : filtered
                }
                self[keyPath: modelsPath] = models.isEmpty ? defaults : models
                let current = self[keyPath: selectedPath]
                if current.isEmpty || !self[keyPath: modelsPath].contains(where: { $0.id == current }) {
                    self[keyPath: selectedPath] = self[keyPath: modelsPath].first?.id ?? fallbackModel
                }
            } catch {
                appendLog("Failed to fetch \(providerName) models: \(error.localizedDescription)")
                self[keyPath: modelsPath] = defaults
            }
        }
    }

    func fetchOpenRouterModels() {
        isFetchingOpenRouterModels = true
        Task {
            defer { isFetchingOpenRouterModels = false }
            do {
                let models = try await Self.fetchOpenRouterCatalog(apiKey: openRouterAPIKey)
                openRouterModels = models
                let ids = models.map(\.id)
                if openRouterModel.isEmpty || (!ids.isEmpty && !ids.contains(openRouterModel)) {
                    openRouterModel = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch OpenRouter models: \(error.localizedDescription)")
                openRouterModels = []
            }
        }
    }

    /// Fetch OpenRouter's /models catalog and keep only entries Agent! can actually drive:
    /// nonzero context_length AND supports the "tools" parameter. Strips out preview,
    /// embedding, image-only, and legacy chat-only entries that would just confuse the picker.
    /// Display name uses OpenRouter's human-friendly "name" field instead of the raw id.
    private nonisolated static func fetchOpenRouterCatalog(apiKey: String) async throws -> [OpenAIModelInfo] {
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
              let entries = json["data"] as? [[String: Any]] else { return [] }

        let filtered = entries.compactMap { entry -> OpenAIModelInfo? in
            guard let id = entry["id"] as? String, !id.isEmpty else { return nil }
            // Require a real context window — strips preview/placeholder rows.
            let ctx = entry["context_length"] as? Int ?? 0
            guard ctx > 0 else { return nil }
            // Require tool-calling support — Agent!'s loop is tool-driven, so
            // chat-only / embedding / image-only models would just dead-end.
            let params = entry["supported_parameters"] as? [String] ?? []
            guard params.contains("tools") else { return nil }
            let displayName = (entry["name"] as? String).map { $0.isEmpty ? id : $0 } ?? id
            return OpenAIModelInfo(id: id, name: displayName)
        }
        return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func fetchHuggingFaceModels() {
        guard !huggingFaceAPIKey.isEmpty else {
            huggingFaceModels = Self.defaultHuggingFaceModels
            return
        }
        isFetchingHuggingFaceModels = true
        Task {
            defer { isFetchingHuggingFaceModels = false }
            do {
                let models = try await Self.fetchHuggingFaceModelsFromAPI(apiKey: huggingFaceAPIKey)
                huggingFaceModels = models.isEmpty ? Self.defaultHuggingFaceModels : models
                let ids = huggingFaceModels.map(\.id)
                if huggingFaceModel.isEmpty || (!ids.isEmpty && !ids.contains(huggingFaceModel)) {
                    huggingFaceModel = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch HuggingFace models: \(error.localizedDescription)")
                huggingFaceModels = Self.defaultHuggingFaceModels
            }
        }
    }

    func fetchMiniMaxModels() {
        fetchProviderModels(
            key: miniMaxAPIKey,
            endpoint: "https://api.minimax.io/v1/models",
            defaults: Self.defaultMiniMaxModels,
            fallbackModel: "MiniMax-M3",
            isFetching: \.isFetchingMiniMaxModels,
            models: \.miniMaxModels,
            selected: \.miniMaxModel,
            providerName: "MiniMax"
        )
    }

    // MARK: - Static API Fetch Helpers

    private nonisolated static func fetchOpenAIModelsFromAPI(apiKey: String) async throws -> [OpenAIModelInfo] {
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            throw AgentError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = llmAPITimeout

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AgentError.apiError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "OpenAI API error")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsArray = json["data"] as? [[String: Any]] else
        {
            return defaultOpenAIModels
        }

        // No filtering — return every model ID the OpenAI API reports. The
        // picker shows the raw list so new models appear the moment OpenAI
        // publishes them, and users can choose legacy models if they want.
        let models = modelsArray
            .compactMap { model -> OpenAIModelInfo? in
                guard let id = model["id"] as? String, !id.isEmpty else { return nil }
                return OpenAIModelInfo(id: id, name: id)
            }
            .sorted { $0.name < $1.name }

        return models.isEmpty ? defaultOpenAIModels : models
    }

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
        isFetchingZAIModels = true
        let key = zAIAPIKey
        Task {
            defer { isFetchingZAIModels = false }
            guard !key.isEmpty else { return }
            let models = await Self.fetchZAIModelsFromAPI(apiKey: key)
            if !models.isEmpty {
                zAIModels = models
                if zAIModel.isEmpty || !zAIModels.contains(where: { $0.id == zAIModel }) {
                    zAIModel = zAIModels.first?.id ?? ""
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
        isFetchingQwenModels = true
        let key = qwenAPIKey
        Task {
            defer { isFetchingQwenModels = false }
            guard !key.isEmpty else {
                qwenModels = Self.defaultQwenModels
                return
            }
            // Try international endpoint first, then China mainland
            let endpoints = [
                "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/models",
                "https://dashscope.aliyuncs.com/compatible-mode/v1/models",
            ]
            for endpoint in endpoints {
                do {
                    let models = try await Self.fetchOpenAICompatibleModels(apiKey: key, endpoint: endpoint)
                    if !models.isEmpty {
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
                        qwenModels = chatModels.isEmpty ? models : chatModels
                        if qwenModel.isEmpty || !qwenModels.contains(where: { $0.id == qwenModel }) {
                            qwenModel = qwenModels.first?.id ?? "qwen-plus"
                        }
                        return
                    }
                } catch {
                    AuditLog.log(.api, "Failed to fetch Qwen models from \(endpoint): \(error.localizedDescription)")
                }
            }
            qwenModels = Self.defaultQwenModels
        }
    }

    // MARK: - Google Gemini Models

    func fetchGeminiModels() {
        fetchProviderModels(
            key: geminiAPIKey,
            endpoint: "https://generativelanguage.googleapis.com/v1beta/openai/models",
            defaults: Self.defaultGeminiModels,
            fallbackModel: "gemini-2.5-flash",
            isFetching: \.isFetchingGeminiModels,
            models: \.geminiModels,
            selected: \.geminiModel,
            providerName: "Gemini"
        )
    }

    // MARK: - Grok Models

    func fetchGrokModels() {
        fetchProviderModels(
            key: grokAPIKey,
            endpoint: "https://api.x.ai/v1/models",
            defaults: Self.defaultGrokModels,
            fallbackModel: "grok-3-mini-fast",
            isFetching: \.isFetchingGrokModels,
            models: \.grokModels,
            selected: \.grokModel,
            providerName: "Grok"
        )
    }

    // MARK: - Mistral Models

    func fetchMistralModels() {
        fetchProviderModels(
            key: mistralAPIKey,
            endpoint: "https://api.mistral.ai/v1/models",
            defaults: Self.defaultMistralModels,
            fallbackModel: "mistral-large-latest",
            isFetching: \.isFetchingMistralModels,
            models: \.mistralModels,
            selected: \.mistralModel,
            providerName: "Mistral"
        )
    }

    func fetchCodestralModels() {
        // Codestral key works on codestral.mistral.ai/v1/models.
        // Filter out embed models — keep only chat/completion models.
        fetchProviderModels(
            key: codestralAPIKey,
            endpoint: "https://codestral.mistral.ai/v1/models",
            defaults: Self.defaultCodestralModels,
            fallbackModel: "codestral-latest",
            isFetching: \.isFetchingCodestralModels,
            models: \.codestralModels,
            selected: \.codestralModel,
            providerName: "Codestral",
            filter: { $0.filter { !$0.id.lowercased().contains("embed") } }
        )
    }

    func fetchVibeModels() {
        // Vibe key only works with *-latest models, not dated versions like devstral-small-2507
        fetchProviderModels(
            key: vibeAPIKey,
            endpoint: "https://api.mistral.ai/v1/models",
            defaults: Self.defaultVibeModels,
            fallbackModel: "devstral-latest",
            isFetching: \.isFetchingVibeModels,
            models: \.vibeModels,
            selected: \.vibeModel,
            providerName: "Vibe",
            filter: { $0.filter { $0.id.lowercased().contains("devstral") && $0.id.contains("latest") } }
        )
    }

    /// Shared OpenAI-compatible model list fetcher
    private nonisolated static func fetchOpenAICompatibleModels(apiKey: String, endpoint: String) async throws -> [OpenAIModelInfo] {
        guard let url = URL(string: endpoint) else { throw AgentError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = llmAPITimeout
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return [] }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let modelsData = json["data"] as? [[String: Any]] else { return [] }
        return modelsData.compactMap { model -> OpenAIModelInfo? in
            guard let id = model["id"] as? String else { return nil }
            return OpenAIModelInfo(id: id, name: id)
        }.sorted { $0.name < $1.name }
    }

    // MARK: - vLLM Models

    func fetchVLLMModels() {
        isFetchingVLLMModels = true
        let endpoint = vLLMEndpoint
        let key = vLLMAPIKey
        Task {
            defer { isFetchingVLLMModels = false }
            do {
                let (models, windows) = try await Self.fetchVLLMModelsFromAPI(endpoint: endpoint, apiKey: key)
                vLLMModels = models
                vLLMContextWindows = windows
                let ids = models.map(\.id)
                if vLLMModel.isEmpty || (!ids.isEmpty && !ids.contains(vLLMModel)) {
                    vLLMModel = ids.first ?? ""
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
        isFetchingLMStudioModels = true
        let proto = lmStudioProtocol
        let modelsEndpoint: String
        switch proto {
        case .lmStudio: modelsEndpoint = "http://localhost:1234/api/v1/models"
        default: modelsEndpoint = "http://localhost:1234/v1/models"
        }
        Task {
            defer { isFetchingLMStudioModels = false }
            do {
                let models = try await Self.fetchLMStudioModelsFromAPI(modelsURL: modelsEndpoint)
                lmStudioModels = models
                let ids = models.map(\.id)
                if lmStudioModel.isEmpty || (!ids.isEmpty && !ids.contains(lmStudioModel)) {
                    lmStudioModel = ids.first ?? ""
                }
            } catch {
                appendLog("Failed to fetch LM Studio models: \(error.localizedDescription)")
            }
            // Real context length per model from LM Studio's REST API — drives the
            // compaction threshold. Best-effort: older LM Studio versions without
            // /api/v0/models just keep the 32K fallback.
            if let windows = try? await Self.fetchLMStudioContextWindows() {
                lmStudioContextWindows = windows
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
        switch provider {
        case .claude: if force || availableClaudeModels.isEmpty { Task { await fetchClaudeModels() } }
        case .codex: if force || codexModels.isEmpty { fetchCodexModels() }
        case .openAI: if force || openAIModels.isEmpty { fetchOpenAIModels() }
        case .ollama: if force || ollamaModels.isEmpty { fetchOllamaModels() }
        case .localOllama: if force || localOllamaModels.isEmpty { fetchLocalOllamaModels() }
        case .deepSeek: if force || deepSeekModels.isEmpty { fetchDeepSeekModels() }
        case .huggingFace: if force || huggingFaceModels.isEmpty { fetchHuggingFaceModels() }
        case .vLLM: if force || vLLMModels.isEmpty { fetchVLLMModels() }
        case .lmStudio: if force || lmStudioModels.isEmpty { fetchLMStudioModels() }
        case .zAI: if force || zAIModels.isEmpty { fetchZAIModels() }
        case .qwen: if force || qwenModels.isEmpty { fetchQwenModels() }
        case .gemini: if force || geminiModels.isEmpty { fetchGeminiModels() }
        case .grok: if force || grokModels.isEmpty { fetchGrokModels() }
        case .mistral: if force || mistralModels.isEmpty { fetchMistralModels() }
        case .codestral: if force || codestralModels.isEmpty { fetchCodestralModels() }
        case .vibe: if force || vibeModels.isEmpty { fetchVibeModels() }
        case .miniMax: if force || miniMaxModels.isEmpty { fetchMiniMaxModels() }
        case .openRouter: if force || openRouterModels.isEmpty { fetchOpenRouterModels() }
        case .bigModel: break
        default: break
        }
    }
}
