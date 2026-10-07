import SwiftUI

struct TabBarView: View {
    @Bindable var viewModel: AgentViewModel
    @State private var draggingTabId: UUID?
    @State private var dragOffset: CGFloat = 0

    private let swapThreshold: CGFloat = 60

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Main tab (always present, not closable, not draggable)
                let mainProvider = viewModel.mainTabProvider
                let mainTitle = viewModel.globalModelForProvider(mainProvider)
                TabItem(
                    title: mainTitle.isEmpty ? mainProvider.displayName : mainTitle,
                    isSelected: viewModel.selectedTabId == nil,
                    isRunning: viewModel.isRunning,
                    tint: .green,
                    onSelect: { viewModel.selectMainTab() },
                    onClose: nil
                )
                .id("main-\(mainProvider.rawValue)-\(mainTitle)")

                ForEach(viewModel.scriptTabs) { tab in
                    let isDragging = draggingTabId == tab.id
                    let color = tab.isMessagesTab ? Color.green : tab.isMainTab ? Color.blue : ContentView.tabColor(
                        for: tab.id,
                        in: viewModel.scriptTabs
                    )
                    let index = viewModel.scriptTabs.firstIndex(where: { $0.id == tab.id }) ?? 0
                    TabItem(
                        title: tab.displayTitle,
                        isSelected: viewModel.selectedTabId == tab.id,
                        isRunning: (tab.isMainTab || tab.isMessagesTab) ? tab.isLLMRunning : tab.isRunning,
                        tint: color,
                        onSelect: { viewModel.selectedTabId = tab.id },
                        onClose: { viewModel.closeScriptTab(id: tab.id) },
                        onMoveLeft: index > 0 ? { moveTab(tab.id, by: -1) } : nil,
                        onMoveRight: index < viewModel.scriptTabs.count - 1 ? { moveTab(tab.id, by: 1) } : nil
                    )
                    .zIndex(isDragging ? 1 : 0)
                    .offset(x: isDragging ? dragOffset : 0)
                    .scaleEffect(isDragging ? 1.05 : 1.0)
                    .animation(isDragging ? nil : .easeInOut(duration: 0.2), value: viewModel.scriptTabs.map(\.id))
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                if draggingTabId == nil {
                                    draggingTabId = tab.id
                                }
                                dragOffset = value.translation.width

                                guard let fromIndex = viewModel.scriptTabs.firstIndex(where: { $0.id == tab.id }) else { return }

                                if dragOffset > swapThreshold, fromIndex < viewModel.scriptTabs.count - 1 {
                                    viewModel.scriptTabs.swapAt(fromIndex, fromIndex + 1)
                                    dragOffset -= swapThreshold
                                } else if dragOffset < -swapThreshold, fromIndex > 0 {
                                    viewModel.scriptTabs.swapAt(fromIndex, fromIndex - 1)
                                    dragOffset += swapThreshold
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    dragOffset = 0
                                    draggingTabId = nil
                                }
                            }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 28)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    /// Keyboard/VoiceOver alternative to drag-reordering.
    private func moveTab(_ id: UUID, by delta: Int) {
        guard let from = viewModel.scriptTabs.firstIndex(where: { $0.id == id }) else { return }
        let to = from + delta
        guard viewModel.scriptTabs.indices.contains(to) else { return }
        viewModel.scriptTabs.swapAt(from, to)
        announceForAccessibility("\(viewModel.scriptTabs[to].displayTitle) moved to position \(to + 2) of \(viewModel.scriptTabs.count + 1)")
    }
}

private struct TabItem: View {
    let title: String
    let isSelected: Bool
    let isRunning: Bool
    let tint: Color
    let onSelect: () -> Void
    let onClose: (() -> Void)?
    var onMoveLeft: (() -> Void)? = nil
    var onMoveRight: (() -> Void)? = nil

    @State private var isHovering = false
    // Increase Contrast: darker text and solid borders so low-vision users can tell tabs apart
    @Environment(\.colorSchemeContrast) private var contrast
    private var highContrast: Bool { contrast == .increased }

    var body: some View {
        HStack(spacing: 4) {
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovering || isSelected || isRunning ? 1 : 0)
                .help("Close Tab")
            }
            if isRunning {
                ProgressView()
                    .controlSize(.mini)
                    .scaleEffect(0.6)
            }
            Text(title)
                .font(.system(size: 11))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .foregroundStyle(isSelected ? tint : (highContrast ? .primary : .secondary))
        .background(
            Capsule()
                .fill(
                    isSelected
                        ? tint.opacity(0.2)
                        : isHovering ? tint.opacity(0.1) : Color(nsColor: .separatorColor).opacity(0.5)
                )
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    highContrast
                        ? (isSelected ? tint : Color.primary.opacity(0.6))
                        : (isSelected ? tint.opacity(0.5) : Color(nsColor: .separatorColor).opacity(0.3)),
                    lineWidth: highContrast ? (isSelected ? 2 : 1) : 0.5
                )
        )
        .contentShape(Capsule())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
        // Tap gesture alone is invisible to VoiceOver — expose the tab as a selectable button
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isRunning ? "Running" : "")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityAction(.default, onSelect)
        .accessibilityActions {
            if let onClose {
                Button("Close Tab", action: onClose)
            }
            if let onMoveLeft {
                Button("Move Tab Left", action: onMoveLeft)
            }
            if let onMoveRight {
                Button("Move Tab Right", action: onMoveRight)
            }
        }
    }
}
