import AppKit
import AgentAudit

/// One-step MCP install ("add sentry mcp server"): match a preset (or take a custom url/command), collect
/// credentials in a native secure prompt, store them in the Keychain, save the config with `${keychain:…}`
/// placeholders, and connect immediately so the tools are usable on the next turn — no restart.
///
/// Secrets never reach the LLM: the prompt is an app-modal NSAlert outside the chat, values go straight to the
/// Keychain, and every string returned from here only names the credential, never its value.
@MainActor
enum MCPInstaller {
    private static let placeholderPrefix = "${keychain:"

    static func keychainAccount(server: String, key: String) -> String { "mcp.\(server).\(key)" }

    // MARK: - Secret resolution (connect time only)

    private static func resolveSecrets(_ s: String) -> String {
        guard s.contains(placeholderPrefix) else { return s }
        var out = s
        while let start = out.range(of: placeholderPrefix),
              let end = out.range(of: "}", range: start.upperBound..<out.endIndex)
        {
            let account = String(out[start.upperBound..<end.lowerBound])
            out.replaceSubrange(start.lowerBound..<end.upperBound, with: KeychainService.shared.getMCPSecret(account) ?? "")
        }
        return out
    }

    /// Copy of `config` with Keychain placeholders replaced by their values. Never persist or log the result.
    static func resolved(_ config: MCPServerConfig) -> MCPServerConfig {
        var c = config
        c.environment = c.environment.mapValues(resolveSecrets)
        c.headers = c.headers.mapValues(resolveSecrets)
        c.arguments = c.arguments.map(resolveSecrets)
        return c
    }

    /// Keychain accounts referenced by a config's placeholders (for cleanup on remove).
    private static func referencedAccounts(_ config: MCPServerConfig) -> [String] {
        let values = Array(config.environment.values) + Array(config.headers.values) + config.arguments
        return values.compactMap { v in
            guard let start = v.range(of: placeholderPrefix),
                  let end = v.range(of: "}", range: start.upperBound..<v.endIndex) else { return nil }
            return String(v[start.upperBound..<end.lowerBound])
        }
    }

    // MARK: - Secure prompt

    /// App-modal prompt with one secure field per credential. Returns nil when cancelled.
    private static func promptSecrets(server: String, fields: [MCPSecretField]) -> [String]? {
        let alert = NSAlert()
        alert.messageText = "Connect \(server)"
        alert.informativeText = "Credentials are saved in your macOS Keychain and are never sent to the AI model or shown in chat."
        alert.addButton(withTitle: "Connect")
        alert.addButton(withTitle: "Cancel")

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        var inputs: [NSSecureTextField] = []
        for field in fields {
            let label = NSTextField(labelWithString: field.label + (field.optional ? "" : " *"))
            label.font = .boldSystemFont(ofSize: NSFont.smallSystemFontSize)
            let input = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 340, height: 24))
            input.placeholderString = field.key
            input.widthAnchor.constraint(equalToConstant: 340).isActive = true
            let help = NSTextField(wrappingLabelWithString: field.help)
            help.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            help.textColor = .secondaryLabelColor
            help.preferredMaxLayoutWidth = 340
            stack.addArrangedSubview(label)
            stack.addArrangedSubview(input)
            stack.addArrangedSubview(help)
            stack.setCustomSpacing(10, after: help)
            inputs.append(input)
        }
        stack.frame = NSRect(origin: .zero, size: stack.fittingSize)
        alert.accessoryView = stack
        alert.window.initialFirstResponder = inputs.first

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return inputs.map { $0.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    // MARK: - Install

    /// Install + connect. Returns a model-safe summary (no secret values).
    static func install(config base: MCPServerConfig, secrets: [MCPSecretField]) async -> String {
        let registry = MCPServerRegistry.shared
        if let existing = registry.servers.first(where: { $0.name.caseInsensitiveCompare(base.name) == .orderedSame }) {
            if MCPService.shared.connectedServerIds.contains(existing.id) {
                return "'\(existing.name)' is already installed and connected. \(toolSummary(existing))"
            }
            return await connect(existing, verb: "Already installed — reconnected")
        }

        var config = base
        if !secrets.isEmpty {
            guard let values = promptSecrets(server: config.name, fields: secrets) else {
                return "User cancelled the credential prompt — '\(config.name)' was not installed."
            }
            for (field, value) in zip(secrets, values) {
                if value.isEmpty {
                    if field.optional { continue }
                    return "Required credential '\(field.label)' was left blank — '\(config.name)' was not installed."
                }
                let account = keychainAccount(server: config.name, key: field.key)
                KeychainService.shared.setMCPSecret(account, value)
                let placeholder = placeholderPrefix + account + "}"
                switch field.target {
                case .env(let name): config.environment[name] = placeholder
                case .header(let name, let prefix): config.headers[name] = prefix + placeholder
                }
            }
        }

        if let error = registry.add(config) {
            return "Could not install '\(config.name)': \(error)"
                + (config.command == "npx" ? " (install Node.js: `brew install node`)" : "")
        }
        AuditLog.log(.mcp, "[MCPInstaller] Installed \(config.name)")
        return await connect(config, verb: "Installed")
    }

    private static func connect(_ config: MCPServerConfig, verb: String) async -> String {
        do {
            try await MCPService.shared.connect(to: config)
            return "\(verb) and connected '\(config.name)'. \(toolSummary(config)) Credentials (if any) are in the macOS Keychain and are not visible to you."
        } catch {
            MCPService.shared.connectionErrors[config.id] = error.localizedDescription
            return "\(verb) '\(config.name)' but connecting failed: \(error.localizedDescription). Check the credential or retry with action:connect."
        }
    }

    private static func toolSummary(_ config: MCPServerConfig) -> String {
        let tools = MCPService.shared.discoveredTools.filter { $0.serverId == config.id }.map { "mcp_\(config.name)_\($0.name)" }
        guard !tools.isEmpty else { return "No tools discovered yet." }
        let shown = tools.prefix(25).joined(separator: ", ")
        return "\(tools.count) tools available now: \(shown)\(tools.count > 25 ? ", …" : "")."
    }

    // MARK: - `mcp` tool

    static func handleTool(input: [String: Any]) async -> String {
        let action = (input["action"] as? String ?? "").lowercased()
        let server = input["server"] as? String ?? ""
        let registry = MCPServerRegistry.shared

        switch action {
        case "catalog":
            return MCPPresets.all.map { p in
                let creds = p.secrets.filter { !$0.optional }.map(\.label)
                return "\(p.id) — \(p.menuLabel)" + (creds.isEmpty ? " (no credentials)" : " (asks for: \(creds.joined(separator: ", ")))")
            }.joined(separator: "\n")

        case "list":
            guard !registry.servers.isEmpty else { return "No MCP servers installed." }
            return registry.servers.map { s in
                let state = MCPService.shared.connectedServerIds.contains(s.id) ? "connected" : (s.enabled ? "not connected" : "disabled")
                let count = MCPService.shared.discoveredTools.filter { $0.serverId == s.id }.count
                return "\(s.name) — \(state), \(count) tools — \(s.displayAddress)"
            }.joined(separator: "\n")

        case "add":
            let url = (input["url"] as? String ?? "").trimmingCharacters(in: .whitespaces)
            let command = (input["command"] as? String ?? "").trimmingCharacters(in: .whitespaces)
            if url.isEmpty && command.isEmpty {
                guard let preset = MCPPresets.match(server) else {
                    return "No preset matches '\(server)'. Presets:\n" + MCPPresets.all.map(\.id).joined(separator: ", ")
                        + "\nFor any other server pass name + url (HTTP) or command + args (stdio), and list credential names in secret_env / secret_headers."
                }
                return await install(config: preset.makeConfig(), secrets: preset.secrets)
            }
            let name = server.isEmpty ? (URL(string: url)?.host ?? command) : server
            let config = url.isEmpty
                ? MCPServerConfig(name: name, command: command, arguments: input["args"] as? [String] ?? [])
                : MCPServerConfig(name: name, url: url)
            let secrets = (input["secret_env"] as? [String] ?? []).map {
                MCPSecretField(target: .env($0), label: $0, help: "Value for environment variable \($0)")
            } + (input["secret_headers"] as? [String] ?? []).map {
                MCPSecretField(
                    target: .header($0, prefix: $0.caseInsensitiveCompare("Authorization") == .orderedSame ? "Bearer " : ""),
                    label: $0, help: $0.caseInsensitiveCompare("Authorization") == .orderedSame ? "Token only — \"Bearer \" is added for you" : "Value for HTTP header \($0)"
                )
            }
            return await install(config: config, secrets: secrets)

        case "connect":
            guard let s = registry.servers.first(where: { $0.name.caseInsensitiveCompare(server) == .orderedSame }) else {
                return "No installed server named '\(server)'. Use action:list."
            }
            await MCPService.shared.disconnect(serverId: s.id)
            return await connect(s, verb: "Reconnected")

        case "remove":
            guard let s = registry.servers.first(where: { $0.name.caseInsensitiveCompare(server) == .orderedSame }) else {
                return "No installed server named '\(server)'. Use action:list."
            }
            await MCPService.shared.disconnect(serverId: s.id)
            referencedAccounts(s).forEach { KeychainService.shared.deleteMCPSecret($0) }
            registry.remove(at: s.id)
            return "Removed '\(s.name)' and its stored credentials."

        default:
            return "Error: action must be catalog, list, add, connect, or remove."
        }
    }

    static let toolSchema: [String: Any] = [
        "name": "mcp",
        "description": "Install and manage MCP servers in one step. add: server:\"sentry\" (or linear, github, notion, stripe, context7, playwright… see catalog) installs the preset, securely prompts the user for any API key/token in a native dialog (stored in Keychain, never shown to you), and connects immediately — its mcp_<Server>_* tools are usable on your next turn, no restart. NEVER ask the user to paste keys/tokens into chat; this tool collects them. Custom server: add with server name + url (HTTP) or command + args (stdio), and list credential names in secret_env/secret_headers.",
        "input_schema": [
            "type": "object",
            "properties": [
                "action": ["type": "string", "enum": ["catalog", "list", "add", "connect", "remove"], "description": "catalog = known presets; list = installed servers; add = install + connect; connect = reconnect; remove = uninstall + delete its Keychain credentials."],
                "server": ["type": "string", "description": "Preset id/name (\"sentry\", \"linear\") or the server name for custom/connect/remove."],
                "url": ["type": "string", "description": "Custom HTTP MCP endpoint (add)."],
                "command": ["type": "string", "description": "Custom stdio command, e.g. npx (add)."],
                "args": ["type": "array", "items": ["type": "string"], "description": "Arguments for command (add)."],
                "secret_env": ["type": "array", "items": ["type": "string"], "description": "Env var names the user must supply securely (add, stdio)."],
                "secret_headers": ["type": "array", "items": ["type": "string"], "description": "HTTP header names the user must supply securely, e.g. Authorization (add, HTTP)."],
            ] as [String: Any],
            "required": ["action"],
        ] as [String: Any],
    ]
}
