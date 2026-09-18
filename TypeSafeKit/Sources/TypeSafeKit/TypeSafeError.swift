// Errors mirror the documented status codes: 401, 422, 429, 529, plus transport
// and local validation failures.

import Foundation

public enum TypeSafeError: Error, Sendable {
    /// No API key was supplied and TYPESAFE_API_KEY is unset.
    case missingAPIKey
    /// Caught locally before the request is sent.
    case invalidRequest(String)
    /// 400 — malformed request.
    case badRequest(APIErrorBody?)
    /// 401 — missing or invalid API key.
    case authentication(APIErrorBody?)
    /// 403 — key lacks permission for this resource.
    case permissionDenied(APIErrorBody?)
    /// 404 — unknown route or model.
    case notFound(APIErrorBody?)
    /// 422 — the body failed server validation; `body` names the offending field.
    case unprocessableEntity(APIErrorBody?)
    /// 429 — rate limit exceeded. Back off and retry.
    case rateLimit(retryAfter: TimeInterval?, body: APIErrorBody?)
    /// 529 — TypeSafe temporarily overloaded. Retry after a short delay.
    case overloaded(retryAfter: TimeInterval?, body: APIErrorBody?)
    /// Any other non-2xx status.
    case server(status: Int, body: APIErrorBody?)
    /// Transport failure (DNS, TLS, offline).
    case connection(String)
    /// The request timed out.
    case timeout
    /// The response was not the documented shape.
    case decoding(String)

    /// HTTP status, when the error came from a response.
    public var statusCode: Int? {
        switch self {
        case .badRequest: 400
        case .authentication: 401
        case .permissionDenied: 403
        case .notFound: 404
        case .unprocessableEntity: 422
        case .rateLimit: 429
        case .overloaded: 529
        case .server(let status, _): status
        case .missingAPIKey, .invalidRequest, .connection, .timeout, .decoding: nil
        }
    }

    /// Delay the server asked for, when it sent one.
    public var retryAfter: TimeInterval? {
        switch self {
        case .rateLimit(let retryAfter, _), .overloaded(let retryAfter, _): retryAfter
        default: nil
        }
    }

    static func from(status: Int, body: APIErrorBody?, retryAfter: TimeInterval?) -> TypeSafeError {
        switch status {
        case 400: .badRequest(body)
        case 401: .authentication(body)
        case 403: .permissionDenied(body)
        case 404: .notFound(body)
        case 422: .unprocessableEntity(body)
        case 429: .rateLimit(retryAfter: retryAfter, body: body)
        case 529: .overloaded(retryAfter: retryAfter, body: body)
        default: .server(status: status, body: body)
        }
    }
}

extension TypeSafeError: LocalizedError {
    public var errorDescription: String? {
        func detail(_ body: APIErrorBody?) -> String {
            body?.message.map { ": \($0)" } ?? ""
        }
        switch self {
        case .missingAPIKey:
            return "No TypeSafe API key. Pass one to TypeSafeClient or set TYPESAFE_API_KEY."
        case .invalidRequest(let reason):
            return "Invalid request: \(reason)"
        case .badRequest(let body):
            return "400 Bad Request\(detail(body))"
        case .authentication(let body):
            return "401 Unauthorized\(detail(body))"
        case .permissionDenied(let body):
            return "403 Forbidden\(detail(body))"
        case .notFound(let body):
            return "404 Not Found\(detail(body))"
        case .unprocessableEntity(let body):
            return "422 Unprocessable Entity\(detail(body))"
        case .rateLimit(let retryAfter, let body):
            let wait = retryAfter.map { " · retry after \($0)s" } ?? ""
            return "429 Too Many Requests\(wait)\(detail(body))"
        case .overloaded(let retryAfter, let body):
            let wait = retryAfter.map { " · retry after \($0)s" } ?? ""
            return "529 Overloaded\(wait)\(detail(body))"
        case .server(let status, let body):
            return "HTTP \(status)\(detail(body))"
        case .connection(let reason):
            return "Connection failed: \(reason)"
        case .timeout:
            return "Request timed out"
        case .decoding(let reason):
            return "Unexpected response: \(reason)"
        }
    }
}
