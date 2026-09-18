// Request and response envelopes for POST /v1/systemone and GET /v1/models.

import Foundation

public struct SystemOneRequest: Sendable, Encodable {
    public var state: State
    public var model: String
    public var questions: [String: Question]

    public init(state: State, questions: [String: Question], model: String = Model.jevLatest) {
        self.state = state
        self.questions = questions
        self.model = model
    }

    func validate() throws {
        if questions.isEmpty {
            throw TypeSafeError.invalidRequest("A request needs at least one question")
        }
        for (id, question) in questions {
            try question.validate(id: id)
        }
    }
}

public struct Usage: Sendable, Hashable, Decodable {
    public let inputTokens: Int
    /// Output tokens are reported but not billed.
    public let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

public struct SystemOneResponse: Sendable, Hashable, Decodable {
    /// The versioned model that performed the evaluation, e.g. `jev-1.13.0`.
    public let model: String
    /// One answer per question, keyed by the same IDs you sent.
    public let answers: [String: Answer]
    public let usage: Usage

    /// The answer for `id`, or nil when the response carries no such key.
    public subscript(id: String) -> Answer? { answers[id] }
}

public struct ModelCard: Sendable, Hashable, Decodable {
    /// The model ID or alias, as accepted by the `model` field.
    public let name: String
    public let description: String
    public let releaseDate: String

    enum CodingKeys: String, CodingKey {
        case name, description
        case releaseDate = "release_date"
    }
}

struct ModelListResponse: Decodable {
    let models: [ModelCard]
}

/// Model names accepted by the `model` field. Aliases move when a release ships;
/// pin a versioned ID if you have tuned confidence thresholds against it.
public enum Model {
    /// Most recent stable release. Default for this client.
    public static let jevLatest = "jev-latest"
    /// Most recent release, official or not. Moves ahead of `jev-latest` when a
    /// preview build exists.
    public static let jevPreview = "jev-preview"
}

/// Error body returned alongside a non-2xx status.
public struct APIErrorBody: Sendable, Hashable, Decodable {
    public let message: String?
    public let type: String?
    public let detail: JSONValue?
}
