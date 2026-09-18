import Foundation
import TypeSafeKit
import TypeSafeMiddleware

/// The questions Agent! asks Jev about its own actions.
///
/// Thin by design: `TypeSafeMiddleware` owns the question wording, the criteria
/// and the answer decoding; this type only decides *when* to ask and turns the
/// package's verdict into an Agent!-flavoured refusal string.
///
/// Every helper is fail-open — `nil` means "no opinion", so an unconfigured key
/// or a TypeSafe outage can never stall the tool loop.
enum JevAdvisor {

    static var isAdvising: Bool {
        JevConfiguration.advisoryEnabled && JevConfiguration.isConfigured
    }

    /// Probability above which Jev's "this destroys data" answer overrides the
    /// command. Deliberately high — `ShellSafetyService` is the enforcement
    /// layer; Jev only catches what the pattern rules miss.
    static let destructiveBlockThreshold = 0.9

    /// Second-opinion gate for a shell command that already passed
    /// `ShellSafetyService.check`. Returns a refusal reason, or `nil` to allow.
    static func shellBlockReason(command: String, workingDirectory: String) async -> String? {
        guard isAdvising, let provider = JevConfiguration.provider() else { return nil }

        guard let risk = try? await provider.commandRisk(
            command: command,
            workingDirectory: workingDirectory,
            threshold: destructiveBlockThreshold),
            risk.isBlocked
        else { return nil }

        return """
        Refused: Jev rated this command \(risk.percent)% likely to irreversibly destroy data.
        Command: \(command)
        Narrow the target or run it yourself if this is intentional. \
        (Turn off "Consult Jev before tools" in Settings to disable this gate.)
        """
    }

    /// `GET /v1/models` — the names this account may send. Throws so Settings
    /// can show why a fetch failed.
    static func availableModels() async throws -> [ModelCard] {
        guard let provider = JevConfiguration.provider() else {
            throw TypeSafeError.missingAPIKey
        }
        return try await provider.availableModels()
    }
}
