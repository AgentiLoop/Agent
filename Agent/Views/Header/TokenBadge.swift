import SwiftUI
import Charts

struct TokenBadge: View {
    let taskIn: Int
    let taskOut: Int
    let sessionIn: Int
    let sessionOut: Int
    var providerName: String = ""
    var modelName: String = ""
    /// Fraction of per-task token budget used (0.0–1.0). 0 = no budget set.
    var budgetUsedFraction: Double = 0

    @State private var showDetail: Bool = false
    @Environment(\.colorSchemeContrast) private var contrast
    private var highContrast: Bool { contrast == .increased }

    var body: some View {
        Button {
            showDetail.toggle()
        } label: {
            let total = TokenUsageStore.shared.todayInput + TokenUsageStore.shared.todayOutput
            HStack(spacing: 4) {
                Text(formatTokens(total))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(highContrast ? .primary : .secondary)
                if budgetUsedFraction > 0 {
                    Text("\(Int(budgetUsedFraction * 100))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(budgetUsedFraction >= 0.9 ? .red : budgetUsedFraction >= 0.7 ? .orange : highContrast ? .primary : .secondary)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.1))
            .overlay(Capsule().stroke(highContrast ? Color.primary.opacity(0.8) : Color.clear, lineWidth: 1))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Token usage today")
        .accessibilityValue(accessibilityValueText)
        .accessibilityHint("Shows token usage details")
        .popover(isPresented: $showDetail) {
            TokenDetailView(
                taskIn: taskIn, taskOut: taskOut,
                sessionIn: sessionIn, sessionOut: sessionOut,
                providerName: providerName, modelName: modelName
            )
        }
    }

    private var accessibilityValueText: String {
        let total = TokenUsageStore.shared.todayInput + TokenUsageStore.shared.todayOutput
        var text = "\(formatTokens(total)) tokens"
        if budgetUsedFraction > 0 {
            text += ", \(Int(budgetUsedFraction * 100))% of task budget used"
        }
        return text
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Detail Popover

private struct TokenDetailView: View {
    let taskIn: Int
    let taskOut: Int
    let sessionIn: Int
    let sessionOut: Int
    let providerName: String
    let modelName: String
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var noColor
    private var highContrast: Bool { contrast == .increased }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text("Token Usage")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Text("Current session breakdown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .padding(.bottom, 4)

            Divider()

            // Provider & Model
            if !providerName.isEmpty {
                row {
                    Text("Provider").font(.subheadline)
                    Spacer()
                    Text(providerName)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                }
            }

            if !modelName.isEmpty {
                row {
                    Text("Model").font(.subheadline)
                    Spacer()
                    Text(shortModel(modelName))
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Task tokens
            row {
                Text("Task").font(.subheadline)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    tokenBar(label: "↑", value: taskIn, color: .blue, max: max(taskIn, taskOut))
                    tokenBar(label: "↓", value: taskOut, color: .green, max: max(taskIn, taskOut))
                }
            }

            // Session tokens
            row {
                Text("Session").font(.subheadline)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    tokenBar(label: "↑", value: sessionIn, color: .blue, max: max(sessionIn, sessionOut))
                    tokenBar(label: "↓", value: sessionOut, color: .green, max: max(sessionIn, sessionOut))
                }
            }

            // Today
            let store = TokenUsageStore.shared
            row {
                Text("Today").font(.subheadline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("↑ \(fmt(store.todayInput))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.blue)
                        .accessibilityLabel("Sent \(fmt(store.todayInput))")
                    Text("↓ \(fmt(store.todayOutput))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.green)
                        .accessibilityLabel("Received \(fmt(store.todayOutput))")
                    Text("Total: \(fmt(store.todayInput + store.todayOutput))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    if store.todayCacheRead > 0 {
                        Text("⚡︎ Cache: \(fmt(store.todayCacheRead))")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.cyan)
                            .accessibilityLabel("Cache \(fmt(store.todayCacheRead))")
                    }
                }
            }

            // Daily chart
            let recent = store.recentDays(7)
            if !recent.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    Text("Daily Usage (7 days) — tokens are est.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Chart {
                        ForEach(recent, id: \.date) { day in
                            // PointMarks ensure single-day data is visible — LineMark
                            // alone draws nothing when there's only one data point.
                            PointMark(
                                x: .value("Date", shortDate(day.date)),
                                y: .value("Tokens", day.inputTokens)
                            )
                            .foregroundStyle(.blue)
                            .symbol(noColor ? .circle : .circle)
                            .symbolSize(40)

                            PointMark(
                                x: .value("Date", shortDate(day.date)),
                                y: .value("Tokens", day.outputTokens)
                            )
                            .foregroundStyle(.green)
                            .symbol(noColor ? .square : .circle)
                            .symbolSize(40)

                            PointMark(
                                x: .value("Date", shortDate(day.date)),
                                y: .value("Tokens", day.cacheReadTokens)
                            )
                            .foregroundStyle(.cyan)
                            .symbol(noColor ? .triangle : .circle)
                            .symbolSize(40)

                            LineMark(
                                x: .value("Date", shortDate(day.date)),
                                y: .value("Tokens", day.inputTokens),
                                series: .value("Type", "Sent")
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: noColor ? [] : []))
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Date", shortDate(day.date)),
                                y: .value("Tokens", day.outputTokens),
                                series: .value("Type", "Received")
                            )
                            .foregroundStyle(.green)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: noColor ? [5, 3] : []))
                            .interpolationMethod(.catmullRom)

                            LineMark(
                                x: .value("Date", shortDate(day.date)),
                                y: .value("Tokens", day.cacheReadTokens),
                                series: .value("Type", "Cache")
                            )
                            .foregroundStyle(.cyan)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: noColor ? [1, 3] : []))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Int.self) {
                                    Text(fmt(v)).font(.caption2)
                                }
                            }
                            AxisGridLine()
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { value in
                            AxisValueLabel {
                                if let s = value.as(String.self) {
                                    Text(s).font(.caption2)
                                }
                            }
                        }
                    }
                    .chartLegend(.hidden)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Daily usage chart, last 7 days")
                    .accessibilityValue(recent.map { "\(shortDate($0.date)): sent \(fmt($0.inputTokens)), received \(fmt($0.outputTokens)), cache \(fmt($0.cacheReadTokens))" }.joined(separator: "; "))
                    .frame(height: 120)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    // Legend
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: noColor ? "circle.fill" : "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.blue)
                            Text("↑ Sent").font(.caption2).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: noColor ? "square.fill" : "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.green)
                            Text("↓ Received").font(.caption2).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: noColor ? "triangle.fill" : "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.cyan)
                            Text("⚡︎ Cache").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .accessibilityHidden(true)
                }
            }
        }
        .padding(.bottom, 15)
        .frame(width: 320)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack { content() }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func tokenBar(label: String, value: Int, color: Color, max: Int) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(highContrast ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                .frame(width: 24, alignment: .trailing)
            GeometryReader { geo in
                let fraction: CGFloat = max > 0 ? CGFloat(value) / CGFloat(max) : 0
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.opacity(highContrast ? 1 : 0.5))
                    .frame(width: geo.size.width * fraction)
            }
            .frame(width: 80, height: 8)
            Text(fmt(value))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(highContrast ? .primary : .secondary)
                .frame(width: 50, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label == "↑" ? "Sent" : "Received") \(fmt(value))")
    }

    private func fmt(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }

    private func shortDate(_ dateStr: String) -> String {
        // "2026-03-29" → "Mar 29"
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3, let day = Int(parts[2]) else { return dateStr }
        let months = ["", "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        let month = Int(parts[1]) ?? 0
        return month > 0 && month <= 12 ? "\(months[month]) \(day)" : dateStr
    }

    private func shortModel(_ model: String) -> String {
        // Trim long model IDs like "claude-sonnet-4-20250514" to "claude-sonnet-4"
        let parts: [String] = model.components(separatedBy: "-")
        if parts.count > 3, let last = parts.last, last.count == 8, Int(last) != nil {
            return parts.dropLast().joined(separator: "-")
        }
        return model
    }
}
