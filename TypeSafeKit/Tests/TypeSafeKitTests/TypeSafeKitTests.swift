import Foundation
import Testing
import TypeSafeKit
import TypeSafeMiddleware

final class Box: @unchecked Sendable {
    var requests: [URLRequest] = []
    var bodies: [Data] = []
    var attempts = 0
}

struct StubTransport: TypeSafeTransport {
    let box: Box
    let responses: [(status: Int, body: String, headers: [String: String])]

    init(box: Box, status: Int = 200, body: String, headers: [String: String] = [:]) {
        self.box = box
        self.responses = [(status, body, headers)]
    }

    init(box: Box, responses: [(status: Int, body: String, headers: [String: String])]) {
        self.box = box
        self.responses = responses
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        box.requests.append(request)
        if let body = request.httpBody { box.bodies.append(body) }
        let index = min(box.attempts, responses.count - 1)
        box.attempts += 1
        let canned = responses[index]
        let response = HTTPURLResponse(
            url: request.url!, statusCode: canned.status,
            httpVersion: "HTTP/1.1", headerFields: canned.headers)!
        return (Data(canned.body.utf8), response)
    }
}

let sampleResponse = """
{
  "model": "jev-1.13.0",
  "answers": {
    "is_urgent": { "type": "noul", "noul": 0.92 },
    "department": {
      "type": "choice",
      "choice": "technical",
      "probabilities": { "billing": 0.08, "technical": 0.85, "sales": 0.07 },
      "confidence": 0.82
    },
    "frustration": {
      "type": "score",
      "score": 1.6,
      "legend": { "0": "Calm", "1": "Frustrated", "2": "Very angry" },
      "probabilities": { "0": 0.05, "1": 0.3, "2": 0.65 },
      "confidence": 0.78
    }
  },
  "usage": { "input_tokens": 312, "output_tokens": 48 }
}
"""

func makeClient(_ transport: any TypeSafeTransport, retry: RetryPolicy = .none) throws -> TypeSafeClient {
    try TypeSafeClient(apiKey: "test-key", retryPolicy: retry, transport: transport)
}

@Test func decodesAllThreeAnswerTypes() async throws {
    let box = Box()
    let client = try makeClient(StubTransport(box: box, body: sampleResponse))
    let response = try await client.systemOne(
        state: "Help! My payouts have been failing for 3 days.",
        questions: [
            "is_urgent": .noul(instructions: "Does this convey urgency?"),
            "department": .choice(instructions: "Which team?", criteria: [
                "billing": "Payments", "technical": "Bugs", "sales": nil,
            ]),
            "frustration": .score(
                instructions: "How frustrated?",
                levels: ["Calm", "Frustrated", "Very angry"]),
        ])

    #expect(response.model == "jev-1.13.0")
    #expect(response["is_urgent"]?.noulValue == 0.92)
    #expect(response["department"]?.choiceValue == "technical")
    #expect(response["department"]?.confidence == 0.82)
    #expect(response["frustration"]?.scoreValue == 1.6)
    #expect(response.usage.inputTokens == 312)
    #expect(response.usage.outputTokens == 48)
    if case .score(let score) = response["frustration"]! {
        #expect(score.nearestLevel == "Very angry")
    } else {
        Issue.record("frustration was not a score answer")
    }
}

@Test func buildsDocumentedRequestShape() async throws {
    let box = Box()
    let client = try makeClient(StubTransport(box: box, body: sampleResponse))
    _ = try await client.systemOne(
        state: "Help!",
        questions: [
            "is_urgent": .noul(
                instructions: "Does this convey urgency?",
                criteria: NoulCriteria(yes: "Explicitly time-sensitive", no: "No urgency")),
            "department": .choice(instructions: "Which team?", criteria: [
                "billing": "Payments", "sales": nil,
            ]),
            "frustration": .score(instructions: "How frustrated?", levels: ["Calm", "Angry"]),
        ])

    let request = try #require(box.requests.first)
    #expect(request.url?.absoluteString == "https://api.typesafe.ai/v1/systemone")
    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

    let body = try #require(box.bodies.first)
    let json = try #require(
        try JSONSerialization.jsonObject(with: body) as? [String: Any])
    #expect(json["state"] as? String == "Help!")
    #expect(json["model"] as? String == "jev-latest")

    let questions = try #require(json["questions"] as? [String: Any])
    let noul = try #require(questions["is_urgent"] as? [String: Any])
    #expect(noul["type"] as? String == "noul")
    #expect((noul["criteria"] as? [String: Any])?["true"] as? String == "Explicitly time-sensitive")
    #expect((noul["criteria"] as? [String: Any])?["false"] as? String == "No urgency")

    let choice = try #require(questions["department"] as? [String: Any])
    let criteria = try #require(choice["criteria"] as? [String: Any])
    #expect(criteria["billing"] as? String == "Payments")
    #expect(criteria["sales"] is NSNull)

    let score = try #require(questions["frustration"] as? [String: Any])
    #expect(score["criteria"] as? [String] == ["Calm", "Angry"])
}

@Test func structuredStateEncodesAsJSON() async throws {
    let box = Box()
    let client = try makeClient(StubTransport(box: box, body: sampleResponse))
    _ = try await client.systemOne(
        state: State(["first message", "second message"]),
        questions: ["is_urgent": .noul(instructions: "Urgent?")])

    let json = try #require(
        try JSONSerialization.jsonObject(with: box.bodies[0]) as? [String: Any])
    #expect(json["state"] as? [String] == ["first message", "second message"])
}

@Test func mapsDocumentedErrorStatuses() async throws {
    let cases: [(Int, String)] = [(401, "auth"), (422, "validation"), (429, "slow down"), (529, "busy")]
    for (status, message) in cases {
        let client = try makeClient(StubTransport(
            box: Box(), responses: [(status, "{\"message\":\"\(message)\"}", [:])]))
        await #expect(throws: TypeSafeError.self) {
            _ = try await client.systemOne(
                state: "x", questions: ["q": .noul(instructions: "Urgent?")])
        }
    }

    let client = try makeClient(StubTransport(
        box: Box(), responses: [(429, "{}", ["retry-after": "3"])]))
    do {
        _ = try await client.systemOne(
            state: "x", questions: ["q": .noul(instructions: "Urgent?")])
        Issue.record("expected a rate limit error")
    } catch let error as TypeSafeError {
        #expect(error.statusCode == 429)
        #expect(error.retryAfter == 3)
    }
}

@Test func retriesOverloadedThenSucceeds() async throws {
    let box = Box()
    let transport = StubTransport(box: box, responses: [
        (529, "{}", [:]),
        (200, sampleResponse, [:]),
    ])
    let policy = RetryPolicy(maxAttempts: 2, initialBackoff: 0.01, maxBackoff: 0.01, jitter: 0)
    let client = try makeClient(transport, retry: policy)
    let response = try await client.systemOne(
        state: "x", questions: ["q": .noul(instructions: "Urgent?")])
    #expect(response.model == "jev-1.13.0")
    #expect(box.attempts == 2)
}

@Test func doesNotRetryClientErrors() async throws {
    let box = Box()
    let transport = StubTransport(box: box, responses: [(422, "{}", [:])])
    let client = try makeClient(transport, retry: RetryPolicy(maxAttempts: 4, initialBackoff: 0.01))
    _ = try? await client.systemOne(
        state: "x", questions: ["q": .noul(instructions: "Urgent?")])
    #expect(box.attempts == 1)
}

@Test func rejectsInvalidQuestionsLocally() async throws {
    let box = Box()
    let client = try makeClient(StubTransport(box: box, body: sampleResponse))
    await #expect(throws: TypeSafeError.self) {
        _ = try await client.systemOne(
            state: "x", questions: ["bad": .score(instructions: "Rate", levels: ["only one"])])
    }
    await #expect(throws: TypeSafeError.self) {
        _ = try await client.systemOne(state: "x", questions: [:])
    }
    #expect(box.attempts == 0)
}

@Test func listsModels() async throws {
    let body = """
    { "models": [ { "name": "jev-latest", "description": "Flagship", "release_date": "2026-09-16" } ] }
    """
    let box = Box()
    let client = try makeClient(StubTransport(box: box, body: body))
    let models = try await client.models.list()
    #expect(models.first?.name == "jev-latest")
    #expect(models.first?.releaseDate == "2026-09-16")
    #expect(box.requests.first?.url?.absoluteString == "https://api.typesafe.ai/v1/models")
    #expect(box.requests.first?.httpMethod == "GET")
}

@Test func missingKeyThrows() {
    #expect(throws: TypeSafeError.self) {
        _ = try TypeSafeClient(apiKey: "")
    }
}

// MARK: - Middleware

enum Department: String, CaseIterable, Sendable {
    case billing, technical, sales
}

struct FakeProvider: DecisionProvider {
    let box: Box
    let answers: [String: Answer]

    func decide(state: State, questions: [String: Question]) async throws -> [String: Answer] {
        box.attempts += 1
        return answers
    }
}

func answers(from json: String) throws -> [String: Answer] {
    try JSONDecoder().decode(SystemOneResponse.self, from: Data(json.utf8)).answers
}

@Test func middlewareRoutesOntoSwiftEnum() async throws {
    let provider = FakeProvider(
        box: Box(),
        answers: try answers(from: sampleResponse).reduce(into: [:]) { result, pair in
            if pair.key == "department" { result["route"] = pair.value }
        })
    let routing = try await provider.route(
        "Payouts failing",
        instructions: "Which team should handle this?",
        as: Department.self,
        descriptions: [.billing: "Payments", .technical: "Bugs", .sales: "Pricing"],
        minimumConfidence: 0.8)

    #expect(routing.route == .technical)
    #expect(routing.confidence == 0.82)
    #expect(routing.isConfident)
    #expect(routing.probabilities[.billing] == 0.08)
}

@Test func middlewareGateThresholds() async throws {
    let provider = FakeProvider(
        box: Box(), answers: ["gate": .noul(NoulAnswer(noul: 0.92))])
    let open = try await provider.gate("Payouts failing", statement: "Is this urgent?")
    #expect(open.passed)
    let strict = try await provider.gate(
        "Payouts failing", statement: "Is this urgent?", threshold: 0.95)
    #expect(!strict.passed)
    #expect(strict.probability == 0.92)
}

@Test func middlewareRateNormalizes() async throws {
    let scoreOnly = try answers(from: sampleResponse)["frustration"]!
    let provider = FakeProvider(box: Box(), answers: ["rating": scoreOnly])
    let rating = try await provider.rate(
        "Payouts failing",
        instructions: "How frustrated?",
        levels: ["Calm", "Frustrated", "Very angry"],
        minimumConfidence: 0.7)
    #expect(rating.score == 1.6)
    #expect(rating.level == "Very angry")
    #expect(abs(rating.normalized - 0.8) < 0.0001)
    #expect(rating.isConfident)
}

@Test func middlewareCompositeWeightsScores() async throws {
    let scoreOnly = try answers(from: sampleResponse)["frustration"]!
    let provider = FakeProvider(
        box: Box(), answers: ["severity": scoreOnly, "reach": scoreOnly])
    let composite = try await provider.composite(
        "Payouts failing",
        components: [
            "severity": .score(instructions: "Severity?", levels: ["Low", "Mid", "High"]),
            "reach": .score(instructions: "Reach?", levels: ["One", "Some", "All"]),
        ],
        weights: ["severity": 2, "reach": 0.5])
    #expect(abs(composite.total - (0.8 * 2 + 0.8 * 0.5)) < 0.0001)
    #expect(composite.normalized.count == 2)
}

@Test func middlewareSurfacesWrongAnswerType() async throws {
    let provider = FakeProvider(box: Box(), answers: ["gate": try answers(from: sampleResponse)["department"]!])
    await #expect(throws: MiddlewareError.self) {
        _ = try await provider.gate("x", statement: "Is this urgent?")
    }
}
