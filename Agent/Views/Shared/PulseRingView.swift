import SwiftUI

struct PulseRing: View {
    private let duration: Double = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                // Static ring: no expanding animation when Reduce Motion is on
                Circle()
                    .stroke(Color.green.opacity(0.6), lineWidth: 2)
                    .frame(width: 12, height: 12)
            } else {
                TimelineView(.animation) { timeline in
                    let progress = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration) / duration
                    let ease = 1.0 - pow(1.0 - progress, 2.0) // easeOut curve
                    Circle()
                        .stroke(Color.green.opacity(0.6), lineWidth: 2)
                        .frame(width: 12, height: 12)
                        .scaleEffect(1.0 + 1.5 * ease)
                        .opacity(0.8 * (1.0 - ease))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
