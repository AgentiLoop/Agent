import SwiftUI

/// Coding preferences — opt-in features for agentic coding workflows.
struct CodingPreferencesView: View {
    @Bindable var viewModel: AgentViewModel
    @Environment(\.colorSchemeContrast) private var contrast
    /// Increase Contrast: promote faint secondary/tertiary captions to primary text.
    private var highContrast: Bool { contrast == .increased }
    private var captionStyle: HierarchicalShapeStyle { highContrast ? .primary : .secondary }
    private var detailStyle: HierarchicalShapeStyle { highContrast ? .primary : .tertiary }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Coding Preferences")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("Opt-in features for autonomous coding workflows.")
                    .font(.caption)
                    .foregroundStyle(captionStyle)
            }
            .padding()

            row {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Verify").font(.subheadline)
                    Text("After build succeeds, launch app and test via accessibility")
                        .font(.caption2)
                        .foregroundStyle(detailStyle)
                }
                Spacer()
                Toggle("", isOn: $viewModel.autoVerifyEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Auto-Verify")
                    .accessibilityHint("After build succeeds, launch app and test via accessibility")
            }

            row {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Critic Review").font(.subheadline)
                    Text("LLM reviews the task's diff before task_complete is accepted")
                        .font(.caption2)
                        .foregroundStyle(detailStyle)
                }
                Spacer()
                Toggle("", isOn: $viewModel.criticReviewEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Critic Review")
                    .accessibilityHint("LLM reviews the task's diff before task_complete is accepted")
            }

            row {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Visual Tests").font(.subheadline)
                    Text("LLM can define click/verify UI assertions")
                        .font(.caption2)
                        .foregroundStyle(detailStyle)
                }
                Spacer()
                Toggle("", isOn: $viewModel.visualTestsEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Visual Tests")
                    .accessibilityHint("LLM can define click/verify UI assertions")
            }

            row {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto PR").font(.subheadline)
                    Text("Create branch, commit, push, open GitHub PR")
                        .font(.caption2)
                        .foregroundStyle(detailStyle)
                }
                Spacer()
                Toggle("", isOn: $viewModel.autoPREnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Auto PR")
                    .accessibilityHint("Create branch, commit, push, open GitHub PR")
            }

            row {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Project Templates").font(.subheadline)
                    Text("Scaffold new Xcode projects from prompts")
                        .font(.caption2)
                        .foregroundStyle(detailStyle)
                }
                Spacer()
                Toggle("", isOn: $viewModel.autoScaffoldEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                    .accessibilityLabel("Project Templates")
                    .accessibilityHint("Scaffold new Xcode projects from prompts")
            }
        }
        .padding(.bottom, 15)
        .frame(width: 320)
    }

    @ViewBuilder
    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack { content() }
                .padding(.vertical, 8)
                .padding(.horizontal)
        }
    }
}
