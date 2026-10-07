import SwiftUI

/// HUD (Heads-Up Display) options popover — Terminal Speed and Scan Lines
/// for the LLM Output overlay. Shown via the viewfinder icon in the toolbar.
struct HUDOptionsView: View {
    @Bindable var viewModel: AgentViewModel
    @Environment(\.colorSchemeContrast) private var contrast
    /// Primary text under Increase Contrast; secondary otherwise.
    private var captionStyle: HierarchicalShapeStyle { contrast == .increased ? .primary : .secondary }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HUD")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text("Heads-Up Display for LLM Output. Press ⌘B to show/hide during a task.")
                .font(.caption)
                .foregroundStyle(captionStyle)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            HStack {
                Text("Show HUD").font(.caption)
                Spacer()
                Toggle("", isOn: $viewModel.showThinkingIndicator)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(.green)
                    .accessibilityLabel("Show HUD")
            }

            HStack {
                Text("Smooth Streaming").font(.caption)
                Spacer()
                Toggle("", isOn: $viewModel.dripEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(.green)
                    .accessibilityLabel("Smooth Streaming")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Terminal Speed")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                Picker("", selection: $viewModel.terminalSpeed) {
                    ForEach(AgentViewModel.TerminalSpeed.allCases, id: \.self) { speed in
                        Text(speed.label).tag(speed)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.small)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .tint(.green)
                .accessibilityLabel("Terminal Speed")
            }

            HStack {
                Text("Scan Lines").font(.caption)
                Spacer()
                Toggle("", isOn: $viewModel.scanLinesEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(.green)
                    .accessibilityLabel("Scan Lines")
            }

            HStack {
                Text("Activity Log Below HUD").font(.caption)
                Spacer()
                Toggle("", isOn: $viewModel.hudLogBelow)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(.green)
                    .accessibilityLabel("Activity Log Below HUD")
            }
        }
        .padding(16)
        .frame(width: 460, alignment: .leading)
        .clipped()
    }
}
