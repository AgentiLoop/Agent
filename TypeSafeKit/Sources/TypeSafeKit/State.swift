// The `state` field of a System One request: the content Jev evaluates.
// Jev ingests the state once and evaluates every question against it in parallel.

import Foundation

public struct State: Sendable, Hashable, Encodable, ExpressibleByStringLiteral {
    public let value: JSONValue

    public init(_ text: String) { value = .string(text) }
    public init(_ values: [String]) { value = .array(values.map(JSONValue.string)) }
    public init(_ fields: [String: JSONValue]) { value = .object(fields) }
    public init(json: JSONValue) { value = json }
    public init(stringLiteral text: String) { value = .string(text) }

    /// Encodes any `Encodable` record as structured state.
    public static func encoding(_ record: some Encodable) throws -> State {
        State(json: try JSONValue.encoding(record))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
