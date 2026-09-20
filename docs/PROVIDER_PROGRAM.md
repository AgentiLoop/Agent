# LLM Provider Sponsorship & Integration

For LLM API providers, gateways, and model hosts (OpenAI-, Anthropic-, or Gemini-compatible endpoints). See [SPONSORSHIP.md](./SPONSORSHIP.md) for the full program.

## Levels of sponsorship

| Level | Price | README files | Website (agentiloop.ai) | Sponsors menu in Agent! |
|---|---|---|---|---|
| **Silver** | $500 / mo | Name + Silver sponsored badge under LLM Providers | — | ✓ (name + level → your website) |
| **Gold** | $1,500 / mo | Name + Gold sponsored badge under LLM Providers | **Logo** in the Sponsored Providers section → your website | ✓ |
| **Platinum** | $2,500 / mo | Name + Platinum sponsored badge under LLM Providers | **Logo** in the Sponsored Providers section (top placement) → your website | ✓ |

## Integration fee (every LLM Provider, regardless of level)

- **$1,500** one-time — implementation, testing, and troubleshooting of your endpoint in Agent!
- **$2,500** one-time when more than one API must be implemented (e.g. OpenRouter exposes both OpenAI- and Anthropic-compatible APIs, and each needs to work with different model types)

## Compatibility standard (required for listing)

The endpoint must publicly document and pass:

- **Chat completions** in OpenAI, Anthropic Messages, or Gemini format
- **Streaming** (SSE) with correct `finish_reason` / stop handling
- **Native tool calling** with parallel tool calls and tool results round-trip — Agent! is tool-driven; a model that can't call tools reliably will be marked "chat only"
- **Model list endpoint** or a static, dated model list we can embed
- **Context window and max output tokens** per model
- **Public pricing page** and documented rate limits
- **API key auth** via header

## Rules

- **All billing via [GitHub Sponsors → AgentiLoop](https://github.com/sponsors/AgentiLoop)** — no invoiced billing, no credits, no in-kind payments
- Month-to-month; 3-month minimum on the badge/logo
- No slots — every qualifying provider is listed
- Sponsorship does not buy: changes to Agent!'s default provider/model, removal or down-ranking of competitors, exclusivity, or user data (the app has no analytics)

## Contact

Provider partnerships: **agent@agentiloop.ai** (Todd Bruss, maintainer). Include: endpoint format (OpenAI / Anthropic / Gemini), model list URL, pricing page, and the level you're interested in.
