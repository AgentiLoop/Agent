import Foundation
import AgentTools

/// Bridge extension that provides convenience methods using app-specific services
/// (ToolPreferencesService, MCPService) that the AgentTools package doesn't know about.
extension AgentTools {

    /// Xcode tool names that should be filtered out when not in an Xcode project.
    private static let xcodeToolNames: Set<String> = [
        "xc",
        "xcode",
        "xcode_build",
        "xcode_run",
        "xcode_list_projects",
        "xcode_select_project",
        "xcode_add_file",
        "xcode_remove_file",
        "xcode_analyze",
        "xcode_snippet",
        "xcode_bump_version",
        "xcode_bump_build",
        "xcode_get_version",
        "xcode_grant_permission"
    ]

    /// Combined filter: user prefs + group filter + Xcode gating.
    @MainActor private static func makeFilter(
        provider: APIProvider,
        activeGroups: Set<String>?,
        projectFolder: String
    ) -> (String) -> Bool
    {
        let prefs = ToolPreferencesService.shared
        let hasXcode = AgentViewModel.isXcodeProject(projectFolder)
        return { name in
            if !hasXcode && xcodeToolNames.contains(name) { return false }
            return prefs.isEnabled(provider, name, activeGroups: activeGroups)
        }
    }

    @MainActor private static func filteredMCP(projectFolder: String) -> [MCPToolInfo] {
        let mcpService = MCPService.shared
        let all: [MCPToolInfo] = mcpService.discoveredTools
            .filter { mcpService.isToolEnabled(serverName: $0.serverName, toolName: $0.name) }
            .map { MCPToolInfo(serverName: $0.serverName, name: $0.name, description: $0.description, inputSchemaJSON: $0.inputSchemaJSON) }
        let hasXcode = AgentViewModel.isXcodeProject(projectFolder)
        if hasXcode { return all }
        return all.filter { !$0.name.lowercased().contains("xcode") && !$0.name.lowercased().contains("xcf") }
    }

    /// Claude format with ToolPreferencesService, MCPService, and Xcode gating.
    @MainActor static func claudeFormat(
        activeGroups: Set<String>? = nil,
        compact: Bool = false,
        projectFolder: String = ""
    ) -> [[String: Any]]
    {
        return claudeFormat(
            isEnabled: makeFilter(provider: .claude, activeGroups: activeGroups, projectFolder: projectFolder),
            mcpTools: filteredMCP(projectFolder: projectFolder),
            compact: compact
        )
    }

    /// Ollama format with ToolPreferencesService, MCPService, and Xcode gating.
    @MainActor static func ollamaTools(
        for provider: APIProvider,
        activeGroups: Set<String>? = nil,
        compact: Bool = false,
        projectFolder: String = ""
    ) -> [[String: Any]] {
        return ollamaTools(
            isEnabled: makeFilter(provider: provider, activeGroups: activeGroups, projectFolder: projectFolder),
            mcpTools: filteredMCP(projectFolder: projectFolder),
            compact: compact
        )
    }

    /// Backward-compat alias.
    @MainActor static var ollamaFormat: [[String: Any]] { ollamaTools(for: .ollama) }

    /// Local tool (schema in-app, not in the AgentTools package) in OpenAI/Ollama
    /// function format: `goal_state`.
    @MainActor static func localOllamaTool() -> [[String: Any]] {
        localToolSchemas().map { schema in
            [
                "type": "function",
                "function": [
                    "name": schema["name"] as? String ?? "",
                    "description": schema["description"] as? String ?? "",
                    "parameters": schema["input_schema"] as? [String: Any] ?? ["type": "object", "properties": [:] as [String: Any]]
                ] as [String: Any]
            ]
        }
    }

    /// Local tool whose schema lives in the app (not the AgentTools package):
    /// `goal_state` — view/update the persistent goal + verification criteria.
    @MainActor static func localToolSchemas() -> [[String: Any]] {
        [
            [
                "name": "goal_state",
                "description": "Read or update the persistent goal state. Set the goal and its verifiable success criteria when starting a non-trivial task; mark criteria done as you verify them; clear when the task is finished.",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "action": [
                            "type": "string",
                            "enum": ["set", "get", "mark", "clear"],
                            "description": "set = record goal + criteria; get = read current state; mark = mark a criterion done/open; clear = wipe the goal."
                        ],
                        "goal": ["type": "string", "description": "The task goal (action: set)."],
                        "criteria": [
                            "type": "array",
                            "items": ["type": "string"],
                            "description": "Verifiable success criteria (action: set). Each should be checkable with a tool call."
                        ],
                        "criterion": ["type": "string", "description": "Criterion text to mark (action: mark)."],
                        "done": ["type": "boolean", "description": "Mark done (true) or still open (false). Default true."]
                    ],
                    "required": ["action"]
                ] as [String: Any]
            ]
        ]
    }
}
