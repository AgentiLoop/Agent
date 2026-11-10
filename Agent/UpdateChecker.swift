import AppKit
import AutoUpdateKit

/// Auto-update from the GitHub releases (tags `vX.Y.Z.B`, `Agent-vX.Y.Z.B-macOS.zip` asset) via AutoUpdateKit:
/// offers a newer version, downloads it, verifies the Developer ID signature, swaps the bundle in place and relaunches.
@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()

    /// UserDefaults key for the opt-in "Include Pre-releases" toggle (default: off).
    static let includePrereleasesKey = "updateChecker.includePrereleases"

    private let updater: AutoUpdater

    private init() {
        let info = Bundle.main.infoDictionary ?? [:]
        let short = info["CFBundleShortVersionString"] as? String ?? "0"
        let build = info["CFBundleVersion"] as? String ?? "0"
        updater = AutoUpdater(configuration: AutoUpdateConfiguration(
            appName: "Agent!",
            repository: "AgentiLoop/Agent",
            tagPrefix: "v",
            isUpdateAsset: { $0.hasPrefix("Agent-v") && $0.hasSuffix("-macOS.zip") },
            teamID: "469UCUB275",
            // Release builds only: Debug's ".debug" ID never matches a release, so its install is refused.
            bundleIdentifier: AppConstants.bundleID,
            installedVersion: "\(short).\(build)",
            skippedVersionKey: "updateChecker.skippedVersion",
            snoozedUntilKey: "updateChecker.snoozedUntil",
            prereleasesKey: Self.includePrereleasesKey
        ))
    }

    /// Automatic checks shortly after launch and every 6 hours (Release builds only).
    func start() {
        #if !DEBUG
        updater.start()
        #endif
    }

    /// Entry point for the "Check for Updates…" menu item.
    func checkForUpdates() {
        Task { await updater.check(interactive: true) }
    }
}
