// Retry with exponential backoff, honoring `retry-after` when present.
// Defaults match the documented guidance for 429 and 529.

import Foundation

public struct RetryPolicy: Sendable, Hashable {
    /// Total attempts, including the first. 1 disables retrying.
    public var maxAttempts: Int
    /// Statuses worth retrying.
    public var retryableStatuses: Set<Int>
    /// Delay before the second attempt.
    public var initialBackoff: TimeInterval
    /// Multiplier applied to the delay after each attempt.
    public var backoffMultiplier: Double
    /// Ceiling for a single delay.
    public var maxBackoff: TimeInterval
    /// Random fraction of the delay added to spread out concurrent clients.
    public var jitter: Double
    /// Use the server's `retry-after` header instead of the computed delay.
    public var honorRetryAfterHeader: Bool

    public init(
        maxAttempts: Int = 3,
        retryableStatuses: Set<Int> = [408, 429, 500, 502, 503, 504, 529],
        initialBackoff: TimeInterval = 0.5,
        backoffMultiplier: Double = 2,
        maxBackoff: TimeInterval = 8,
        jitter: Double = 0.25,
        honorRetryAfterHeader: Bool = true
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.retryableStatuses = retryableStatuses
        self.initialBackoff = initialBackoff
        self.backoffMultiplier = backoffMultiplier
        self.maxBackoff = maxBackoff
        self.jitter = jitter
        self.honorRetryAfterHeader = honorRetryAfterHeader
    }

    public static let `default` = RetryPolicy()
    public static let none = RetryPolicy(maxAttempts: 1)

    /// Seconds to wait before `attempt` + 1, or nil when no retry is allowed.
    /// `attempt` is 1-based.
    func delay(afterAttempt attempt: Int, status: Int?, retryAfter: TimeInterval?) -> TimeInterval? {
        guard attempt < maxAttempts else { return nil }
        if let status, !retryableStatuses.contains(status) { return nil }
        if honorRetryAfterHeader, let retryAfter { return retryAfter }
        let exponential = initialBackoff * pow(backoffMultiplier, Double(attempt - 1))
        let capped = min(exponential, maxBackoff)
        return capped + capped * jitter * Double.random(in: 0...1)
    }
}
