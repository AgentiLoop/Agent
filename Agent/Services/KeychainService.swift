import Foundation
import Security
import AgentAudit

/// Secure credential storage using the macOS data protection keychain.
/// No password prompts across rebuilds.
final class KeychainService: Sendable {
    static let shared = KeychainService()

    private init() {}

    /// Non-provider credentials, keyed by their exact legacy keychain account
    /// string so existing stored keys keep working. Provider API keys are
    /// addressed by `APIProvider.keychainAccount` instead.
    enum APIKey: String, CaseIterable, Sendable {
        case tavily = "agent.tavilyAPIKey"
        case exa = "com.agent.exa-api-key"
    }

    func set(_ apiKey: APIKey, _ value: String) { set(key: apiKey.rawValue, value: value) }
    func get(_ apiKey: APIKey) -> String? { get(key: apiKey.rawValue) }

    func set(_ provider: APIProvider, _ value: String) { set(key: provider.keychainAccount, value: value) }
    func get(_ provider: APIProvider) -> String? { get(key: provider.keychainAccount) }


    private func set(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "Agent!",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecUseDataProtectionKeychain as String: true
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess && status != errSecDuplicateItem {
            AuditLog.log(.keychain, "KeychainService: Failed to store \(key): \(status)")
        }
    }

    private func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "Agent!",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else
        {
            return nil
        }
        return value
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "Agent!",
            kSecUseDataProtectionKeychain as String: true
        ]
        SecItemDelete(query as CFDictionary)
    }
}
