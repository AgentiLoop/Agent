import AgentAudit
import AppKit
import CryptoKit
import Network

/// Native "Sign in with Browser" for remote MCP servers — the MCP authorization spec (OAuth 2.1 authorization
/// code + PKCE, protected-resource / authorization-server discovery, dynamic client registration) with a
/// loopback redirect. No npx, no mcp-remote, no Node.js.
///
/// The access token goes to the Keychain and the saved config only holds an `Authorization: Bearer ${keychain:…}`
/// placeholder; refresh state (refresh token, client id, token endpoint) is a separate Keychain item. Nothing
/// reaches the chat or the LLM.
@MainActor
enum MCPOAuth {
    private struct State: Codable {
        var tokenEndpoint: String
        var clientId: String
        var clientSecret: String?
        var resource: String
        var refreshToken: String?
        var expiresAt: Date?
    }

    private struct Endpoints {
        let authorize: URL
        let token: URL
        let register: URL?
        let scope: String?
    }

    struct OAuthError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func accessAccount(_ server: String) -> String { "mcp.\(server).oauth.access" }
    private static func stateAccount(_ server: String) -> String { "mcp.\(server).oauth.state" }

    /// True when the server was set up with browser sign-in.
    static func isOAuth(_ server: String) -> Bool { loadState(server) != nil }

    /// Delete the stored tokens (on remove).
    static func forget(_ server: String) {
        KeychainService.shared.deleteMCPSecret(accessAccount(server))
        KeychainService.shared.deleteMCPSecret(stateAccount(server))
    }

    // MARK: - Sign in

    /// Open the server's login page in the default browser and wait (up to 5 min) for the redirect back.
    static func signIn(server: String, mcpURL: String) async throws {
        guard let resource = URL(string: mcpURL), resource.host != nil else { throw OAuthError(message: "Invalid URL: \(mcpURL)") }
        let endpoints = await discover(resource)
        guard let registerURL = endpoints.register else {
            throw OAuthError(message: "\(server) does not offer dynamic client registration, so browser sign-in isn't available — use an API key.")
        }

        let receiver = try LoopbackReceiver()
        defer { receiver.stop() }
        let port = try await receiver.start()
        let redirect = "http://127.0.0.1:\(port)/callback"

        let registration = try await postJSON(registerURL, [
            "client_name": "Agent!",
            "redirect_uris": [redirect],
            "grant_types": ["authorization_code", "refresh_token"],
            "response_types": ["code"],
            "token_endpoint_auth_method": "none",
        ])
        guard let clientId = registration["client_id"] as? String else {
            throw OAuthError(message: "\(server) client registration returned no client_id.")
        }
        let clientSecret = registration["client_secret"] as? String

        let verifier = randomString(32)
        let challenge = base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
        let stateParam = randomString(16)
        guard var comps = URLComponents(url: endpoints.authorize, resolvingAgainstBaseURL: false) else {
            throw OAuthError(message: "Bad authorization endpoint for \(server).")
        }
        comps.queryItems = (comps.queryItems ?? []) + [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirect),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: stateParam),
            URLQueryItem(name: "resource", value: mcpURL),
        ] + (endpoints.scope.map { [URLQueryItem(name: "scope", value: $0)] } ?? [])
        guard let authURL = comps.url else { throw OAuthError(message: "Bad authorization URL for \(server).") }

        AuditLog.log(.mcp, "[MCPOAuth] Opening browser sign-in for \(server)")
        NSWorkspace.shared.open(authURL)
        let params = try await receiver.waitForCallback(timeout: 300)
        NSApp.activate(ignoringOtherApps: true)

        if let error = params["error"] {
            throw OAuthError(message: "\(server) sign-in was denied: \(params["error_description"] ?? error)")
        }
        guard params["state"] == stateParam, let code = params["code"] else {
            throw OAuthError(message: "\(server) sign-in returned an invalid response.")
        }

        var form = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirect,
            "client_id": clientId,
            "code_verifier": verifier,
            "resource": mcpURL,
        ]
        if let clientSecret { form["client_secret"] = clientSecret }
        let tokens = try await postForm(endpoints.token, form)
        let state = State(
            tokenEndpoint: endpoints.token.absoluteString,
            clientId: clientId,
            clientSecret: clientSecret,
            resource: mcpURL
        )
        try store(server, tokens, state)
        AuditLog.log(.mcp, "[MCPOAuth] Signed in to \(server)")
    }

    /// Refresh the access token if it expires within a minute. Returns false when it's expired and can't be
    /// refreshed (the user must sign in again). No-op (true) for servers without browser sign-in.
    @discardableResult
    static func refreshIfNeeded(server: String) async -> Bool {
        guard let state = loadState(server) else { return true }
        let hasToken = KeychainService.shared.getMCPSecret(accessAccount(server)) != nil
        if hasToken, state.expiresAt.map({ $0 > Date().addingTimeInterval(60) }) ?? true { return true }
        guard let refresh = state.refreshToken, let url = URL(string: state.tokenEndpoint) else { return false }
        var form = ["grant_type": "refresh_token", "refresh_token": refresh, "client_id": state.clientId, "resource": state.resource]
        if let secret = state.clientSecret { form["client_secret"] = secret }
        do {
            try store(server, try await postForm(url, form), state)
            return true
        } catch {
            AuditLog.log(.mcp, "[MCPOAuth] Refresh failed for \(server): \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Token storage

    private static func store(_ server: String, _ tokens: [String: Any], _ base: State) throws {
        guard let access = tokens["access_token"] as? String else {
            throw OAuthError(message: "\(server) token response had no access_token.")
        }
        var state = base
        if let refresh = tokens["refresh_token"] as? String { state.refreshToken = refresh }
        let expiresIn = (tokens["expires_in"] as? NSNumber)?.doubleValue ?? Double(tokens["expires_in"] as? String ?? "")
        state.expiresAt = expiresIn.map { Date().addingTimeInterval($0) }
        KeychainService.shared.setMCPSecret(accessAccount(server), access)
        if let data = try? JSONEncoder().encode(state), let json = String(data: data, encoding: .utf8) {
            KeychainService.shared.setMCPSecret(stateAccount(server), json)
        }
    }

    private static func loadState(_ server: String) -> State? {
        guard let json = KeychainService.shared.getMCPSecret(stateAccount(server)) else { return nil }
        return try? JSONDecoder().decode(State.self, from: Data(json.utf8))
    }


    /// Auto-detect: does this HTTP MCP endpoint require login AND advertise OAuth (MCP auth spec)? True when an
    /// unauthenticated request gets 401 and the server publishes protected-resource or authorization-server metadata.
    static func supportsOAuth(_ mcpURL: String) async -> Bool {
        guard let resource = URL(string: mcpURL), resource.host != nil else { return false }
        var probe = URLRequest(url: resource, timeoutInterval: 10)
        probe.httpMethod = "POST"
        probe.setValue("application/json", forHTTPHeaderField: "Content-Type")
        probe.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
        probe.httpBody = Data(#"{"jsonrpc":"2.0","id":0,"method":"ping"}"#.utf8)
        guard let (_, response) = try? await URLSession.shared.data(for: probe),
              let http = response as? HTTPURLResponse, http.statusCode == 401 else { return false }
        if http.value(forHTTPHeaderField: "WWW-Authenticate")?.contains("resource_metadata") == true { return true }
        let origin = originString(resource)
        let path = resource.path == "/" ? "" : resource.path
        for candidate in [
            "\(origin)/.well-known/oauth-protected-resource\(path)",
            "\(origin)/.well-known/oauth-protected-resource",
            "\(origin)/.well-known/oauth-authorization-server",
        ].compactMap(URL.init(string:)) {
            if let json = await getJSON(candidate), json["authorization_servers"] != nil || json["authorization_endpoint"] != nil {
                return true
            }
        }
        return false
    }

    // MARK: - Discovery

    /// RFC 9728 protected-resource metadata → RFC 8414 / OIDC authorization-server metadata, falling back to
    /// the MCP spec's default /authorize, /token, /register on the server's origin.
    private static func discover(_ resource: URL) async -> Endpoints {
        let origin = originString(resource)
        let path = resource.path == "/" ? "" : resource.path

        // An unauthenticated request usually answers 401 with WWW-Authenticate: Bearer resource_metadata="…".
        var prmURLs: [URL] = []
        var probe = URLRequest(url: resource)
        probe.httpMethod = "POST"
        probe.setValue("application/json", forHTTPHeaderField: "Content-Type")
        probe.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
        probe.httpBody = Data(#"{"jsonrpc":"2.0","id":0,"method":"ping"}"#.utf8)
        if let (_, response) = try? await URLSession.shared.data(for: probe),
           let header = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "WWW-Authenticate"),
           let start = header.range(of: "resource_metadata=\""),
           let end = header.range(of: "\"", range: start.upperBound..<header.endIndex),
           let url = URL(string: String(header[start.upperBound..<end.lowerBound]))
        {
            prmURLs.append(url)
        }
        prmURLs += ["\(origin)/.well-known/oauth-protected-resource\(path)", "\(origin)/.well-known/oauth-protected-resource"]
            .compactMap(URL.init(string:))

        var issuer = URL(string: origin) ?? resource
        var scope: String?
        for url in prmURLs {
            if let json = await getJSON(url), let first = (json["authorization_servers"] as? [String])?.first, let as_ = URL(string: first) {
                issuer = as_
                scope = (json["scopes_supported"] as? [String]).map { $0.joined(separator: " ") }
                break
            }
        }

        let asOrigin = originString(issuer)
        let asPath = issuer.path == "/" ? "" : issuer.path
        var candidates = [
            "\(asOrigin)/.well-known/oauth-authorization-server\(asPath)",
            "\(asOrigin)/.well-known/openid-configuration\(asPath)",
        ]
        if !asPath.isEmpty { candidates.append("\(asOrigin)\(asPath)/.well-known/openid-configuration") }
        for candidate in candidates.compactMap(URL.init(string:)) {
            if let json = await getJSON(candidate),
               let authorize = (json["authorization_endpoint"] as? String).flatMap(URL.init(string:)),
               let token = (json["token_endpoint"] as? String).flatMap(URL.init(string:))
            {
                return Endpoints(
                    authorize: authorize,
                    token: token,
                    register: (json["registration_endpoint"] as? String).flatMap(URL.init(string:)),
                    scope: scope
                )
            }
        }
        let base = URL(string: asOrigin) ?? issuer
        return Endpoints(
            authorize: base.appendingPathComponent("authorize"),
            token: base.appendingPathComponent("token"),
            register: base.appendingPathComponent("register"),
            scope: scope
        )
    }

    private static func originString(_ url: URL) -> String {
        "\(url.scheme ?? "https")://\(url.host ?? "")" + (url.port.map { ":\($0)" } ?? "")
    }

    // MARK: - HTTP helpers

    private static func getJSON(_ url: URL) async -> [String: Any]? {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private static func postJSON(_ url: URL, _ body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await send(request)
    }

    private static func postForm(_ url: URL, _ form: [String: String]) async throws -> [String: Any] {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Data(form.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value)"
        }.joined(separator: "&").utf8)
        return try await send(request)
    }

    private static func send(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        guard (200..<300).contains(status) else {
            let detail = json["error_description"] as? String ?? json["error"] as? String ?? "HTTP \(status)"
            throw OAuthError(message: "\(request.url?.host ?? "server"): \(detail)")
        }
        return json
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func randomString(_ count: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return base64URL(Data(bytes))
    }
}

/// One-shot HTTP listener on 127.0.0.1 that captures the OAuth redirect (`GET /callback?code=…&state=…`).
/// All state is touched only on `queue`.
private final class LoopbackReceiver: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "Agent.mcp.oauth.loopback")
    private var readyContinuation: CheckedContinuation<UInt16, Error>?
    private var callbackContinuation: CheckedContinuation<[String: String], Error>?
    private var pending: Result<[String: String], Error>?

    init() throws {
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
        listener = try NWListener(using: params)
    }

    func start() async throws -> UInt16 {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                self.readyContinuation = continuation
                self.listener.stateUpdateHandler = { state in self.stateChanged(state) }
                self.listener.newConnectionHandler = { connection in self.accept(connection) }
                self.listener.start(queue: self.queue)
            }
        }
    }

    func waitForCallback(timeout: TimeInterval) async throws -> [String: String] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                if let pending = self.pending {
                    continuation.resume(with: pending)
                    return
                }
                self.callbackContinuation = continuation
                self.queue.asyncAfter(deadline: .now() + timeout) {
                    self.finish(.failure(MCPOAuth.OAuthError(message: "Timed out waiting for the browser sign-in.")))
                }
            }
        }
    }

    func stop() { listener.cancel() }

    private func stateChanged(_ state: NWListener.State) {
        switch state {
        case .ready:
            readyContinuation?.resume(returning: listener.port?.rawValue ?? 0)
            readyContinuation = nil
        case .failed(let error):
            readyContinuation?.resume(throwing: error)
            readyContinuation = nil
            finish(.failure(error))
        default:
            break
        }
    }

    private func accept(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16384) { data, _, _, _ in
            // Request line: "GET /callback?code=…&state=… HTTP/1.1"
            let request = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let target = request.split(separator: " ").dropFirst().first.map(String.init) ?? ""
            let comps = URLComponents(string: "http://127.0.0.1" + target)
            let isCallback = comps?.path == "/callback"
            let body = isCallback
                ? "<html><body style=\"font-family:-apple-system;text-align:center;margin-top:20vh\"><h2>Signed in</h2><p>You can close this tab and return to Agent!</p></body></html>"
                : "Not found"
            let head = isCallback ? "HTTP/1.1 200 OK" : "HTTP/1.1 404 Not Found"
            let response = "\(head)\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(body.utf8.count)\r\nConnection: close\r\n\r\n\(body)"
            connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in connection.cancel() })
            guard isCallback else { return }
            var params: [String: String] = [:]
            for item in comps?.queryItems ?? [] { params[item.name] = item.value ?? "" }
            self.finish(.success(params))
        }
    }

    private func finish(_ result: Result<[String: String], Error>) {
        if let continuation = callbackContinuation {
            callbackContinuation = nil
            continuation.resume(with: result)
        } else if pending == nil {
            pending = result
        }
    }
}
