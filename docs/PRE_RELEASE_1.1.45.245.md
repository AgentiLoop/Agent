<!-- Suggested release title: Agent! 1.1.45.245-pre -->
<!-- Draft only: 1.1.45 (build 245) and v1.1.45.245 are proposed, not yet applied. -->

## ⚠️ Pre-release — 1.1.45 (build 245)

<!-- Add your screenshot here. -->

This **pre-release draft** covers changes on `main` through `e1ca074c` since `v1.1.44.244`: an optional **Jev decision layer**, the bundled **TypeSafeKit** Swift package, and a dedicated **LLM Common Settings** panel. Jev provides a second opinion before shell execution; it does not replace your selected LLM provider.

### 🔒 Jev — optional shell-command advice
- Added Jev integration using TypeSafe System One, separate from the chat-provider picker (`51056c33`).
- Before executing a shell command, Agent! can ask Jev whether it would irreversibly destroy data or render the system unbootable. The advisor uses a destructive-risk threshold of 0.9 alongside the existing local shell guardrails.
- Extended the advisory check to the user Launch Agent and privileged Launch Daemon execution paths (`6ded35e1`, `26277cec`).
- Automatic shell advice is a no-op when no API key is configured or **Consult Jev before tools** is off. Ordinary API failures are logged and allow the command to continue; cancellation during a Jev check stops execution (`bd1e1e3c`).
- Activity logging now reports Jev's risk percentage, allowed/refused verdict, answering model, and input/output token counts. Failed checks are visible rather than silently looking like a safe verdict (`82188f8f`, `ed759350`).

<!-- Source: Agent/Services/JevAdvisor.swift:15–63; Agent/Services/UserService.swift:222–226; Agent/Services/HelperService.swift:221–225. -->

### ⚙️ LLM Common Settings
- Moved provider-independent controls into **LLM Common Settings**: web-search keys, Jev configuration, and system-prompt editing (`01b94461`).
- Added Jev API-key entry, model selection, catalog refresh, and the advisory toggle. The model catalog loads automatically after a usable key is entered (`6ded35e1`).
- Preserved explicitly selected model IDs during catalog refresh and kept selections absent from the returned catalog visible in the picker (`917e2d58`, `e1ca074c`).

<!-- Source: Agent/Views/Settings/LLMCommonSettingsView.swift:56–113,116–139; Agent/AgentViewModel/Core/AgentViewModel.swift:293–350. -->

### 📦 TypeSafeKit
- Replaced the app's hand-written Jev client with **TypeSafeKit**, then vendored the package into this repository (`89c91d1f`, `173bc59b`).
- The package provides the System One HTTP client and a separate **TypeSafeMiddleware** product with typed routing, gating, rating, composite-scoring, and evaluation helpers.
- Added focused regression coverage alongside fixes for client-model preservation and HTTP cancellation handling (`e45339ac`, `23f7ac04`).

<!-- Source: TypeSafeKit/README.md:5–8; commit subjects and file lists for 89c91d1f,173bc59b,e45339ac,23f7ac04. -->

### 📄 Repository notices
- Restored the canonical MIT `LICENSE` text and moved ownership, trademark, and distributed-binary notices into `NOTICE` (`18bdb16f`).

<!-- Source: NOTICE:8–24; commit 18bdb16f. -->

### 🧪 What to test
- With Jev disabled or no key configured, confirm shell execution does not wait for a Jev advisory request.
- With a valid key and advice enabled, confirm the activity log shows a verdict and usage information.
- Stop a task while Jev is checking a command and confirm the command does not launch afterward.
- Refresh the model catalog with a pinned model selected and confirm the selection is retained.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version and release preparation
- Proposed version: **1.1.45 (build 245)**; proposed tag: `v1.1.45.245`.
- Before publishing: add the screenshot, apply and verify the version/build, run release validation, and attach the Release workflow's verified artifacts. This draft does not claim that binaries have been built, notarized, or uploaded.

**Changes covered by this draft:** `v1.1.44.244...e1ca074c`.

<!-- When the release tag exists, replace the draft comparison above with:
**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.44.244...v1.1.45.245
-->
