# Using Claude Code OAuth Tokens with Agent!

Agent! accepts two credential types in the **Claude API** settings field:

| Paste this | Billed against |
|---|---|
| `sk-ant-api03-…` (API key) | Your Anthropic Console account, per-token |
| `sk-ant-oat01-…` (OAuth token) | Your **Claude Pro / Max / Team / Enterprise subscription** |

The OAuth path bills against a subscription you already pay for — no separate API credits required. Agent! detects the token prefix and sends the correct auth headers automatically.

---

## Generating an OAuth Token

### 1. Install Claude Code (if you don't have it)

```bash
npm install -g @anthropic-ai/claude-code
```

Requires Node.js 18+ and an active Claude subscription.

### 2. Run the setup command

```bash
claude setup-token
```

### 3. Sign in through the browser

The command opens your default browser at Anthropic's authorization page:

- `https://claude.com/cai/oauth/authorize?…` (for Claude.ai subscribers)
- `https://platform.claude.com/oauth/authorize?…` (Console path)

Sign in with the Claude account that holds your subscription. Claude Code is listening on `http://localhost:<port>/callback` and catches the redirect automatically.

### 4. Copy the token

The terminal prints:

```
✓ Long-lived authentication token created successfully!

Your OAuth token (valid for 1 year):
sk-ant-oat01-<long-base64-ish-string>

Store this token securely. You won't be able to see it again.
```

**You can't view this token again** — if you lose it, re-run `claude setup-token` to mint a new one. The old token keeps working until it expires.

### 5. Paste it into Agent!

1. Open Agent! → **Settings** (⚙️) → **LLM Settings** (🧠) → **Claude API** section.
2. Paste the whole `sk-ant-oat01-…` string into the **"API Key or OAuth Token"** field.
3. A small **OAuth (subscription)** capsule appears next to the label confirming Agent! detected the prefix.
4. Pick any Claude model. Run a task. Usage debits your Claude subscription.

---

## What Agent! Does Differently

Source: `Agent/Services/ClaudeService.swift` → `applyAuthHeaders(on:credential:apiVersion:)`.

### API key path (`sk-ant-api…`)
```
POST https://api.anthropic.com/v1/messages
x-api-key: sk-ant-api03-...
anthropic-version: 2023-06-01
anthropic-beta: prompt-caching-2024-07-31
```

### OAuth path (`sk-ant-oat01-…`)
```
POST https://api.anthropic.com/v1/messages
Authorization: Bearer sk-ant-oat01-...
anthropic-version: 2023-06-01
anthropic-beta: oauth-2025-04-20,prompt-caching-2024-07-31
```

Everything else — request body, streaming, tool use, prompt caching — is identical. Same endpoint, same model list, same features.

---

## Scopes & Limits

OAuth tokens minted by `claude setup-token` carry **only the `user:inference` scope**. That's exactly what Agent! needs: permission to call `/v1/messages`. The tokens cannot:

- Create API keys on your behalf
- Access MCP servers registered to your account
- Upload files to Claude.ai
- Drive remote agents via the Claude Code bridge

If you need a fuller-scope token (for a feature Agent! doesn't use yet), use `claude auth login` inside Claude Code instead of `claude setup-token` — but that token lives in CC's keychain entry and isn't meant to be pasted elsewhere.

**Token lifetime**: 365 days from generation. Agent! does not refresh OAuth tokens; when yours expires, re-run `claude setup-token` and paste the new one.

**Subscription limits**: the same per-model, per-hour, per-day limits that apply to Claude Code (and claude.ai) apply here. Hitting them returns 429 / 529 with a `Retry-After` header — Agent! already honors that header for back-off.

---

## Switching Back to an API Key

Just paste a `sk-ant-api…` key over the OAuth token. The **OAuth (subscription)** capsule disappears, the auth headers flip back to `x-api-key`, and billing goes through the Console account. No restart, no settings toggle.

---

## Security Notes

- The token is stored in Agent!'s Keychain-backed settings storage (same as the API key path).
- `sk-ant-oat01-…` is a bearer credential — anyone with the string can bill against your subscription until it expires or is revoked. Treat it like a password.
- To revoke a token, sign into [claude.ai/settings](https://claude.ai/settings) and remove the authorized session.
- Agent! never transmits the token anywhere except to `https://api.anthropic.com` (verified via URL in `ClaudeService.swift`).

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| 401 "OAuth token has expired" | Token is past its 365-day lifetime | Re-run `claude setup-token`, paste the new token |
| 401 "Invalid bearer token" | Token revoked at claude.ai, or malformed paste (missing chars) | Re-run `claude setup-token` |
| 403 "Insufficient scope" | Minted with a different flow (e.g. `claude auth login`) | Re-mint with `claude setup-token` specifically — that's the inference-only path |
| 429 rate limit | Subscription quota hit | Wait for the `Retry-After` period; Agent! back-off is automatic |
| No capsule shows up after paste | Token prefix isn't `sk-ant-oat01-` | Confirm you copied the full token; API keys starting with `sk-ant-api` use the `x-api-key` path instead — that's fine if intended |

---

## Reference

All of this is derived from Claude Code's own behavior — `claude setup-token` mints an OAuth token with `inferenceOnly: true` and `expiresIn: 365 * 24 * 60 * 60`. Agent! sends the exact same two-header combination Claude Code uses internally for subscription auth.

- Endpoint: `https://api.anthropic.com/v1/messages`
- OAuth beta header value: `oauth-2025-04-20`
- Agent! implementation: `Agent/Services/ClaudeService.swift:applyAuthHeaders(on:credential:apiVersion:)`
- Detection helper: `Agent/Services/ClaudeService.swift:isOAuthToken(_:)`
