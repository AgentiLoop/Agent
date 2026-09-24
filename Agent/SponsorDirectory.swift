import Foundation

/// Sponsor directory — single source of truth for the in-app Sponsors menu.
/// LLM Provider sponsors are listed with their sponsorship tier (Silver / Gold / Platinum).
/// GitHub Sponsors monthly tiers auto-refresh this list; see docs/SPONSORSHIP.md.
enum SponsorDirectory {
    struct Entry: Identifiable, Equatable {
        let id: String
        let name: String
        let url: String
        /// nil for non-provider sponsors; "Silver", "Gold", or "Platinum" for LLM provider sponsors.
        let tier: String?

        init(name: String, url: String, tier: String? = nil) {
            self.id = name.lowercased().replacingOccurrences(of: " ", with: "-")
            self.name = name
            self.url = url
            self.tier = tier
        }
    }

    /// Static fallback list. LLM provider sponsors appear here with their tier.
    static let providers: [Entry] = [
        Entry(name: "Fluxion AI", url: "https://fluxionai.world/register?source=github&campaign=aiagent&promo=AIAGENT", tier: "Silver"),
    ]

    static func load() -> [Entry] {
        providers
    }
}
