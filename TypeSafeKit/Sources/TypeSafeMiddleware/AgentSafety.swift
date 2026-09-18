// Decisions an autonomous agent loop asks about its own actions, before it
// takes them. The question wording, criteria and thresholds live here so a host
// app never has to construct a `Question` or know the wire vocabulary — it asks
// "how risky is this command?" and gets a number back.

import Foundation
import TypeSafeKit

/// Jev's opinion on a single proposed shell command.
public struct CommandRisk: Sendable, Hashable {
    /// Probability that running the command irreversibly destroys data, 0...1.
    public let destructive: Double
    /// The probability above which the caller said it would refuse.
    public let threshold: Double

    public var isBlocked: Bool { destructive > threshold }
    /// `destructive` as a whole percentage, for log lines and refusal messages.
    public var percent: Int { Int((destructive * 100).rounded()) }
}

extension DecisionProvider {

    /// Second opinion on a shell command that already passed the host's own
    /// pattern-based safety rules. Deliberately one Noul question: the pattern
    /// rules stay the enforcement layer, this only catches what they miss.
    ///
    /// - Parameter threshold: probability above which `isBlocked` is true.
    ///   High by default — a model's guess should not veto a borderline command.
    public func commandRisk(
        command: String,
        workingDirectory: String? = nil,
        threshold: Double = 0.9,
        id: String = "destructive"
    ) async throws -> CommandRisk {
        let state = State([
            "working_directory": .string(workingDirectory.flatMap { $0.isEmpty ? nil : $0 } ?? "(none)"),
            "shell_command": .string(command)
        ])

        let gate = try await gate(
            state,
            statement: "Running shell_command would irreversibly destroy the user's data or render their system unbootable.",
            threshold: threshold,
            criteria: NoulCriteria(
                yes: "Deletes, overwrites or formats data that cannot be recovered, or breaks the OS install",
                no: "Reversible, read-only, or scoped to build artifacts and temporary files"),
            id: id)

        return CommandRisk(destructive: gate.probability, threshold: threshold)
    }
}
