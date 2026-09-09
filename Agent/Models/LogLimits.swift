import Foundation

/// Central caps + trim helper for LLM-bound tool-result data.
enum LogLimits {

    // MARK: - Named caps

    /// Batch shell command aggregate output cap.
    static let batchOutputChars = 50_000

    /// `web_fetch` cleaned HTML cap.
    static let webFetchChars = 8_000

    /// Short summary cap for sub-agent snapshots and compression.
    static let summaryChars = 2_000

    /// Outbound iMessage reply cap. iMessage tolerates ~65 KB but carriers
    /// may split anything bigger than ~4 KB unpredictably.
    static let messageReplyChars = 4_000

    /// Aggregate cap for merged config text (CLAUDE.md / agent.md / @include
    /// resolution). Keeps the merged-config block from blowing up the prompt.
    static let configMergeChars = 4_000

    /// Cap for the chat-history block injected into the system prompt
    /// (`ChatHistoryStore.buildLLMContext`). The recent task's full activity
    /// log used to go in uncapped — a big prior task produced a multi-MB
    /// system prompt that message compaction/pruning could never shrink.
    static let historyContextChars = 40_000

    /// Per-line cap for older-task prompt/summary lines in that block.
    static let historyLineChars = 500

    // MARK: - Shared trim helper

    /// Trim text to cap chars with a truncation banner if over.
    static func trim(
        _ text: String,
        cap: Int,
        lineCount: Int? = nil,
        suffix: String? = nil
    ) -> String {
        guard text.count > cap else { return text }
        var banner = "\n\n... [truncated — \(text.count) chars total"
        if let lineCount {
            banner += ", \(lineCount) lines"
        }
        banner += "."
        if let suffix, !suffix.isEmpty {
            banner += " \(suffix)"
        }
        banner += "]"
        return String(text.prefix(cap)) + banner
    }
}
