// HTTP client for the TypeSafe System One API.
//
//   let client = try TypeSafeClient()                     // reads TYPESAFE_API_KEY
//   let reply = try await client.systemOne(
//       state: "Help! My payouts have been failing for 3 days.",
//       questions: ["is_urgent": .noul(instructions: "Does this convey urgency?")])
//   reply["is_urgent"]?.noulValue                         // 0.92

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum TypeSafeConstants {
    public static let defaultBaseURL = URL(string: "https://api.typesafe.ai")!
    public static let apiKeyEnvironmentVariable = "TYPESAFE_API_KEY"
    public static let baseURLEnvironmentVariable = "TYPESAFE_BASE_URL"
    public static let defaultTimeout: TimeInterval = 60
    public static let systemOnePath = "/v1/systemone"
    public static let modelsPath = "/v1/models"
}

/// Seam for tests and for callers who want their own networking stack.
public protocol TypeSafeTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: TypeSafeTransport {
    let session: URLSession

    public init(session: URLSession = .shared) { self.session = session }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw TypeSafeError.decoding("Response was not HTTP")
        }
        return (data, http)
    }
}

public struct TypeSafeClient: Sendable {
    public let baseURL: URL
    /// Model used when a call does not name one.
    public let model: String
    public let retryPolicy: RetryPolicy
    public let timeout: TimeInterval

    private let apiKey: String
    private let transport: any TypeSafeTransport

    /// Reads the key from `TYPESAFE_API_KEY` and the base URL from
    /// `TYPESAFE_BASE_URL` when they are not passed explicitly.
    public init(
        apiKey: String? = nil,
        baseURL: URL? = nil,
        model: String = Model.jevLatest,
        retryPolicy: RetryPolicy = .default,
        timeout: TimeInterval = TypeSafeConstants.defaultTimeout,
        transport: (any TypeSafeTransport)? = nil
    ) throws {
        let environment = ProcessInfo.processInfo.environment
        guard let key = apiKey
            ?? environment[TypeSafeConstants.apiKeyEnvironmentVariable],
            !key.isEmpty
        else { throw TypeSafeError.missingAPIKey }

        self.apiKey = key
        self.baseURL = baseURL
            ?? environment[TypeSafeConstants.baseURLEnvironmentVariable].flatMap(URL.init(string:))
            ?? TypeSafeConstants.defaultBaseURL
        self.model = model
        self.retryPolicy = retryPolicy
        self.timeout = timeout
        self.transport = transport ?? URLSessionTransport()
    }

    // MARK: - System One

    /// Evaluates `questions` against `state` in a single call. Every question is
    /// evaluated in parallel and in isolation against the same state.
    public func systemOne(
        state: State,
        questions: [String: Question],
        model: String? = nil
    ) async throws -> SystemOneResponse {
        try await systemOne(SystemOneRequest(
            state: state, questions: questions, model: model ?? self.model))
    }

    public func systemOne(_ request: SystemOneRequest) async throws -> SystemOneResponse {
        try request.validate()
        let body = try JSONEncoder().encode(request)
        return try await perform(
            method: "POST", path: TypeSafeConstants.systemOnePath, body: body,
            as: SystemOneResponse.self)
    }

    // MARK: - Models

    public var models: Models { Models(client: self) }

    public struct Models: Sendable {
        let client: TypeSafeClient

        /// Names your account can send in the `model` field.
        public func list() async throws -> [ModelCard] {
            try await client.perform(
                method: "GET", path: TypeSafeConstants.modelsPath, body: nil,
                as: ModelListResponse.self).models
        }
    }

    // MARK: - Transport

    private func perform<Response: Decodable>(
        method: String,
        path: String,
        body: Data?,
        as type: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        var attempt = 1
        while true {
            let failure: TypeSafeError
            do {
                let (data, response) = try await transport.send(request)
                if (200..<300).contains(response.statusCode) {
                    do {
                        return try JSONDecoder().decode(Response.self, from: data)
                    } catch {
                        throw TypeSafeError.decoding(String(describing: error))
                    }
                }
                failure = TypeSafeError.from(
                    status: response.statusCode,
                    body: try? JSONDecoder().decode(APIErrorBody.self, from: data),
                    retryAfter: Self.retryAfter(from: response))
            } catch let error as TypeSafeError {
                if case .decoding = error { throw error }
                failure = error
            } catch let error as URLError {
                failure = error.code == .timedOut
                    ? .timeout
                    : .connection(error.localizedDescription)
            } catch {
                throw error
            }

            guard let delay = retryPolicy.delay(
                afterAttempt: attempt,
                status: failure.statusCode,
                retryAfter: failure.retryAfter)
            else { throw failure }

            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            attempt += 1
        }
    }

    static func retryAfter(from response: HTTPURLResponse) -> TimeInterval? {
        guard let value = response.value(forHTTPHeaderField: "retry-after") else { return nil }
        return TimeInterval(value.trimmingCharacters(in: .whitespaces))
    }
}
