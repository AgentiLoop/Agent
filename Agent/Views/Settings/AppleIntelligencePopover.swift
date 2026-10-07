import AgentAccess
import SwiftUI

struct AppleIntelligencePopover: View {
    @ObservedObject private var aiMediator = AppleIntelligenceMediator.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            mediatorSection
        }
        .padding(16)
        .frame(width: 380)
        .onAppear {
            // Refresh master toggle — flip off/on so downstream sub-features re-evaluate
            let wasEnabled = aiMediator.isEnabled
            aiMediator.isEnabled = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                aiMediator.isEnabled = wasEnabled
            }
        }
    }

    // MARK: - Mediator Section

    private var mediatorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apple Intelligence Mediator")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 6) {
                Circle()
                    .fill(AppleIntelligenceMediator.isAvailable ? Color.green : Color.red.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text(AppleIntelligenceMediator.isAvailable ? "Available" : "Not Available")
                    .font(.caption)
                    .foregroundStyle(AppleIntelligenceMediator.isAvailable ? .green : .secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Apple Intelligence")
            .accessibilityValue(AppleIntelligenceMediator.isAvailable ? "Available" : "Not Available")

            if !AppleIntelligenceMediator.isAvailable {
                Text(AppleIntelligenceMediator.unavailabilityReason)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Grid(alignment: .leading, verticalSpacing: 8) {
                GridRow {
                    VStack(alignment: .leading) {
                        Text("Enable Mediator")
                            .font(.caption)
                        Text("Master switch for on-device Apple AI — sub-features below are only active when this is on")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Toggle("", isOn: $aiMediator.isEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                        .tint(aiMediator.isEnabled ? Color.blue : Color.gray)
                        .accessibilityLabel("Enable Mediator")
                        .accessibilityHint("Master switch for on-device Apple AI")
                }

                if aiMediator.isEnabled {
                    GridRow {
                        VStack(alignment: .leading) {
                            Text("Triage greetings")
                                .font(.caption)
                            Text("Answer hi / hello / thanks on-device before the cloud LLM — skip the round-trip for small talk")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Toggle("", isOn: $aiMediator.triageEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                            .tint(aiMediator.triageEnabled ? Color.green : Color.orange)
                            .accessibilityLabel("Triage greetings")
                            .accessibilityHint("Answer small talk on-device before the cloud model")
                    }

                    GridRow {
                        VStack(alignment: .leading) {
                            Text("Show annotations to user")
                                .font(.caption)
                            Text("Display task summaries and error explanations in the activity log")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Toggle("", isOn: $aiMediator.showAnnotationsToUser)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                            .tint(aiMediator.showAnnotationsToUser ? Color.pink : Color.orange)
                            .accessibilityLabel("Show annotations to user")
                            .accessibilityHint("Display task summaries and error explanations in the activity log")
                    }

                    GridRow {
                        VStack(alignment: .leading) {
                            Text("Token compression")
                                .font(.caption)
                            Text("Fallback tier of context compaction — when the active model can't produce a summary (or for sub-agents), Apple AI summarizes old messages on-device at the model's context threshold. Free, private, no API tokens consumed")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Toggle("", isOn: $aiMediator.tokenCompressionEnabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                            .tint(aiMediator.tokenCompressionEnabled ? Color.purple : Color.orange)
                            .accessibilityLabel("Token compression")
                            .accessibilityHint("Summarize old messages on-device when context runs low")
                    }

                }
            }
        }
    }
}
