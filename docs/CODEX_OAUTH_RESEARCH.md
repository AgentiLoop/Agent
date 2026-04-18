# OpenAI Codex OAuth — Research & Comparison to Agent!'s Claude OAuth

> Research memo, not an implementation. Goal: figure out exactly what Agent! would have to do to accept a **ChatGPT Plus / Pro / Business / Edu / Enterprise** credential in the OpenAI-compatible settings field, the same way it already accepts `sk-ant-oat01-…` in the Claude field.

---

## 1. How Agent!'s Claude OAuth works today (the working reference)

Implemented in `Agent/Services/ClaudeService.swift`.

### 1a. The "magic byte" prefix sniffer
```swift
// ClaudeService.swift:192
nonisolated static func isOAuthToken(_ credential: String) -> Bool {
    sanitizedCredential(credential).hasPrefix("sk-ant-oat01-")
}
```
Agent! decides OAuth-vs-API-key **purely from the token prefix** — no settings toggle, no mode picker, no separate field:

| Prefix | Path |
|---|---|
| `sk-ant-api03-…` | `x-api-key` header (Console billing) |
| `sk-ant-oat01-…` | `Authorization: Bearer` + OAuth beta header (subscription billing) |

### 1b. Header branching
```swift
// ClaudeService.swift:225 — applyAuthHeaders(on:credential:apiVersion:)
if clean.hasPrefix("sk-ant-oat01-") {
    request.setValue("Bearer \(clean)", forHTTPHeaderField: "Authorization")
    request.setValue(
        "oauth-2025-04-20,prompt-caching-2024-07-31",
        forHTTPHeaderField: "anthropic-beta"
    )
} else {
    request.setValue(clean, forHTTPHeaderField: "x-api-key")
    request.setValue("prompt-caching-2024-07-31", forHTTPHeaderField: "anthropic-beta")
}
```

### 1c. Required identity system prompt (the "gate")
```swift
// ClaudeService.swift:201
nonisolated static let claudeCodeIdentityPrompt =
    "You are Claude Code, Anthropic's official CLI for Claude."
```
When the credential is an OAuth token, Agent! prepends that exact string as the **first** system block. Without it Anthropic's OAuth gate 429s immediately with `{"message":"Error"}` and no `Retry-After`. Agent's real system prompt follows as a second (cache-controlled) block.

### 1d. Endpoint stays identical
Same URL (`https://api.anthropic.com/v1/messages`), same body shape, same streaming, same tool-use schema. Only the auth triplet (header + beta + system-block identity) changes.

### 1e. Paste hygiene
```swift
// ClaudeService.swift:181
static func sanitizedCredential(_ raw: String) -> String { … strip whitespace/control chars … }
```
Because terminals wrap long bearer tokens across lines, the paste path strips every whitespace / control character before matching the prefix and setting the header. A stray `\n` in `Authorization: Bearer …` is a silent 401.

---

## 2. OpenAI Codex OAuth — what's actually out there

### 2a. Official flow (OpenAI's own docs)
<cite index="1-2,1-3">When you sign in with ChatGPT from the Codex app, CLI, or IDE Extension, Codex opens a browser window for you to complete the login flow. After you sign in, the browser returns an access token to the CLI or IDE extension.</cite> <cite index="11-1">Codex caches login details locally in a plaintext file at ~/.codex/auth.json or in your OS-specific credential store.</cite>

<cite index="1-8,1-9">Features that rely on ChatGPT credits, such as fast mode, are available only when you sign in with ChatGPT. If you sign in with an API key, Codex uses standard API pricing instead.</cite>

<cite index="11-2">For sign in with ChatGPT sessions, Codex refreshes tokens automatically during use before they expire, so active sessions usually continue without requiring another browser login.</cite>

### 2b. PKCE flow details (from the published OpenCode reverse-engineering thread)
<cite index="3-8">OAuth Bearer Token: Standard OAuth 2.0 access token obtained via PKCE flow · Client ID: Uses app_EMoamEEZ73f0CkXaXp7hrann (OpenAI Codex public client) Authorization Endpoint: https://auth.openai.com/oauth/authorize · Token Endpoint: https://auth.openai.com/oauth/token · PKCE Flow: Complete code challenge/verifier implementation for security · Automatic Refresh: Tokens refresh automatically when expiring within 5 minutes</cite>

Authorize URL parameters (from the public OpenCode implementation):
```
response_type=code
client_id=app_EMoamEEZ73f0CkXaXp7hrann
redirect_uri=http://localhost:1455/auth/callback
scope=openid profile email offline_access
code_challenge=<S256 of verifier>
code_challenge_method=S256
state=<random>
id_token_add_organizations=true
codex_cli_simplified_flow=true
```
Token exchange: `POST https://auth.openai.com/oauth/token` with `grant_type=authorization_code`, `code`, `redirect_uri`, `client_id`, `code_verifier` — standard RFC 7636.

### 2c. The "chatgpt_account_id" header (the actual magic)
<cite index="14-4">Account Detection: Extracts ChatGPT account ID from JWT claims</cite>

The access token is a JWT whose `https://api.openai.com/auth` claim contains `chatgpt_account_id`. That account ID must be echoed on every request as a header (`chatgpt-account-id`) — that's how ChatGPT-credit routing works. Agent! would have to decode the JWT payload (base64url middle segment, JSON-parse) to pull the id.

### 2d. The required "You are Codex" system prompt (the OpenAI equivalent of Anthropic's identity gate)
<cite index="3-10,3-11">Configure required system prompt: "You are Codex, based on GPT-5. You are running as a coding agent in the Codex CLI on a user's ..." Add bearer token authentication with OAuth access token · Map OAuth credentials to provider API client · Configure model endpoints for ChatGPT API (https://api.openai.com/v1) Test provider initialization with OAuth tokens · Verify API calls succeed with OAuth bearer authentication · System Prompt Requirement: OpenAI's OAuth API requires a specific system prompt to validate Codex CLI authorization. Without this exact prompt format, API requests will be rejected even with valid OAuth tokens.</cite>

Exact parallel to the Claude `"You are Claude Code, Anthropic's official CLI for Claude."` block.

### 2e. Endpoint is **not** the normal OpenAI Platform URL
<cite index="21-11,21-12">OpenAI's Codex CLI uses a special endpoint at chatgpt.com/backend-api/codex/responses to let you use special OpenAI rate limits tied to your ChatGPT account. By using the same Oauth tokens as Codex, we can effectively use OpenAI's API through Oauth instead of buying API credits.</cite>

So the OAuth path talks to `https://chatgpt.com/backend-api/codex/responses` — **not** `https://api.openai.com/v1/chat/completions`. Request shape is OpenAI's `/v1/responses` format, not `/v1/chat/completions`. Stateless: <cite index="21-9,21-10">There is no stateful replay support on the CLI /v1/responses endpoint. The proxy is stateless and expects callers to send the full conversation history.</cite>

### 2f. Token storage on disk (Codex CLI's layout)
<cite index="11-29,11-30,11-31">Codex caches login details locally in a plaintext file at ~/.codex/auth.json or in your OS-specific credential store. For sign in with ChatGPT sessions, Codex refreshes tokens automatically during use before they expire, so active sessions usually continue without requiring another browser login. Use cli_auth_credentials_store to control where the Codex CLI stores cached credentials: # file | keyring | auto cli_auth_credentials_store = "keyring" file stores credentials in auth.json under CODEX_HOME (defaults to ~/.codex).</cite>

The `auth.json` schema (by inspection):
```json
{
  "OPENAI_API_KEY": null,
  "tokens": {
    "id_token": "eyJ...",      // JWT with chatgpt_account_id claim
    "access_token": "eyJ...",  // the bearer we send
    "refresh_token": "rt-...",
    "account_id": "…"
  },
  "last_refresh": "2026-04-17T..."
}
```

---

## 3. Side-by-side

| Concern | Claude OAuth (shipped) | Codex OAuth (proposed) |
|---|---|---|
| **"Magic byte" / prefix sniff** | `sk-ant-oat01-` vs `sk-ant-api` | ChatGPT token is a JWT — starts `eyJ` (base64url of `{"alg":"…`). API keys start `sk-`. Prefix test: **JWT → OAuth, `sk-` → API key.** |
| **Auth header (OAuth)** | `Authorization: Bearer <token>` + `anthropic-beta: oauth-2025-04-20,prompt-caching-2024-07-31` | `Authorization: Bearer <access_token>` + `chatgpt-account-id: <from JWT>` + `OpenAI-Beta: responses=v1` |
| **Auth header (API key)** | `x-api-key: <key>` | `Authorization: Bearer <sk-…>` |
| **Identity system prompt** | `"You are Claude Code, Anthropic's official CLI for Claude."` (first system block) | `"You are Codex, based on GPT-5. You are running as a coding agent in the Codex CLI on a user's …"` (first system / instructions block) |
| **Endpoint (OAuth)** | `https://api.anthropic.com/v1/messages` (same as API key) | `https://chatgpt.com/backend-api/codex/responses` (**different** from `api.openai.com/v1/chat/completions`) |
| **Request body shape** | Identical for both paths | OAuth path uses `/v1/responses` format; API path uses `/v1/chat/completions`. **Not interchangeable.** |
| **Token lifetime** | 365 days, no refresh | ~1 hour access, long-lived refresh, auto-refresh within 5 min of expiry |
| **Subscription gate** | `/extra-usage` must be enabled in Claude Code | ChatGPT Plus/Pro/Business/Edu/Enterprise required; no separate toggle |
| **Paste hygiene** | Strip whitespace/control chars | Same — JWTs are long and line-wrap |
| **Tool use** | Claude native tools | Responses API tools schema (different JSON keys from chat/completions) |
| **Streaming** | SSE, identical to API key | SSE on `/responses`, different event names |

---

## 4. What Agent! would need to add

In rough order of risk:

### 4a. Tiny, copy-the-Claude-pattern parts
1. **Prefix/shape detector** in `OpenAIService` (new helper, mirror of `ClaudeService.isOAuthToken`):
   ```swift
   static func isChatGPTOAuthToken(_ credential: String) -> Bool {
       let clean = sanitizedCredential(credential)
       // Access tokens are JWTs: three base64url segments separated by '.'
       let parts = clean.split(separator: ".")
       return parts.count == 3 && clean.hasPrefix("eyJ")
   }
   ```
2. **`sanitizedCredential`** — verbatim copy of the Claude one; same rationale (terminal-wrapped pastes).
3. **Capsule in Settings UI** — "ChatGPT (subscription)" badge next to the field, parallel to the existing "OAuth (subscription)" capsule.

### 4b. New work not present in the Claude path
4. **JWT claim extractor** — decode the middle segment of the access token, parse JSON, pull `https://api.openai.com/auth.chatgpt_account_id`. Needed for the `chatgpt-account-id` header. (~15 lines of Swift; `Data(base64Encoded:)` with `=` padding + `JSONDecoder`.)
5. **Endpoint switcher** — when OAuth is detected, route to `https://chatgpt.com/backend-api/codex/responses` instead of `https://api.openai.com/v1/chat/completions`. Two different base URLs live in `OpenAIService`.
6. **Responses-API request/response model** — new Codable types, because `/v1/responses` uses `input`, `instructions`, `output`, `output_text` whereas `/v1/chat/completions` uses `messages`/`choices`. Tool-call format also differs. This is the **biggest** lift — it's not just a header swap like Claude's was.
7. **Token refresh** — Claude tokens are 365-day, no refresh. ChatGPT access tokens are ~1h. Agent! would need a refresh flow hitting `POST https://auth.openai.com/oauth/token` with `grant_type=refresh_token`. Store `refresh_token` in Keychain alongside the access token.
8. **Identity "instructions" block** — the Codex system prompt string, prepended as the first `instructions` entry on every OAuth request. Same shape/purpose as Claude's identity block, different string.

### 4c. Optional but nice
9. **Import from `~/.codex/auth.json`** — if it exists, offer "Use existing Codex login" in Settings. Parallels the `claude setup-token` ergonomics without shipping a browser-login flow inside Agent! itself. Cheapest viable onboarding.
10. **PKCE browser login inside Agent!** — full parity with Claude's paste-token flow would be nice, but `~/.codex/auth.json` import covers 95% of users because most already have Codex CLI installed.

---

## 5. Gotchas discovered during research

- **Endpoint asymmetry.** Unlike Anthropic, OpenAI did **not** unify OAuth and API-key auth on the same URL. An API key hits `api.openai.com/v1/chat/completions`; an OAuth token hits `chatgpt.com/backend-api/codex/responses`. You can't just flip a header and keep the rest of the code. This is a bigger architectural change than the Claude OAuth patch was.
- **Responses vs chat/completions.** Tool use, streaming events, and output parsing are all different between the two OpenAI APIs. Any existing OpenAI tool-call parsing in Agent! stays for the API-key path and a **parallel** parser is needed for OAuth.
- **Terms of Service gray zone.** <cite index="9-15,9-16,9-17">Using OAuth authentication for personal coding assistance aligns with OpenAI's official Codex CLI use case. However, violating OpenAI's terms could result in account action: ... OAuth is a proper, supported authentication method. Session token scraping and reverse-engineering private APIs are explicitly prohibited by OpenAI's terms.</cite> OpenAI publicly states Codex OAuth is for "personal development use." Agent! is a personal dev tool, so this fits, but it's worth documenting (like the Claude doc's "extra usage" banner).
- **Hard-coded client_id.** `app_EMoamEEZ73f0CkXaXp7hrann` is the Codex CLI's public client. If OpenAI rotates it, Agent! is broken until we update the constant. (Same risk exists for Anthropic's OAuth beta header string; track both.)
- **Account-id leakage in logs.** `chatgpt-account-id` is a UUID tied to the user's ChatGPT account. Don't log request headers verbatim anywhere (`Activity Log`, telemetry, redux-style dumps) — treat it like a PII field.
- **Rate limits are tier-dependent.** <cite index="9-5">This plugin respects the same rate limits enforced by OpenAI's official Codex CLI: Rate limits are determined by your ChatGPT subscription tier (Plus/Pro) Limits are enforced server-side through OAuth tokens · The plugin does NOT and CANNOT bypass OpenAI's rate limits</cite> — Agent! gets no special treatment here, same as Claude's OAuth path.
- **5-hour + weekly windows.** ChatGPT-subscription quota is dual-windowed (5h rolling + weekly). When rate limited, OpenAI returns a response the user can't debug from headers alone. Agent! should surface both thresholds like Claude's "extra usage" doc does.

---

## 6. Recommendation

**Do it, but do it in two phases.**

**Phase 1 — Import path (1-2 days work):**
- Prefix sniffer + JWT account-id extractor.
- Read `~/.codex/auth.json` if present, expose "Use Codex login" toggle.
- New `CodexOAuthService` (sibling to `OpenAIService`), dedicated `/backend-api/codex/responses` client with its own Codable models.
- No browser flow yet. User runs `codex login` once via Codex CLI, Agent! reads the file.
- Document in `docs/CODEX_OAUTH.md` mirroring `docs/CLAUDE_CODE_OAUTH.md`.

**Phase 2 — Native login (3-5 days work):**
- PKCE flow using `ASWebAuthenticationSession`.
- Local callback listener on `http://localhost:1455/auth/callback`.
- Auto refresh-token rotation.
- Keychain storage separate from the API-key path.

The Phase 1 "import existing login" trick is the highest leverage because most users who want Codex OAuth already have the Codex CLI installed — we get the feature with ~20% of the total work.

---

## 7. Files Agent! would touch

```
Agent/Services/
├── OpenAIService.swift                (+ prefix sniffer, + endpoint branch)
├── CodexOAuthService.swift            (NEW — /backend-api/codex/responses client)
├── CodexOAuthModels.swift             (NEW — Responses API Codable types)
├── CodexAuthFileImporter.swift        (NEW — ~/.codex/auth.json reader)
└── JWTClaims.swift                    (NEW — base64url + JSONDecoder helper)

Agent/Settings/
└── LLMSettingsView.swift              (+ "ChatGPT (subscription)" capsule)

docs/
└── CODEX_OAUTH.md                     (NEW — user-facing doc)
```

---

## 8. Reference implementations surveyed

- Official: <https://developers.openai.com/codex/auth>
- OpenCode plugin (most complete reverse-engineering): <https://github.com/numman-ali/opencode-openai-codex-auth>
- PKCE flow details: <https://github.com/anomalyco/opencode/issues/3281>
- Proxy-only approach: <https://github.com/EvanZhouDev/openai-oauth>
- Account switcher (auth.json format reference): <https://github.com/Loongphy/codex-auth>

---

*Research date: 2026-04-17. Project index recreated to 260 files the same day.*
