import Foundation

/// Compatibility layer between Agent! and TypeSafe's **Jev** (System One) model.
///
/// Jev is not a text-generating LLM and cannot drive the tool loop: it evaluates
/// typed questions against a `state` and returns structured answers (Choice /
/// Score / Noul). This service exposes it as a *decision layer* the existing
/// loop can consult — "should this command run?", "which tool fits?", "did this
/// result satisfy the goal?" — not as an `APIProvider`.
///
/// Wire format: `POST https://api.typesafe.ai/v1/systemone`, Bearer auth.
/// See https://docs.typesafe.ai/api
final class JevService: Sendable {
    static let shared = JevService()

    static let baseURL = "https://api.typesafe.ai/v1"
    static let defaultModel = "jev-latest"
    /// UserDefaults key for the model the Settings picker writes.
    static let modelDefaultsKey = "jevModel"

    private init() {}

    // MARK: - Configuration

    var apiKey: String {
        (KeychainService.shared.get(.jev) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var model: String {
        let stored = UserDefaults.standard.string(forKey: Self.modelDefaultsKey) ?? ""
        return stored.isEmpty ? Self.defaultModel : stored
    }

    /// Jev is only consulted when the user has configured a key.
    var isConfigured: Bool { !apiKey.isEmpty }

    // MARK: - Questions

    /// One typed question. `id` is the key the answer comes back under; it is
    /// never sent to the model, so `instructions` must be self-contained.
    enum Question: Sendable {
        /// Yes/no. `criteria` optionally describes what yes and no mean.
        case noul(instructions: String, yes: String? = nil, no: String? = nil)
        /// Pick one option. `criteria` maps option → description (description may be empty).
        case choice(instructions: String, options: [String: String])
        /// Rate along ordered levels (at least two).
        case score(instructions: String, levels: [String])

        var payload: [String: Any] {
            switch self {
            case let .noul(instructions, yes, no):
                var q: [String: Any] = ["type": "noul", "instructions": instructions]
                if yes != nil || no != nil {
                    var criteria: [String: Any] = [:]
                    if let yes { criteria["true"] = yes }
                    if let no { criteria["false"] = no }
                    q["criteria"] = criteria
                }
                return q
            case let .choice(instructions, options):
                let criteria = options.mapValues { $0.isEmpty ? NSNull() as Any : $0 as Any }
                return ["type": "choice", "instructions": instructions, "criteria": criteria]
            case let .score(instructions, levels):
                return ["type": "score", "instructions": instructions, "criteria": levels]
            }
        }
    }

    // MARK: - Answers

    enum Answer: Sendable {
        /// Probability the answer is yes, 0...1.
        case noul(Double)
        case choice(choice: String, confidence: Double, probabilities: [String: Double])
        case score(score: Double, confidence: Double, legend: [String: String], probabilities: [String: Double])

        /// The Noul probability, or nil for other answer types.
        var noulValue: Double? { if case let .noul(v) = self { v } else { nil } }
        /// The selected Choice label, or nil for other answer types.
        var choiceValue: String? { if case let .choice(c, _, _) = self { c } else { nil } }
        /// The Score position, or nil for other answer types.
        var scoreValue: Double? { if case let .score(s, _, _, _) = self { s } else { nil } }
        /// Confidence for Choice/Score. Noul has none — the probability *is* the signal.
        var confidence: Double? {
            switch self {
            case .noul: nil
            case let .choice(_, c, _): c
            case let .score(_, c, _, _): c
            }
        }
    }

    struct Response: Sendable {
        let model: String
        let answers: [String: Answer]
        let inputTokens: Int
        let outputTokens: Int
    }

    enum JevError: LocalizedError {
        case notConfigured
        case badURL
        case http(status: Int, body: String)
        case malformedResponse(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: "Jev API key not set. Add it in Settings."
            case .badURL: "Invalid Jev endpoint URL."
            case let .http(status, body): "Jev API returned \(status): \(body.prefix(300))"
            case let .malformedResponse(detail): "Malformed Jev response: \(detail)"
            }
        }
    }

    // MARK: - Core call

    /// Evaluates `state` against every question in one request. Jev ingests the
    /// state once and answers all questions in parallel, so batching is free —
    /// send speculative questions rather than making a second call.
    ///
    /// `state` may be a `String`, or any JSON-encodable object/array.
    func ask(state: Any, questions: [String: Question], maxRetries: Int = 2) async throws -> Response {
        guard isConfigured else { throw JevError.notConfigured }
        guard let url = URL(string: "\(Self.baseURL)/systemone") else { throw JevError.badURL }

        let body: [String: Any] = [
            "state": state,
            "model": model,
            "questions": questions.mapValues(\.payload)
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        var attempt = 0
        while true {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw JevError.malformedResponse("no HTTP response")
            }
            // 429 / 529 are the documented back-off codes.
            if (http.statusCode == 429 || http.statusCode == 529), attempt < maxRetries {
                let retryAfter = (http.value(forHTTPHeaderField: "retry-after")).flatMap(Double.init)
                let delay = retryAfter ?? pow(2, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                attempt += 1
                continue
            }
            guard (200..<300).contains(http.statusCode) else {
                throw JevError.http(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
            }
            return try Self.decode(data)
        }
    }

    private static func decode(_ data: Data) throws -> Response {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw JevError.malformedResponse("top level is not an object")
        }
        guard let rawAnswers = json["answers"] as? [String: [String: Any]] else {
            throw JevError.malformedResponse("missing `answers`")
        }

        var answers: [String: Answer] = [:]
        for (id, raw) in rawAnswers {
            switch raw["type"] as? String {
            case "noul":
                if let v = raw["noul"] as? Double { answers[id] = .noul(v) }
            case "choice":
                if let choice = raw["choice"] as? String {
                    answers[id] = .choice(
                        choice: choice,
                        confidence: raw["confidence"] as? Double ?? 0,
                        probabilities: raw["probabilities"] as? [String: Double] ?? [:]
                    )
                }
            case "score":
                if let score = raw["score"] as? Double {
                    answers[id] = .score(
                        score: score,
                        confidence: raw["confidence"] as? Double ?? 0,
                        legend: raw["legend"] as? [String: String] ?? [:],
                        probabilities: raw["probabilities"] as? [String: Double] ?? [:]
                    )
                }
            default:
                continue
            }
        }

        let usage = json["usage"] as? [String: Any]
        return Response(
            model: json["model"] as? String ?? "",
            answers: answers,
            inputTokens: usage?["input_tokens"] as? Int ?? 0,
            outputTokens: usage?["output_tokens"] as? Int ?? 0
        )
    }

    // MARK: - Single-question convenience

    /// Probability that `question` is true of `state`, or nil if Jev is
    /// unconfigured or the call failed. Call sites treat nil as "no opinion"
    /// and fall back to their existing behaviour.
    func noul(_ question: String, state: Any, yes: String? = nil, no: String? = nil) async -> Double? {
        try? await ask(state: state, questions: ["q": .noul(instructions: question, yes: yes, no: no)])
            .answers["q"]?.noulValue
    }

    /// Selected option plus its confidence, or nil on failure.
    func choose(_ question: String, options: [String: String], state: Any) async -> (choice: String, confidence: Double)? {
        guard let answer = try? await ask(state: state, questions: ["q": .choice(instructions: question, options: options)]).answers["q"],
              case let .choice(choice, confidence, _) = answer
        else { return nil }
        return (choice, confidence)
    }

    /// Position along `levels` plus its confidence, or nil on failure.
    func score(_ question: String, levels: [String], state: Any) async -> (score: Double, confidence: Double)? {
        guard let answer = try? await ask(state: state, questions: ["q": .score(instructions: question, levels: levels)]).answers["q"],
              case let .score(score, confidence, _, _) = answer
        else { return nil }
        return (score, confidence)
    }

    // MARK: - Models

    struct ModelInfo: Identifiable, Sendable, Hashable {
        let name: String
        let description: String
        let releaseDate: String
        var id: String { name }
    }

    /// `GET /v1/models` — the aliases and versioned IDs this account may send.
    func listModels() async throws -> [ModelInfo] {
        guard isConfigured else { throw JevError.notConfigured }
        guard let url = URL(string: "\(Self.baseURL)/models") else { throw JevError.badURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw JevError.malformedResponse("no HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw JevError.http(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]]
        else { throw JevError.malformedResponse("missing `models`") }

        return models.compactMap { entry in
            guard let name = entry["name"] as? String else { return nil }
            return ModelInfo(
                name: name,
                description: entry["description"] as? String ?? "",
                releaseDate: entry["release_date"] as? String ?? ""
            )
        }
    }
}
