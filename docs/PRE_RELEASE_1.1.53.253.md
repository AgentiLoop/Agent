## ⚠️ Pre-release — 1.1.53 (build 253)

<!-- Add your screenshot here. -->

This is a **pre-release** from `main`, tagged `v1.1.53.253`. It includes the changes since `v1.1.52.252`: the **truncation-retry escalation now respects the model's learned output ceiling** (no more doubling a 128K-capped model toward a guaranteed 400), the **compaction threshold no longer double-counts a safety buffer** against the output half of the window, **Agent! refuses to `rm -rf` its own project folder** on every execution path including the root daemon, and the project has been **relicensed from MIT to PolyForm Noncommercial 1.0.0**. Jev supplements your selected LLM provider rather than replacing it. The Release workflow builds, notarizes, and staples the `.zip` / `.dmg` attachments; downloads will appear after that workflow succeeds. Please report regressions against the v1.1.33.233 stable release.

### 🐛 Fixes
- **`max_tokens` escalation ignored the model's real output cap** — after a `max_tokens` truncation, `escalatedMaxTokens` doubled the budget bounded only by the context window, so a model with a learned 128K ceiling (e.g. Claude Fable 5.1 on a 1M window) could be retried at 256K and rejected. It now takes `modelCap:` from `modelMaxOutputTokens[model]` and clamps to it; at the cap it returns `nil` so no futile retry is spent. Unknown caps (`nil` / 0) behave as before ([`37a2d309`](https://github.com/AgentiLoop/Agent/commit/37a2d309)).
- **Compaction threshold undershot the 50% line** — `CompactionState.threshold` subtracted an extra `min(13K, window/10)` buffer from `window − reservedOutput`, pulling a 200K/100K configuration down to 87K instead of 100K. The buffer is gone: when `max_tokens` is the other half of the window, the 50% line already leaves exactly that room ([`95ed1f56`](https://github.com/AgentiLoop/Agent/commit/95ed1f56)).

### 🛡️ Safety
- **Recursive deletion of the current project folder is blocked** — `ShellSafetyService.check` now takes `projectFolder:`; `rm -rf` of that folder itself, or a glob of everything inside it (`*`, `.`, quoted forms), is refused with rule `rm.project-folder` on `execute_agent_command`, `execute_daemon_command`, the user Launch Agent, and the root Launch Daemon (`Shared/DaemonCore.swift`). Named subdirectories inside the project remain deletable ([`fa0ab6f0`](https://github.com/AgentiLoop/Agent/commit/fa0ab6f0)).

### 📄 License
- **Relicensed from MIT to PolyForm Noncommercial 1.0.0** — `LICENSE`, `NOTICE`, `CONTRIBUTING.md`, `CLA.md`, all README translations, and `docs/` updated; copyright year bumped to 2026 ([`fc72aaf5`](https://github.com/AgentiLoop/Agent/commit/fc72aaf5), [`ed1dd790`](https://github.com/AgentiLoop/Agent/commit/ed1dd790)).

### 🧪 Tests
- `HarnessGuardTests`: new `maxTokensEscalationRespectsModelCap` covering at-cap → `nil`, below-cap → clamped, and unknown-cap → unchanged doubling ([`37a2d309`](https://github.com/AgentiLoop/Agent/commit/37a2d309)).
- `ShellSafetyServiceTests`: project-folder wipe cases (folder itself, `*` glob, quoted path, root-daemon context) and the allowed named-subdirectory case ([`fa0ab6f0`](https://github.com/AgentiLoop/Agent/commit/fa0ab6f0)).

### 🧪 What to test
- Install the signed `.dmg` / `.zip` from this pre-release and confirm the Launch Agent and Launch Daemon helpers register on first launch.
- With Claude Fable 5.1 selected and Max Output Tokens at 0, run a task long enough to truncate once; the activity log should show a single `retrying the same request with max_tokens … → 128000` (or no retry if already at the cap) and never a `max_tokens: 256000 > 128000` rejection.
- With a 200K-window model, confirm compaction now triggers near 100K input tokens rather than ~87K.
- Ask Agent! to `rm -rf` the current project folder (or `rm -rf *` inside it) via both the user agent and the root daemon; both must be refused with `rm.project-folder`. Deleting a named subdirectory should still work.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version
- Version/build updated to **1.1.53 (build 253)**.

**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.52.252...v1.1.53.253
