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
