// The three TypeSafe question primitives. All share `type` and `instructions`;
// each adds its own `criteria`. Questions are keyed by IDs you choose; the ID is
// not sent to the model, so put the whole question in `instructions`.

import Foundation

public enum QuestionType: String, Sendable, Hashable, Codable {
    case noul, choice, score
}

/// Optional descriptions of what a yes and a no mean for a Noul question.
public struct NoulCriteria: Sendable, Hashable, Codable {
    public var yes: String?
    public var no: String?

    public init(yes: String? = nil, no: String? = nil) {
        self.yes = yes
        self.no = no
    }

    enum CodingKeys: String, CodingKey {
        case yes = "true"
        case no = "false"
    }
}

public enum Question: Sendable, Encodable {
    /// Yes/no. Returns the probability the answer is yes.
    case noul(instructions: String, criteria: NoulCriteria? = nil)
    /// Picks one option from a set. `criteria` maps option to rubric description;
    /// a nil description is sent as JSON null.
    case choice(instructions: String, criteria: [String: String?])
    /// Rates the state along an ordered rubric. At least two levels are required.
    case score(instructions: String, levels: [String])

    /// Choice options that need no extra description.
    public static func choice(instructions: String, options: [String]) -> Question {
        .choice(instructions: instructions, criteria: Dictionary(
            uniqueKeysWithValues: options.map { ($0, nil) }))
    }

    public var type: QuestionType {
        switch self {
        case .noul: .noul
        case .choice: .choice
        case .score: .score
        }
    }

    public var instructions: String {
        switch self {
        case .noul(let instructions, _),
             .choice(let instructions, _),
             .score(let instructions, _):
            instructions
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, instructions, criteria
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(instructions, forKey: .instructions)
        switch self {
        case .noul(_, let criteria):
            try container.encodeIfPresent(criteria, forKey: .criteria)
        case .choice(_, let criteria):
            var options = container.nestedContainer(
                keyedBy: AnyCodingKey.self, forKey: .criteria)
            for key in criteria.keys.sorted() {
                if let description = criteria[key] ?? nil {
                    try options.encode(description, forKey: AnyCodingKey(key))
                } else {
                    try options.encodeNil(forKey: AnyCodingKey(key))
                }
            }
        case .score(_, let levels):
            try container.encode(levels, forKey: .criteria)
        }
    }

    /// Mirrors the server's 422 validation so obvious mistakes fail locally.
    func validate(id: String) throws {
        if instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw TypeSafeError.invalidRequest("Question '\(id)' has empty instructions")
        }
        switch self {
        case .noul:
            break
        case .choice(_, let criteria):
            if criteria.isEmpty {
                throw TypeSafeError.invalidRequest("Choice question '\(id)' has no options")
            }
        case .score(_, let levels):
            if levels.count < 2 {
                throw TypeSafeError.invalidRequest(
                    "Score question '\(id)' needs at least two levels")
            }
        }
    }
}

struct AnyCodingKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }

    init(_ stringValue: String) { self.stringValue = stringValue }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}
