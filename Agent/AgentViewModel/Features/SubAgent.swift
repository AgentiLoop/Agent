@preconcurrency import Foundation
import AgentTools
import AgentLLM

// MARK: - Sub-Agent Spawning

/// Represents an isolated sub-agent execution with its own message history.
@MainActor
final class SubAgent: Identifiable {
    let id = UUID()
    let name: String
    let prompt: String
    let projectFolder: String
    var toolGroups: Set<String>? // nil = default (Core+Work+Code)
    var maxIterations: Int = 15
    /// Optional model id for this agent (from the active provider's model
    /// list) — lets a cheap/fast model run search agents while the parent
    /// keeps its own model. nil = parent's model.
    var modelOverride: String?
    /// Whether the agent's tool groups can mutate state (Code/Auto/User/Root).
    var isWriteCapable: Bool = true
    /// Full findings written to {project}/.agent/subagents/<id>.md when the
    /// result exceeds the notification cap.
    var resultFilePath: String?
    var status: Status = .running
    var result: String = ""
    var task: Task<String, Never>?
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    let startTime = Date()
    /// Mailbox for inter-agent messages. Parent can inject messages mid-task.
    var mailbox: [String] = []

    enum Status: String {
        case running, completed, failed
    }

    init(name: String, prompt: String, projectFolder: String) {
        self.name = name
        self.prompt = prompt
        self.projectFolder = projectFolder
    }

    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    /// XML notification for parent context.
    var notification: String {
        let fileLine = resultFilePath.map {
            "\n  <full-result-file>\($0) — read_file for the complete findings</full-result-file>"
        } ?? ""
        return """
        <task-notification>
          <task-id>\(id.uuidString.prefix(8))</task-id>
          <name>\(name)</name>
          <status>\(status.rawValue)</status>
          <result>\(LogLimits.trim(result, cap: LogLimits.summaryChars))</result>\(fileLine)
          <usage>
            <input_tokens>\(inputTokens)</input_tokens>
            <output_tokens>\(outputTokens)</output_tokens>
            <duration_ms>\(Int(duration * 1000))</duration_ms>
          </usage>
        </task-notification>
        """
    }
}

extension AgentViewModel {

    /// Maximum concurrent sub-agents per task.
    static let maxSubAgents = 3
    /// Read-only agents (no write-capable tool groups) get a higher cap —
    /// parallel research fans out without risking concurrent mutations.
    static let maxTotalSubAgents = 6

    /// Active sub-agents for the current task.
    var activeSubAgents: [SubAgent] {
        subAgents.filter { $0.status == .running }
    }

    /// Spawn an isolated sub-agent that runs concurrently with the parent task.
    /// Returns immediately with the agent ID. Results arrive via notification.
    func spawnSubAgent(
        name: String, prompt: String, toolGroups: Set<String>? = nil,
        maxIterations: Int = 15, model: String? = nil
    ) -> String {
        // Write-capable agents stay capped at 3 to avoid concurrent mutations;
        // pure read/research agents fan out up to the total cap.
        let requestedGroups = toolGroups ?? [Tool.Group.core, Tool.Group.work, Tool.Group.code]
        let writeGroups: Set<String> = [Tool.Group.code, Tool.Group.auto, Tool.Group.user, Tool.Group.root, Tool.Group.subAgents]
        let writeCapable = !requestedGroups.isDisjoint(with: writeGroups)
        let activeWrite = activeSubAgents.filter { $0.isWriteCapable }.count
        if activeSubAgents.count >= Self.maxTotalSubAgents
            || (writeCapable && activeWrite >= Self.maxSubAgents)
        {
            return "Error: sub-agent limit reached (\(writeCapable ? "\(Self.maxSubAgents) write-capable" : "\(Self.maxTotalSubAgents) total")). Wait for a <task-notification>, then spawn again — or pass tools: \"Core,Work\" for a read-only agent."
        }

        let agent = SubAgent(name: name, prompt: prompt, projectFolder: projectFolder)
        agent.toolGroups = toolGroups
        agent.maxIterations = maxIterations
        agent.modelOverride = model
        agent.isWriteCapable = writeCapable
        subAgents.append(agent)
        appendLog("🔀 Sub-agent '\(name)' spawned [\(agent.id.uuidString.prefix(8))]")
        flushLog()

        agent.task = Task { [weak self] in
            guard let self else { return "Error: parent deallocated" }
            let result = await self.executeSubAgent(agent)
            return result
        }

        return
            "Sub-agent '\(name)' spawned "
            + "(id: \(agent.id.uuidString.prefix(8))). "
            + "You will receive a <task-notification> when it completes."
    }

    /// Execute a sub-agent's task in isolation using the current provider/model.
    private func executeSubAgent(_ agent: SubAgent) async -> String {
        let provider = selectedProvider
        let modelName = agent.modelOverride ?? globalModelForProvider(provider)
        let mt = maxTokens

        // Build a minimal service for this sub-agent
        let historyContext = "" // Sub-agents start with clean context
        let claude: ClaudeService?
        if provider == .claude {
            claude = ClaudeService(
                apiKey: apiKey,
                model: modelName,
                historyContext: historyContext,
                projectFolder: agent.projectFolder,
                maxTokens: mt
            )
        } else if provider == .lmStudio && lmStudioProtocol == .anthropic {
            claude = ClaudeService(
                apiKey: lmStudioAPIKey,
                model: modelName,
                historyContext: historyContext,
                projectFolder: agent.projectFolder,
                baseURL: lmStudioEndpoint,
                maxTokens: mt
            )
        } else if provider == .openRouter && openRouterProtocol == .anthropic {
            claude = ClaudeService(
                apiKey: openRouterAPIKey,
                model: modelName,
                historyContext: historyContext,
                projectFolder: agent.projectFolder,
                baseURL: OpenRouterProtocol.anthropic.endpoint,
                maxTokens: mt
            )
        } else {
            claude = nil
        }
        let openAICompatible: OpenAICompatibleService?
        switch provider {
        case .claude, .codex, .ollama, .localOllama, .foundationModel:
            openAICompatible = nil
        case .lmStudio where lmStudioProtocol == .anthropic:
            openAICompatible = nil
        case .openRouter where openRouterProtocol == .anthropic:
            openAICompatible = nil
        case .vLLM:
            openAICompatible = OpenAICompatibleService(
                apiKey: apiKeyForProvider(provider), model: modelName,
                baseURL: vLLMEndpoint, historyContext: historyContext,
                projectFolder: agent.projectFolder, provider: provider,
                maxTokens: mt
            )
        default:
            let url = chatURLForProvider(provider)
            openAICompatible = url.isEmpty ? nil : OpenAICompatibleService(
                apiKey: apiKeyForProvider(provider), model: modelName,
                baseURL: url, historyContext: historyContext,
                projectFolder: agent.projectFolder, provider: provider,
                maxTokens: mt
            )
        }
        let ollama: OllamaService?
        switch provider {
        case .ollama:
            ollama = OllamaService(
                apiKey: ollamaAPIKey, model: modelName,
                endpoint: ollamaEndpoint, historyContext: historyContext,
                projectFolder: agent.projectFolder, provider: .ollama
            )
        case .localOllama:
            ollama = OllamaService(
                apiKey: "", model: modelName,
                endpoint: localOllamaEndpoint, historyContext: historyContext,
                projectFolder: agent.projectFolder, provider: .localOllama,
                contextSize: localOllamaContextSize
            )
        default:
            ollama = nil
        }

        // Set temperature
        claude?.temperature = temperatureForProvider(.claude)
        ollama?.temperature = temperatureForProvider(provider)
        openAICompatible?.temperature = temperatureForProvider(provider)

        // Sub-agent tool groups — configurable by parent, defaults to Core+Work+Code. Deliberately NOT including
        // Tool.Group.subAgents in the default, so a spawned child cannot recursively spawn grandchildren without explicit parent opt-in. The maxSubAgents=3 cap is enforced per-parent, so recursive spawning would silently blow past it. Parents that need multi-level orchestration can pass agent.toolGroups explicitly.
        let activeGroups: Set<String> = agent.toolGroups ?? [Tool.Group.core, Tool.Group.work, Tool.Group.code]

        var messages: [[String: Any]] = [
            ["role": "user", "content": agent.prompt]
        ]

        var iterations = 0
        let maxIterations = agent.maxIterations
        var finalResult = ""
        // Sub-agents previously never compacted — a long research loop grew
        // until the provider rejected the transcript. Same tiered compaction
        // as the main/tab loops, threshold from the provider's real context.
        var compactionState = CompactionState(contextWindow: contextWindow(for: provider))

        while !Task.isCancelled && iterations < maxIterations {
            iterations += 1

            if iterations > 1 {
                compactionState.refreshThreshold(contextWindow: contextWindow(for: provider))
                _ = await Self.tieredCompact(&messages, state: &compactionState)
            }

            do {
                let response: (content: [[String: Any]], stopReason: String, inputTokens: Int, outputTokens: Int)
                if let claude {
                    response = try await claude.sendStreaming(messages: messages, activeGroups: activeGroups) { _ in }
                } else if let openAICompatible {
                    let r = try await openAICompatible.sendStreaming(messages: messages, activeGroups: activeGroups) { _ in }
                    response = (r.content, r.stopReason, r.inputTokens, r.outputTokens)
                } else if let ollama {
                    let r = try await ollama.sendStreaming(messages: messages, activeGroups: activeGroups) { _ in }
                    response = (r.content, r.stopReason, r.inputTokens, r.outputTokens)
                } else {
                    agent.status = .failed
                    agent.result = "No LLM service available"
                    return agent.notification
                }

                agent.inputTokens += response.inputTokens
                agent.outputTokens += response.outputTokens

                var toolResults: [[String: Any]] = []
                var hasToolUse = false

                for block in response.content {
                    guard let type = block["type"] as? String else { continue }
                    if type == "text", let text = block["text"] as? String {
                        finalResult = text
                    } else if type == "tool_use" {
                        hasToolUse = true
                        guard let toolId = block["id"] as? String,
                              var name = block["name"] as? String,
                              var input = block["input"] as? [String: Any] else { continue }

                        (name, input) = Self.expandConsolidatedTool(name: name, input: input)

                        if name == "task_complete" {
                            finalResult = input["summary"] as? String ?? finalResult
                            break
                        }

                        // Execute tool (sub-agent shares parent's dispatch)
                        let ctx = ToolContext(
                            toolId: toolId,
                            projectFolder: agent.projectFolder,
                            selectedProvider: selectedProvider,
                            tavilyAPIKey: tavilyAPIKey
                        )
                        var results: [[String: Any]] = []
                        _ = await dispatchTool(name: name, input: input, ctx: ctx, toolResults: &results)
                        toolResults.append(contentsOf: results)
                    }
                }

                let assistantContent: Any = response.content.isEmpty ? "Continuing." as Any : response.content as Any
                messages.append(["role": "assistant", "content": assistantContent])

                // Check mailbox for messages from parent/other agents
                if !agent.mailbox.isEmpty {
                    let incoming = agent.mailbox.joined(separator: "\n")
                    agent.mailbox.removeAll()
                    // Anthropic rejects `tool_result` blocks whose `tool_use_id` has no
                    // matching `tool_use` in the prior assistant message — use `text` instead.
                    toolResults.append([
                        "type": "text",
                        "text": "<message from coordinator>\n\(incoming)\n</message>"
                    ])
                }

                if hasToolUse && !toolResults.isEmpty {
                    messages.append(["role": "user", "content": toolResults])
                } else if !hasToolUse {
                    break // Text-only response = done
                }

            } catch {
                agent.status = .failed
                agent.result = "Error: \(error.localizedDescription)"
                appendLog("🔀 Sub-agent '\(agent.name)' failed: \(error.localizedDescription)")
                flushLog()
                return agent.notification
            }
        }

        agent.status = .completed
        // Spill full findings to disk when they exceed the notification cap so
        // long research isn't lost to truncation — the parent reads the file.
        if !agent.projectFolder.isEmpty, finalResult.count > LogLimits.summaryChars {
            let dir = URL(fileURLWithPath: agent.projectFolder)
                .appendingPathComponent(".agent/subagents")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let url = dir.appendingPathComponent("\(agent.id.uuidString.prefix(8)).md")
            if (try? finalResult.write(to: url, atomically: true, encoding: .utf8)) != nil {
                agent.resultFilePath = url.path
            }
        }
        agent.result = LogLimits.trim(finalResult, cap: LogLimits.summaryChars)
        appendLog(
            "🔀 Sub-agent '\(agent.name)' completed "
                + "(\(agent.inputTokens + agent.outputTokens) tokens, "
                + "\(String(format: "%.1f", agent.duration))s)"
        )
        flushLog()
        return agent.notification
    }

    /// Send a message to a running sub-agent by name. Returns status.
    func sendMessageToAgent(name: String, message: String) -> String {
        guard let agent = subAgents.first(where: { $0.name == name && $0.status == .running }) else {
            // Try by ID prefix
            if let agent = subAgents.first(where: { $0.id.uuidString.hasPrefix(name) && $0.status == .running }) {
                agent.mailbox.append(message)
                return "Message delivered to '\(agent.name)'."
            }
            return "Error: No running sub-agent named '\(name)'. Active agents: \(activeSubAgents.map(\.name).joined(separator: ", "))"
        }
        agent.mailbox.append(message)
        return "Message delivered to '\(agent.name)'."
    }

    /// Collect notifications from completed sub-agents and clear them.
    func collectSubAgentNotifications() -> [String] {
        let completed = subAgents.filter { $0.status != .running }
        let notifications = completed.map(\.notification)
        subAgents.removeAll { $0.status != .running }
        return notifications
    }
}
