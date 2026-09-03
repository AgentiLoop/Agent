# 🦾 AgentiLoop Agent!

### **Agentic AI for your Mac Desktop**

[![Latest Release](https://img.shields.io/github/v/release/AgentiLoop/Agent?label=Download&color=blue&style=for-the-badge)](https://github.com/AgentiLoop/Agent/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Stars&color=gold)](https://github.com/AgentiLoop/Agent/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/AgentiLoop/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donation-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Tip Jar" /></a>

## README Translations

- [English](README.md)
- [Español](README_es.md)
- [Français](README_fr.md)
- [Deutsch](README_de.md)
- [中文 (简体)](README_zh.md)

## Chess within Agent
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## What is Agent!?

**One app. Any AI. Total command over your Mac.**

Agent! is a 100% native Swift 6.2 / SwiftUI app that wires **18 LLM providers** — Claude, GPT, Gemini, Grok, Mistral, DeepSeek, Qwen, Z.ai, BigModel, Hugging Face, OpenRouter, Ollama (cloud and local), vLLM, LM Studio, Codestral, Mistral Vibe, and on-device **Apple Intelligence** — into an autonomous task loop that actually *does things*: reads your codebase, fixes the bug, builds the Xcode project, commits the diff, drives any Mac app through the Accessibility API, runs shell commands as you or as root, texts you results over iMessage, and answers to a spoken *"Agent!"*.

No NPM, no Electron, no subscription, no telemetry. Bring your own API key, run fully local, or run free on Apple Intelligence. Every Swift package it depends on was written by the same author. See [Backstory](#backstory) below.

## What's New 🚀

**v1.1.x — The Hardened Harness Release** · [Releases →](https://github.com/AgentiLoop/Agent/releases/latest)

- **Context compaction, rebuilt.** Threshold = model window − reserved output − buffer, driven by real `input_tokens`. Provider-side 9-section LLM summary replaces on-device 4K summaries; open goal, plan checklist and edited files are re-attached after every compaction. Oversized tool results are spilled to disk at emission and recoverable via `restore_tool_result`. 413 overflow routes through forced compaction with a shorter retry; `max_tokens` overruns recover by escalating, then continuing.
- **Read-before-edit gate.** `edit_file` / `apply_diff` / `diff_apply` refuse to touch a file the LLM hasn't read this task, or that changed on disk since the last read (SHA-256). The refusal auto-reads the file so the next call is the edit. External file changes are surfaced each turn as diff snippets.
- **Real context windows for local models.** LM Studio, Ollama and vLLM report their actual per-model context length — no more hardcoded 32K assumption.
- **Faster turns.** Read-only tools start while the Claude response is still streaming; input-aware shell concurrency; jittered exponential retry with `Retry-After` on 429/529; mid-stream SSE errors surfaced on every provider.
- **Defense-in-depth.** `ShellSafetyService` is now enforced daemon-side (AgentHelper + AgentUser) as well as client-side; release builds reject un-teamed XPC clients; both XPC listeners require same-team code signing derived from the app's own signature.
- **Activity log.** No more 50K truncation or 500K relaunch trim — large logs render off-main with a "Processing tab data…" overlay; optional "Activity Log Below HUD" layout.
- **App menu:** Check for Updates… (GitHub releases), Website, GitHub. CI Build & Test workflow on every PR; **273 passing tests**.
- Plus: `goal_state` with evidence-verified criteria, opt-in critic diff review before completion, task-scoped `rewind_task`, extended thinking for Claude, `reasoning_effort` pass-through, sub-agents with per-agent model override (3 concurrent, 6 read-only), typed tool errors with recovery hints, event hooks.

## Quick Start (Download)

1. **Download** [Agent!](https://github.com/AgentiLoop/Agent/releases/latest) and drag to Applications
2. **Open Agent!** — it sets up everything automatically
3. **Pick your AI** — Settings → choose a provider → enter API key

## Quick Start (Build from Source)

```bash
git clone https://github.com/AgentiLoop/agent.git
cd Agent
```

**Option A — Xcode (Apple Developer account):** open `Agent.xcodeproj`, set your Development Team, Build & Run the `Agent` target, approve the helper when prompted.

**Option B — no developer account (Xcode Command Line Tools only):**
```bash
./build.sh              # Debug
./build.sh Release      # Release
open "build/DerivedData/Build/Products/Debug/Agent!.app"
```

> ⚠️ Option B builds are ad-hoc signed. The Launch Agent/Daemon helpers won't register (SMAppService needs a Team ID), but the LLM loop, all tools, Accessibility, AppleScript, shell, and MCP still work.

> 💡 **Cheap setup:** **GLM-5.1** via **Z.ai** (fastest signup, default model) costs pennies per million tokens. Running locally? Only **GLM-4.7-Turbo** (32B) fits consumer hardware (64–128GB Apple Silicon via Ollama).

### Troubleshooting (Build from Source)

- **`xcode-select` points at Command Line Tools** → `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- **Odd `BUILD FAILED` after pulling** → stale DerivedData: `./build.sh clean && ./build.sh`
- **Helpers never register** → expected on Option B; use Option A for the helpers
- **Deployment target / SDK errors** → Agent! targets macOS 26; update macOS and Xcode
- **Config argument is case-sensitive** → `./build.sh` (Debug) or `./build.sh Release`

## What Can It Do?

> *"Build the Xcode project and fix any errors"* · *"Play my Workout playlist in Music"* · *"Take a photo with Photo Booth"* · *"Send an iMessage to Mom saying I'll be home at 6"* · *"Open Safari and search for flights to Tokyo"* · *"Refactor this class into smaller files"* · *"What calendar events do I have today?"*

Just type what you want. Agent! figures out how and makes it happen.

---

## Key Features

- **🧠 Self-verifying task loop** — reasons, executes, observes results, self-corrects. A task can't declare itself done until `goal_state` criteria are marked with evidence; an opt-in critic reviews the diff first.
- **🛠 Agentic coding** — reads codebases, edits with string-replace diffs, builds Xcode projects natively (clickable errors), manages git, indexes repos into a portable JSONL repo-map. Every edit is snapshotted — one-click rollback or whole-task `rewind_task`.
- **🖥 Desktop automation** — drives any Mac app through the Accessibility API ([AXorcist](https://github.com/steipete/AXorcist)), element-based with fuzzy auto-retry. Plus NSAppleScript, JXA and 51 ScriptingBridge app bridges, all in-process with TCC.
- **📜 AgentScript** — Swift dylibs compiled at runtime and `dlopen`'d in-process with full TCC. Deleted scripts go to `.Trash` and are restorable.
- **🛡 Privileged execution** — shell as you via a Launch Agent, or as root via a Launch Daemon you approve exactly once (SMAppService + XPC). See [docs/SECURITY.md](docs/SECURITY.md) for why SMAppService already enforces signing identity.
- **🎙 Voice** — say **"Agent!"** followed by your task; on-device `SFSpeechRecognizer`, auto-runs after ~2.5s of silence, loops.
- **📱 iMessage remote control** — text `Agent! next song` from your iPhone; approved senders only. Needs Full Disk Access for `chat.db`.
- **🌐 Web** — built-in Safari automation (JavaScript + AppleScript); optional Selenium and [Playwright MCP](https://github.com/microsoft/playwright-mcp) for cross-browser.
- **🤝 Sub-agents** — up to 3 concurrent (6 read-only) isolated agents with mailbox messaging and per-agent model override.
- **🧩 MCP** — add any MCP server in Settings → MCP Servers; tools appear as `mcp_<server>_<tool>`. Xcode MCP: `{"mcpServers":{"xcode":{"command":"xcrun","args":["mcpbridge"],"transport":"stdio"}}}`.
- **🗂 Tabs, history, memory, plans, skills** — each tab has its own project folder and log; persistent user memory; multi-plan checklists surfaced in every prompt.
- **🔄 Fallback chain** — auto-switch to the next configured provider on 429/timeout/network failure.

## 🤖 18 AI Providers

| Provider | Cost | Best for |
|---|---|---|
| **Claude** | Paid | Long autonomous tasks, extended thinking, prompt caching |
| **OpenAI** | Paid | General purpose, tool calling, vision, `reasoning_effort` |
| **Google Gemini** | Paid (free tier) | Long context, vision |
| **Grok** (xAI) | Paid | Real-time info |
| **Mistral** / **Codestral** / **Mistral Vibe** | Paid | Open-weight cloud, code, agent product |
| **DeepSeek** | Cheap | Budget coding, cache-hit reporting |
| **Hugging Face** | Varies | Open models, serverless or dedicated endpoints |
| **OpenRouter** | Paid | 200+ models, one key; Claude routed via Anthropic protocol |
| **Z.ai** / **BigModel** | Cheap | GLM-5.1 — recommended starting point |
| **Qwen** (Alibaba) | Cheap | Qwen 2.5 / 3 via Dashscope |
| **Ollama** (cloud) | Free tier | Hosted open models |
| **Local Ollama** / **vLLM** / **LM Studio** | Free + hardware | Fully offline; real per-model context window detected |
| **Apple Intelligence** | Free, on-device | Triage, summaries, token compression (brain icon, not the provider picker) |

> 💡 Self-hosted providers are free only in the API-fee sense — a usable 30B+ model needs an M2/M3/M4 Ultra Mac Studio (64–128GB). Without that hardware, the cheap cloud paths above are dramatically cheaper.

## Tools

Canonical names come from `AgentTools.Name.*` (source of truth: the [AgentTools](https://github.com/AgentiLoop/AgentTools) package). Per-provider toggles can hide individual tools.

| Group | Tools |
|---|---|
| **Core** | `done` · `list_tools` · `search` · `web_search` · `fetch` · `chat` · `memory` · `plan` · `goal_state` · `restore_tool_result` · `directory` · `skill` · `ask_user` · `index` |
| **Code / build** | `file` (read/write/edit/diff_apply/undo/list/search/mkdir/…) · `git` · `xcode` (build/run/analyze/snippet/code_review/add_file/bump_version/…) · `agent_script` |
| **Shell** | `user_shell` (Launch Agent) · `root_shell` (Launch Daemon) · `shell` (in-process fallback) · `batch` · `multi` |
| **macOS automation** | `accessibility` (25 element-based actions) · `applescript` (with `lookup_sdef`) · `javascript` (JXA) |
| **Web** | `safari` · `selenium` · `mcp_playwright_browser_*` (optional) |
| **Sub-agents** | `spawn_agent` · `tell_agent` |

Full per-action reference: [docs/TECHNICAL.md](docs/TECHNICAL.md).

## Privacy & Safety

Your files, screen contents and personal data never leave your Mac — cloud providers only see prompt text; local providers keep everything offline. Every action is logged.

| Layer | What it does |
|---|---|
| **Shell Safety Service** | Hard-blocks `rm -rf /`, `rm -rf ~`, bare-glob `rm -rf`, `--no-preserve-root` — enforced client-side **and** daemon-side. Cannot be bypassed by the LLM. |
| **XPC client trust** | Both listeners require same-team code signing derived from the app's own signature; release builds reject un-teamed clients. |
| **Read-before-edit gate** | Edits to unread or externally-modified files are refused (SHA-256), with auto-read on refusal. |
| **File backups + rewind** | Every edit snapshotted (1-week TTL); Rollback UI, `file(action:"undo")`, or task-scoped `rewind_task`. |
| **TCC in-process routing** | AppleScript/JXA/screencapture/accessibility commands run in-process where Agent! holds TCC grants, never through the daemons. |
| **Tool execution gating** | The LLM cannot fabricate results — every call flows through `dispatchTool()` and returns real output. Tool-less "I clicked/searched…" claims get a correction injected. |
| **Typed errors + guards** | Every failing tool result carries a recovery hint; broken-record and stuck guards nudge, then stop; completion gates cap refusals at 3 per task. |
| **Console audit trail** | Every tool call and every helper command is logged. |

## Keyboard Shortcuts & Slash Commands

| Shortcut | Action |
|---|---|
| `Return` | Run task · `⌘ .` / `Esc` cancel |
| `⌘ T` / `⌘ W` / `⌘ 1–9` / `⌘ ⇧ ←→` | New / close / switch / prev-next tab |
| `⌘ B` / `⌘ D` | Toggle LLM Output overlay / chevrons |
| `⌘ F` / `⌘ L` / `⌘ V` | Search log / clear log / paste image |
| `↑` / `↓` | Prompt history |
| `⌘ ⇧ M` / `⌘ ⇧ P` | Messages Monitor / Settings |
| `⌘ ⇧ K` `L` `H` `J` `U` | Clear all / LLM panel / prompt history / task history / token counters |

Slash commands run locally: `/clear [log|all|llm|history|tasks|tokens]`, `/memory [show|clear|edit|<text>]`.

## FAQ

**Do I need to know how to code?** No — plain English (or your native language).
**How much does it cost?** The app is free (MIT). You pay your provider; GLM-5.1 via Z.ai/BigModel or DeepSeek are the cheapest for serious work. Local models are free if you own the hardware.
**What Mac do I need?** Apple Silicon, macOS 26.4.1+. Any modern Mac for cloud providers; 64GB+ for 30B local models.
**How is this different from Siri?** Siri answers. Agent! *acts* — apps, files, code, system.

More: [docs/FAQ.md](docs/FAQ.md) · [Technical Architecture](docs/TECHNICAL.md) · [Comparisons](docs/COMPARISON.md) (vs Claude Code, Cursor, Cline, OpenClaw) · [Security Model](docs/SECURITY.md)

## Backstory

Agent! is the result of three years of building agentic AI apps — ANIE, Game Changer, BattleScript, XCF MCP Server and Client, D1F, and about eight original Swift packages. The missing piece was an intelligent autonomous loop; once achieved, the best of those projects came together into Agent!. It has written video games ([Boss-Man](https://github.com/AgentiLoop/bossman)), created apps, written poetry into Pages via AppleScript, generated disk images and attached them to GitHub releases. Where Claude Code relies on ~65 third-party NPM packages, Agent! is 100% native, uses very little RAM, and ships Xcode automation, Swift Syntax 6.2 analysis, Accessibility, AppleScript, AgentScript/ScriptingBridge, Safari automation and MCP support out of the box.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) — build from source in ~5 minutes with `./build.sh`, no developer account needed. Pull requests run the CI Build & Test workflow. Check the [good first issues](https://github.com/AgentiLoop/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22).

## License

MIT — free and open source.

---

> ⚠️ **Legal Notice & Attribution**
>
> ### Trademark Notice
>
> "🦾 Agent! for macOS26" is an independent software project and is **not** affiliated with, endorsed by, sponsored by, or otherwise associated with Apple Inc. "Apple," "Mac," "Mac mini," "MacBook," "macOS," and related marks are trademarks of Apple Inc., registered in the U.S. and other countries. All other trademarks, service marks, and trade names referenced herein are the property of their respective owners and are used for identification purposes only.
>
> "🦾 Agent!" and the 🦾 Agent! logo are trademarks of AgentiLoop Agent. Use of these marks requires prior written permission. The MIT license below grants rights to the source code only — it does **not** grant any trademark rights.
>
> ### Source Code License (MIT)
>
> The source code of "🦾 Agent! for macOS26" is open source and licensed under the **MIT License**. You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the source code, subject to the conditions in the [LICENSE](./LICENSE) file (retain copyright notice and the MIT permission notice in all copies or substantial portions of the software).
>
> ### Compiled Binaries & Releases
>
> Compiled binaries, installers, code-signed builds, and release artifacts distributed through this project's GitHub Releases, [AgentiLoop.ai](https://AgentiLoop.ai), or any other official channel are the copyrighted work of AgentiLoop Agent and are **not** covered by the MIT license that governs the source code. All rights to the official binaries — including the "🦾 Agent!" name, logo, code-signing identity, and Developer ID — are reserved.
>
> Copyright © 2000, 2023–2026 AgentiLoop Agent, All Rights Reserved.
>
> You are welcome to build your own binaries from source under the MIT license, provided you do not use the "🦾 Agent!" name, logo, or branding to identify your product.
>
> ### Warranty Disclaimer
>
> This software is provided **"AS IS,"** without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement. In no event shall the author or copyright holder be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.
>
> ---
>
> Thank you for your interest in 🦾 Agent! — an application crafted for Mac mini, MacBook, and Mac studio computers running macOS 26.4 or later on genuine Mac hardware and software.
>
> - Website: https://AgentiLoop.ai
> - Github : https://github.com/AgentiLoop/agent
