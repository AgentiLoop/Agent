//  UserAuthGate.swift Agent
//  Requires the physical user (Touch ID, with the login password as fallback) before Tools or Services
//  can be changed, so the AI can't flip them on its own through accessibility clicks.
//  One successful check unlocks changes for a short grace window, so several toggles need only one fingerprint.

import LocalAuthentication

@MainActor
enum UserAuthGate {
    private static let graceWindow: TimeInterval = 120
    private static var unlockedUntil: Date = .distantPast
    private static var inFlight = false

    /// Runs `action` after the user authenticates. `reason` completes the system prompt "Agent! is trying to …".
    static func run(_ reason: String, _ action: @escaping @MainActor () -> Void) {
        if Date() < unlockedUntil { action(); return }
        guard !inFlight else { return }
        inFlight = true
        Task { @MainActor in
            defer { inFlight = false }
            let context = LAContext()
            var error: NSError?
            // No owner authentication available on this Mac: don't lock the user out of their own settings.
            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { action(); return }
            do {
                try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                unlockedUntil = Date().addingTimeInterval(graceWindow)
                action()
            } catch {
                // Cancelled or failed — leave the setting unchanged.
            }
        }
    }
}
