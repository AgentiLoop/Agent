## ⚠️ Pre-release — 1.1.49 (build 249)

<!-- Add your screenshot here. -->

This is a **pre-release** from `main`, tagged `v1.1.49.249`. It includes the changes since `v1.1.48.248`: an **AgentMCP package bump to 1.6.6**, three new README translations (**Russian, Korean, Japanese**), and README guidance making it explicit that every release and pre-release ships a signed, notarized, stapled binary. Jev supplements your selected LLM provider rather than replacing it. The Release workflow builds, notarizes, and staples the `.zip` / `.dmg` attachments; downloads will appear after that workflow succeeds. Please report regressions against the v1.1.33.233 stable release.

### 📦 Dependencies
- Bumped the `AgentMCP` Swift package from 1.6.5 to **1.6.6** (`project.pbxproj` minimum version and `Package.resolved` pin) ([`665b4e82`](https://github.com/AgentiLoop/Agent/commit/665b4e82)).

### 📚 Documentation
- Added Russian (`README_ru.md`), Korean (`README_ko.md`), and Japanese (`README_ja.md`) READMEs and linked them from the translation lists in every existing README ([`fc1f27f1`](https://github.com/AgentiLoop/Agent/commit/fc1f27f1), [`2008d122`](https://github.com/AgentiLoop/Agent/commit/2008d122)).
- README now states up front that you never need to compile from source: every release **and** pre-release ships a CI-built `.dmg` / `.zip` signed, notarized, and stapled with the AgentiLoop Team ID, so the Launch Agent / Launch Daemon helpers always register. Option B (ad-hoc source build) notes and the "helpers never register" troubleshooting entry point to the signed binary ([`aaae84cf`](https://github.com/AgentiLoop/Agent/commit/aaae84cf)).

### 🧪 What to test
- Install the signed `.dmg` / `.zip` from this pre-release and confirm the Launch Agent and Launch Daemon helpers register on first launch (no "lost helper" state).
- Confirm MCP servers still connect and their tools appear in `list_tools` after the AgentMCP 1.6.6 bump.
- Skim the new `README_ru.md`, `README_ko.md`, `README_ja.md` and confirm the translation links resolve from each README.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version
- Version/build updated to **1.1.49 (build 249)**.

**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.48.248...v1.1.49.249
