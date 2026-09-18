## ⚠️ Pre-release — 1.1.45 (build 245)

<!-- Add your screenshot here. -->

This is a **pre-release** from `main`, tagged `v1.1.45.245`. It includes the changes since `v1.1.44.244`: optional **Jev shell-command advice**, the bundled **TypeSafeKit** Swift package, and a dedicated **LLM Common Settings** panel. Jev supplements your selected LLM provider rather than replacing it. The Release workflow builds, notarizes, and staples the `.zip` / `.dmg` attachments; downloads will appear after that workflow succeeds. Please report regressions against the v1.1.33.233 stable release.

### 🔒 Jev — optional shell-command advice
- Added Jev (TypeSafe System One) as a separate decision layer, with a second opinion on potentially destructive shell commands alongside the existing local guardrails ([`51056c33`](https://github.com/AgentiLoop/Agent/commit/51056c33)).
- Extended advisory checks to the user Launch Agent and privileged Launch Daemon shell paths ([`6ded35e1`](https://github.com/AgentiLoop/Agent/commit/6ded35e1), [`26277cec`](https://github.com/AgentiLoop/Agent/commit/26277cec)).
- Shell advice is a no-op when no API key is configured or **Consult Jev before tools** is off. Ordinary API failures are logged and allow the command to continue; cancellation during a Jev check stops execution ([`bd1e1e3c`](https://github.com/AgentiLoop/Agent/commit/bd1e1e3c)).
- Activity logging reports the destructive-risk percentage, allowed/refused verdict, answering model, and input/output token counts. Failed checks are visible rather than silently looking like a safe verdict ([`82188f8f`](https://github.com/AgentiLoop/Agent/commit/82188f8f), [`ed759350`](https://github.com/AgentiLoop/Agent/commit/ed759350)).

### ⚙️ LLM Common Settings
- Moved provider-independent controls into **LLM Common Settings**: web-search keys, Jev configuration, and system-prompt editing ([`01b94461`](https://github.com/AgentiLoop/Agent/commit/01b94461)).
- Added Jev API-key entry, model selection, catalog refresh, and the advisory toggle. The model catalog loads automatically after a usable key is entered ([`6ded35e1`](https://github.com/AgentiLoop/Agent/commit/6ded35e1)).
- Preserved explicitly selected model IDs during catalog refresh and kept selections absent from the returned catalog visible in the picker ([`917e2d58`](https://github.com/AgentiLoop/Agent/commit/917e2d58), [`e1ca074c`](https://github.com/AgentiLoop/Agent/commit/e1ca074c)).

### 📦 TypeSafeKit
- Replaced the app's hand-written Jev client with **TypeSafeKit**, then vendored the package into this repository ([`89c91d1f`](https://github.com/AgentiLoop/Agent/commit/89c91d1f), [`173bc59b`](https://github.com/AgentiLoop/Agent/commit/173bc59b)).
- The package provides the System One HTTP client and a separate **TypeSafeMiddleware** product with typed routing, gating, rating, composite-scoring, and evaluation helpers.
- Added regression coverage and fixed client-model preservation and HTTP cancellation handling ([`e45339ac`](https://github.com/AgentiLoop/Agent/commit/e45339ac), [`23f7ac04`](https://github.com/AgentiLoop/Agent/commit/23f7ac04)).

### 📄 Repository notices
- Restored the canonical MIT `LICENSE` text and moved ownership, trademark, and distributed-binary notices into `NOTICE` ([`18bdb16f`](https://github.com/AgentiLoop/Agent/commit/18bdb16f)).

### 🧪 What to test
- With Jev disabled or no key configured, confirm shell execution does not wait for a Jev advisory request.
- With a valid key and advice enabled, confirm the activity log shows a verdict and usage information.
- Stop a task while Jev is checking a command and confirm the command does not launch afterward.
- Refresh the model catalog with a pinned model selected and confirm the selection is retained.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version
- Version/build updated to **1.1.45 (build 245)** ([`18704749`](https://github.com/AgentiLoop/Agent/commit/18704749)).

**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.44.244...v1.1.45.245
