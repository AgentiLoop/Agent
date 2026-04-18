# Using Codex (ChatGPT OAuth) with Agent!

Agent! can talk to OpenAI's Codex endpoint using your **ChatGPT Plus / Pro / Business / Edu / Enterprise** subscription — the same backend the official `codex` CLI uses. No API key, no per-token charges: requests bill against your ChatGPT plan.

| Path | Endpoint | Auth | Billing |
|---|---|---|---|
| **OpenAI** (other providers field) | `api.openai.com/v1/chat/completions` | `sk-…` API key | OpenAI Platform, per-token |
| **Codex** (this doc) | `chatgpt.com/backend-api/codex/responses` | ChatGPT OAuth (file-based) | Your ChatGPT subscription |

---

## One-time Setup

Codex auth is file-based. You sign in once with the `codex` CLI, and Agent! reads `~/.codex/auth.json` automatically.

### 1. Install the Codex CLI (if you don't have it)

```bash
brew install codex
# or:
npm install -g @openai/codex
```

### 2. Sign in

```bash
codex login
```

This opens a browser, you authorize with your ChatGPT account, and the CLI writes tokens to `~/.codex/auth.json`. You only do this once — tokens auto-refresh.

### 3. Select Codex in Agent!

1. Click the LLM Provider toolbar button (🧠).
2. Pick **Codex** from the dropdown.
3. You should see a green ✅ **Signed in** badge with an `expires in …m` countdown.
4. Click ↻ next to the Model field to fetch the live model list for your tier.
5. Pick a model (typically `gpt-5.2`, `gpt-5-codex`, or whatever your plan exposes).

You're ready to run tasks against Codex.

---

## Inside Agent!: what the Settings panel shows

When Codex is the selected provider, the panel shows:

- **Signed in** / **Not signed in** — whether `~/.codex/auth.json` is readable and parseable.
- **expires in Xm** — time until the current access token's JWT `exp` claim. Tokens are long-lived (days), but Agent! refreshes silently in the background within 5 minutes of expiry.
- **Refresh Token** button — force an early refresh (hits `auth.openai.com/oauth/token` with `grant_type=refresh_token`).
- **Sign In Again** button — launches Terminal with `codex login` so you can re-authenticate.
- **Model** picker — populated from the live `/codex/models` endpoint, filtered to models your subscription tier exposes.

**No account ID, no token text, no refresh token is ever shown in the UI** — `chatgpt-account-id` is treated as PII.

---

## How Agent! talks to Codex under the hood

Every outbound request:

1. `CodexAuthRefresher.validAuth()` re-reads `~/.codex/auth.json` from disk.
2. Decodes the JWT's `exp` claim. If within 5 min of expiry, refreshes via `auth.openai.com/oauth/token` and writes new tokens back to the file.
3. Posts to `https://chatgpt.com/backend-api/codex/responses?client_version=0.21.0` with:
   - `Authorization: Bearer <access_token>`
   - `chatgpt-account-id: <account_id from JWT>`
   - `OpenAI-Beta: responses=v1`
   - `User-Agent: codex_cli_rs/0.21.0`
4. Body is the OpenAI **Responses API** shape (`input`, `instructions`, `store: false`, `stream: true` — the proxy is stream-only).
5. The first `instructions` string starts with the required identity line:
   > `"You are Codex, based on GPT-5. You are running as a coding agent in the Codex CLI on a user's computer."`
   Without this prefix OpenAI's OAuth gate rejects the request immediately.
6. Streams SSE events (`response.output_text.delta`, `response.function_call_arguments.delta`, `response.completed`). Text deltas go to the activity log live; tool calls are reassembled and dispatched to Agent!'s tool runner.

Auth never leaves the local process except on the signed HTTPS request. Tokens are stored by the Codex CLI (`~/.codex/auth.json`, 0644) — Agent! only reads and refreshes them.

---

## Model list

Run once after signing in, or whenever you change plans:

1. Settings → Codex panel → click **↻** next to the Model picker.
2. The list is fetched live from `chatgpt.com/backend-api/codex/models?client_version=0.21.0`.
3. Hidden / admin-restricted models are filtered out.

Typical availability:

| Plan | Models |
|---|---|
| **Plus** | `gpt-5.2`, `gpt-5-codex`, `gpt-5-mini`, `gpt-5-nano`, `codex-mini-latest`, `o4-mini` |
| **Pro** | adds `o3`, higher reasoning effort levels |
| **Business / Edu / Enterprise** | admin-pinned set, possibly custom |

Model strings are never hardcoded in Agent! — whatever your tier returns is what you see.

---

## Troubleshooting

**"Not signed in" badge in Settings**
- `~/.codex/auth.json` is missing or malformed. Run `codex login` again from a Terminal.

**"Codex API Error: Invalid response from API"**
- Usually a stale/revoked token. Click **Refresh Token**, or `codex login` to fully re-auth.
- Check `Activity Log` / AuditLog — `CodexService` logs the HTTP status and first 500 bytes of the error body on failures.

**Model dropdown is empty even after clicking ↻**
- You're not signed in, or the token was revoked. Sign in again.
- Network issue reaching `chatgpt.com`. Try `curl -I https://chatgpt.com`.

**"Stream must be set to true"**
- You're running an older build. The current Codex path is always streaming — update Agent!.

**429 / rate limit**
- You've hit your ChatGPT plan's 5-hour or weekly rolling quota. Wait, or upgrade tier. Agent! does not bypass OpenAI's rate limits.

**"expires in 0m" / "expired"**
- Shouldn't happen — the refresher runs on every outbound call. If it does, click **Refresh Token** manually. If that fails, `codex login` again.

---

## What does *not* work (yet)

- **Native PKCE sign-in inside Agent!** — Phase 2. Current sign-in shells out to `codex login`. If you don't want the Codex CLI installed, you'll have to wait.
- **Reasoning effort control** — gpt-5.2 supports `low/medium/high/xhigh` reasoning effort; Agent! currently sends no `reasoning.effort` field (server default = `medium`).
- **Reasoning output display** — reasoning summary deltas are dropped on the floor rather than streamed into the Thinking HUD.
- **`apply_patch` native tool** — gpt-5.2 has a native patch-apply tool; Agent! exposes its own `edit_file` / `diff_and_apply` instead.
- **Codex native web search tool** — skipped; Tavily is used as the cross-provider web search.
- **Live 401 retry** — Agent! refreshes proactively before expiry, but doesn't catch a 401 mid-stream (from e.g. server-side revocation) and retry. For now, click **Refresh Token** or sign in again.

---

## Privacy / security notes

- `~/.codex/auth.json` contains long-lived OAuth credentials. Treat it like any credential file — don't share screenshots of it.
- `chatgpt-account-id` is a UUID tied to your ChatGPT account. Agent! never logs it or shows it in the UI.
- Access tokens are JWTs; their `exp` claim is the only thing displayed (as a countdown), and only for UX.
- Agent!'s activity log may include reasoning / tool-call details; treat the log as sensitive if you share it.

---

## Reference

- `Agent/Services/CodexService.swift` — file-based auth, JWT decoder, auto-refresher, Responses API client, SSE parser.
- `docs/CODEX_OAUTH_RESEARCH.md` — the research memo this implementation is based on (Claude vs Codex OAuth comparison).
- OpenAI official docs: <https://developers.openai.com/codex/auth>
- Codex CLI repo: <https://github.com/openai/codex>
