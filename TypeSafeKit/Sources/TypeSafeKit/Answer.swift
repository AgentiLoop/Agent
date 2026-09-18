// Typed answers. Every answer carries a `type` matching its question.
// Choice and Score also carry `confidence` (0...1) derived from the distribution;
// Noul has no separate confidence.

import Foundation

public struct NoulAnswer: Sendable, Hashable, Decodable {
    /// Probability that the answer is yes. Near 1 is a strong yes, near 0 a
    /// strong no, near 0.5 uncertain.
    public let noul: Double

    public init(noul: Double) { self.noul = noul }
}

public struct ChoiceAnswer: Sendable, Hashable, Decodable {
    /// The highest-probability option.
    public let choice: String
    /// Every option mapped to its probability; sums to 1.
    public let probabilities: [String: Double]
    public let confidence: Double

    public init(choice: String, probabilities: [String: Double], confidence: Double) {
        self.choice = choice
        self.probabilities = probabilities
        self.confidence = confidence
    }
}

public struct ScoreAnswer: Sendable, Hashable, Decodable {
    /// Probability-weighted position across the levels; can land between levels.
    public let score: Double
    /// Each level number mapped back to its description.
    public let legend: [String: String]
    /// Each level (string key) mapped to its probability; sums to 1.
    public let probabilities: [String: Double]
    public let confidence: Double

    public init(
        score: Double,
        legend: [String: String],
        probabilities: [String: Double],
        confidence: Double
    ) {
        self.score = score
        self.legend = legend
        self.probabilities = probabilities
        self.confidence = confidence
    }

    /// The description of the nearest whole level, if the legend has one.
    public var nearestLevel: String? {
        legend[String(Int(score.rounded()))]
    }
}

public enum Answer: Sendable, Hashable, Decodable {
    case noul(NoulAnswer)
    case choice(ChoiceAnswer)
    case score(ScoreAnswer)

    enum CodingKeys: String, CodingKey { case type }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(QuestionType.self, forKey: .type) {
        case .noul: self = .noul(try NoulAnswer(from: decoder))
        case .choice: self = .choice(try ChoiceAnswer(from: decoder))
        case .score: self = .score(try ScoreAnswer(from: decoder))
        }
    }

    public var type: QuestionType {
        switch self {
        case .noul: .noul
        case .choice: .choice
        case .score: .score
        }
    }

    /// Noul probability, or nil for other answer types.
    public var noulValue: Double? {
        if case .noul(let answer) = self { answer.noul } else { nil }
    }

    /// Selected Choice option, or nil for other answer types.
    public var choiceValue: String? {
        if case .choice(let answer) = self { answer.choice } else { nil }
    }

    /// Score position, or nil for other answer types.
    public var scoreValue: Double? {
        if case .score(let answer) = self { answer.score } else { nil }
    }

    /// Confidence for Choice and Score. Noul reports none.
    public var confidence: Double? {
        switch self {
        case .noul: nil
        case .choice(let answer): answer.confidence
        case .score(let answer): answer.confidence
        }
    }

    /// Distribution for Choice and Score. Noul reports none.
    public var probabilities: [String: Double]? {
        switch self {
        case .noul: nil
        case .choice(let answer): answer.probabilities
        case .score(let answer): answer.probabilities
        }
    }
}
