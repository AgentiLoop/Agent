import SwiftUI
import AppKit

// MARK: - Coordinator: Scroll Helpers

extension ActivityLogView.Coordinator {
    /// Check if scroll view is near the bottom
    func isNearBottom(_ textView: NSTextView) -> Bool {
        guard let scrollView = textView.enclosingScrollView else { return true }
        let visibleBottom = scrollView.contentView.bounds.origin.y + scrollView.contentView.bounds.height
        let contentHeight = textView.frame.height
        return (contentHeight - visibleBottom) < 300
    }

    /// Instant scroll to end — no animation
    func snapToEnd(_ textView: NSTextView) {
        guard let scrollView = textView.enclosingScrollView,
              let textContainer = textView.textContainer else
        {
            textView.scrollToEndOfDocument(nil)
            return
        }
        isProgrammaticScroll = true
        textView.layoutManager?.ensureLayout(for: textContainer)
        textView.scrollToEndOfDocument(nil)
        scrollView.reflectScrolledClipView(scrollView.contentView)
        isProgrammaticScroll = false
        userIsAtBottom = true
    }

    /// Smooth animated scroll to end
    func smoothScrollToEnd(_ textView: NSTextView) {
        guard let scrollView = textView.enclosingScrollView,
              let textContainer = textView.textContainer else
        {
            textView.scrollToEndOfDocument(nil)
            return
        }
        textView.layoutManager?.ensureLayout(for: textContainer)
        let contentHeight = textView.frame.height
        let clipHeight = scrollView.contentView.bounds.height
        let targetY = max(0, contentHeight - clipHeight)
        // Already there — nothing to animate
        guard abs(scrollView.contentView.bounds.origin.y - targetY) > 0.5 else {
            userIsAtBottom = true
            return
        }
        isProgrammaticScroll = true
        smoothScrollGeneration += 1
        let generation = smoothScrollGeneration
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            // Ease-out so retargeting mid-animation (new streamed text) stays fluid
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: targetY))
        } completionHandler: {
            MainActor.assumeIsolated { [weak self] in
                // A newer animation superseded this one — let it finish
                guard let self, generation == self.smoothScrollGeneration else { return }
                scrollView.reflectScrolledClipView(scrollView.contentView)
                self.isProgrammaticScroll = false
                self.userIsAtBottom = true
            }
        }
    }

    /// Throttled scroll — at most once per 0.1s, skipped if user scrolled away from bottom.
    /// Animates (smooth) to the bottom; each new call retargets the in-flight animation.
    func throttledScrollToEnd(_ textView: NSTextView) {
        guard userIsAtBottom else { return }
        let now = CFAbsoluteTimeGetCurrent()
        let interval: CFAbsoluteTime = 0.1
        pendingScrollWork?.cancel()
        if now - lastScrollTime >= interval {
            lastScrollTime = now
            smoothScrollToEnd(textView)
        } else {
            let work = DispatchWorkItem { [weak self, weak textView] in
                guard let self, let textView else { return }
                guard self.userIsAtBottom else { return }
                self.lastScrollTime = CFAbsoluteTimeGetCurrent()
                self.smoothScrollToEnd(textView)
            }
            pendingScrollWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: work)
        }
    }
}
