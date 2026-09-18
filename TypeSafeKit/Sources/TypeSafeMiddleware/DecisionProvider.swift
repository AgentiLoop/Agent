// Middleware layer: one protocol Agent!-style loops depend on, plus the typed
// decision helpers built on top of it. Jev is not a chat model — it returns no
// text and no tool calls — so this deliberately does NOT imitate a chat
// completion API. It exposes the decisions an agent loop actually needs:
// route, gate, rate, and weighted composites.

import Foundation
import TypeSafeKit

/// Anything that can evaluate typed questions against a state.
/// `TypeSafeClient` conforms via `JevProvider`; stub it in tests.
public protocol DecisionProvider: Sendable {
    func decide(state: State, questions: [String: Question]) async throws -> [String: Answer]
}

/// Result of a Choice question mapped back onto a Swift enum.
public struct Routing<Route: Hashable & Sendable>: Sendable {
    public let route: Route
    public let confidence: Double
    public let probabilities: [Route: Double]
    /// Whether `confidence` cleared the threshold the caller asked for.
    public let isConfident: Bool
}

/// Result of a Noul question.
public struct Gate: Sendable, Hashable {
    /// Probability the statement is true.
    public let probability: Double
    public let threshold: Double
    public var passed: Bool { probability >= threshold }
}

/// Result of a Score question.
public struct Rating: Sendable, Hashable {
    public let score: Double
    /// Description of the nearest whole level, when the legend names one.
    public let level: String?
    public let confidence: Double
    public let isConfident: Bool
    /// `score` mapped to 0...1 across the supplied levels.
    public let normalized: Double
}

/// Weighted combination of atomic scores, per the composite scoring pattern.
public struct Composite: Sendable {
    /// Weighted sum of the normalized component scores.
    public let total: Double
    /// Each component's score mapped to 0...1.
    public let normalized: [String: Double]
    public let answers: [String: Answer]
}

public enum MiddlewareError: Error, Sendable, LocalizedError {
    case missingAnswer(String)
    case wrongAnswerType(id: String, expected: QuestionType, got: QuestionType)
    case unknownOption(id: String, option: String)
    case noRoutes

    public var errorDescription: String? {
        switch self {
        case .missingAnswer(let id):
            "No answer returned for question '\(id)'"
        case .wrongAnswerType(let id, let expected, let got):
            "Question '\(id)' returned a \(got.rawValue) answer, expected \(expected.rawValue)"
        case .unknownOption(let id, let option):
            "Question '\(id)' returned option '\(option)', which was not in criteria"
        case .noRoutes:
            "The route type has no cases"
        }
    }
}

extension DecisionProvider {
    /// Classifies `state` into one case of `Route`. Enum raw values become the
    /// Choice options; `descriptions` supplies each option's rubric.
    public func route<Route>(
        _ state: State,
        instructions: String,
        as routeType: Route.Type,
        descriptions: [Route: String] = [:],
        minimumConfidence: Double = 0,
        id: String = "route"
    ) async throws -> Routing<Route>
    where Route: CaseIterable & RawRepresentable<String> & Hashable & Sendable {
        let cases = Array(Route.allCases)
        guard !cases.isEmpty else { throw MiddlewareError.noRoutes }
        var criteria: [String: String?] = [:]
        for option in cases { criteria[option.rawValue] = descriptions[option] }

        let answers = try await decide(
            state: state,
            questions: [id: .choice(instructions: instructions, criteria: criteria)])
        guard let answer = answers[id] else { throw MiddlewareError.missingAnswer(id) }
        guard case .choice(let choice) = answer else {
            throw MiddlewareError.wrongAnswerType(
                id: id, expected: .choice, got: answer.type)
        }
        guard let route = Route(rawValue: choice.choice) else {
            throw MiddlewareError.unknownOption(id: id, option: choice.choice)
        }

        var probabilities: [Route: Double] = [:]
        for (option, probability) in choice.probabilities {
            if let key = Route(rawValue: option) { probabilities[key] = probability }
        }
        return Routing(
            route: route,
            confidence: choice.confidence,
            probabilities: probabilities,
            isConfident: choice.confidence >= minimumConfidence)
    }

    /// Yes/no gate. `statement` is judged against the state; `threshold` decides
    /// what counts as a pass.
    public func gate(
        _ state: State,
        statement: String,
        threshold: Double = 0.5,
        criteria: NoulCriteria? = nil,
        id: String = "gate"
    ) async throws -> Gate {
        let answers = try await decide(
            state: state,
            questions: [id: .noul(instructions: statement, criteria: criteria)])
        guard let answer = answers[id] else { throw MiddlewareError.missingAnswer(id) }
        guard let probability = answer.noulValue else {
            throw MiddlewareError.wrongAnswerType(id: id, expected: .noul, got: answer.type)
        }
        return Gate(probability: probability, threshold: threshold)
    }

    /// Rates the state along an ordered rubric.
    public func rate(
        _ state: State,
        instructions: String,
        levels: [String],
        minimumConfidence: Double = 0,
        id: String = "rating"
    ) async throws -> Rating {
        let answers = try await decide(
            state: state,
            questions: [id: .score(instructions: instructions, levels: levels)])
        guard let answer = answers[id] else { throw MiddlewareError.missingAnswer(id) }
        guard case .score(let score) = answer else {
            throw MiddlewareError.wrongAnswerType(id: id, expected: .score, got: answer.type)
        }
        return Rating(
            score: score.score,
            level: score.nearestLevel,
            confidence: score.confidence,
            isConfident: score.confidence >= minimumConfidence,
            normalized: Self.normalize(score))
    }

    /// Asks every question in one request, then weights the Score answers.
    /// Weights default to 1 for any component you leave out.
    public func composite(
        _ state: State,
        components: [String: Question],
        weights: [String: Double] = [:]
    ) async throws -> Composite {
        let answers = try await decide(state: state, questions: components)
        var normalized: [String: Double] = [:]
        var total = 0.0
        for (id, answer) in answers {
            guard case .score(let score) = answer else { continue }
            let value = Self.normalize(score)
            normalized[id] = value
            total += value * (weights[id] ?? 1)
        }
        return Composite(total: total, normalized: normalized, answers: answers)
    }

    /// Passthrough for the speculative fan-out pattern: many questions, one call.
    public func evaluate(
        _ state: State,
        questions: [String: Question]
    ) async throws -> [String: Answer] {
        try await decide(state: state, questions: questions)
    }

    static func normalize(_ score: ScoreAnswer) -> Double {
        let top = Double(max(score.legend.count - 1, 1))
        return min(max(score.score / top, 0), 1)
    }
}
