import SwiftUI

/// "List of Sponsors" menu — built within Agent!, links to sponsor websites.
/// Sponsor data lives in SponsorDirectory.swift; add sponsors there.
struct SponsorsMenu: View {
    @State private var sponsors: [SponsorDirectory.Entry] = SponsorDirectory.load()

    var body: some View {
        Menu {
            if sponsors.isEmpty {
                Text("No sponsors yet — be the first!")
                Divider()
            }
            ForEach(sponsors) { sponsor in
                Button {
                    if let url = URL(string: sponsor.url) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label(sponsor.name, systemImage: "link")
                }
            }
            Divider()
            Button {
                if let url = URL(string: "https://github.com/AgentiLoop/Agent/blob/main/docs/SPONSORSHIP.md") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Become a Sponsor…", systemImage: "heart")
            }
        } label: {
            Label("Sponsors", systemImage: "heart.circle")
        }
    }
}
