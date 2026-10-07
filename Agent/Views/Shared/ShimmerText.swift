import SwiftUI

/// Text with a pulse animation matching the LLM icon throb effect.
struct ShimmerText: View {
    let text: String
    let color: Color
    @State private var dimmed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    init(_ text: String, color: Color = .blue) {
        self.text = text
        self.color = color
    }

    var body: some View {
        // Increase Contrast: primary text at full opacity (the pulse dims to 0.65)
        let highContrast = contrast == .increased
        Text(text)
            .font(.caption)
            .foregroundStyle(highContrast ? Color.primary : color)
            .opacity(dimmed && !highContrast ? 0.65 : 1.0)
            .onAppear {
                // Skip the endless pulse when Reduce Motion is on
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    dimmed = true
                }
            }
    }
}
