import AgentAudit
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

    // MARK: - Block threshold

    static let blockThresholdDefaultsKey = "jevBlockThreshold"

    /// Default cut-off: Jev only overrides a command it rates 90%+ destructive.
    /// `ShellSafetyService` is the enforcement layer; Jev catches the rest.
    static let defaultBlockThreshold = 0.9

    /// Probability above which Jev's "this destroys data" answer blocks the
    /// command, 0.0–1.0. Settings stores it in 10% steps. An unset key reads as
    /// 0, so absence falls back to the default instead of blocking everything.
    static var blockThreshold: Double {
        guard UserDefaults.standard.object(forKey: blockThresholdDefaultsKey) != nil else {
            return defaultBlockThreshold
        }
        let stored = UserDefaults.standard.double(forKey: blockThresholdDefaultsKey)
        return min(max(stored, 0), 1)
    }

    // MARK: - Activity reporting

    /// Jev is consulted from the nonisolated tool loop, where there is no
    /// AgentViewModel to call, so every Jev event is broadcast instead: the
    /// view model appends it to the activity log, and it is mirrored into the
    /// audit log for Console.app.
    nonisolated static func report(_ message: String) {
        AuditLog.log(.api, message)
        NotificationCenter.default.post(
            name: .jevActivity, object: nil, userInfo: ["message": message])
    }

    // MARK: - Provider

    /// The package's decision layer, wired to this app's endpoint and key.
    /// `nil` when no key is set — callers treat that as "no opinion".
    /// A caller that knows what it asked supplies its own `onUsage` so it can
    /// log the verdict and the token cost as one line; the default callback
    /// only proves that Jev ran.
    static func provider(
        onUsage: (@Sendable (String, Usage) -> Void)? = nil
    ) -> JevProvider? {
        let sink = onUsage ?? { answeringModel, usage in
            report("🔒 Jev answered via \(answeringModel) — \(usage.inputTokens) in / \(usage.outputTokens) out tokens")
        }
        return try? JevProvider(apiKey: apiKey, baseURL: baseURL, model: model, onUsage: sink)
    }

}
