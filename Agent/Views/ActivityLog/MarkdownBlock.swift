import SwiftUI
import AppKit
import AgentColorSyntax

// MARK: - Coordinator: Block-Level Markdown Rendering Fenced code blocks, headers, bullets, blockquotes, horizontal
// rules, and NSTextTable-backed markdown tables.

/// Progress reporting for a background full render (see `startAsyncFullRender`).
/// The unit of progress is UTF-16 characters consumed of the whole log: `base` is
/// the offset of the segment currently being rendered, `total` the full length.
/// That 0…1 char fraction is mapped into the `lower`…`upper` window so each render
/// phase (ANSI strip, path scans, fence scan, line walk) owns a slice of the bar and
/// the bar keeps moving from start to finish instead of sitting at 0 % while the
/// whole-string passes run. `report` is called from the render thread.
struct RenderProgress: Sendable {
    let total: Int
    let base: Int
    let lower: Double
    let upper: Double
    let report: @Sendable (Double) -> Void

    init(total: Int, base: Int, lower: Double = 0, upper: Double = 1, report: @escaping @Sendable (Double) -> Void) {
        self.total = total
        self.base = base
        self.lower = lower
        self.upper = upper
        self.report = report
    }

    /// Same reporter, re-based for a sub-segment starting `delta` chars into this one.
    func offset(by delta: Int) -> RenderProgress {
        RenderProgress(total: total, base: base + delta, lower: lower, upper: upper, report: report)
    }

    /// Same reporter, restricted to the `from`…`to` slice (0…1) of this one's window.
    func phase(_ from: Double, _ to: Double) -> RenderProgress {
        let span = upper - lower
        return RenderProgress(total: total, base: base, lower: lower + from * span, upper: lower + to * span, report: report)
    }

    /// Report that `localOffset` chars of the current segment are done.
    func consumed(_ localOffset: Int) {
        let fraction = min(1, Double(base + localOffset) / Double(max(total, 1)))
        report(lower + fraction * (upper - lower))
    }

    /// Chars between reports for the line walk — ~0.5 % of the log, never finer than 2 KB.
    var charStride: Int { max(total / 200, 2048) }
}

extension ActivityLogView.Coordinator {
    nonisolated func renderMarkdown(_ text: String, progress: RenderProgress? = nil) -> NSAttributedString {
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]
        // Whole-segment passes (line split, code heuristics, fence scan) own the first
        // slice of this segment's bar window; the line walk gets the rest.
        let prep = progress?.phase(0, 0.08)
        let walk = progress?.phase(0.08, 1)
        let segLength = (text as NSString).length

        // Check if the text is read_file output (strictly matches "NN |" at the start of lines)
        // This check MUST come before markdown processing to preserve backticks in code
        let readFilePattern = #"^\s*\d+\s*\|\s"#
        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        let isReadFileOutput = !lines.isEmpty
            && lines.allSatisfy { line in
                line.range(of: readFilePattern, options: .regularExpression) != nil
            }

        if isReadFileOutput {
            let hl = CodeBlockHighlighter.highlight(code: text, language: "swift", font: font)
            let block = NSMutableAttributedString(attributedString: hl)
            block.addAttribute(
                .backgroundColor,
                value: CodeBlockTheme.bg,
                range: NSRange(location: 0, length: block.length)
            )
            progress?.consumed(segLength)
            return block
        }

        // Detect source code output (e.g. from cat command) — look for Swift/code patterns Skip this heuristic if text
        // contains markdown indicators (headers, fences, bullets) to avoid treating markdown summaries with embedded code as raw code output
        let hasMarkdownStructure = lines.contains { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            return t.hasPrefix("#") || t.hasPrefix("```") || t.hasPrefix("- ") || t.hasPrefix("* ")
        }
        let codeIndicators = [
            "import ",
            "func ",
            "class ",
            "struct ",
            "enum ",
            "protocol ",
            "@MainActor",
            "@Observable",
            "let ",
            "var ",
            "private ",
            "public ",
            "extension "
        ]
        let codeLineCount = lines
            .filter { line in codeIndicators.contains(where: { line.trimmingCharacters(in: .whitespaces).hasPrefix($0) }) }.count
        let isCodeOutput = !hasMarkdownStructure && lines.count >= 3 && codeLineCount >= 2

        if isCodeOutput {
            let hl = CodeBlockHighlighter.highlight(code: text, language: "swift", font: font)
            let block = NSMutableAttributedString(attributedString: hl)
            block.addAttribute(
                .backgroundColor,
                value: CodeBlockTheme.bg,
                range: NSRange(location: 0, length: block.length)
            )
            progress?.consumed(segLength)
            return block
        }
        // Line split + code heuristics are done — first visible movement for this segment.
        prep?.consumed(segLength / 4)

        // Handle code fences (```lang\n...\n```) first
        guard let fenceRx = MarkdownPatterns.fencePattern else { return NSAttributedString(string: text, attributes: baseAttrs) }
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        // Enumerate rather than `matches(in:)` so a fence-heavy multi-MB log reports as the
        // scan advances instead of going quiet until the last match is found.
        var fences: [NSTextCheckingResult] = []
        fenceRx.enumerateMatches(in: text, range: fullRange) { match, _, _ in
            guard let match else { return }
            fences.append(match)
            prep?.consumed(segLength / 4 + (match.range.location + match.range.length) * 3 / 4)
        }
        prep?.consumed(segLength)

        guard !fences.isEmpty else {
            return renderInlineMarkdown(text, progress: walk)
        }

        let result = NSMutableAttributedString()
        var cursor = 0

        for fence in fences {
            if fence.range.location > cursor {
                let seg = nsText.substring(with: NSRange(location: cursor, length: fence.range.location - cursor))
                result.append(renderInlineMarkdown(seg, progress: walk?.offset(by: cursor)))
            }

            let lang = fence.range(at: 1).length > 0 ? nsText.substring(with: fence.range(at: 1)) : nil
            var code = nsText.substring(with: fence.range(at: 2))
            if code.hasSuffix("\n") { code = String(code.dropLast()) }

            // Copy button only for actual source code blocks (not shell output or file reads)
            let shellLangs: Set<String> = ["bash", "sh", "zsh", "shell", "console", "terminal"]
            let firstLine = code.components(separatedBy: "\n").first ?? ""
            let looksLikeNumberedOutput = firstLine.range(of: #"^\s*\d+\s+"#, options: .regularExpression) != nil
            let isSourceCode = (lang.map { !shellLangs.contains($0.lowercased()) } ?? false) && !looksLikeNumberedOutput
            if isSourceCode {
                let attach = makeAttachmentOnMain { [code] in CopyButtonCell(codeText: code) }
                let rightPara = NSMutableParagraphStyle()
                rightPara.alignment = .right
                let copyStr = NSMutableAttributedString(attachment: attach)
                copyStr.addAttribute(.paragraphStyle, value: rightPara, range: NSRange(location: 0, length: copyStr.length))
                result.append(copyStr)
            }

            // Syntax-highlighted code with background
            let hl = CodeBlockHighlighter.highlight(code: code, language: lang, font: font)
            let block = NSMutableAttributedString(string: "\n", attributes: baseAttrs)
            block.append(hl)
            block.append(NSAttributedString(string: "\n", attributes: baseAttrs))
            block.addAttribute(
                .backgroundColor,
                value: CodeBlockTheme.bg,
                range: NSRange(location: 0, length: block.length)
            )
            result.append(block)

            cursor = fence.range.location + fence.range.length
            walk?.consumed(cursor)
        }

        if cursor < nsText.length {
            result.append(renderInlineMarkdown(
                nsText.substring(with: NSRange(location: cursor, length: nsText.length - cursor)),
                progress: walk?.offset(by: cursor)
            ))
        }

        return result
    }

    /// Splits text into lines and renders block-level markdown (headers, lists, rules, tables)
    /// then delegates inline rendering (bold, italic, code) per line.
    /// `progress` (background full renders only) is fed the running UTF-16 offset every
    /// `progressLineStride` lines or `charStride` chars (whichever comes first, so a few
    /// huge lines still move the bar) — this walk is where the bulk of render time goes.
    nonisolated func renderInlineMarkdown(_ text: String, progress: RenderProgress? = nil) -> NSAttributedString {
        guard !text.isEmpty else { return NSAttributedString() }

        let result = NSMutableAttributedString()
        let lines = text.components(separatedBy: "\n")
        var i = 0
        // UTF-16 chars consumed so far (lines + the "\n" separators between them)
        var consumed = 0
        var linesSinceReport = 0
        var consumedAtReport = 0
        let progressLineStride = 200
        let progressCharStride = progress?.charStride ?? Int.max
        progress?.consumed(0)

        while i < lines.count {
            // Detect markdown table blocks (consecutive lines starting with |)
            if lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                var tableLines: [String] = []
                var j = i
                while j < lines.count && lines[j].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                    tableLines.append(lines[j])
                    j += 1
                }
                if tableLines.count >= 3, isTableSeparator(tableLines[1]),
                   let tableAttr = renderMarkdownTable(tableLines)
                {
                    result.append(tableAttr)
                    if let progress {
                        consumed += tableLines.reduce(0) { $0 + $1.utf16.count + 1 }
                        linesSinceReport += tableLines.count
                        if linesSinceReport >= progressLineStride || consumed - consumedAtReport >= progressCharStride {
                            progress.consumed(consumed)
                            linesSinceReport = 0
                            consumedAtReport = consumed
                        }
                    }
                    i = j
                    continue
                }
            }

            // Regular line
            result.append(renderMarkdownLine(lines[i]))
            if i < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: [.font: font]))
            }
            if let progress {
                consumed += lines[i].utf16.count + 1
                linesSinceReport += 1
                if linesSinceReport >= progressLineStride || consumed - consumedAtReport >= progressCharStride {
                    progress.consumed(consumed)
                    linesSinceReport = 0
                    consumedAtReport = consumed
                }
            }
            i += 1
        }
        progress?.consumed(consumed)

        return result
    }

    // MARK: - Markdown Table Rendering (NSTextTable)

    nonisolated func isTableSeparator(_ line: String) -> Bool {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("|") else { return false }
        var inner = t[t.index(after: t.startIndex)...]
        if inner.hasSuffix("|") { inner = inner.dropLast() }
        let cells = inner.split(separator: "|", omittingEmptySubsequences: false)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let s = cell.trimmingCharacters(in: .whitespaces)
            return !s.isEmpty && s.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }

    nonisolated func parseTableRow(_ line: String) -> [String] {
        let t = line.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("|") else { return [] }
        var inner = t[t.index(after: t.startIndex)...]
        if inner.hasSuffix("|") { inner = inner.dropLast() }
        return inner.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    nonisolated func renderMarkdownTable(_ lines: [String]) -> NSAttributedString? {
        let headerCells = parseTableRow(lines[0])
        guard !headerCells.isEmpty else { return nil }

        let sepCells = parseTableRow(lines[1])
        let alignments: [NSTextAlignment] = sepCells.map { cell in
            let left = cell.hasPrefix(":")
            let right = cell.hasSuffix(":")
            if left && right { return .center }
            if right { return .right }
            return .left
        }

        var dataRows: [[String]] = []
        for idx in 2..<lines.count {
            let cells = parseTableRow(lines[idx])
            if !cells.isEmpty { dataRows.append(cells) }
        }

        let colCount = headerCells.count
        let table = NSTextTable()
        table.numberOfColumns = colCount
        table.layoutAlgorithm = .automaticLayoutAlgorithm
        table.collapsesBorders = true
        table.hidesEmptyCells = false

        let result = NSMutableAttributedString()
        let borderColor = NSColor.separatorColor
        let headerBg = NSColor.controlAccentColor.withAlphaComponent(0.15)
        let boldFont = NSFont.monospacedSystemFont(ofSize: font.pointSize, weight: .bold)

        for (col, cell) in headerCells.prefix(colCount).enumerated() {
            let align = col < alignments.count ? alignments[col] : .left
            result.append(makeTableCell(
                text: cell, table: table, row: 0, column: col,
                bg: headerBg, cellFont: boldFont, align: align, border: borderColor
            ))
        }

        let evenBg = NSColor.controlBackgroundColor
        let oddBg = NSColor.windowBackgroundColor
        for (rowIdx, row) in dataRows.enumerated() {
            let bg = (rowIdx % 2 == 0) ? evenBg : oddBg
            for col in 0..<colCount {
                let cellText = col < row.count ? row[col] : ""
                let align = col < alignments.count ? alignments[col] : .left
                result.append(makeTableCell(
                    text: cellText, table: table, row: rowIdx + 1, column: col,
                    bg: bg, cellFont: font, align: align, border: borderColor
                ))
            }
        }

        return result
    }

    nonisolated func makeTableCell(
        text: String, table: NSTextTable, row: Int, column: Int,
        bg: NSColor, cellFont: NSFont, align: NSTextAlignment, border: NSColor
    ) -> NSAttributedString {
        let block = NSTextTableBlock(
            table: table, startingRow: row, rowSpan: 1,
            startingColumn: column, columnSpan: 1
        )
        block.backgroundColor = bg
        block.setBorderColor(border)
        block.setWidth(0.5, type: .absoluteValueType, for: .border)
        block.setWidth(5.0, type: .absoluteValueType, for: .padding)

        let style = NSMutableParagraphStyle()
        style.textBlocks = [block]
        style.alignment = align

        let rendered = renderInlineElements(text, baseFont: cellFont)
        let cell = NSMutableAttributedString(attributedString: rendered)
        cell.append(NSAttributedString(string: "\n"))
        cell.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: cell.length))
        return cell
    }

    /// Renders a single line, detecting block-level elements first, then inline.
    nonisolated func renderMarkdownLine(_ line: String) -> NSAttributedString {
        let nsLine = line as NSString
        let fullRange = NSRange(location: 0, length: nsLine.length)

        // Horizontal rule (check before bullet since --- could conflict)
        if MarkdownPatterns.hrPattern?.firstMatch(in: line, range: fullRange) != nil {
            let result = NSMutableAttributedString()
            let attachment = makeAttachmentOnMain { HRLineCell(color: .separatorColor) }
            result.append(NSAttributedString(attachment: attachment))
            return result
        }

        // Header
        if let match = MarkdownPatterns.headerPattern?.firstMatch(in: line, range: fullRange) {
            let level = nsLine.substring(with: match.range(at: 1)).count
            let content = nsLine.substring(with: match.range(at: 2))
            let size: CGFloat
            switch level {
            case 1: size = font.pointSize * 1.5
            case 2: size = font.pointSize * 1.3
            case 3: size = font.pointSize * 1.15
            default: size = font.pointSize
            }
            let headerFont = NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
            return renderInlineElements(content, baseFont: headerFont)
        }

        // Bullet list
        if let match = MarkdownPatterns.bulletPattern?.firstMatch(in: line, range: fullRange) {
            let indent = nsLine.substring(with: match.range(at: 1))
            let content = nsLine.substring(with: match.range(at: 2))
            let result = NSMutableAttributedString()
            result.append(NSAttributedString(
                string: indent + "  \u{2022} ",
                attributes: [.font: font, .foregroundColor: NSColor.secondaryLabelColor]
            ))
            result.append(renderInlineElements(content, baseFont: font))
            return result
        }

        // Blockquote
        if let match = MarkdownPatterns.blockquotePattern?.firstMatch(in: line, range: fullRange) {
            let content = nsLine.substring(with: match.range(at: 1))
            let result = NSMutableAttributedString()
            result.append(NSAttributedString(
                string: "\u{258E} ",
                attributes: [.font: font, .foregroundColor: NSColor.systemBlue]
            ))
            let rendered = renderInlineElements(content, baseFont: font)
            let mutableRendered = NSMutableAttributedString(attributedString: rendered)
            let rRange = NSRange(location: 0, length: mutableRendered.length)
            mutableRendered.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: rRange)
            result.append(mutableRendered)
            return result
        }

        // Activity log output (timestamps, grep results) — bypass markdown parser but still linkify URLs
        if let highlighted = CodeBlockHighlighter.highlightActivityLogLine(line: line, font: font) {
            return linkifyURLs(highlighted)
        }

        // Regular line — inline elements only
        return renderInlineElements(line, baseFont: font)
    }
}
