import SwiftUI
import AppKit
import AgentColorSyntax
import AgentTerminalNeo

// MARK: - Coordinator: Render Pipeline

extension ActivityLogView.Coordinator {
    /// All rendering logic — runs on main thread but OUTSIDE SwiftUI's layout pass
    func performRender() {
        guard let textView = latestTextView, let scrollView = latestScrollView else {

            return
        }
        // Queued renders must use the model, not an older SwiftUI snapshot.
        if let textProvider { latestText = textProvider() }
        let text = latestText
        let searchText = latestSearchText
        let caseSensitive = latestCaseSensitive
        let currentMatchIndex = latestMatchIndex
        let onMatchCount = latestMatchCallback
        let tabID = latestTabID

        if text.isEmpty {
            // View > Bigger/Smaller Text on an empty log: redraw the placeholder at the new size
            let placeholderSize = ActivityLogTextSize.current
            let placeholderSizeChanged = placeholderSize != font.pointSize
            if placeholderSizeChanged {
                font = NSFont.monospacedSystemFont(ofSize: placeholderSize, weight: .regular)
                textView.font = font
                invalidateAllCaches()
            }
            // Invalidate old background results before acknowledging the clear.
            cancelAsyncRender()
            pendingRenderWork?.cancel()
            pendingRenderWork = nil
            pendingSearchWork?.cancel()
            pendingSearchWork = nil
            pendingScrollWork?.cancel()
            pendingScrollWork = nil
            lastRenderedText = ""
            tableAnchorText = nil
            tableAnchorStorage = nil
            lastSearchRanges = []
            savedForegroundColors = []
            userIsAtBottom = true
            guard !showingPlaceholder || placeholderSizeChanged else { return }
            if !showingPlaceholder {
                textView.alphaValue = 0
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.3
                    textView.animator().alphaValue = 1
                }
            }
            textView.textStorage?.setAttributedString(
                NSAttributedString(
                    string: "Ready. Enter a task below to begin.",
                    attributes: [.font: font, .foregroundColor: NSColor.secondaryLabelColor]
                )
            )
            showingPlaceholder = true
            lastLength = 0
            lastSearch = ""
            lastMatchIndex = -1
            clearCache()
            if let tabID { invalidateCache(for: tabID) }
            onMatchCount?(0)
            return
        }

        let len = (text as NSString).length
        let searchChanged = searchText != lastSearch || currentMatchIndex != lastMatchIndex
        let tabSwitched = forceTabSwitch || tabID != lastTabID
        forceTabSwitch = false

        let currentAppearance = scrollView.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        let textSize = ActivityLogTextSize.current
        let textSizeChanged = textSize != font.pointSize
        if textSizeChanged {
            // View > Bigger/Smaller Text: rebuild every line with the new base font
            font = NSFont.monospacedSystemFont(ofSize: textSize, weight: .regular)
            textView.font = font
            cancelAsyncRender()
        }
        let appearanceChanged = currentAppearance != lastAppearanceName || textSizeChanged
        if appearanceChanged {
            lastAppearanceName = currentAppearance
            lastLength = 0
            lastRenderedText = ""
            clearCache()
            invalidateAllCaches()
            CodeBlockTheme.updateAppearance()
            TerminalNeoTheme.updateAppearance()
        }

        // Cap-trim (`ScriptTab.capActivityLog`) drops the FRONT of the string, so at
        // steady state the log can change content while keeping the exact same length —
        // length alone would skip the render and freeze the view (e.g. ✅ Completed never shows).
        let sameLenContentChanged = len == lastLength && lastLength > 0 && text != lastRenderedText
        guard len != lastLength || sameLenContentChanged || showingPlaceholder || searchChanged || tabSwitched || appearanceChanged else { return }

        let textChanged = len != lastLength || sameLenContentChanged || showingPlaceholder
        let textGrew = len > lastLength
        let searchCleared = searchText.isEmpty && !lastSearch.isEmpty
        showingPlaceholder = false

        if tabSwitched {
            if let storage = textView.textStorage, lastLength > 0, !lastRenderedText.isEmpty {
                cacheAttributedString(NSAttributedString(attributedString: storage), for: lastTabID, text: lastRenderedText)
            }
            lastTabID = tabID
            clearCache()
            // Reset lastLength to 0 so the textChanged path treats this as fresh content
            lastLength = 0
            lastRenderedText = ""
            userIsAtBottom = true
            // A tab switch abandons any in-flight background render for the previous tab
            cancelAsyncRender()
            // Fall through to textChanged path — same scroll behavior as first load
        } else if asyncRenderInFlight, textChanged {
            // Background render still running — its completion re-enters performRender to pick up new text
            return
        }

        if textChanged || searchCleared {
            // The append fast-path is only safe if the WHOLE previously-rendered text is still an exact prefix of the
            // new text (a cap-trim or task-start reset shifts the front). Compare UTF-8 bytes with memcmp — a few MB
            // is sub-millisecond, unlike NSString substring + Unicode-aware `==`.
            let prefixIntact: Bool = {
                guard lastLength > 0, !lastRenderedText.isEmpty else { return true }
                guard len >= lastLength else { return false }
                return Self.utf8HasPrefix(text, lastRenderedText)
            }()
            // Task start cap-trims the FRONT of the log (keepRecentTasks). Drop the same task
            // sections from the rendered storage instead of re-rendering the whole log — the
            // full re-render path would show the "Processing tab data…" overlay mid-task.
            if !prefixIntact, !tabSwitched, !appearanceChanged, !searchCleared,
               let storage = textView.textStorage,
               trimRenderedFront(to: text, storage: storage) {
                userIsAtBottom = true
                if len == lastLength {
                    // Nothing appended after the trim — storage already matches `text`.
                    lastSearch = searchText
                    lastMatchIndex = currentMatchIndex
                    snapToEnd(textView)
                    return
                }
            }
            let isAppending = len > lastLength && lastLength > 0 && !searchCleared && Self.utf8HasPrefix(text, lastRenderedText)

            if isAppending, let storage = textView.textStorage {
                let prevLen = lastLength
                let nsText = text as NSString
                let newText = nsText.substring(from: prevLen)
                // Auto-scroll to bottom when a new task starts
                if newText.contains(AgentViewModel.newTaskMarker) {
                    userIsAtBottom = true
                }
                let newLines = newText.components(separatedBy: "\n")
                let hasTableLines = newLines.contains { $0.trimmingCharacters(in: .whitespaces).hasPrefix("|") }
                // Only the last few lines before the append point matter — never split the whole prefix.
                let tailStart = max(0, prevLen - 2048)
                let prevTail = nsText.substring(with: NSRange(location: tailStart, length: prevLen - tailStart))
                    .components(separatedBy: "\n").suffix(3)
                let prevHasTableLines = prevTail.contains { $0.trimmingCharacters(in: .whitespaces).hasPrefix("|") }

                // Freeze scroll position during text mutation to prevent tearing
                let wasAtBottom = userIsAtBottom
                let savedY = scrollView.contentView.bounds.origin.y

                CATransaction.begin()
                CATransaction.setDisableActions(true)
                storage.beginEditing()
                if prevHasTableLines, let anchorText = tableAnchorText, let anchorStorage = tableAnchorStorage,
                   anchorText < prevLen, anchorStorage <= storage.length
                {
                    // A table is continuing across flushes: re-render only from where that table block started so
                    // column widths stay coherent, replacing the previously rendered block — O(table), not O(log).
                    let block = nsText.substring(from: anchorText)
                    storage.replaceCharacters(
                        in: NSRange(location: anchorStorage, length: storage.length - anchorStorage),
                        with: renderMarkdownOnly(block)
                    )
                } else {
                    if hasTableLines {
                        tableAnchorText = prevLen
                        tableAnchorStorage = storage.length
                    } else if !prevHasTableLines {
                        tableAnchorText = nil
                        tableAnchorStorage = nil
                    }
                    storage.append(renderMarkdownOnly(newText))
                }
                storage.endEditing()
                CATransaction.commit()

                // Restore scroll position if user was NOT at bottom
                if !wasAtBottom {
                    isProgrammaticScroll = true
                    scrollView.contentView.scroll(to: NSPoint(x: 0, y: savedY))
                    scrollView.reflectScrolledClipView(scrollView.contentView)
                    isProgrammaticScroll = false
                }

                lastLength = len
                lastRenderedText = text
            } else {
                let savedOrigin = scrollView.contentView.bounds.origin
                let wasAtBottom = tabSwitched || isNearBottom(textView)
                tableAnchorText = nil
                tableAnchorStorage = nil
                // Try instant swap from cached TextStorage (no re-layout)
                if tabSwitched, swapToCachedStorage(for: tabID, text: text, textView: textView, scrollView: scrollView) {
                    // Cache hit — layout preserved, scroll restored
                } else if len > Self.asyncRenderThreshold {
                    // Big log, no cache: parse off-main behind a progress overlay. lastLength /
                    // lastRenderedText are committed when the result lands (see finishAsyncRender).
                    startAsyncFullRender(text: text, len: len, tabID: tabID, textView: textView, scrollView: scrollView)
                    return
                } else {
                    textView.textStorage?.beginEditing()
                    textView.textStorage?.setAttributedString(buildAttributedString(from: text))
                    textView.textStorage?.endEditing()
                    if !wasAtBottom {
                        scrollView.contentView.scroll(to: savedOrigin)
                        scrollView.reflectScrolledClipView(scrollView.contentView)
                    }
                }
                lastLength = len
                lastRenderedText = text
            }
        }

        if !searchText.isEmpty || !lastSearch.isEmpty {
            if searchChanged {
                pendingRenderWork?.cancel()
                applySearchHighlighting(
                    textView: textView,
                    searchText: searchText,
                    caseSensitive: caseSensitive,
                    currentMatch: currentMatchIndex,
                    onMatchCount: onMatchCount
                )
            } else if textChanged && !searchText.isEmpty {
                pendingRenderWork?.cancel()
                let work = DispatchWorkItem { [weak self] in
                    guard let self, let tv = self.latestTextView else { return }
                    self.applySearchHighlighting(
                        textView: tv, searchText: self.latestSearchText,
                        caseSensitive: self.latestCaseSensitive,
                        currentMatch: self.latestMatchIndex,
                        onMatchCount: self.latestMatchCallback
                    )
                }
                pendingRenderWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
            }
        }
        lastSearch = searchText
        lastMatchIndex = currentMatchIndex

        if textGrew {
            throttledScrollToEnd(textView)
        }
    }

    // MARK: - Front Trim

    /// `text` is `lastRenderedText` with its front dropped by `capActivityLog` (and possibly new
    /// lines appended). Delete the same front from `storage` so the remainder can take the append
    /// fast-path instead of a full re-render (which shows the "Processing tab data…" overlay).
    /// Two shapes:
    /// - task-count cap: `text` starts with `newTaskMarker`; whole task sections were dropped.
    ///   The marker renders literally, so the k-th marker from the end lines up in source and storage.
    /// - byte cap: `text` starts with `trimBanner`; the kept remainder begins on a line boundary.
    ///   Its first line (a timestamped log line, rendered literally) locates the cut in storage.
    /// Returns false (storage untouched) when `text` isn't a front-trimmed continuation.
    private func trimRenderedFront(to text: String, storage: NSTextStorage) -> Bool {
        guard lastLength > 0, !lastRenderedText.isEmpty else { return false }
        let banner = ScriptTab.trimBanner
        if text.hasPrefix(banner) {
            return trimRenderedFrontToBanner(text: text, banner: banner, storage: storage)
        }
        return trimRenderedFrontToMarker(text: text, storage: storage)
    }

    private func trimRenderedFrontToBanner(text: String, banner: String, storage: NSTextStorage) -> Bool {
        let body = (text as NSString).substring(from: (banner as NSString).length) as NSString
        let old = lastRenderedText as NSString
        let rendered = storage.string as NSString
        let oldStart = lastRenderedText.hasPrefix(banner) ? (banner as NSString).length : 0
        let nl = body.range(of: "\n").location
        guard nl != NSNotFound, nl > 0 else { return false }
        let firstLine = body.substring(to: nl + 1)
        // Cut in the old text: first line-start occurrence of the kept remainder's first line
        // whose suffix is a prefix of `body`.
        var search = NSRange(location: oldStart, length: old.length - oldStart)
        var cut: Int?
        while search.length > 0 {
            let r = old.range(of: firstLine, options: [], range: search)
            guard r.location != NSNotFound else { break }
            let lineStart = r.location == 0 || old.character(at: r.location - 1) == 10
            if lineStart, Self.utf8HasPrefix(body as String, old.substring(from: r.location)) {
                cut = r.location
                break
            }
            search = NSRange(location: r.location + 1, length: old.length - r.location - 1)
        }
        guard let cut else { return false }
        // Same line in the rendered storage (log lines are timestamped, so effectively unique).
        var back = NSRange(location: 0, length: rendered.length)
        var storageCut: Int?
        while back.length > 0 {
            let r = rendered.range(of: firstLine, options: [], range: back)
            guard r.location != NSNotFound else { break }
            if r.location == 0 || rendered.character(at: r.location - 1) == 10 {
                storageCut = r.location
                break
            }
            back = NSRange(location: r.location + 1, length: rendered.length - r.location - 1)
        }
        guard let storageCut else { return false }
        storage.beginEditing()
        storage.deleteCharacters(in: NSRange(location: 0, length: storageCut))
        storage.insert(renderMarkdownOnly(banner), at: 0)
        storage.endEditing()
        tableAnchorText = nil
        tableAnchorStorage = nil
        lastRenderedText = banner + old.substring(from: cut)
        lastLength = (lastRenderedText as NSString).length
        return true
    }

    private func trimRenderedFrontToMarker(text: String, storage: NSTextStorage) -> Bool {
        let marker = AgentViewModel.newTaskMarker
        let old = lastRenderedText as NSString
        let rendered = storage.string as NSString
        // Walk marker occurrences in the old text from the front; the first whose suffix is a
        // prefix of `text` is the cut (largest possible kept remainder).
        var search = NSRange(location: 0, length: old.length)
        var cut: Int?
        while search.length > 0 {
            let r = old.range(of: marker, options: [], range: search)
            guard r.location != NSNotFound else { break }
            if r.location > 0, Self.utf8HasPrefix(text, old.substring(from: r.location)) {
                cut = r.location
                break
            }
            search = NSRange(location: r.location + r.length, length: old.length - r.location - r.length)
        }
        guard let cut else { return false }
        // k = markers kept in the old text from the cut onward.
        var k = 0
        var scan = NSRange(location: cut, length: old.length - cut)
        while scan.length > 0 {
            let r = old.range(of: marker, options: [], range: scan)
            guard r.location != NSNotFound else { break }
            k += 1
            scan = NSRange(location: r.location + r.length, length: old.length - r.location - r.length)
        }
        guard k > 0 else { return false }
        // Find the k-th marker from the end of the rendered storage.
        var storageCut: Int?
        var back = NSRange(location: 0, length: rendered.length)
        for _ in 0..<k {
            let r = rendered.range(of: marker, options: .backwards, range: back)
            guard r.location != NSNotFound else { return false }
            storageCut = r.location
            back = NSRange(location: 0, length: r.location)
        }
        guard let storageCut, storageCut > 0 else { return false }
        storage.beginEditing()
        storage.deleteCharacters(in: NSRange(location: 0, length: storageCut))
        storage.endEditing()
        tableAnchorText = nil
        tableAnchorStorage = nil
        lastRenderedText = old.substring(from: cut)
        lastLength = (lastRenderedText as NSString).length
        return true
    }

    // MARK: - Async Full Render

    /// Moves a non-Sendable NSAttributedString across the background → main hop.
    private struct RenderedBox: @unchecked Sendable { let value: NSAttributedString }

    /// Parse a large log on a background thread, showing a centered progress overlay meanwhile.
    /// The text view is emptied first so the previous tab's content never bleeds through.
    /// The bar is determinate while the parse runs (chars consumed / total, reported by
    /// `buildAttributedString`), then flips to indeterminate for the final TextKit layout,
    /// which gives no progress and would otherwise look frozen at 100 %.
    func startAsyncFullRender(text: String, len: Int, tabID: UUID?, textView: NSTextView, scrollView: NSScrollView) {
        asyncRenderGeneration += 1
        let generation = asyncRenderGeneration
        asyncRenderInFlight = true
        textView.textStorage?.setAttributedString(NSAttributedString())
        textView.alphaValue = 1
        showLoadingOverlay(in: scrollView)
        setLoadingBarDeterminate(true)

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let box = RenderedBox(value: self.buildAttributedString(from: text) { [weak self] fraction in
                Task { @MainActor [weak self] in
                    self?.updateLoadingProgress(fraction, generation: generation)
                }
            })
            await MainActor.run {
                self.finishAsyncRender(box, len: len, text: text, tabID: tabID, generation: generation)
            }
        }
    }

    /// Push a background-parse progress value to the bar. Stale generations are ignored;
    /// values that move the bar <1 % are dropped so a 200-line stride can't flood main.
    private func updateLoadingProgress(_ fraction: Double, generation: Int) {
        guard generation == asyncRenderGeneration, asyncRenderInFlight, let bar = loadingBar else { return }
        guard fraction - lastReportedProgress >= 0.01 || fraction >= 1 else { return }
        lastReportedProgress = fraction
        bar.doubleValue = fraction
    }

    private func finishAsyncRender(_ box: RenderedBox, len: Int, text: String, tabID: UUID?, generation: Int) {
        // Stale: tab switched or a newer render started while this one was running
        guard generation == asyncRenderGeneration, tabID == latestTabID else { return }
        // Parse done — the remaining work is TextKit layout, which reports nothing.
        // Flip the bar to indeterminate and give AppKit one runloop turn to draw
        // that before the synchronous setAttributedString blocks main.
        setLoadingBarDeterminate(false)
        DispatchQueue.main.async { [weak self] in
            guard let self, generation == self.asyncRenderGeneration, tabID == self.latestTabID else { return }
            self.asyncRenderInFlight = false
            guard let textView = self.latestTextView else { self.hideLoadingOverlay(); return }
            textView.textStorage?.beginEditing()
            textView.textStorage?.setAttributedString(box.value)
            textView.textStorage?.endEditing()
            self.hideLoadingOverlay()
            self.lastLength = len
            self.lastRenderedText = text
            self.snapToEnd(textView)
            // Pick up anything that streamed in (or a search change) while we were rendering
            self.performRender()
        }
    }

    /// Abandon an in-flight background render (tab switch). Its result is discarded on arrival.
    func cancelAsyncRender() {
        guard asyncRenderInFlight else { return }
        asyncRenderGeneration += 1
        asyncRenderInFlight = false
        hideLoadingOverlay()
    }

    private func showLoadingOverlay(in scrollView: NSScrollView) {
        if let overlay = loadingOverlay {
            overlay.isHidden = false
            return
        }
        let overlay = NSView(frame: scrollView.bounds)
        overlay.autoresizingMask = [.width, .height]
        overlay.wantsLayer = true
        overlay.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.6).cgColor

        let bar = NSProgressIndicator()
        bar.style = .bar
        bar.minValue = 0
        bar.maxValue = 1
        bar.isIndeterminate = true
        bar.controlSize = .regular
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.widthAnchor.constraint(equalToConstant: 240).isActive = true
        bar.startAnimation(nil)
        loadingBar = bar

        let label = NSTextField(labelWithString: "Processing tab data…")
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabelColor
        label.alignment = .center

        let stack = NSStackView(views: [bar, label])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])

        scrollView.addSubview(overlay, positioned: .above, relativeTo: nil)
        loadingOverlay = overlay
    }

    private func hideLoadingOverlay() {
        loadingOverlay?.isHidden = true
    }

    /// Determinate (0…1, driven by `updateLoadingProgress`) for the background parse;
    /// indeterminate for phases that can't report progress (final TextKit layout).
    private func setLoadingBarDeterminate(_ determinate: Bool) {
        guard let bar = loadingBar else { return }
        lastReportedProgress = 0
        if determinate {
            bar.stopAnimation(nil)
            bar.isIndeterminate = false
            bar.doubleValue = 0
        } else {
            bar.isIndeterminate = true
            bar.startAnimation(nil)
        }
    }
}
