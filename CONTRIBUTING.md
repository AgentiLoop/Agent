# Contributing to 🦾 Agent!

Thanks for your interest! Agent! is a 100% Swift, native macOS agentic AI app — and contributions of every size are welcome: bug fixes, tests, docs, new bridges, new tools.

## 5-Minute Setup (no Apple Developer account needed)

```bash
git clone https://github.com/AgentiLoop/Agent.git
cd Agent
./build.sh              # Debug build (requires only Xcode Command Line Tools)
open "build/DerivedData/Build/Products/Debug/Agent!.app"
```

> ⚠️ Ad-hoc signed builds can't register the Launch Agent/Daemon helpers (SMAppService needs a Team ID), but everything else works: the LLM loop, all tools, accessibility, AppleScript, shell, and MCP.

### With Xcode (full experience)

1. Open `Agent.xcodeproj`
2. Select the **Agent** scheme, set your own Development Team
3. Build & Run — approve the helper daemon when prompted

**Requirements:** macOS 26.0+, Xcode with Swift 6.2.

## Project Layout

| Path | What it is |
|---|---|
| `Agent/` | Main SwiftUI app — Views, Services, Models, MCP |
| `Agent/Services/` | Tool implementations, LLM providers, XPC clients |
| `AgentHelper/` | Privileged root daemon (NSXPCListener) |
| `AgentUser/` | User-level Launch Agent |
| `Shared/` | Code shared between app and daemons |
| `AgentTests/` | Unit tests — great examples to copy when adding your own |
| `docs/` | Technical docs, FAQ, security notes |

## Making a Change

1. **Fork** and create a branch: `git checkout -b fix/my-thing`
2. **Small, focused changes** — one concern per PR
3. **Build** (`./build.sh` or Xcode) and run the tests (`AgentTests` target)
4. **Match existing style** — the codebase uses Swift 6.2, `@Observable` view models, and async/await
5. Open a PR with a clear description of what and why

PRs are reviewed quickly — usually within a day or two.

## Good First Issues

Look for the [`good first issue`](https://github.com/AgentiLoop/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) label — these are scoped, recipe-style tasks with pointers to the exact files to touch. If you have a fork sitting around, that's the fastest way to turn it into a merged PR.

## Ideas That Are Always Welcome

- **Tests** — pick a service in `Agent/Services/` without coverage and add a test file to `AgentTests/` (copy the style of an existing one)
- **Docs** — clarify README sections, expand `docs/FAQ.md`, fix typos
- **New app bridges / SDEFs** — add scripting support for another Mac app
- **UI polish** — small SwiftUI improvements to views in `Agent/Views/`
- **Bug reports** — even without a fix, a clear reproduction is valuable

## Questions?

Open a [GitHub issue](https://github.com/AgentiLoop/Agent/issues) or a [discussion](https://github.com/AgentiLoop/Agent/discussions). No question is too small.

## License

By contributing, you agree your contributions are licensed under the [MIT License](./LICENSE). Note: the "🦾 Agent!" name and logo are trademarks of Heisenburg and not covered by the MIT license (see README Legal Notice).
