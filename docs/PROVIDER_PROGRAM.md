# LLM Provider Partner Program

Standards for how LLM API providers, gateways, and model hosts (OpenAI-, Anthropic-, or Gemini-compatible endpoints) integrate with and sponsor 🦾 Agent!. This is the provider-specific companion to [SPONSORSHIP.md](./SPONSORSHIP.md).

Design goals, in order: (1) providers get something *measurable* for their money, (2) Agent! users always see honest, labeled placements, (3) the price points sit where comparable projects have actually closed deals rather than where we'd like them to be.

## What providers actually pay for

From the provider's side, sponsorship is a customer-acquisition cost. The things that convert are, in rough order of value to them:

| # | What | Why it converts |
|---|---|---|
| 1 | **Being in the provider picker with a one-click preset** (base URL, model list, capability flags pre-filled) | Zero-friction setup = tokens routed through them the same day |
| 2 | **A tracked signup link / promo code** in the app, README, and docs | Lets them attribute users and justify renewal — Agent! has no telemetry, so this is the *only* measurement channel |
| 3 | **"Works with Agent!" verification** — nightly CI run of the tool-calling + streaming suite against their endpoint | Compatibility badge they can show their own customers; catches regressions before users do |
| 4 | **A maintainer-written config guide** (`docs/providers/<name>.md`) that ranks in search | Long-tail traffic for "<provider> macOS agent" |
| 5 | **Logo placement** (README, website, release notes) | Brand awareness; matters less than 1–4 to most providers |
| 6 | **Co-marketing** (launch post, case study, social) | Content they can repost |
| 7 | **Priority compatibility fixes + roadmap input** | Insurance that their endpoint keeps working across releases |

Providers rarely pay for logo-only placement at a project this size. They pay for #1–#3 and treat #5–#7 as extras.

## Tiers

Prices are USD, month-to-month, billed via [GitHub Sponsors](https://github.com/sponsors/AgentiLoop) (custom amount) or invoice. Logo/badge placements have a 3-month minimum. Annual prepay = 12 months for the price of 10.

| Tier | Cash | or API credits* | Slots | Includes |
|---|---|---|---|---|
| **Listed** | Free | — | Unlimited | Row in the README **AI Providers** table for any endpoint that passes the compatibility suite. No logo, no link tracking. Neutral baseline — every compatible provider gets this. |
| **Verified** | $250 / mo | $500 / mo | Unlimited | "Works with Agent!" badge; nightly CI compatibility run against your endpoint with public status; logo + tracked signup link in the provider table; `docs/providers/<name>.md` config guide; promo code surfaced in the FAQ and guide |
| **Featured** | $1,000 / mo | $2,000 / mo | 6 | Everything in Verified, plus: first-class provider preset in the in-app picker (icon, base URL, model list, capability metadata); "Sponsored" callout in the FAQ cost section; mention in every release's notes; launch announcement in Discussions + agentiloop.ai; quarterly 30-min call |
| **Premier** | $2,500 / mo | $5,000 / mo | 2 | Everything in Featured, plus: logo in the README header + agentiloop.ai; 2-business-day acknowledgement on compatibility issues; early access to pre-release builds for testing new models; co-marketing case study; input on provider-related roadmap |

\* Credits are valued at 50% of face value (see [in-kind policy](./SPONSORSHIP.md#in-kind-sponsorship-api-credits-discounts-hardware)). Mixed cash + credits is fine. Credits must be usable for CI and provider testing (no expiry shorter than 90 days).

### One-time

| Item | Price | Notes |
|---|---|---|
| **Integration** | $1,500 | First-class provider entry: picker icon, base URL preset, model list, capability metadata, tool-calling + streaming tests, config guide. Delivered under MIT. **Waived** for Featured/Premier with a 6-month commitment. |
| **Model launch** | $500 | Same-week support + release-notes callout when you ship a new model (adds it to the preset, verifies tool calling, updates the guide) |
| **Feature bounty** | from $1,000 | Provider-specific capability (e.g. prompt caching, batch API, native structured output). Scoped and quoted per issue. |

### Performance-based (no cash)

If you run an affiliate / referral program, Agent! will use your referral link in all placements **instead of** a cash fee at the Verified level, provided the program pays on paid usage (not just signups). This is often the easiest deal for a provider to approve.

## Compatibility standard (required for Listed and above)

To be listed, an endpoint must publicly document and pass:

- **Chat completions** in OpenAI, Anthropic Messages, or Gemini format
- **Streaming** (SSE) with correct `finish_reason` / stop handling
- **Native tool calling** with parallel tool calls and tool results round-trip — Agent! is tool-driven; a model that can't call tools reliably will be marked "chat only"
- **Model list endpoint** or a static, dated model list we can embed
- **Context window and max output tokens** per model
- **Public pricing page** and documented rate limits
- **API key auth** via header; no browser-only or OAuth-only access

We run the suite from CI on macOS runners. Results are public in the provider's guide. Failing 2 consecutive nightly runs downgrades the badge to "Verification pending" until fixed — sponsorship does not override this.

## Placement rules (what every provider gets, and what nobody gets)

**Every paid placement is labeled** "Sponsor" or "Sponsored". Any material connection (cash, credits, discounts, referral revenue) is disclosed where the sponsor appears.

Not for sale, at any tier:
- Changing Agent!'s default provider or default model
- Removing, hiding, or down-ranking a competing provider
- Exclusivity of any kind
- Unlabeled recommendations, edited benchmarks, or editorial control over the FAQ's cost guidance
- User data — the app has no analytics and never will as a sponsor perk

## Terms

- Month-to-month; 3-month minimum on logo/badge placements; 30 days' notice to cancel after that
- Invoicing (net-30) available at Featured and above; GitHub Sponsors otherwise
- Placement removed at the end of the last paid month; the config guide stays (it helps users) but loses the badge
- Provider must keep the tracked signup link and promo code valid for the term
- Governing law: North Carolina, USA

## How we benchmarked these prices

| Project | Scale | Comparable price points |
|---|---|---|
| Open WebUI | ~150k ★ | $1,024/mo release-notes logo · $2,048/mo docs logo · $8,192/mo top logo |
| Crawl4AI | ~50k devs | $500/mo team tier · $2,000/mo infrastructure partner |
| AgentOS | small | Featured provider-list placement, all sponsor placements labeled |

Agent! is ~600 ★ with 2,000+ downloads, so tiers sit roughly 4–8× below Open WebUI's and in line with Crawl4AI's, while offering the one thing those projects don't: a native macOS picker preset and a nightly compatibility run against the provider's endpoint.

## Contact

Provider partnerships: **agent@agentiloop.ai** (Todd Bruss, maintainer). Include: endpoint format (OpenAI / Anthropic / Gemini), model list URL, pricing page, and whether you prefer cash, credits, or referral.
