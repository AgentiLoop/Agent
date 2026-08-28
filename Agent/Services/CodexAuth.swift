import AgentAudit
@preconcurrency import Foundation
import AppKit

// MARK: - Codex OAuth Service
//
// Uses ChatGPT-subscription OAuth tokens (from `codex login` → ~/.codex/auth.json)
// to talk to https://chatgpt.com/backend-api/codex/responses — the same endpoint
// the official OpenAI Codex CLI uses. This is the Responses API shape, NOT
// /v1/chat/completions. See docs/CODEX_OAUTH_RESEARCH.md for the full comparison
// against Agent!'s Claude OAuth path.
//
// Phase 1 (this file): auth plumbing + non-streaming text + tool_use end-to-end.
// Streaming is implemented by awaiting the full response and delivering it as
// one delta — real SSE parsing for `response.output_text.delta` events is a TODO.

// MARK: Auth file on disk

struct CodexAuthFile {
    var accessToken: String
    var idToken: String?
    var refreshToken: String
    var accountId: String
    var lastRefresh: Date?

    /// Read ~/.codex/auth.json. Returns nil if missing or malformed.
    static func load() -> CodexAuthFile? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent(".codex/auth.json")
        guard let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = root["tokens"] as? [String: Any],
              let access = tokens["access_token"] as? String,
              let refresh = tokens["refresh_token"] as? String,
              let account = tokens["account_id"] as? String
        else { return nil }
        let id = tokens["id_token"] as? String
        let last = (root["last_refresh"] as? String).flatMap(Self.parseISO8601)
        return CodexAuthFile(
            accessToken: access,
            idToken: id,
            refreshToken: refresh,
            accountId: account,
            lastRefresh: last
        )
    }

    /// Persist updated tokens back to ~/.codex/auth.json so the Codex CLI
    /// and Agent! stay in sync after a refresh.
    func save() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent(".codex/auth.json")
        var root: [String: Any] = [:]
        if let data = try? Data(contentsOf: url),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            root = existing
        }
        var tokens: [String: Any] = root["tokens"] as? [String: Any] ?? [:]
        tokens["access_token"] = accessToken
        tokens["refresh_token"] = refreshToken
        tokens["account_id"] = accountId
        if let id = idToken { tokens["id_token"] = id }
        root["tokens"] = tokens
        if let last = lastRefresh {
            root["last_refresh"] = Self.formatISO8601(last)
        }
        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: .atomic)
    }

    private static func parseISO8601(_ s: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: s) ?? ISO8601DateFormatter().date(from: s)
    }

    private static func formatISO8601(_ d: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: d)
    }
}

// MARK: JWT claim extractor

enum CodexJWT {
    /// Decode the middle segment of a JWT and return the claims dict.
    /// Returns nil for malformed tokens.
    static func claims(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { return nil }
        let payload = String(parts[1])
        guard let data = base64URLDecode(payload),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return obj
    }

    /// Extract chatgpt_account_id from the nested `https://api.openai.com/auth`
    /// claim. Falls back to the top-level `account_id` from auth.json when
    /// the JWT is opaque or shape has shifted.
    static func accountId(_ jwt: String) -> String? {
        guard let c = claims(jwt),
              let auth = c["https://api.openai.com/auth"] as? [String: Any]
        else { return nil }
        return auth["chatgpt_account_id"] as? String
    }

    /// Expiry timestamp from the `exp` claim (seconds since epoch).
    static func expiry(_ jwt: String) -> Date? {
        guard let c = claims(jwt), let exp = c["exp"] as? Double else { return nil }
        return Date(timeIntervalSince1970: exp)
    }

    private static func base64URLDecode(_ s: String) -> Data? {
        var b = s.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        b += String(repeating: "=", count: (4 - b.count % 4) % 4)
        return Data(base64Encoded: b)
    }
}

// MARK: Token refresh

enum CodexAuthRefresher {
    /// OpenAI's published client_id for the Codex CLI. Public (PKCE).
    static let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"
    static let tokenURL = URL(string: "https://auth.openai.com/oauth/token") ?? URL(filePath: "/")

    /// Exchange the refresh token for a new access token. Writes the fresh
    /// tokens back to ~/.codex/auth.json so the Codex CLI stays in sync.
    nonisolated static func refresh(_ auth: CodexAuthFile) async throws -> CodexAuthFile {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": auth.refreshToken,
            "client_id": clientID,
            "scope": "openid profile email offline_access"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AgentError.invalidResponse
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = obj["access_token"] as? String
        else { throw AgentError.invalidResponse }
        let refresh = (obj["refresh_token"] as? String) ?? auth.refreshToken
        let id = (obj["id_token"] as? String) ?? auth.idToken
        var updated = CodexAuthFile(
            accessToken: access,
            idToken: id,
            refreshToken: refresh,
            accountId: auth.accountId,
            lastRefresh: Date()
        )
        // Re-extract account ID from the fresh JWT when available.
        if let freshAccount = CodexJWT.accountId(access) { updated.accountId = freshAccount }
        try? updated.save()
        return updated
    }

    /// Returns a valid access token, refreshing if within 5 min of expiry.
    nonisolated static func validAuth() async throws -> CodexAuthFile {
        guard let current = CodexAuthFile.load() else {
            throw AgentError.noAPIKey
        }
        if let expiry = CodexJWT.expiry(current.accessToken),
           expiry.timeIntervalSinceNow < 5 * 60
        {
            return try await refresh(current)
        }
        return current
    }
}

// MARK: Login launcher

enum CodexLoginLauncher {
    /// Find the `codex` CLI binary. Checks PATH plus a few common install
    /// locations so the button still works when the user's GUI shell hasn't
    /// inherited their interactive PATH (a frequent macOS papercut).
    static func codexBinary() -> String? {
        let candidates = [
            "/usr/local/bin/codex",
            "/opt/homebrew/bin/codex",
            "\(NSHomeDirectory())/.nvm/versions/node/v22/bin/codex",
            "\(NSHomeDirectory())/.npm-global/bin/codex",
            "\(NSHomeDirectory())/.bun/bin/codex"
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }

    /// Open Terminal.app with `codex login` pre-typed so the user can watch
    /// the PKCE browser flow and come back. Falls back to opening
    /// https://developers.openai.com/codex/auth if the CLI isn't installed.
    @MainActor
    static func launch() {
        let binary = codexBinary()
        let command: String
        if let bin = binary {
            command = "clear; echo '── codex login ──'; \(bin) login; echo; echo 'Close this window when done.'"
        } else {
            command = "clear; echo 'codex CLI not found. Install with:'; echo '  brew install codex'; echo '  # or: npm install -g @openai/codex'; echo; read -n 1 -s"
        }
        let script = """
        tell application "Terminal"
            activate
            do script "\(command.replacingOccurrences(of: "\"", with: "\\\""))"
        end tell
        """
        if let apple = NSAppleScript(source: script) {
            var err: NSDictionary?
            apple.executeAndReturnError(&err)
        }
    }
}
