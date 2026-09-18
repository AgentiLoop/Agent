# TypeSafeKit

Swift client + agent middleware for the [TypeSafe AI](https://typesafe.ai) System One API (`jev-latest`).

Two products:

- **TypeSafeKit** — thin, dependency-free HTTP client for `POST /v1/systemone` and `GET /v1/models`.
- **TypeSafeMiddleware** — a `DecisionProvider` protocol plus typed helpers (`route`, `gate`, `rate`, `composite`, `evaluate`) for wiring Jev into an agent loop.

## Jev is not a chat model

Jev takes a **state** plus a map of typed **questions** and returns **typed answers with probability distributions**. There are no messages, no assistant text, no streaming, and no tool calling. This package therefore does **not** imitate an OpenAI/Anthropic chat surface — a shim like that would have to fabricate text Jev never produces. Use Jev next to your chat model, for the decisions: intent routing, tool-use gating, confidence checks, classification, extraction scoring.

## Install

```swift
.package(url: "https://github.com/<you>/TypeSafeKit.git", from: "0.1.0")
```

```swift
.product(name: "TypeSafeKit", package: "TypeSafeKit"),
.product(name: "TypeSafeMiddleware", package: "TypeSafeKit"),
```

## Client

```swift
import TypeSafeKit

let client = try TypeSafeClient()   // reads TYPESAFE_API_KEY, defaults to jev-latest

let reply = try await client.systemOne(
    state: "Hi, I've been trying to connect my Stripe account for 3 days and it keeps failing.",
    questions: [
        "is_urgent": .noul(instructions: "Does this message convey urgency?"),
        "department": .choice(instructions: "Which team should handle this?", criteria: [
            "billing":   "Payments, invoicing, refunds",
            "technical": "Bugs, outages, integrations",
            "sales":     "Pricing, upgrades, new accounts",
        ]),
        "frustration": .score(
            instructions: "How frustrated is the customer?",
            levels: ["Calm", "Frustrated", "Very angry"]),
    ])

reply["is_urgent"]?.noulValue      // 0.92
reply["department"]?.choiceValue   // "technical"
reply["department"]?.confidence    // 0.82
reply["frustration"]?.scoreValue   // 1.6
reply.usage.inputTokens            // billed; output tokens are free
reply.model                        // versioned ID that answered, e.g. jev-1.13.0
```

Every question in one request is evaluated in parallel against the same state, so pack them together (speculative fan-out) instead of making several calls.

State can be structured:

```swift
try await client.systemOne(state: State(["turn 1", "turn 2"]), questions: [...])
try await client.systemOne(state: try State.encoding(myRecord), questions: [...])
```

List models:

```swift
for model in try await client.models.list() { print(model.name, model.releaseDate) }
```

## Middleware

```swift
import TypeSafeMiddleware

enum Route: String, CaseIterable { case answerDirectly, callTool, askHuman }

let jev = try JevProvider()

let routing = try await jev.route(
    State(transcript),
    instructions: "What should the agent do next?",
    as: Route.self,
    descriptions: [
        .answerDirectly: "The answer is already known",
        .callTool:       "External data or a side effect is needed",
        .askHuman:       "Destructive, ambiguous, or out of policy",
    ],
    minimumConfidence: 0.7)

guard routing.isConfident else { return .escalate }
switch routing.route { ... }
```

```swift
// Tool-use gate before executing a side effect
let safe = try await jev.gate(
    State(["tool": .string(name), "arguments": args]),
    statement: "This tool call is safe to run without user confirmation.",
    threshold: 0.9)
if !safe.passed { await confirmWithUser() }
```

```swift
// Weighted composite instead of one broad judgment
let score = try await jev.composite(
    State(pitch),
    components: [
        "market":      .score(instructions: "Market size?", levels: ["Niche", "Large", "Huge"]),
        "feasibility": .score(instructions: "Technical feasibility?", levels: ["Unlikely", "Plausible", "Proven"]),
    ],
    weights: ["market": 2, "feasibility": 1])
```

Conform your own type to `DecisionProvider` (one method: `decide(state:questions:)`) to stub Jev in tests or swap in another decision engine — the helpers come free.

## Behavior

| Concern | Handling |
| --- | --- |
| Auth | `Authorization: Bearer $TYPESAFE_API_KEY`; `TYPESAFE_BASE_URL` overrides the host |
| Retries | `RetryPolicy` — 3 attempts, exponential backoff + jitter, honors `retry-after`, retries 408/429/500/502/503/504/529 only |
| Errors | `TypeSafeError` cases for 400/401/403/404/422/429/529, transport, timeout, decoding, and local validation |
| Local validation | Empty instructions, empty question map, Choice with no options, Score with fewer than two levels fail before the request |
| Networking | `URLSession` by default; inject any `TypeSafeTransport` |

## Limits (per TypeSafe docs, Jev 1.13)

- 64k tokens per request total; 32k for state plus the longest single question
- Text only — pre-process images/audio/binaries into text or fields
- Input tokens billed, output tokens free
- Rate limits are adjusting dynamically during early access; expect 429s and keep retries on

## Tests

```
swift test    # 14 tests, no network — stubbed transport
```

Every request/response shape asserted in the tests is taken from the published API reference. **Nothing here has been exercised against the live service yet** — Jev is in early access behind a waitlist, so a real `TYPESAFE_API_KEY` is needed to confirm end-to-end.
