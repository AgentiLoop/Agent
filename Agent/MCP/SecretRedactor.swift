import Foundation

/// Strips API keys/tokens out of a user prompt BEFORE it reaches the LLM, chat history, prompt history or the
/// activity log. Each detected value is moved into the Keychain under `mcp.pasted.<kind>` and replaced with a
/// readable marker. `MCPInstaller` pre-fills its secure prompt from that entry, so "add sentry mcp server
/// sntryu_…" still works — the user just clicks Connect, and the token never leaves the Mac's Keychain.
enum SecretRedactor {
    /// (kind, display name, regex). Kind matches an MCP preset id where one exists.
    private static let patterns: [(kind: String, name: String, regex: String)] = [
        ("sentry", "Sentry token", #"sntry[us]_[A-Za-z0-9+/=_\-]{20,}"#),
        ("linear", "Linear API key", #"lin_(?:api|oauth)_[A-Za-z0-9]{20,}"#),
        ("github", "GitHub token", #"github_pat_[A-Za-z0-9_]{40,}|gh[pousr]_[A-Za-z0-9]{30,}"#),
        ("notion", "Notion token", #"ntn_[A-Za-z0-9]{30,}|secret_[A-Za-z0-9]{40,}"#),
        ("stripe", "Stripe key", #"[sr]k_(?:live|test)_[A-Za-z0-9]{20,}"#),
        ("anthropic", "Anthropic API key", #"sk-ant-[A-Za-z0-9_\-]{20,}"#),
        ("openai", "OpenAI API key", #"sk-(?:proj-)?[A-Za-z0-9_\-]{30,}"#),
        ("gitlab", "GitLab token", #"glpat-[A-Za-z0-9_\-]{20,}"#),
        ("slack", "Slack token", #"xox[abpr]-[A-Za-z0-9\-]{10,}"#),
        ("aws", "AWS access key", #"AKIA[0-9A-Z]{16}"#),
        ("google", "Google API key", #"AIza[0-9A-Za-z_\-]{35}"#),
    ]

    static func pastedAccount(_ kind: String) -> String { "mcp.pasted.\(kind.lowercased())" }

    /// Returns the prompt with secrets replaced, plus the display names of what was removed.
    static func redact(_ text: String) -> (text: String, removed: [String]) {
        var out = text
        var removed: [String] = []
        for p in patterns {
            guard let re = try? NSRegularExpression(pattern: p.regex) else { continue }
            let ns = out as NSString
            let matches = re.matches(in: out, range: NSRange(location: 0, length: ns.length))
            guard !matches.isEmpty else { continue }
            // Replace back-to-front so earlier ranges stay valid.
            for m in matches.reversed() {
                let value = ns.substring(with: m.range)
                KeychainService.shared.setMCPSecret(pastedAccount(p.kind), value)
                out = (out as NSString).replacingCharacters(
                    in: m.range,
                    with: "[\(p.name) removed — stored in macOS Keychain, not visible to the AI]"
                )
                removed.append(p.name)
            }
        }
        return (out, removed)
    }

    /// Log line for the user (never contains a value).
    static func notice(_ removed: [String]) -> String {
        "🔒 Kept \(removed.count) secret(s) out of the chat (\(Set(removed).sorted().joined(separator: ", "))) — "
            + "saved to the macOS Keychain; the AI only sees a placeholder."
    }
}
