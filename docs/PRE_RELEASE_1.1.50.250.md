## ⚠️ Pre-release — 1.1.50 (build 250)

<!-- Add your screenshot here. -->

This is a **pre-release** from `main`, tagged `v1.1.50.250`. It includes the changes since `v1.1.49.249`: a **Clear All (⌘⇧K) fix** so the "🧹 All cleared." confirmation lands in the log you are actually looking at, plus **community standards files** (Code of Conduct, issue templates, PR template). Jev supplements your selected LLM provider rather than replacing it. The Release workflow builds, notarizes, and staples the `.zip` / `.dmg` attachments; downloads will appear after that workflow succeeds. Please report regressions against the v1.1.33.233 stable release.

### 🐛 Fixes
- **Clear All with a script tab selected** wiped the tab's log but wrote the "🧹 All cleared." confirmation to the hidden main log, leaving the tab showing an empty placeholder. `clearAll()` now appends and flushes the confirmation into the selected tab (or the main log when no tab is selected) ([`d578c9bf`](https://github.com/AgentiLoop/Agent/commit/d578c9bf)).

### 🤝 Community
- Added `CODE_OF_CONDUCT.md`, GitHub issue templates (`bug_report.yml`, `feature_request.yml`, `config.yml`), and a pull-request template under `.github/` ([`078f87ce`](https://github.com/AgentiLoop/Agent/commit/078f87ce)).

### 🧪 What to test
- Install the signed `.dmg` / `.zip` from this pre-release and confirm the Launch Agent and Launch Daemon helpers register on first launch.
- With a script tab selected, press ⌘⇧K (or `/clear all`) and confirm the tab shows `🧹 All cleared.` instead of a blank view. Repeat with no tab selected and confirm the main log shows the same line.
- Open a new issue on GitHub and confirm the Bug Report / Feature Request templates appear.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version
- Version/build updated to **1.1.50 (build 250)**.

**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.49.249...v1.1.50.250
