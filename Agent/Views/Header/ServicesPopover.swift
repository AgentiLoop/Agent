//  ServicesPopover.swift Agent  Extracted from ContentView.swift 

import SwiftUI

struct ServicesPopover: View {
    @Environment(\.colorSchemeContrast) private var contrast
    private var captionStyle: HierarchicalShapeStyle { contrast == .increased ? .primary : .secondary }
    @Bindable var viewModel: AgentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Background agents for shell commands and automation.")
                .font(.caption)
                .foregroundStyle(captionStyle)

            Grid(alignment: .leading, verticalSpacing: 10) {
                GridRow {
                    StatusDot(
                        isActive: viewModel.userServiceActive,
                        wasActive: viewModel.userWasActive,
                        isBusy: viewModel.isRunning,
                        enabled: viewModel.userEnabled
                    )
                    .accessibilityHidden(true)
                    Text("User Agent")
                        .font(.caption)
                        .accessibilityValue(statusText(active: viewModel.userServiceActive, enabled: viewModel.userEnabled))
                    Toggle("", isOn: $viewModel.userEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .tint(.green)
                        .labelsHidden()
                        .accessibilityLabel("Enable User Agent")
                }
                GridRow {
                    StatusDot(
                        isActive: viewModel.rootServiceActive,
                        wasActive: viewModel.rootWasActive,
                        isBusy: viewModel.isRunning,
                        enabled: viewModel.rootEnabled
                    )
                    .accessibilityHidden(true)
                    Text("Daemon Agent")
                        .font(.caption)
                        .accessibilityValue(statusText(active: viewModel.rootServiceActive, enabled: viewModel.rootEnabled))
                    Toggle("", isOn: $viewModel.rootEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .tint(.green)
                        .labelsHidden()
                        .accessibilityLabel("Enable Daemon Agent")
                }
            }

            Divider()

            // Action Buttons
            HStack(spacing: 8) {
                Button("Unregister") {
                    viewModel.unregisterAgent()
                    viewModel.unregisterDaemon()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint("Unregisters the user agent and the daemon")

                Button("Register") {
                    viewModel.registerAgent()
                    viewModel.registerDaemon()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint("Registers the user agent and the daemon")

                Button("Connect") {
                    viewModel.testConnection()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint("Tests the connection to both services")
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private func statusText(active: Bool, enabled: Bool) -> String {
        active ? "Running" : (enabled ? "Stopped" : "Disabled")
    }
}
