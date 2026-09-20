# LLM Provider Sponsorship & Integration

For LLM API providers, gateways, and model hosts (OpenAI-, Anthropic-, or Gemini-compatible endpoints). Simple rules, one integration fee, no logos on GitHub.

## The rules

1. **Any sponsorship level (Silver $500 / Gold $1,500 / Platinum $2,500) puts your name in the README under LLM Providers with a sponsorship badge** (Silver, Gold, or Platinum). README listing is name + badge — nothing else.
2. **On the website (agentiloop.ai):**
   - **Silver $500/mo** — listed under LLM Providers with the Silver badge.
   - **Gold $1,500/mo** — website LLM Providers card with your **logo**, linking to your website.
   - **Platinum $2,500/mo** — website LLM Providers card with your **logo + Platinum badge**, linking to your website.
3. **In-app:** every LLM Provider sponsor appears in Agent!'s built-in **Sponsors menu**, linking to your website.
4. **Integration fee (every LLM Provider, regardless of sponsorship level): $1,500.** Covers implementation, testing, and troubleshooting of your endpoint in Agent!.
   - **$2,500 integration fee** if more than one API must be implemented — e.g. OpenRouter exposes both OpenAI- and Anthropic-compatible APIs, and each needs to work with different model types.
5. Cash only, month-to-month via [GitHub Sponsors](https://github.com/sponsors/AgentiLoop) or invoice; 3-month minimum on the badge. No slots — every qualifying provider is listed.

## Compatibility standard (required for listing)

The endpoint must publicly document and pass:

- **Chat completions** in OpenAI, Anthropic Messages, or Gemini format
- **Streaming** (SSE) with correct `finish_reason` / stop handling
- **Native tool calling** with parallel tool calls and tool results round-trip — Agent! is tool-driven; a model that can't call tools reliably will be marked "chat only"
- **Model list endpoint** or a static, dated model list we can embed
- **Context window and max output tokens** per model
- **Public pricing page** and documented rate limits
- **API key auth** via header; no browser-only or OAuth-only access

We run the suite from CI on macOS runners. Results are public. Failing 2 consecutive nightly runs suspends the badge until fixed — sponsorship does not override this.

## What sponsorship does **not** buy

- Changing Agent!'s default provider or default model
- Removing, hiding, or down-ranking a competing provider
- Exclusivity of any kind
- Unlabeled recommendations or editorial control over benchmarks and FAQ cost guidance
- User data — the app has no analytics

## Contact

Provider partnerships: **agent@agentiloop.ai** (Todd Bruss, maintainer). Include: endpoint format (OpenAI / Anthropic / Gemini), model list URL, pricing page, and the tier you're interested in.
