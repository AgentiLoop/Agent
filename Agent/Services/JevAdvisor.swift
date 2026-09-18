import Foundation

/// Domain-specific Jev questions Agent! asks about its own actions.
///
/// Every helper is fail-open: it returns `nil` when Jev is unconfigured, the
/// advisory toggle is off, or the call errors. Call sites treat `nil` as "no
/// opinion" and keep their existing behaviour, so a Jev outage can never stall
/// the tool loop.
extension JevService {

    /// UserDefaults key written by `AgentViewModel.jevAdvisoryEnabled`.
    static let advisoryDefaultsKey = "jevAdvisoryEnabled"

    /// Read nonisolated so `executeTCC` and friends can check it without hopping
    /// to the main actor.
    static var advisoryEnabled: Bool {
        UserDefaults.standard.bool(forKey: advisoryDefaultsKey)
    }

    var isAdvising: Bool { Self.advisoryEnabled && isConfigured }

    /// Probability threshold above which Jev's "this destroys data" answer
    /// overrides the command. Deliberately high — `ShellSafetyService` is the
    /// enforcement layer; Jev only catches what the pattern rules miss.
    static let destructiveBlockThreshold = 0.9

    /// Second-opinion gate for a shell command that already passed
    /// `ShellSafetyService.check`. Returns a block reason, or `nil` to allow.
    func shellBlockReason(command: String, workingDirectory: String) async -> String? {
        guard isAdvising else { return nil }

        let state: [String: Any] = [
            "working_directory": workingDirectory.isEmpty ? "(none)" : workingDirectory,
            "shell_command": command
        ]

        guard let response = try? await ask(state: state, questions: [
            "destructive": .noul(
                instructions: "Running shell_command would irreversibly destroy the user's data or render their system unbootable.",
                yes: "Deletes, overwrites or formats data that cannot be recovered, or breaks the OS install",
                no: "Reversible, read-only, or scoped to build artifacts and temporary files"
            )
        ]) else { return nil }

        guard let destructive = response.answers["destructive"]?.noulValue,
              destructive > Self.destructiveBlockThreshold
        else { return nil }

        return """
        Refused: Jev rated this command \(Int(destructive * 100))% likely to irreversibly destroy data.
        Command: \(command)
        Narrow the target or run it yourself if this is intentional. \
        (Turn off "Consult Jev before tools" in Settings to disable this gate.)
        """
    }
}
