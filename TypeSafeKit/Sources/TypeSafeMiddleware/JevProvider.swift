// Jev-backed DecisionProvider, plus the usage totals an agent loop wants to log.

import Foundation
import TypeSafeKit

public struct JevProvider: DecisionProvider {
    public let client: TypeSafeClient
    public let model: String
    /// Called after every successful request with the model that answered and
    /// its token usage, so a host app can meter spend.
    public let onUsage: (@Sendable (String, Usage) -> Void)?

    public init(
        client: TypeSafeClient,
        model: String? = nil,
        onUsage: (@Sendable (String, Usage) -> Void)? = nil
    ) {
        self.client = client
        self.model = model ?? client.model
        self.onUsage = onUsage
    }

    /// Convenience: builds the client itself. The host app owns the credential
    /// and the endpoint, so both are passed in; leave them nil to fall back to
    /// `TYPESAFE_API_KEY` / `TYPESAFE_BASE_URL`.
    public init(
        apiKey: String? = nil,
        baseURL: URL? = nil,
        model: String = Model.jevLatest,
        retryPolicy: RetryPolicy = .default,
        onUsage: (@Sendable (String, Usage) -> Void)? = nil
    ) throws {
        self.init(
            client: try TypeSafeClient(
                apiKey: apiKey, baseURL: baseURL, model: model, retryPolicy: retryPolicy),
            model: model,
            onUsage: onUsage)
    }

    /// Model names this account may send. Surfaced here so a host app can fill
    /// a picker without importing the HTTP client directly.
    public func availableModels() async throws -> [ModelCard] {
        try await client.models.list()
    }

    public func decide(
        state: State,
        questions: [String: Question]
    ) async throws -> [String: Answer] {
        let response = try await client.systemOne(
            state: state, questions: questions, model: model)
        onUsage?(response.model, response.usage)
        return response.answers
    }
}
