import Foundation
import Security
import AgentAudit

/// Client authentication for the XPC listeners. SMAppService only gates who
/// may INSTALL/register a helper — once the mach service is up, launchd lets
/// any local process connect, so the helper must validate peers itself.
///
/// Instead of hardcoding a Development Team, the requirement is derived at
/// runtime from this process's own code signature: accept only clients signed
/// by the same team that signed me.
enum XPCClientTrust {

    /// Designated requirement string for same-team clients, or nil when this
    /// process has no team identifier (ad-hoc/unsigned dev builds — which
    /// SMAppService refuses to register anyway).
    static func sameTeamRequirement() -> String? {
        guard let team = selfTeamIdentifier() else { return nil }
        return "anchor apple generic and certificate leaf[subject.OU] = \"\(team)\""
    }

    /// The TeamIdentifier from this process's own code signature.
    static func selfTeamIdentifier() -> String? {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess,
              let staticCode else { return nil }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(
            staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info
        ) == errSecSuccess,
        let dict = info as? [String: Any],
        let team = dict[kSecCodeInfoTeamIdentifier as String] as? String,
        !team.isEmpty else { return nil }
        return team
    }

    /// Apply the same-team requirement to a connection. Returns false when the
    /// connection must be rejected. Unsigned/ad-hoc builds have nothing to pin
    /// to: DEBUG builds accept with a logged warning so local development
    /// still works; release builds refuse — a registered daemon with no
    /// signing requirement would be a root shell for any local process.
    static func harden(_ connection: NSXPCConnection, label: String) -> Bool {
        guard let requirement = sameTeamRequirement() else {
            #if DEBUG
            AuditLog.denied(.permission, "\(label): no team identifier on own signature — accepting connection WITHOUT code-signing requirement (DEBUG build)")
            return true
            #else
            AuditLog.denied(.permission, "\(label): no team identifier on own signature — REJECTING connection (release build must be team-signed)")
            return false
            #endif
        }
        connection.setCodeSigningRequirement(requirement)
        AuditLog.log(.permission, "\(label): connection accepted with same-team code-signing requirement")
        return true
    }
}
