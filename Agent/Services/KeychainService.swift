import Foundation
import Security
import AgentAudit

/// Secure credential storage using the macOS data protection keychain.
/// No password prompts across rebuilds.
final class KeychainService: Sendable {
    static let shared = KeychainService()

    private init() {}

    /// Every stored credential, keyed by its exact legacy keychain account
    /// string so existing stored keys keep working.
    enum APIKey: String, CaseIterable, Sendable {
        case claude = "agent.claudeAPIKey"
        case ollama = "agent.ollamaAPIKey"
        case tavily = "agent.tavilyAPIKey"
        case openAI = "agent.openAIAPIKey"
        case deepSeek = "agent.deepSeekAPIKey"
        case huggingFace = "agent.huggingFaceAPIKey"
        case vLLM = "agent.vLLMAPIKey"
        case zAI = "com.agent.zai-api-key"
        case gemini = "com.agent.gemini-api-key"
        case grok = "com.agent.grok-api-key"
        case mistral = "com.agent.mistral-api-key"
        case codestral = "com.agent.codestral-api-key"
        case vibe = "com.agent.vibe-api-key"
        case bigModel = "com.agent.bigmodel-api-key"
        case qwen = "com.agent.qwen-api-key"
        case miniMax = "com.agent.minimax-api-key"
        case openRouter = "com.agent.openrouter-api-key"
        case exa = "com.agent.exa-api-key"
        case lmStudio = "com.agent.lmstudio-api-key"
    }

    func set(_ apiKey: APIKey, _ value: String) { set(key: apiKey.rawValue, value: value) }
    func get(_ apiKey: APIKey) -> String? { get(key: apiKey.rawValue) }

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
