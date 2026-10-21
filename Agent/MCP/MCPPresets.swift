import Foundation

/// A credential an MCP preset needs (API key, PAT, access token). Collected by `MCPInstaller` in a native
/// secure field, stored in the Keychain, and referenced from the saved config only as a `${keychain:…}`
/// placeholder — the value never enters the chat, the LLM context, or mcp_servers.json.
struct MCPSecretField: Sendable {
    enum Target: Sendable {
        /// Stdio server environment variable.
        case env(String)
        /// HTTP header; `prefix` is prepended to the secret (e.g. "Bearer ").
        case header(String, prefix: String)
    }

    let target: Target
    let label: String
    /// Where the user gets the credential — shown under the secure field.
    let help: String
    var optional: Bool = false

    /// Env var or header name this secret fills.
    var key: String {
        switch target {
        case .env(let name): return name
        case .header(let name, _): return name
        }
    }
}

/// / Curated MCP server presets — one-click add from the MCP menu, or by asking the agent ("add sentry mcp server")
/// via the `mcp` tool. / / To add a preset: append `MCPPreset` to `all` with unique id, label, `keywords`, `secrets`
/// and `makeConfig()`.
struct MCPPreset: Identifiable {
    let id: String
    let menuLabel: String
    /// Lowercase words that match a natural-language request ("sentry", "linear", "github").
    var keywords: [String] = []
    /// Credentials collected securely at install time. Empty → no prompt.
    var secrets: [MCPSecretField] = []
    let makeConfig: () -> MCPServerConfig
}

@MainActor
enum MCPPresets {
    /// / Curated MCP server presets. The Z.AI Web Search preset / was removed 2026-04-08 because
    /// Z.AI's MCP server returns truncated tools/list / JSON (unbalanced braces, mid-character cutoff). Use `web_search` tool via / Settings → Z.AI API key instead (see performZAIWebSearchInternal). / Re-enable only after Z.AI fixes their MCP server.
    static let all: [MCPPreset] = [
        MCPPreset(id: "xcf", menuLabel: "xcf.ai — Xcode Build & Run", keywords: ["xcf", "xcode"]) {
            MCPServerConfig(
                name: "xcf",
                command: "/Applications/xcf.app/Contents/MacOS/xcf server"
            )
        },
        MCPPreset(id: "parallel.search", menuLabel: "Parallel Search — Web Search & Fetch", keywords: ["parallel"]) {
            MCPServerConfig(
                name: "Parallel Search",
                url: "https://search.parallel.ai/mcp"
            )
        },
        MCPPreset(id: "cohesivity", menuLabel: "Cohesivity — Postgres, Hosting & Storage", keywords: ["cohesivity"]) {
            MCPServerConfig(
                name: "Cohesivity",
                url: "https://cohesivity.ai/mcp"
            )
        },
        MCPPreset(id: "keenable.search", menuLabel: "Keenable Search — Web Search & Fetch", keywords: ["keenable"]) {
            MCPServerConfig(
                name: "Keenable Search",
                url: "https://api.keenable.ai/mcp",
                headers: ["X-Keenable-Title": "Agent!"]
            )
        },
        MCPPreset(
            id: "sentry",
            menuLabel: "Sentry — Issues, Errors & Releases",
            keywords: ["sentry"],
            secrets: [
                MCPSecretField(
                    target: .env("SENTRY_ACCESS_TOKEN"),
                    label: "Sentry User Auth Token",
                    help: "sentry.io → Settings → Account → API → User Auth Tokens (scopes: org:read, project:read/write, team:read, event:write)"
                ),
                MCPSecretField(
                    target: .env("SENTRY_HOST"),
                    label: "Self-hosted Sentry host (optional)",
                    help: "Leave blank for sentry.io. Example: sentry.example.com",
                    optional: true
                ),
            ]
        ) {
            MCPServerConfig(
                name: "Sentry",
                command: "npx",
                arguments: ["-y", "@sentry/mcp-server@latest"]
            )
        },
        MCPPreset(
            id: "linear",
            menuLabel: "Linear — Issues, Projects & Cycles",
            keywords: ["linear"],
            secrets: [
                MCPSecretField(
                    target: .header("Authorization", prefix: "Bearer "),
                    label: "Linear API Key",
                    help: "linear.app → Settings → Security & access → Personal API keys"
                ),
            ]
        ) {
            MCPServerConfig(name: "Linear", url: "https://mcp.linear.app/mcp")
        },
        MCPPreset(
            id: "github",
            menuLabel: "GitHub — Repos, Issues & Pull Requests",
            keywords: ["github", "gh"],
            secrets: [
                MCPSecretField(
                    target: .header("Authorization", prefix: "Bearer "),
                    label: "GitHub Personal Access Token",
                    help: "github.com → Settings → Developer settings → Personal access tokens"
                ),
            ]
        ) {
            MCPServerConfig(name: "GitHub", url: "https://api.githubcopilot.com/mcp/")
        },
        MCPPreset(
            id: "notion",
            menuLabel: "Notion — Pages, Databases & Search",
            keywords: ["notion"],
            secrets: [
                MCPSecretField(
                    target: .env("NOTION_TOKEN"),
                    label: "Notion Integration Token",
                    help: "notion.so/profile/integrations → New integration → Internal Integration Secret (ntn_…)"
                ),
            ]
        ) {
            MCPServerConfig(
                name: "Notion",
                command: "npx",
                arguments: ["-y", "@notionhq/notion-mcp-server"]
            )
        },
        MCPPreset(
            id: "stripe",
            menuLabel: "Stripe — Payments, Customers & Billing",
            keywords: ["stripe"],
            secrets: [
                MCPSecretField(
                    target: .header("Authorization", prefix: "Bearer "),
                    label: "Stripe Secret or Restricted Key",
                    help: "dashboard.stripe.com → Developers → API keys (a restricted key is safer)"
                ),
            ]
        ) {
            MCPServerConfig(name: "Stripe", url: "https://mcp.stripe.com")
        },
        MCPPreset(id: "context7", menuLabel: "Context7 — Up-to-date Library Docs", keywords: ["context7", "context 7"]) {
            MCPServerConfig(name: "Context7", url: "https://mcp.context7.com/mcp")
        },
        MCPPreset(id: "playwright", menuLabel: "Playwright — Browser Automation", keywords: ["playwright"]) {
            MCPServerConfig(
                name: "Playwright",
                command: "npx",
                arguments: ["-y", "@playwright/mcp@latest"]
            )
        },
    ]

    /// Find a preset by id, server name, or keyword contained in a free-form request.
    static func match(_ query: String) -> MCPPreset? {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return nil }
        if let exact = all.first(where: { $0.id == q || $0.makeConfig().name.lowercased() == q }) { return exact }
        let words = Set(q.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))
        return all.first { preset in preset.keywords.contains { words.contains($0) || ($0.contains(" ") && q.contains($0)) } }
    }
}
