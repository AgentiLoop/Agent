## ⚠️ Pre-release — 1.1.52 (build 252)

<!-- Add your screenshot here. -->

This is a **pre-release** from `main`, tagged `v1.1.52.252`. It includes the changes since `v1.1.51.251`: the **Claude output budget and compaction threshold are now percentages of the model's context window** instead of hard-coded token counts (no more 16K `max_tokens` on a 1M-context model), the **per-model output ceiling is learned automatically** from Anthropic's `max_tokens: X > Y` rejection and remembered, and the truncation-retry escalation no longer stops at 64K. Also a CLA workflow tweak and a stray file removal. Jev supplements your selected LLM provider rather than replacing it. The Release workflow builds, notarizes, and staples the `.zip` / `.dmg` attachments; downloads will appear after that workflow succeeds. Please report regressions against the v1.1.33.233 stable release.

### 🐛 Fixes
- **Claude `max_tokens` defaulted to a flat 16384** — with Max Output Tokens left at 0, requests to a 1M-context model went out with a 16K output budget and the truncation retry only doubled it to 32K. The default is now `defaultClaudeMaxTokens(contextWindow:modelCap:)` = window × `outputBudgetFraction` (0.5), floored at 4096 — 1M → 500K, 200K → 100K ([`367dd995`](https://github.com/AgentiLoop/Agent/commit/367dd995), [`6d5f7d8f`](https://github.com/AgentiLoop/Agent/commit/6d5f7d8f), [`d5a0136e`](https://github.com/AgentiLoop/Agent/commit/d5a0136e)).
- **Truncation retry capped at 64K** — `escalatedMaxTokens` now doubles the current budget bounded only by the room left in the context window; the fixed 64K ceiling is gone ([`d5a0136e`](https://github.com/AgentiLoop/Agent/commit/d5a0136e)).
- **Compaction threshold was a fixed token count** — `CompactionState.threshold` now compacts at `compactionFraction` (0.5) of the window (1M → 500K, 200K → 100K), still clamped so the reserved output fits on tiny local windows ([`d5a0136e`](https://github.com/AgentiLoop/Agent/commit/d5a0136e)).

### ✨ New
- **Per-model output cap learned from the API** — when Anthropic rejects a request with `max_tokens: X > Y, which is the maximum allowed number of output tokens for MODEL`, `parseMaxOutputCap` extracts Y and the model id, stores it in `modelMaxOutputTokens` (persisted in UserDefaults), logs `⚠️ MODEL caps output at Y tokens (asked X) — remembering it and retrying`, and retries the same transcript at Y. From then on that model's default budget is `min(window × 0.5, Y)` ([`d5a0136e`](https://github.com/AgentiLoop/Agent/commit/d5a0136e)).
- **Settings ▸ Max Output Tokens** — the Claude placeholder and caption now show the computed default and explain it is 50% of the context window, clamped to the model's real cap once learned ([`367dd995`](https://github.com/AgentiLoop/Agent/commit/367dd995), [`a8f9eee2`](https://github.com/AgentiLoop/Agent/commit/a8f9eee2)).

### 🧪 Tests
- `HarnessGuardTests` and `LLMCompactionTests` updated for the fraction-based default budget, learned-cap clamping, and the new compaction threshold ([`367dd995`](https://github.com/AgentiLoop/Agent/commit/367dd995), [`6d5f7d8f`](https://github.com/AgentiLoop/Agent/commit/6d5f7d8f), [`a8f9eee2`](https://github.com/AgentiLoop/Agent/commit/a8f9eee2)).

### 🤝 Community
- CLA Assistant is no longer a required status check in the `main` ruleset; the check still runs on every pull request ([`d5602219`](https://github.com/AgentiLoop/Agent/commit/d5602219)).
- Removed a stray screenshot file (`chat`) that was accidentally committed ([`6480b334`](https://github.com/AgentiLoop/Agent/commit/6480b334)).

### 🧪 What to test
- Install the signed `.dmg` / `.zip` from this pre-release and confirm the Launch Agent and Launch Daemon helpers register on first launch.
- With Claude selected and Max Output Tokens at 0, run a long task and confirm the activity log no longer shows `retrying the same request with max_tokens 16384 → 32768`.
- Select a Claude model with a lower real output ceiling and confirm the first request logs `⚠️ … caps output at … — remembering it and retrying`, then succeeds; a second task on the same model should not hit the rejection again.
- Open **Settings ▸ Max Output Tokens** and confirm the caption shows the computed default for the selected model.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version
- Version/build updated to **1.1.52 (build 252)**.

**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.51.251...v1.1.52.252
