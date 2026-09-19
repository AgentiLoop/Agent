## ⚠️ Pre-release — 1.1.46 (build 246)

<!-- Add your screenshot here. -->

This is a **pre-release** from `main`, tagged `v1.1.46.246`. It includes the changes since `v1.1.45.245`: a user-tunable **Jev reject threshold** in Settings, a lower **70% default** cut-off, and blue tinting for the Jev controls. Jev supplements your selected LLM provider rather than replacing it. The Release workflow builds, notarizes, and staples the `.zip` / `.dmg` attachments; downloads will appear after that workflow succeeds. Please report regressions against the v1.1.33.233 stable release.

### 🔒 Jev — tunable reject threshold
- Added a **Reject at … % destructive** slider to LLM Common Settings, 0–100% in 10% steps, disabled until a Jev API key exists and **Consult Jev before tools** is on ([`76172e7c`](https://github.com/AgentiLoop/Agent/commit/76172e7c)).
- Stored the threshold in `UserDefaults` under `jevBlockThreshold` as 0.0–1.0 and bound it to the view model as a percentage. An unset key falls back to the default instead of reading as 0 and blocking everything ([`76172e7c`](https://github.com/AgentiLoop/Agent/commit/76172e7c)).
- `JevAdvisor.destructiveBlockThreshold` is now a computed property reading `JevConfiguration.blockThreshold`, so the advisory gate picks up the user's setting instead of a hardcoded constant ([`76172e7c`](https://github.com/AgentiLoop/Agent/commit/76172e7c)).
- Lowered the default cut-off from 90% to **70%** destructive ([`d19d4de9`](https://github.com/AgentiLoop/Agent/commit/d19d4de9)).

### ⚙️ LLM Common Settings
- Tinted the **Consult Jev before tools** toggle and the threshold slider blue ([`ba0d0542`](https://github.com/AgentiLoop/Agent/commit/ba0d0542)).

### 🧪 What to test
- Move the **Reject at** slider, quit, and relaunch; confirm the setting persists.
- With no key or the advisory toggle off, confirm the slider is disabled and shell execution does not wait on Jev.
- Set the threshold low and confirm borderline commands are refused; set it to 100% and confirm only certainties are refused.
- On a profile that never set the threshold, confirm the effective default is 70% and not 0%.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version
- Version/build updated to **1.1.46 (build 246)**.

**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.45.245...v1.1.46.246
