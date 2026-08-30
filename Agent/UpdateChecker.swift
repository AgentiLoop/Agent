import AppKit
import Foundation

/// Checks GitHub for a newer release DMG — same logic as agent.xcf.ai/script.js:
/// fetch the releases feed, find the latest release with a .dmg asset,
/// extract the version from the asset name, and offer the download.
@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()
    private init() {}

    private static let releasesAPI = "https://api.github.com/repos/macOS26/Agent/releases"

    private struct Release: Decodable {
        struct Asset: Decodable {
            let name: String
            let browser_download_url: String
        }
        let tag_name: String
        let assets: [Asset]
    }

    private struct LatestDMG {
        let url: URL
        let version: String
        let tag: String
    }

    private var isChecking = false

    /// Entry point for the "Check for Updates…" menu item.
    func checkForUpdates() {
        guard !isChecking else { return }
        isChecking = true
        Task {
            defer { isChecking = false }
            do {
                guard let latest = try await fetchLatestDMG() else {
                    showAlert(title: "Check for Updates",
                              message: "No downloadable release was found on GitHub.")
                    return
                }
                let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
                if isVersion(latest.version, newerThan: current) {
                    promptDownload(latest, currentVersion: current)
                } else {
                    showAlert(title: "You're up to date!",
                              message: "Agent! \(current) is the latest version.")
                }
            } catch {
                showAlert(title: "Update Check Failed",
                          message: "Could not reach GitHub: \(error.localizedDescription)")
            }
        }
    }

    /// Mirrors autoDiscoverReleases() in agent.xcf.ai/script.js:
    /// walk releases newest-first, return the first .dmg asset found.
    private func fetchLatestDMG() async throws -> LatestDMG? {
        guard let apiURL = URL(string: Self.releasesAPI) else { return nil }
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw NSError(domain: "UpdateChecker", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "GitHub returned HTTP \(http.statusCode)"])
        }
        let releases = try JSONDecoder().decode([Release].self, from: data)
        for release in releases {
            for asset in release.assets where asset.name.hasSuffix(".dmg") {
                guard let url = URL(string: asset.browser_download_url) else { continue }
                return LatestDMG(url: url,
                                 version: extractVersion(asset.name),
                                 tag: release.tag_name)
            }
        }
        return nil
    }

    /// Mirrors extractVersion() in script.js — pull "1.0.8" out of "Agent_1.0.8.dmg".
    private func extractVersion(_ filename: String) -> String {
        if let range = filename.range(of: #"\d+\.\d+\.\d+"#, options: .regularExpression) {
            return String(filename[range])
        }
        return ""
    }

    /// Numeric component-wise comparison: "1.0.10" > "1.0.9".
    private func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let a = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let b = current.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    private func promptDownload(_ latest: LatestDMG, currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = "A new version of Agent! is available"
        alert.informativeText = "Agent! \(latest.version) is available — you have \(currentVersion). Would you like to download it now?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(latest.url)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
