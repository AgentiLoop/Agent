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
        guard isAdvising else { return nil }

        // The usage callback fires before the verdict exists, so park it here
        // and log both together — a bare "Jev answered" says nothing about
        // what Jev decided.
        let meter = JevUsageMeter()
        guard let provider = JevConfiguration.provider(onUsage: { model, usage in
            meter.record(model: model, usage: usage)
        }) else { return nil }

        let risk: CommandRisk
        do {
            risk = try await provider.commandRisk(
                command: command,
                workingDirectory: workingDirectory,
                threshold: destructiveBlockThreshold)
        } catch {
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                return "Command cancelled during Jev check."
            }
            // Still fail-open, but never silently: an expired key or a network
            // outage would otherwise be indistinguishable from "Jev says safe".
            JevConfiguration.report("⚠️ Jev check failed, command allowed: \(error.localizedDescription)")
            return nil
        }
        guard !Task.isCancelled else { return "Command cancelled during Jev check." }

        let verdict = risk.isBlocked ? "REFUSED" : "allowed"
        JevConfiguration.report(
            "🔒 Jev: \(risk.percent)% destructive — \(verdict): \(summarize(command))\(meter.suffix)")
        guard risk.isBlocked else { return nil }

        return """
        Refused: Jev rated this command \(risk.percent)% likely to irreversibly destroy data.
        Command: \(command)
        Narrow the target or run it yourself if this is intentional. \
        (Turn off "Consult Jev before tools" in Settings to disable this gate.)
        """
    }

    /// One-line form of a command for the activity log.
    private static func summarize(_ command: String) -> String {
        let flat = command.split(whereSeparator: \.isNewline)
            .joined(separator: " ⏎ ")
            .trimmingCharacters(in: .whitespaces)
        return flat.count > 70 ? String(flat.prefix(70)) + "…" : flat
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

/// Holds the token usage of the single request a `JevAdvisor` helper makes, so
/// the verdict line can carry its cost. Locked because the package calls
/// `onUsage` from whatever thread finished the request.
private final class JevUsageMeter: @unchecked Sendable {
    private let lock = NSLock()
    private var text = ""

    func record(model: String, usage: Usage) {
        lock.lock()
        defer { lock.unlock() }
        text = " (\(model), \(usage.inputTokens) in / \(usage.outputTokens) out)"
    }

    var suffix: String {
        lock.lock()
        defer { lock.unlock() }
        return text
    }
}
