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
            // Fall through to textChanged path — same scroll behavior as first load
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
}
