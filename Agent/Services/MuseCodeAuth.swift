import Foundation
import AppKit
import Security

// MARK: - Muse Code Auth
//
// Reuses the credential that `muse login` (Meta's Muse Code CLI) provisions for the
// signed-in Meta Model API account — the subscription-bound `LLM|…` key — the same way
// Agent! reuses Claude Code OAuth tokens and `codex login` (~/.codex/auth.json).
// The key is stable (no refresh flow) and works against https://api.meta.ai/v1.
//
// Storage, checked in order:
//   1. ~/.config/muse/auth.json (or $XDG_CONFIG_HOME/muse/auth.json)
//   2. login keychain, service "ai.meta.dev.credentials", account "meta"
// Both hold JSON like {"secret_schema_version":1,"api_key":"LLM|…","access_token":"…"};
// only `api_key` is an inference credential.

@MainActor
enum MuseCodeAuth {
    static let keychainService = "ai.meta.dev.credentials"
    static let keychainAccount = "meta"

    /// Cached after the first successful read so the keychain prompt shows once per launch.
    private static var cachedKey: String?

    static var authFileURL: URL {
        if let xdg = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"], !xdg.isEmpty {
            return URL(fileURLWithPath: xdg).appendingPathComponent("muse/auth.json")
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/muse/auth.json")
    }

    /// The Muse Code login API key, or "" when not signed in.
    static func apiKey() -> String {
        if let cachedKey { return cachedKey }
        let key = keyFromFile() ?? keyFromKeychain() ?? ""
        if !key.isEmpty { cachedKey = key }
        return key
    }

    /// True when a `muse login` credential exists. Never reads the secret, so it
    /// doesn't trigger the keychain access prompt.
    static var isSignedIn: Bool {
        if cachedKey != nil || keyFromFile() != nil { return true }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    /// Forget the cached key (after Sign In Again / sign out).
    static func reset() { cachedKey = nil }

    private static func keyFromFile() -> String? {
        guard let data = try? Data(contentsOf: authFileURL) else { return nil }
        return parseKey(data)
    }

    private static func keyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return parseKey(data)
    }

    /// Extract `api_key` from the stored JSON payload.
    nonisolated static func parseKey(_ data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let key = obj["api_key"] as? String else { return nil }
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: Login launcher

    /// Find the `muse` binary (installer puts it in ~/.local/bin, which GUI apps don't have on PATH).
    static func museBinary() -> String? {
        let candidates = [
            "\(NSHomeDirectory())/.local/bin/muse",
            "/usr/local/bin/muse",
            "/opt/homebrew/bin/muse"
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Open Terminal with `muse login` so the user can finish the device-code flow.
    /// If the CLI isn't installed, shows the official install command instead.
    static func launchLogin() {
        reset()
        let command: String
        if let bin = museBinary() {
            command = "clear; echo '── muse login ──'; \(bin) login; echo; echo 'Close this window when done.'"
        } else {
            command = "clear; echo 'muse CLI not found. Install with:'; echo '  curl -fsSL https://dev.meta.ai/install.sh | bash'; echo; read -n 1 -s"
        }
        let script = """
        tell application "Terminal"
            activate
            do script "\(command.replacingOccurrences(of: "\"", with: "\\\""))"
        end tell
        """
        var err: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&err)
    }
}
