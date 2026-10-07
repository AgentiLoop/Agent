//  TaskBannerView.swift Agent  Extracted from ContentView.swift 

import SwiftUI

/// Green banner showing current task with cancel button and optional Apple AI prompt
struct TaskBannerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    private var highContrast: Bool { colorSchemeContrast == .increased }
    let prompt: String
    let appleAIPrompt: String?
    @Binding var showAppleAIBanner: Bool
    let onCancel: () -> Void
    /// Non-nil only while Auto-Pilot is active — ends the session and stops all tasks.
    var onStopAll: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button {
                    if appleAIPrompt != nil {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                            showAppleAIBanner.toggle()
                        }
                    }
                } label: {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                        .frame(width: 14)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .help("User prompt")
                .accessibilityLabel("User prompt")
                .accessibilityHint(appleAIPrompt != nil ? "Shows or hides the Apple Intelligence prompt" : "")

                Text(prompt)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.white)
                    .accessibilityLabel("Current task: \(prompt)")

                Spacer()

                if let onStopAll {
                    Button(action: onStopAll) {
                        Label("Stop All", systemImage: "stop.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .help("End Auto-Pilot and stop this tab's tasks")
                } else {
                    Button(action: onCancel) {
                        Label("Cancel", systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(highContrast ? Color(red: 0, green: 0.4, blue: 0) : Color.green.opacity(0.7))

            // Apple AI prompt row (toggled by tapping person icon)
            if showAppleAIBanner, let aiPrompt = appleAIPrompt {
                HStack(spacing: 6) {
                    Text("\u{F8FF}")
                        .font(.caption2)
                        .frame(width: 14)
                        .foregroundStyle(.white.opacity(highContrast ? 1 : 0.8))
                    Text(aiPrompt)
                        .font(.caption)
                        .lineLimit(4)
                        .foregroundStyle(.white.opacity(highContrast ? 1 : 0.9))
                    Spacer()
                }
                // Private-use Apple logo glyph reads as gibberish — speak a single labeled element
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Apple Intelligence prompt: \(aiPrompt)")
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(highContrast ? Color(red: 0, green: 0.25, blue: 0.6) : Color.blue.opacity(0.6))
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            }
        }
    }
}
