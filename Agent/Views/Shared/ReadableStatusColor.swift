import SwiftUI
import AppKit

// System green/orange/red used as small status text fall below 4.5:1 contrast on a
// light background (~2.2:1 / ~2.2:1 / ~3.6:1). Light mode gets darker shades; dark
// mode keeps the bright system colors.
extension Color {
    static let readableGreen = readable(dark: .systemGreen, light: NSColor(red: 0.0, green: 0.45, blue: 0.10, alpha: 1.0))
    static let readableOrange = readable(dark: .systemOrange, light: NSColor(red: 0.62, green: 0.30, blue: 0.0, alpha: 1.0))
    static let readableRed = readable(dark: .systemRed, light: NSColor(red: 0.75, green: 0.0, blue: 0.0, alpha: 1.0))

    private static func readable(dark: NSColor, light: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}
