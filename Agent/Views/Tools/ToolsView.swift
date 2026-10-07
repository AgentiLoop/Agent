import SwiftUI
import AgentTools

struct ToolsView: View {
    @Binding var selectedProvider: APIProvider
    @Bindable var viewModel: AgentViewModel
    @Bindable var prefs = ToolPreferencesService.shared
    @State private var collapsedGroups: Set<String> = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Group definitions — use actual consolidated tool names from AgentTools.Name. Sub-agents (spawn_agent +
    // tell_agent) live in their own group; previously spawn was in Work and tell was in Core, which split a coherent feature across two toggles for no reason.
    static let groups: [String: (filter: (AgentTools.ToolDef) -> Bool, icon: String)] = [
        Tool.Group.core: ({ [
            Tool.done, Tool.tools, Tool.search, Tool.folder, Tool.mem,
            Tool.chat, Tool.msg, Tool.sh, Tool.plan, Tool.skill, Tool.file,
            Tool.webFetch, Tool.ask
        ].contains($0.name) }, "checkmark.circle"),
        Tool.Group.work: ({ [Tool.batch, Tool.multi, Tool.index].contains($0.name) }, "flowchart"),
        Tool.Group.code: ({ [Tool.xc, Tool.git, Tool.agent].contains($0.name) }, "chevron.left.forwardslash.chevron.right"),
        Tool.Group.auto: ({ [Tool.as, Tool.ax, Tool.js, Tool.web].contains($0.name) }, "gearshape.2"),
        Tool.Group.user: ({ $0.name == Tool.user }, "person"),
        Tool.Group.root: ({ $0.name == Tool.root }, "lock.shield"),
        Tool.Group.subAgents: ({ [Tool.spawn, Tool.messageAgent].contains($0.name) }, "point.3.connected.trianglepath.dotted"),
        Tool.Group.exp: ({ $0.name == Tool.sel }, "flask"),
    ]

    static let groupOrder = Tool.allGroups

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text("Tools")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Text("Toggle tool availability per LLM provider.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Picker("Provider", selection: $selectedProvider) {
                        ForEach(APIProvider.selectableProviders, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.menu)

                    modelPicker
                }
            }
            .padding()
            .padding(.bottom, 4)

            Divider()

            // Tag cloud — native tools only, sorted alphabetically
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let tools = AgentTools.tools()

                    ForEach(Self.groupOrder, id: \.self) { groupName in
                        if let groupInfo = Self.groups[groupName] {
                            let groupTools = tools.filter { groupInfo.filter($0) }.sorted(by: { $0.name < $1.name })

                            if !groupTools.isEmpty {
                                GroupRowView(
                                    groupName: groupName,
                                    icon: groupInfo.icon,
                                    groupTools: groupTools,
                                    provider: selectedProvider,
                                    prefs: prefs,
                                    isCollapsed: collapsedGroups.contains(groupName),
                                    toggleCollapse: { toggleGroup(groupName) },
                                    onGroupToggled: { enabled in
                                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                                            if enabled {
                                                collapsedGroups.remove(groupName)
                                            } else {
                                                collapsedGroups.insert(groupName)
                                            }
                                        }
                                        // Sync service group toggles with launch agent/daemon
                                        if groupName == Tool.Group.user {
                                            viewModel.userEnabled = enabled
                                        } else if groupName == Tool.Group.root {
                                            viewModel.rootEnabled = enabled
                                        }
                                    },
                                    onToolToggled: (groupName == Tool.Group.user || groupName == Tool.Group.root) ? { toolName, enabled in
                                        if toolName == "execute_agent_command" {
                                            viewModel.userEnabled = enabled
                                        } else if toolName == "execute_daemon_command" {
                                            viewModel.rootEnabled = enabled
                                        }
                                    } : nil
                                )
                            }
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                let all = AgentTools.tools()
                let enabledCount = all.filter { prefs.isEnabled(selectedProvider, $0.name) }.count
                Text("\(enabledCount) of \(all.count) enabled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Enable All") {
                    prefs.enableAllGroups()
                    prefs.enableAll(for: selectedProvider)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Button("Disable All") {
                    prefs.disableAllGroups()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .padding(.bottom, 15)
        }
        .frame(width: 460)
        .frame(maxHeight: 660)
    }

    // MARK: - Model Picker

    private var modelBinding: Binding<String> {
        $viewModel.models[selectedProvider]
    }

    /// Normalized (id, name) list for the current provider's models.
    private var modelOptions: [(id: String, name: String)] {
        viewModel.modelOptions(for: selectedProvider)
    }

    @ViewBuilder
    private var modelPicker: some View {
        let options = modelOptions
        if options.isEmpty {
            Picker("Model", selection: modelBinding) {
                Text(modelBinding.wrappedValue.isEmpty ? "No model" : modelBinding.wrappedValue)
                    .tag(modelBinding.wrappedValue)
            }
            .pickerStyle(.menu)
        } else {
            Picker("Model", selection: modelBinding) {
                ForEach(options, id: \.id) { option in
                    HStack(spacing: 4) {
                        Text(option.name)
                        if option.id.hasSuffix(":v") {
                            Image(systemName: "eye")
                                .foregroundStyle(.blue)
                                .font(.caption2)
                                .accessibilityLabel("Vision")
                        }
                    }.tag(option.id)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private func toggleGroup(_ groupName: String) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
            if collapsedGroups.contains(groupName) {
                collapsedGroups.remove(groupName)
            } else {
                collapsedGroups.insert(groupName)
            }
        }
    }
}

// MARK: - Group Row View

struct GroupRowView: View {
    let groupName: String
    let icon: String
    let groupTools: [AgentTools.ToolDef]
    let provider: APIProvider
    let prefs: ToolPreferencesService
    let isCollapsed: Bool
    let toggleCollapse: () -> Void
    let onGroupToggled: (Bool) -> Void
    var onToolToggled: ((String, Bool) -> Void)? = nil
    @Environment(\.colorSchemeContrast) private var contrast
    private var highContrast: Bool { contrast == .increased }

    var body: some View {
        let groupEnabled = prefs.isGroupEnabled(groupName)
        let isServiceGroup: Bool = groupName == Tool.Group.user || groupName == Tool.Group.root
        let offColor: Color = isServiceGroup ? .yellow : .red
        // Increase Contrast: drop the faded opacities so disabled groups stay legible.
        let offStyle: (Double) -> Color = { highContrast ? offColor : offColor.opacity($0) }

        VStack(alignment: .leading, spacing: 4) {
            // Group header with collapse toggle and group toggle
            HStack(spacing: 6) {
                HStack(spacing: 6) {
                    // Collapse arrow
                    Image(systemName: (isCollapsed || !groupEnabled) ? "chevron.right" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(groupEnabled ? (highContrast ? .primary : .secondary) : offStyle(0.5))

                    // Group icon and name
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(groupEnabled ? (isServiceGroup ? .green : .primary) : offStyle(0.6))
                    Text(groupName)
                        .font(.caption).bold()
                        .foregroundColor(groupEnabled ? (highContrast ? .primary : .secondary) : offStyle(0.6))

                    // Tool count
                    Text("\(groupTools.count)")
                        .font(.caption2)
                        .foregroundColor(groupEnabled ? (highContrast ? .primary : .gray) : offStyle(0.4))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(groupName) group, \(groupTools.count) tools")
                .accessibilityValue(groupEnabled ? (isCollapsed ? "Collapsed" : "Expanded") : "Disabled")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { if groupEnabled { toggleCollapse() } }
                // Full Keyboard Access: Tab to the header, Space/Return collapses or expands
                .focusable(groupEnabled)
                .onKeyPress(keys: [.space, .return]) { _ in
                    toggleCollapse()
                    return .handled
                }

                Spacer()

                // Group toggle switch
                Toggle("", isOn: Binding(
                    get: { groupEnabled },
                    set: { newValue in
                        prefs.toggleGroup(groupName)
                        onGroupToggled(newValue)
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .accessibilityLabel("Enable \(groupName) group")
            }
            .padding(.leading, 4)
            .padding(.top, 8)
            .contentShape(Rectangle())
            .onTapGesture { if groupEnabled { toggleCollapse() } }

            // Tool buttons — auto-collapse when group is disabled
            if !isCollapsed && groupEnabled {
                FlowLayout(spacing: 4) {
                    ForEach(groupTools, id: \.name) { tool in
                        let enabled = prefs.isEnabled(provider, tool.name)
                        Button {
                            prefs.toggle(provider, tool.name)
                            let nowEnabled = prefs.isEnabled(provider, tool.name)
                            onToolToggled?(tool.name, nowEnabled)
                        } label: {
                            Text(tool.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(enabled ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                                .foregroundStyle(enabled ? AnyShapeStyle(.primary) : (highContrast ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tertiary)))
                                .clipShape(Capsule())
                                // Increase Contrast: solid accent border when on, dashed gray border when off,
                                // so on/off isn't conveyed by a faint tint alone.
                                .overlay(
                                    Capsule().stroke(
                                        highContrast
                                            ? (enabled ? Color.accentColor : Color.secondary)
                                            : (enabled ? Color.accentColor.opacity(0.5) : Color.clear),
                                        style: StrokeStyle(lineWidth: highContrast ? (enabled ? 1.5 : 1) : 0.5,
                                                           dash: highContrast && !enabled ? [2, 2] : [])
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                        .help(tool.description.components(separatedBy: ". ").first ?? tool.description)
                        .accessibilityValue(enabled ? "Enabled" : "Disabled")
                        .accessibilityHint("Toggles this tool")
                    }
                }
            }
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 400
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
