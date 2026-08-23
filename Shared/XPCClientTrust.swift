import Foundation
import Security

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
    /// connection must be rejected. Unsigned/ad-hoc builds get no requirement
    /// (there is nothing to pin to, and the helpers never register with
    /// launchd in that configuration) — a warning is logged instead.
    static func harden(_ connection: NSXPCConnection, label: String) -> Bool {
        guard let requirement = sameTeamRequirement() else {
            NSLog("%@: no team identifier on own signature — accepting connection WITHOUT code-signing requirement (ad-hoc/dev build)", label)
            return true
        }
        connection.setCodeSigningRequirement(requirement)
        return true
    }
}
