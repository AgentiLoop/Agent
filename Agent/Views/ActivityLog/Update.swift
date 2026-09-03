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
        let text = latestText
        let searchText = latestSearchText
        let caseSensitive = latestCaseSensitive
        let currentMatchIndex = latestMatchIndex
        let onMatchCount = latestMatchCallback
        let tabID = latestTabID

        if text.isEmpty {
            guard !showingPlaceholder else { return }
            textView.alphaValue = 0
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.3
                textView.animator().alphaValue = 1
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
        let appearanceChanged = currentAppearance != lastAppearanceName
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
            let isAppending = len > lastLength && lastLength > 0 && !searchCleared && prefixIntact

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

    // MARK: - Async Full Render

    /// Moves a non-Sendable NSAttributedString across the background → main hop.
    private struct RenderedBox: @unchecked Sendable { let value: NSAttributedString }

    /// Parse a large log on a background thread, showing a centered progress overlay meanwhile.
    /// The text view is emptied first so the previous tab's content never bleeds through.
    func startAsyncFullRender(text: String, len: Int, tabID: UUID?, textView: NSTextView, scrollView: NSScrollView) {
        asyncRenderGeneration += 1
        let generation = asyncRenderGeneration
        asyncRenderInFlight = true
        textView.textStorage?.setAttributedString(NSAttributedString())
        textView.alphaValue = 1
        showLoadingOverlay(in: scrollView)

        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let box = RenderedBox(value: self.buildAttributedString(from: text))
            await MainActor.run {
                self.finishAsyncRender(box, len: len, text: text, tabID: tabID, generation: generation)
            }
        }
    }

    private func finishAsyncRender(_ box: RenderedBox, len: Int, text: String, tabID: UUID?, generation: Int) {
        // Stale: tab switched or a newer render started while this one was running
        guard generation == asyncRenderGeneration, tabID == latestTabID else { return }
        asyncRenderInFlight = false
        hideLoadingOverlay()
        guard let textView = latestTextView else { return }
        textView.textStorage?.beginEditing()
        textView.textStorage?.setAttributedString(box.value)
        textView.textStorage?.endEditing()
        lastLength = len
        lastRenderedText = text
        snapToEnd(textView)
        // Pick up anything that streamed in (or a search change) while we were rendering
        performRender()
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
        bar.isIndeterminate = true
        bar.controlSize = .regular
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.widthAnchor.constraint(equalToConstant: 240).isActive = true
        bar.startAnimation(nil)

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
}
