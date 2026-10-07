import SwiftUI

struct MessagesView: View {
    @Bindable var viewModel: AgentViewModel
    @State private var renderKey = false
    @Environment(\.colorSchemeContrast) private var contrast
    private var highContrast: Bool { contrast == .increased }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Messages Monitor")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Monitor iMessage for \"Agent!\" commands.")
                .font(.caption)
                .foregroundStyle(highContrast ? .primary : .secondary)

            HStack {
                Picker("Active", selection: $viewModel.messageFilter) {
                    ForEach(AgentViewModel.MessageFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Recipient Filter")

                Spacer()

                Toggle("", isOn: $viewModel.messagesMonitorEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(.blue)
                    .labelsHidden()
                    .accessibilityLabel("Enable Messages Monitor")
            }

            Divider()

            if viewModel.filteredRecipients.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "message")
                        .font(.system(size: 32))
                        .foregroundStyle(highContrast ? .primary : .secondary)
                        .accessibilityHidden(true)
                    Text("No recipients yet")
                        .font(.subheadline)
                        .foregroundStyle(highContrast ? .primary : .secondary)
                    Text("Recipients appear here as messages arrive.")
                        .font(.caption)
                        .foregroundStyle(highContrast ? .primary : .tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                HStack {
                    Text("Check recipients to act on \"Agent!\" commands:")
                        .font(.caption)
                        .foregroundStyle(highContrast ? .primary : .secondary)
                    Spacer()
                    Button("All") {
                        let filtered = Set(viewModel.filteredRecipients.map(\.id))
                        viewModel.enabledHandleIds.formUnion(filtered)
                        announceForAccessibility("All recipients enabled")
                    }
                    .buttonStyle(.bordered).controlSize(.mini)
                    .accessibilityLabel("Enable All Recipients")
                    Button("None") {
                        let filtered = Set(viewModel.filteredRecipients.map(\.id))
                        viewModel.enabledHandleIds.subtract(filtered)
                        announceForAccessibility("All recipients disabled")
                    }
                    .buttonStyle(.bordered).controlSize(.mini)
                    .accessibilityLabel("Disable All Recipients")
                    Button("Clear") {
                        viewModel.messageRecipients.removeAll()
                        viewModel.enabledHandleIds.removeAll()
                        UserDefaults.standard.removeObject(forKey: "agentDiscoveredHandles")
                        UserDefaults.standard.removeObject(forKey: "agentDiscoveredServices")
                        UserDefaults.standard.removeObject(forKey: "agentDiscoveredFromMe")
                        announceForAccessibility("Recipient list cleared")
                    }
                    .buttonStyle(.bordered).controlSize(.mini)
                    .accessibilityLabel("Clear Recipient List")
                }

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.filteredRecipients) { recipient in
                            recipientRow(recipient)
                        }
                    }
                }
                .id(renderKey)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Send \"Agent! <prompt>\" from a checked recipient to trigger a task.")
                    .font(.caption)
                    .foregroundStyle(highContrast ? .primary : .secondary)
                Text("Unchecked recipients are logged but not acted on. Each recipient must be approved.")
                    .font(.caption)
                    .foregroundStyle(highContrast ? .primary : .tertiary)
            }

            if !AgentViewModel.checkFullDiskAccess() {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .accessibilityHidden(true)
                    Text("Full Disk Access required to read Messages.")
                        .font(.caption)
                        .foregroundStyle(highContrast ? .primary : .secondary)
                        .accessibilityLabel("Warning: Full Disk Access required to read Messages.")
                    Spacer()
                    Button("Open Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(16)
        .padding(.bottom, 15)
        .frame(width: 380)
        .frame(maxHeight: 480)
        .onAppear {
            viewModel.refreshMessageRecipients()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                renderKey.toggle()
            }
        }
    }

    @ViewBuilder
    private func recipientRow(_ recipient: AgentViewModel.MessageRecipient) -> some View {
        let isEnabled = viewModel.enabledHandleIds.contains(recipient.id)

        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { viewModel.enabledHandleIds.contains(recipient.id) },
                set: { newValue in
                    if newValue {
                        viewModel.enabledHandleIds.insert(recipient.id)
                    } else {
                        viewModel.enabledHandleIds.remove(recipient.id)
                    }
                }
            ))
            .toggleStyle(.switch)
            .controlSize(.mini)
            .tint(.blue)
            .labelsHidden()
            .accessibilityLabel("Act on commands from \(recipient.id), \(recipient.service)")

            Text(recipient.id)
                .font(.subheadline)
                .foregroundStyle(isEnabled || highContrast ? .primary : .secondary)
                .lineLimit(1)
                .accessibilityHidden(true)

            Spacer()

            Text(recipient.service)
                .font(.caption2)
                .foregroundStyle(highContrast ? .primary : .tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isEnabled ? Color.blue.opacity(highContrast ? 0.2 : 0.05) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay {
            if highContrast && isEnabled {
                RoundedRectangle(cornerRadius: 6).stroke(Color.blue, lineWidth: 2)
            }
        }
    }
}
