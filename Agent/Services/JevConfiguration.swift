import Foundation
import TypeSafeKit
import TypeSafeMiddleware

/// What Agent! owns about Jev: the endpoint, the credential, the chosen model
/// and whether the advisory gate is on.
///
/// Everything else — the wire format, retry/backoff, the typed Question/Answer
/// model and the decision helpers — lives in the TypeSafeKit package. Nothing
/// in the app builds a request or parses a response.
enum JevConfiguration {

    // MARK: - Endpoint (app-owned)

    /// TypeSafe's production host. Overridable per install for staging.
    static let defaultBaseURL = TypeSafeConstants.defaultBaseURL
    static let baseURLDefaultsKey = "jevBaseURL"

    static var baseURL: URL {
        let stored = UserDefaults.standard.string(forKey: baseURLDefaultsKey) ?? ""
        return URL(string: stored) ?? defaultBaseURL
    }

    // MARK: - Credential (app-owned)

    static var apiKey: String {
        (KeychainService.shared.get(.jev) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Jev is only consulted once the user has pasted a key.
    static var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Model

    static let defaultModel = Model.jevLatest
    static let modelDefaultsKey = "jevModel"

    static var model: String {
        let stored = UserDefaults.standard.string(forKey: modelDefaultsKey) ?? ""
        return stored.isEmpty ? defaultModel : stored
    }

    // MARK: - Advisory toggle

    static let advisoryDefaultsKey = "jevAdvisoryEnabled"

    /// Read nonisolated so the tool loop can check it without hopping actors.
    static var advisoryEnabled: Bool {
        UserDefaults.standard.bool(forKey: advisoryDefaultsKey)
    }

    // MARK: - Provider

    /// The package's decision layer, wired to this app's endpoint and key.
    /// `nil` when no key is set — callers treat that as "no opinion".
    static func provider() -> JevProvider? {
        try? JevProvider(apiKey: apiKey, baseURL: baseURL, model: model)
    }
}
