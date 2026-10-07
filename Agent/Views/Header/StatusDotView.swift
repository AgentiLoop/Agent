import SwiftUI

/// Stoplight: Green = running, Yellow = was green + cooling down, Red = not running
struct StatusDot: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    let isActive: Bool
    let wasActive: Bool
    let isBusy: Bool
    var enabled: Bool = true

    var dotColor: Color {
        if !enabled { return .gray }
        if isActive || (wasActive && isBusy) { return .green }
        return .red
    }

    /// Shape cue for users who can't tell red from green (System Settings > Accessibility > Display > Differentiate without color)
    private var symbolName: String {
        if dotColor == .green { return "checkmark.circle.fill" }
        if dotColor == .red { return "xmark.circle.fill" }
        return "minus.circle.fill"
    }

    var body: some View {
        ZStack {
            if differentiateWithoutColor {
                Image(systemName: symbolName)
                    .font(.system(size: 10))
                    .foregroundStyle(dotColor)
            } else {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)

                if dotColor == .green {
                    PulseRing()
                }
            }
        }
        .frame(width: 12, height: 12) // Fixed frame prevents layout shift
    }
}

/// Small on/off dot shown next to a text label. Swaps to a checkmark/xmark when Differentiate Without Color is on.
/// Hidden from VoiceOver — the adjacent text already states the status.
struct OnOffDot: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    let isOn: Bool
    var onColor: Color = .green
    var offColor: Color = .red

    var body: some View {
        Group {
            if differentiateWithoutColor {
                Image(systemName: isOn ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isOn ? onColor : offColor)
            } else {
                Circle()
                    .fill(isOn ? onColor : offColor)
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }
}
