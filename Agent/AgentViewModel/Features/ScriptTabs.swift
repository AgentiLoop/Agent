import Foundation
import AgentTools
import AgentLLM

extension AgentViewModel {
    // MARK: - Script Tabs

    func openScriptTab(scriptName: String, selectTab: Bool = true) -> ScriptTab {
        let tab = ScriptTab(scriptName: scriptName)
        // Inherit LLM config from the currently selected main tab
        if let selId = selectedTabId,
           let parent = self.tab(for: selId), parent.isMainTab
        {
            tab.parentTabId = parent.id
        }
        // Inherit project folder from the currently selected tab (parent), falling back to global
        let parentFolder = selectedTabId.flatMap { self.tab(for: $0) }?.projectFolder ?? ""
        let sourceFolder = parentFolder.isEmpty ? self.projectFolder : parentFolder
        tab.projectFolder = Self.resolvedWorkingDirectory(sourceFolder)
        scriptTabs.append(tab)
        if selectTab { selectedTabId = tab.id }
        persistScriptTabs()
        return tab
    }

    /// Create a new main tab with its own LLM provider/model.
    @discardableResult
    func createMainTab(config: LLMConfig) -> ScriptTab {
        // Number duplicate model names: glm-5, glm-5 2, glm-5 3, etc.
        var numberedConfig = config
        let baseName = config.displayName
        let existingCount = scriptTabs.filter { $0.scriptName.hasPrefix(baseName) && $0.isMainTab }.count
        if existingCount > 0 {
            numberedConfig.displayName = "\(baseName) \(existingCount + 1)"
        }
        let tab = ScriptTab(llmConfig: numberedConfig)
        // Inherit project folder from the currently selected tab, falling back to global
        let parentFolder = selectedTabId.flatMap { self.tab(for: $0) }?.projectFolder ?? ""
        let sourceFolder = parentFolder.isEmpty ? self.projectFolder : parentFolder
        tab.projectFolder = Self.resolvedWorkingDirectory(sourceFolder)
        scriptTabs.append(tab)
        selectedTabId = tab.id
        persistScriptTabs()
        return tab
    }

    /// Resolve the LLM provider and model for a given tab.
    /// Main tabs use their own config; script tabs inherit from parent; fallback to global.
    func resolvedLLMConfig(for tab: ScriptTab) -> (provider: APIProvider, model: String) {
        if let config = tab.llmConfig {
            return (config.provider, config.model)
        }
        if let parentId = tab.parentTabId,
           let parent = self.tab(for: parentId),
           let config = parent.llmConfig
        {
            return (config.provider, config.model)
        }
        return (selectedProvider, globalModelForProvider(selectedProvider))
    }

    /// Return the current global model ID for the given provider.
    func globalModelForProvider(_ provider: APIProvider) -> String {
        switch provider {
        case .claude: return selectedModel
        case .codex: return models[.codex]
        case .openAI: return models[.openAI]
        case .deepSeek: return models[.deepSeek]
        case .huggingFace: return models[.huggingFace]
        case .ollama: return models[.ollama]
        case .localOllama: return models[.localOllama]
        case .vLLM: return models[.vLLM]
        case .lmStudio: return models[.lmStudio]
        case .zAI: return models[.zAI].replacingOccurrences(of: ":v", with: "")
        case .bigModel: return models[.bigModel].replacingOccurrences(of: ":v", with: "")
        case .miniMax: return models[.miniMax]
        case .openRouter: return models[.openRouter]
        case .requesty: return models[.requesty]
        case .qwen: return models[.qwen]
        case .gemini: return models[.gemini]
        case .grok: return models[.grok]
        case .mistral: return models[.mistral]
        case .vibe: return models[.vibe]
        case .foundationModel: return "Apple Intelligence"
        }
    }

    /// Return the API key for the given provider.
    func apiKeyForProvider(_ provider: APIProvider) -> String {
        switch provider {
        case .claude: return apiKey
        case .codex: return "" // auth comes from ~/.codex/auth.json, no UI key
        case .openAI: return apiKeys[.openAI]
        case .deepSeek: return apiKeys[.deepSeek]
        case .huggingFace: return apiKeys[.huggingFace]
        case .ollama: return apiKeys[.ollama]
        case .localOllama: return ""
        case .vLLM: return apiKeys[.vLLM]
        case .lmStudio: return apiKeys[.lmStudio]
        case .zAI: return apiKeys[.zAI]
        case .bigModel: return apiKeys[.bigModel]
        case .miniMax: return apiKeys[.miniMax]
        case .openRouter: return apiKeys[.openRouter]
        case .requesty: return apiKeys[.requesty]
        case .qwen: return apiKeys[.qwen]
        case .gemini: return apiKeys[.gemini]
        case .grok: return apiKeys[.grok]
        case .mistral: return apiKeys[.mistral]
        case .vibe: return apiKeys[.vibe]
        case .foundationModel: return ""
        }
    }

    /// Return the chat URL for the given provider from the LLM registry (single source of truth).
    /// Pick the right chat URL — code or vision — based on the model's :v suffix.
    func chatURLForProvider(_ provider: APIProvider) -> String {
        guard let endpoint = LLMRegistry.shared.provider(provider.rawValue)?.endpoint else { return "" }
        let raw = provider == .zAI ? models[.zAI] : (provider == .bigModel ? models[.bigModel] : "")
        let isVision = raw.hasSuffix(":v")
        return endpoint.resolvedChatURL(isVision: isVision)
    }

    /// Return a human-readable display name for a model ID given its provider.
    func modelDisplayName(provider: APIProvider, modelId: String) -> String {
        switch provider {
        case .claude:
            return availableClaudeModels.first(where: { $0.id == modelId })?.displayName ?? modelId
        case .codex:
            return modelId
        case .openAI:
            return modelLists[.openAI].first(where: { $0.id == modelId })?.name
                ?? Self.defaultOpenAIModels.first(where: { $0.id == modelId })?.name ?? modelId
        case .deepSeek:
            return modelLists[.deepSeek].first(where: { $0.id == modelId })?.name
                ?? Self.defaultDeepSeekModels.first(where: { $0.id == modelId })?.name ?? modelId
        case .huggingFace:
            return modelLists[.huggingFace].first(where: { $0.id == modelId })?.name
                ?? Self.defaultHuggingFaceModels.first(where: { $0.id == modelId })?.name ?? modelId
        case .ollama:
            return ollamaModels.first(where: { $0.id == modelId })?.name ?? modelId
        case .localOllama:
            return localOllamaModels.first(where: { $0.id == modelId })?.name ?? modelId
        case .vLLM:
            return modelLists[.vLLM].first(where: { $0.id == modelId })?.name ?? modelId
        case .lmStudio:
            return modelLists[.lmStudio].first(where: { $0.id == modelId })?.name ?? modelId
        case .zAI:
            return modelLists[.zAI].first(where: { $0.id == modelId })?.name
                ?? Self.defaultZAIModels.first(where: { $0.id == modelId })?.name ?? modelId
        case .bigModel:
            return modelId
        case .miniMax:
            return modelLists[.miniMax].first(where: { $0.id == modelId })?.name
                ?? Self.defaultMiniMaxModels.first(where: { $0.id == modelId })?.name ?? modelId
        case .openRouter:
            return modelLists[.openRouter].first(where: { $0.id == modelId })?.name ?? modelId
        case .requesty:
            return modelLists[.requesty].first(where: { $0.id == modelId })?.name ?? modelId
        case .qwen:
            return modelId
        case .gemini:
            return modelLists[.gemini].first(where: { $0.id == modelId })?.name
                ?? Self.defaultGeminiModels.first(where: { $0.id == modelId })?.name ?? modelId
        case .grok:
            return modelLists[.grok].first(where: { $0.id == modelId })?.name
                ?? Self.defaultGrokModels.first(where: { $0.id == modelId })?.name ?? modelId
        case .mistral:
            return modelId

        case .vibe:
            return modelId
        case .foundationModel:
            return "Apple Intelligence"
        }
    }

    func closeScriptTab(id: UUID) {
        if let tab = tab(for: id) {
            // Stop LLM task and clear queue
            if tab.isLLMRunning || !tab.taskQueue.isEmpty {
                stopTabTask(tab: tab)
            }
            // Cancel running script
            if tab.isRunning {
                tab.isCancelled = true
                tab.cancelHandler?()
                tab.isRunning = false
            }
            tab.logFlushTask?.cancel()
            tab.llmStreamFlushTask?.cancel()
            // Clear log before removal — prevents expensive NSAttributedString copy on tab switch
            tab.activityLog = ""
            tab.rawLLMOutput = ""
        }
        if selectedTabId == id {
            if let idx = scriptTabs.firstIndex(where: { $0.id == id }) {
                if idx > 0 {
                    selectedTabId = scriptTabs[idx - 1].id
                } else if scriptTabs.count > 1 {
                    selectedTabId = scriptTabs[1].id
                } else {
                    selectedTabId = nil
                }
            } else {
                selectedTabId = nil
            }
        }
        scriptTabs.removeAll { $0.id == id }
        persistScriptTabs()
    }

    func cancelScriptTab(id: UUID) {
        guard let tab = tab(for: id) else { return }
        tab.isCancelled = true
        tab.cancelHandler?()
        tab.isRunning = false
        // Also cancel any running LLM task
        if tab.isLLMRunning {
            stopTabTask(tab: tab)
        }
    }

    func selectMainTab() {
        selectedTabId = nil
        persistScriptTabs()
    }

    /// / Ensure an LLM tab is selected when a task comes in: / 1. If currently on a main LLM tab, stay there / 2. If on
    /// a script tab with a parent, switch to the parent LLM tab / 3. Otherwise, switch to main tab
    func ensureLLMTabSelected() {
        if selectedTabId == nil {
            // Already on main tab
            return
        }

        guard let currentTab = selectedTab else {
            // Tab not found, go to main
            selectMainTab()
            return
        }

        if currentTab.isMainTab {
            // Already on an LLM main tab, stay there
            return
        }

        // On a script tab - find its parent
        if let parentId = currentTab.parentTabId,
           let parentTab = self.tab(for: parentId), parentTab.isMainTab
        {
            // Switch to parent LLM tab
            selectedTabId = parentTab.id
            persistScriptTabs()
        } else {
            // No parent found or not a main tab, go to main
            selectMainTab()
        }
    }

    // MARK: - Script Tab Persistence

    /// Save open script tabs: order/selected to UserDefaults, log data to SwiftData.
    func persistScriptTabs() {
        for tab in scriptTabs { tab.flush() }

        let ids = scriptTabs.map { $0.id.uuidString }
        UserDefaults.standard.set(ids, forKey: "agentScriptTabIds")
        UserDefaults.standard.set(selectedTabId?.uuidString, forKey: "agentSelectedTabId")

        let tabData = scriptTabs.map { tab in
            let configJSON: String? = {
                guard let config = tab.llmConfig,
                      let data = try? JSONEncoder().encode(config) else { return nil }
                return String(data: data, encoding: .utf8)
            }()
            let historyJSON: String? = {
                guard !tab.promptHistory.isEmpty,
                      let data = try? JSONEncoder().encode(tab.promptHistory) else { return nil }
                return String(data: data, encoding: .utf8)
            }()
            let summariesJSON: String? = {
                guard !tab.tabTaskSummaries.isEmpty,
                      let data = try? JSONEncoder().encode(tab.tabTaskSummaries) else { return nil }
                return String(data: data, encoding: .utf8)
            }()
            let tabErrorsJSON: String? = {
                guard !tab.tabErrors.isEmpty,
                      let data = try? JSONEncoder().encode(tab.tabErrors) else { return nil }
                return String(data: data, encoding: .utf8)
            }()
            let stepsJSON: String? = {
                guard !tab.toolSteps.isEmpty,
                      let data = try? JSONEncoder().encode(tab.toolSteps) else { return nil }
                return String(data: data, encoding: .utf8)
            }()
            return (
                id: tab.id,
                scriptName: tab.scriptName,
                activityLog: tab.activityLog,
                exitCode: tab.exitCode,
                llmConfigJSON: configJSON,
                parentTabIdString: tab.parentTabId?.uuidString,
                isMessagesTab: tab.isMessagesTab,
                projectFolder: tab.projectFolder,
                promptHistoryJSON: historyJSON,
                taskSummariesJSON: summariesJSON,
                errorsJSON: tabErrorsJSON,
                rawLLMOutput: tab.rawLLMOutput,
                lastElapsed: tab.lastElapsed,
                thinkingExpanded: tab.thinkingExpanded,
                thinkingOutputExpanded: tab.thinkingOutputExpanded,
                thinkingDismissed: tab.thinkingDismissed,
                tabInputTokens: tab.tabInputTokens,
                tabOutputTokens: tab.tabOutputTokens,
                toolStepsJSON: stepsJSON
            )
        }
        ChatHistoryStore.shared.saveScriptTabs(tabData)
    }

    /// Restore script tabs from UserDefaults (order) + SwiftData (data).
    func restoreScriptTabs() {
        guard let ids = UserDefaults.standard.stringArray(forKey: "agentScriptTabIds"),
              !ids.isEmpty else { return }

        let records = ChatHistoryStore.shared.fetchScriptTabs()
        let recordMap = Dictionary(records.compactMap { r in (r.tabId, r) }, uniquingKeysWith: { first, _ in first })

        for idStr in ids {
            guard let uuid = UUID(uuidString: idStr),
                  let record = recordMap[uuid] else { continue }
            let tab = ScriptTab(record: record)
            scriptTabs.append(tab)
        }

        // Always start on Main tab
        selectedTabId = nil
    }

}
