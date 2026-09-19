## ⚠️ Pre-release — 1.1.47 (build 247)

<!-- Add your screenshot here. -->

This is a **pre-release** from `main`, tagged `v1.1.47.247`. It includes the changes since `v1.1.46.246`: a fix for the **HUD options popover** overflowing its bounds, and a new **Jev** section in the README (all five languages) explaining what the shell-command advisor does. Jev supplements your selected LLM provider rather than replacing it. The Release workflow builds, notarizes, and staples the `.zip` / `.dmg` attachments; downloads will appear after that workflow succeeds. Please report regressions against the v1.1.33.233 stable release.

### 🖥️ HUD options popover
- Constrained the segmented **speed** picker to the popover width with `.controlSize(.small)`, hidden labels, and `.frame(maxWidth: .infinity)`, so it no longer overflows the 360 pt popover ([`d65faa6f`](https://github.com/AgentiLoop/Agent/commit/d65faa6f)).
- The popover container is now leading-aligned and `.clipped()`, so nothing spills past its edge ([`d65faa6f`](https://github.com/AgentiLoop/Agent/commit/d65faa6f)).

### 📖 README — Jev documentation
- Added a **🔒 Jev — a second opinion before shell commands** section to `README.md`, `README_de.md`, `README_es.md`, `README_fr.md`, and `README_zh.md`, covering what Jev does, where it applies (in-process shell, `user_shell`, `root_shell`), the tunable cut-off (default **70%**), fail-open behavior, activity-log visibility, and where it is configured ([`b84744ad`](https://github.com/AgentiLoop/Agent/commit/b84744ad)).

### 🧪 What to test
- Open the HUD options popover and confirm the speed picker fits inside the popover with no clipping of the segments or overflow past the right edge.
- Switch between speed segments and confirm the selection still applies.
- Skim the new Jev section in your language's README and report anything inaccurate.
- Report regressions with your macOS version, selected provider/model, and relevant activity-log output. Do not include API keys.

### 🔢 Version
- Version/build updated to **1.1.47 (build 247)**.

**Full Changelog**: https://github.com/AgentiLoop/Agent/compare/v1.1.46.246...v1.1.47.247
