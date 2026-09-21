## ⚠️ Pre-release — 1.1.51 (build 251)

<!-- Add your screenshot here. -->

This is a **pre-release** from `main`, tagged `v1.1.51.251`. It includes the changes since `v1.1.50.250`: a **shell PATH fix** so tools installed under `~/.local/bin` (for example the `claude` CLI) resolve from the in-app shells, a new **Sponsors menu** in the Help menu, a **Contributor License Agreement** with an automated CLA-Assistant check, and the **Sponsorship / LLM Provider Partner program** docs. Jev supplements your selected LLM provider rather than replacing it. The Release workflow builds, notarizes, and staples the `.zip` / `.dmg` attachments; downloads will appear after that workflow succeeds. Please report regressions against the v1.1.33.233 stable release.

### 🐛 Fixes
- **`~/.local/bin` missing from the shell PATH** — commands installed there (e.g. `claude`) failed with `command not found` when run through the user shell / fallback shell. Both shell runners now prepend `$HOME/.local/bin` ahead of `/opt/homebrew/bin` and the system paths ([`7c09f111`](https://github.com/AgentiLoop/Agent/commit/7c09f111)).

### ✨ New
- **Sponsors menu** — a "Sponsors" submenu (with a "Become a Sponsor…" link) now appears in the Help menu after the GitHub item. Sponsor entries live in `SponsorDirectory.swift`; the list is empty until the first sponsor signs ([`38cbd984`](https://github.com/AgentiLoop/Agent/commit/38cbd984)).

### 🤝 Community
- Added `CLA.md` (governing law/venue: North Carolina) and a CLA Assistant workflow (`.github/workflows/cla.yml`); signatures are recorded on `main` under `signatures/version1/cla.json` ([`9c42e19c`](https://github.com/AgentiLoop/Agent/commit/9c42e19c), [`47accc12`](https://github.com/AgentiLoop/Agent/commit/47accc12)).
- Added `docs/SPONSORSHIP.md` and `docs/PROVIDER_PROGRAM.md` — Silver / Gold / Platinum tiers via GitHub Sponsors only, with badge / logo placement on the READMEs and website ([`b10a9942`](https://github.com/AgentiLoop/Agent/commit/b10a9942)).
- README: updated tool-usage section; the "Full disclosure" banner is now translated in the de/es/fr/ja/ko/ru/zh READMEs; trademark owner and `.mailmap` author mapping rebranded to AgentiLoop.ai ([`9012c79e`](https://github.com/AgentiLoop/Agent/commit/9012c79e), [`ca7942ca`](https://github.com/AgentiLoop/Agent/commit/ca7942ca), [`a18ae1fc`](https://github.com/AgentiLoop/Agent/commit/a18ae1fc)).

### 📦 Dependencies
- Swift package versions refreshed in `Package.resolved` ([`293abaec`](https://github.com/AgentiLoop/Agent/commit/293abaec)).

### 🧪 What to test
- Install the signed `.dmg` / `.zip` from this pre-release and confirm the Launch Agent and Launch Daemon helpers register on first launch.
- With a tool installed only in `~/.local/bin` (e.g. `claude`), ask Agent! to run it via the user shell and confirm it is found.
- Open **Help ▸ Sponsors** and confirm the placeholder entry and "Become a Sponsor…" link open the sponsorship page.
- Open a pull request and confirm the CLA Assistant status check appears.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version
- Version/build updated to **1.1.51 (build 251)**.

**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.50.250...v1.1.51.251
