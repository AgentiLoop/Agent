# AgentTests — What the test suite covers

`AgentTests` is the single unit-test target for Agent!. It uses **Swift Testing**
(`@Suite` / `@Test` / `#expect`), runs hosted inside `Agent!.app`, and is wired into
the `Agent!` scheme's Test action. 20 test files, ~470 test cases.

## Running

```sh
# Xcode: select the "Agent!" scheme → ⌘U
# CLI (same flags CI uses — ad-hoc signed, no Apple account required):
xcodebuild -project Agent.xcodeproj -scheme "Agent!" -configuration Debug \
  -destination 'platform=macOS' test
```

Two groups need something the default environment may not have:

| Group | Requirement | How it is gated |
|---|---|---|
| Live-network web tests (`WebAutomationTests`) | Real Safari + internet + third-party markup | Skipped unless `AGENT_RUN_NETWORK_TESTS=1` is set (`.enabled(if:)` on the suite) |
| AgentScript tests (`ScriptServiceTests`, `PackageAutoDiscoveryTests`, `PackageGenerationTests`) | `~/Documents/AgentScript` checked out, `swift build` working | Run locally; skipped in CI via `-skip-testing:` (see `.github/workflows/ci.yml`) |

Everything else is deterministic, offline, and runs on a clean machine.

---

## Test groups

The files fall into seven areas. Each section lists the file(s), what the group protects,
and what the individual tests check where the `@Test` names alone aren't self-explanatory.

### 1. Agentic loop — harness guards, loop control, goal state

These are the mechanisms that keep the autonomous task loop honest. A regression here
silently degrades every task, so each guard has deterministic, fixture-driven coverage.

**`HarnessGuardTests.swift`** — suites `HarnessGuards`, `StreamPrefetch`
- `isToolFailure`: a tool result is a failure only from its **status line**, not because the body mentions "error:".
- `toolCallFingerprint` (broken-record guard): fingerprint is deterministic regardless of dictionary key order, changes on any input/tool-name difference, and polling/wait tools are exempt from repeat detection.
- `routeStopReason` (loop control): `tool_use` with nothing parsable → retry; `max_tokens` truncation → continue with its own counter/cap; `end_turn` with open goal criteria → retry listing them; `end_turn` claiming an action with no tool call → retry; retry cap (3) always proceeds; normal turns proceed.
- `max_tokens` escalation: doubles but never past the context window nor the model's learned output cap; Anthropic "max_tokens ceiling" rejections are parsed into `(requested, limit, model)`; the "A + B > C" overflow lowers `max_tokens` instead of pruning.
- Retry delay: exponential with 25% jitter, capped at 32 s; `Retry-After` header wins.
- `GoalStateStore`: new goals start open; marking done **without evidence** is flagged unevidenced; with evidence the goal verifies; the prompt block lists open criteria and blocks `task_complete`; `clear` removes the goal.
- `PlanStateStore`: active plan with open steps is surfaced in the prompt; fully completed / missing plan / non-git folder produce no block.
- Periodic reminders: open criteria are re-listed every 10 turns unless `goal_state` was touched; the cache-warmth note fires once past 25% of a ≥1M-token window and never on small windows.
- Oversized tool results are persisted at emission and replaced with a preview + restore hint; small results, `read_file`, and `restore` pass through untouched.
- `StreamPrefetch`: only `read_file`, read-only shell commands, and list tools are eligible for prefetch; eligible `tool_use` blocks are started while streaming and drained exactly once; `executePendingToolBatches` consumes prefetched results and cancels orphans. Restoring a spilled read after the file changed is flagged **STALE**; restoring an unknown id is a cache miss.
- `uncommittedDiff` returns empty for a non-repo folder (critic gate plumbing).

**`AgenticCoreTests.swift`** — suites `GoalStateStoreTests`, `ToolFailureDetectionTests`, `StuckGuardFingerprintTests`, `FallbackChainServiceTests`
- `GoalStateStore` persistence: `set()` trims/filters criteria; `allCriteriaDone` semantics; empty criteria never count as verified; `setCriterion(text:)` matches case-insensitively and only the first hit; state survives a new store over the same directory; re-opening a criterion clears its evidence; whitespace-only evidence is not evidence; `promptBlock` renders evidence for verified criteria.
- Tool-failure detection: successful edits/writes whose *content* contains failure words are **not** failures; real failures are still detected from the status line; case-insensitive; the bare word "failed" alone does not trigger.
- `StuckGuard` fingerprinting: same contract as above (deterministic, key-order-independent, tool-name-prefixed, mutating tools are never exempt).
- `FallbackChainService` (serialized): first provider failure does not fall back; second failure selects the first *enabled* fallback; chain advances and skips disabled entries; feature-off never switches; a successful call returns to the primary; `reset` vs `clear` semantics; summary marks the active fallback; unknown provider raw values keep their display name.

**`LoopReplayTests.swift`** — suites `RouteStopReasonTests`, `TurnDecisionTests`, `LoopReplayScenarioTests`
Fixture replay of the loop's decision layer using scripted LLM turns — pure functions, no UI or stores.
- `routeStopReason`: same cases as HarnessGuards, replayed through scripted turns.
- `turnDecision`: tool results continue the loop; `task_complete` written as text or "done-signal" phrasing extracts the summary; plain text completes as text-only; tool calls with no results behave like a text-only turn.
- End-to-end scenarios: sub-agent narration is nudged twice then the run is *exhausted* (not completed); happy path; malformed tool call recovers next turn; `max_tokens` truncation is not completion; open criteria bounce premature completion until the cap releases; the tool-outcome advisory fires once at the failure threshold and chronic tools surface at task start; the continuation sanitizer leaves no orphaned tool blocks.

**`ResponseCompletionTests.swift`** — suite `ResponseCompletionTests`
Regression for the same-turn `task_complete` fix: when the model emits a tool call **and** `task_complete` in one turn, the pending tools execute before completion finalizes, and are consumed exactly once (no double execution).

**`ToolErrorClassifierTests.swift`** — suite `ToolErrorClassifier`
Each classification rule maps raw tool output to a typed error code plus a non-empty hint: `old_string_not_found`, `ambiguous_match`, `file_not_found` (only for file tools), `permission_denied`, `build_failed`, `timeout`, `network_unreachable`, `script_syntax_error` (only for script tools), `rate_limited`. Unrecognized output → `nil`; matching is case-insensitive; first matching rule wins; `annotation()` wraps code + hint and returns `nil` when unclassified.

### 2. Context management — compaction and prompt-cache stability

**`LLMCompactionTests.swift`** — suite `LLMCompactionTests`
- Threshold is a percentage of the context window (`compactionFraction`), floored so the reserved output still fits; reported `input_tokens` override the chars/4 estimate.
- `compactWithLLM` rebuilds the transcript as `[first prompt] + summary + "Understood" + tail` and spills the middle; when the summarizer fails, messages are left untouched.
- `microcompact` never clears protected tool results; a continuation idle > 60 min clears all but the last 5 tool results.
- Re-attachment after compaction: `appendUserText` joins the trailing user message or opens a new one; `postCompactReattachment` carries the open goal + edited-file head and resets read-dedup.
- Overflow routes through forced compaction, then falls back to the blind prune; if nothing shrinks the loop breaks.
- Compaction ladder (Tier 0 provider summary → Tier 1 Apple Intelligence → Tier 2 prune): non-Apple providers with a summarizer take Tier 0 and never reach Apple AI; toggle-off + no summarizer lands on Tier 2; Tier 0 failure falls through instead of aborting; Apple AI summarization is a no-op when the toggle is off, rewrites only long middle user turns, and is used only when the model is available.

**`PrefixStabilityTests.swift`** — suite `PrefixStabilityTests`
Between compaction events the message array must be byte-identical so provider prompt caches hit: `tieredCompact` below threshold changes nothing; repeated sends serialize to an identical prefix; `microcompact` keeps the newest tool results and is idempotent.

### 3. File editing and coding tools

**`CodingServiceTests.swift`** — suite `CodingService`
- `readFile`: numbered lines, offset/limit, missing file error, offset beyond EOF, limit larger than remaining.
- `writeFile`: creates file, creates intermediate directories, overwrites.
- `editFile`: exact replace, replace-all, error when `oldString` not found.
- `runCommand`: captures stdout and non-zero exit codes.
- `applyDiff` / `MultiLineDiff` integration: applies a unified diff, errors on a bad diff.
- `listFiles`: directory contents, missing-directory error.
- Git command builders: `buildGitCommitCommand` with/without file list (`git add -A`), single-quote escaping; `buildGitBranchCommand` with/without checkout.
- `preview` helper truncation.

**`DiffToolsTests.swift`** — suites `DiffTools`, `CodingServiceRegression`, `AppWideRegression`
Mirrors the exact input dictionaries the LLM sends to the diff tools and the exact handler steps:
1. `create_diff` then `apply_diff` with line range + UUID (2-step review).
2. `diff_and_apply` with a line range — same steps as create+apply.
3. `undo_edit` by `diff_id` via D1F `createUndoDiff`.
4. Two edits, undo the last one.
5. Truncation safety: a diff that would truncate the file is rejected.
6. Replacing 1 line with 3 lines.
7. All tools produce a D1F ASCII preview.
8. `DiffStore` UUID lifecycle (store, retrieve, track applies, clear).
9. `diff_and_apply` without a line range replaces the whole file.
10. `verifyDiff` SHA verification confirms integrity.
- Regressions: negative `limit` doesn't crash; out-of-range / inverted line ranges rejected; fuzzy line matching spans interior blank lines and leaves no stale lines; `editFile` replace-all works with fuzzy whitespace.
- App-wide regressions: `executeTCC` doesn't deadlock when stderr exceeds the 64 KB pipe buffer; `listBackups` ignores short names like `.DS_Store`; two backups of one file within a second both succeed; `isReadOnly` rejects a write hidden behind a mid-segment `&`.

**`EditGateTests.swift`** — suite `EditGateTests`
Tier 8 edit safety — an existing file may only be edited after it was read in the current task and only while its bytes still match what the model last saw: unread existing file → refused and auto-marked read (new files allowed); read → edit allowed; external change → refused; own edit → allowed again; an external change surfaces **once** as a diff snippet, after which the gate accepts the new bytes; `diffSnippet` output is capped.

**`CodeBlockHighlighterTests.swift`** — suite `CodeBlockHighlighter`
Syntax highlighting used by the activity log / chat renderer:
- `guessLanguage` detection for Swift, Python, JSON, shell; `nil` for unknown.
- Keyword, type, attribute, `self`, string (single/multiline/escaped), number (int/hex/float/scientific), and comment highlighting for Swift; language-specific keywords for Python, JavaScript, C preprocessor, Rust, TypeScript, Kotlin, Go, Ruby, SQL, JSON; language alias resolution.
- Non-code formats: terminal output (`ls -la` permissions, dates, error/warning keywords), diffs (added/removed/line-numbered), activity log lines (timestamps, shell commands, file paths, `file:line:` grep format), git output, hex dumps.
- ANSI escape codes are stripped before highlighting; empty input, unknown language (generic), and `nil` language (auto-detect) edge cases; bold font on keywords; multi-segment and `~` path coloring; property access and function call coloring; dark-mode theme colors; Bash variables and system functions; complex/nested Swift samples.

### 4. Safety — shell guardrails and automation permissions

**`ShellSafetyServiceTests.swift`** — suite `ShellSafetyService`
The command guardrail evaluated before any shell execution, in both the user-agent and root-daemon contexts:
- Catastrophic `rm`: `rm -rf /` and flag variants, `--no-preserve-root`, home-directory forms, bare globs / `.` / `..`, system roots (user agent), and the current project folder are blocked; a specific subdirectory or `rm` without both `-r` and `-f` is allowed.
- Prefix wrappers (`sudo`/`exec`/`eval`, env-var prefixes) cannot disguise a blocked command; a dangerous segment inside a compound command is blocked while harmless compounds pass.
- `find -delete` on a broad root is blocked, narrow roots allowed, `find` without `-delete` always allowed.
- Recursive `chmod`/`chown` on system roots blocked, narrow paths allowed.
- Classic fork bomb blocked; `mv` of home/system dirs to `/dev/null` blocked, normal `mv` allowed.
- Root daemon: still blocks the three catastrophic `rm` patterns (including inside compounds) but allows system-admin operations.
- Everyday commands are allowed; quoted dangerous strings are not false positives; the verdict block carries a reason and rule name.
- Tier 9.2 read-only classification: plain reads (pipes, `&&`, `2>/dev/null`, `git status`) are read-only; anything that can mutate is not; batch classification lets user-shell reads join the parallel batch while root-shell commands never do.

**`AccessibilityEnabledTests.swift`** — suite `AccessibilityEnabled`
The per-action / per-role / per-Apple-Event-selector enable switches stored in `UserDefaults`:
- Everything is enabled by default (AX actions, AX roles, Apple Events write selectors).
- Disabling an AX action (`AXPress`), an AX role (`AXSecureTextField`), or an AE write selector (`delete`) makes it restricted; toggles round-trip back to the original state.
- Unknown IDs are never restricted — only known IDs can be.
- Every Apple Events write selector (`close`, `remove`, `quit`, `move`, `moveTo`, `duplicate`, `save`, `set`, `sendMessage`) can be individually disabled/re-enabled; non-write methods are never in the enabled set.
- `axEnabledKey` / `aeEnabledKey` values are fixed, and `UserDefaults` is populated on first access.

**`AccessibilityServiceTests.swift`** — suite `AccessibilityService`
Behavioural contract of the AX automation service. Several tests degrade gracefully (rather than fail) when the Accessibility permission is not granted:
- Permission queries return booleans without crashing.
- `listWindows`, `inspectElementAt`, `getElementProperties`, `typeText`, `clickAt` (buttons, double-click), `scrollAt`, `pressKey` (modifiers), `captureScreenshot` / `captureAllWindows`, and `getAuditLog` all return well-formed JSON (or a string for the audit log) and honour `limit` / `depth` parameters and invalid coordinates.
- `performAction` allows enabled actions and requires either coordinates or role/title.
- `successJSON` / `errorJSON` helpers produce valid JSON and escape quotes.
- Security: enabled roles are not restricted; enabled actions are allowed.
- Integration smoke tests: list windows, inspect at screen centre, screenshot, audit log.

### 5. Providers and parsers

**`ProviderParserTests.swift`** — suites `OllamaService parsers`, `CodexJWT`, `CodexPatchApplier`, `OpenAIToolCallParsing`
- Ollama text-embedded tool calls: `extractFirstJSON` returns the first balanced object, ignores braces inside strings / escaped quotes, and returns `nil` for unbalanced input; `extractFirstToolCall` picks the earliest known tool name, tolerates up to 20 junk characters before the brace, and returns `nil` with no tool name. DeepSeek V3.1 fullwidth-token format with `tool_sep`, DeepSeek legacy `{name,parameters}` with ASCII pipes and multiple calls, and DSML `invoke`/`parameter` blocks (string and non-string params, bare JSON body) are parsed; each parser returns `nil` without its markers.
- Codex JWT: base64url payload decoding, nested `chatgpt_account_id`, `exp` → `Date`, malformed tokens → `nil`.
- Codex freeform patch applier: `Add File` (creates intermediate dirs), `Update File` context/remove/insert hunks, context mismatch leaves the file untouched, `Delete File` / `Move File`, preamble before `Begin Patch` is skipped, empty patch yields a no-change summary.
- OpenAI-compatible tool-call helpers: `shortToolId` is 9 alphanumeric chars and unique; `sanitizeToolId` hashes long ids deterministically without collisions on shared prefixes and pads short ids; `isToolCallJSON` accepts `{name, arguments}` objects and rejects prose, partial JSON, wrong shapes, or non-string names.

**`ExaSearchTests.swift`** — suite `ExaSearch`
Exa web-search response formatting with hardcoded fixtures (never hits the network): standard response with text + highlights, empty results message, malformed JSON parse error, missing optional fields; snippet fallback order highlights → summary → text (skipping whitespace-only highlights); an empty API key returns a "not set" error without making a request.

### 6. AgentScript (Swift dylib scripts) — local-only

These operate on the real `~/Documents/AgentScript` package and invoke `swift build`, so they
are skipped in CI.

**`ScriptServiceTests.swift`** — suite `ScriptService`
- Create: produces `Sources/Scripts/{Name}.swift`, converts `snake_case` to `UpperCamelCase`, strips a `.swift` suffix, and errors on duplicates.
- Read/Update/Delete/List: nonexistent read → `nil`; update changes content or errors when missing; delete succeeds and is idempotent; list includes created scripts.
- `compileCommand` returns a `swift build` command (or `nil` for a missing script); `dylibPath` uses the `lib` prefix and `.dylib` extension.
- `AGENT_SCRIPT_ARGS`: `loadAndRunScript` exports the arguments via the env var, does not set it when arguments are empty, and cleans it up after the run.
- JSON I/O: a script reads `<Name>_input.json` and writes `<Name>_output.json`, and handles a missing input file gracefully.

**`PackageAutoDiscoveryTests.swift`** — suite `Package.swift Auto-Discovery`
New scripts appear as targets without editing `Package.swift`; deleted scripts disappear; `import XBridge` lines are mapped to the right bridge product dependency (single, multiple, none, and `ScriptingBridgeCommon`). Verified by running `swift package dump-package`.

**`PackageGenerationTests.swift`** — suite `Package.swift Generation`
`Package.swift` exists after `ensurePackage` via create; a created script is listed as a dynamic-library target; a deleted script's target is removed.

### 7. Live-network web automation — opt-in

**`SafariWebAutomationTests.swift`** — suite `WebAutomation` (serialized, `AGENT_RUN_NETWORK_TESTS=1` only)
Drives real Safari against Google, LinkedIn, and GitHub: Google search (open, type, submit, read results, special characters), Google signup form detection / fill / Next button, LinkedIn page-state detection (login vs feed), login field detection, feed post/comment detection, and `executeJavaScript` (document title, DOM element count, click + type via JS). Results depend on network, login state, and third-party markup — that is why the suite is off by default.

---

## Adding tests

- One file per service, named `<Service>Tests.swift`, with a `@Suite("<Service>")`.
- Use `// MARK: -` sections to group related cases; give each `@Test` a sentence-style name that states the expected behaviour.
- Keep tests offline and deterministic. If a test genuinely needs the network or an external checkout, gate it with `.enabled(if:)` and document the env var in this file.
- Tests that touch `AgentViewModel` or `UserDefaults` should be `@MainActor` and, where they share state, `.serialized`.
