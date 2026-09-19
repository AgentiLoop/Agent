## ⚠️ Pre-release — 1.1.48 (build 248)

<!-- Add your screenshot here. -->

This is a **pre-release** from `main`, tagged `v1.1.48.248`. It includes the changes since `v1.1.47.247`: a fix for **tab task log routing**, so activity-log lines produced by a tab task land on that tab instead of the main log or whichever tab happens to be selected. Jev supplements your selected LLM provider rather than replacing it. The Release workflow builds, notarizes, and staples the `.zip` / `.dmg` attachments; downloads will appear after that workflow succeeds. Please report regressions against the v1.1.33.233 stable release.

### 🗂️ Tab task log routing
- Added a `TabLogRouter` task-local in `Logging.swift` that carries the owning `ScriptTab` across shared code; `AgentViewModel.appendLog` and `appendRawOutput` now forward to that tab (and flush) when it is set, instead of writing to the main log ([`c6a867c0`](https://github.com/AgentiLoop/Agent/commit/c6a867c0)).
- `handleTabToolCallBody` binds the owning tab for the duration of each tab tool call, so native tool handlers, completion gates, and the critic gate log to the tab that ran the tool ([`c6a867c0`](https://github.com/AgentiLoop/Agent/commit/c6a867c0)).
- `JevConfiguration.report` now routes directly to the in-flight tab when one is bound, and only broadcasts `.jevActivity` for main-task lines; the view model's `.jevActivity` observer no longer redirects to the selected tab ([`06de2c19`](https://github.com/AgentiLoop/Agent/commit/06de2c19)).
- `startTabTask` binds the tab for the **entire** task (LLM service setup, guards, triage, tool handlers, gates), not just individual tool calls ([`40b1fee4`](https://github.com/AgentiLoop/Agent/commit/40b1fee4)).

### 🧪 What to test
- Run a task in a secondary tab, switch to a different tab while it runs, and confirm every log line (tool output, gates, Jev advisor lines) appears on the tab that started the task — nothing on the main log or the currently selected tab.
- Run a task on the main tab with another tab selected and confirm Jev / tool lines still land on the main log.
- Run concurrent tasks on two tabs and confirm their logs do not cross.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version
- Version/build updated to **1.1.48 (build 248)**.

**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.47.247...v1.1.48.248
