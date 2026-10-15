# Growth Playbook — getting Agent! in front of more Mac users

This is the maintainer's checklist for growing the project *legitimately*: better
discoverability, honest launch posts, and curated-list submissions. Nothing here
involves bought stars, bot accounts or mass outreach — GitHub removes stars and
suspends accounts for that, and it would hurt the project more than help it.

Everything below is a **draft for a human to review and post**. Nothing is posted
automatically.

## 1. Where we stand (snapshot 2026-10-15, via `gh`)

| Metric | Value |
|---|---|
| Stars / forks | 646 / 69 |
| Repo created | 2026-03-11 |
| Latest release | v1.1.87.287 (2026-10-01); 4 pre-releases since (v1.1.88–v1.1.93) |
| Community profile | 100% (README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, PR template) |
| Discussions | enabled |
| Topics | 20 / 20 used |
| Custom social-preview image | **not set** (`usesCustomOpenGraphImage: false`) |
| GitHub license detection | **"Other"** (PolyForm Noncommercial 1.0.0 is not auto-detected) |
| Views, last 14 days | 797 (365 unique) |
| Clones, last 14 days | 999 (275 unique) |
| Top referrers (unique) | Google 124 · github.com 72 · reddit.com 29 · search.brave.com 8 · agentiloop.ai 7 · news.ycombinator.com 4 · formulae.brew.sh 3 |
| Top paths (unique) | repo root 292 · release v1.1.87.287 27 · releases 11 · issues 9 · docs/TECHNICAL.md 7 |

Read: almost all traffic lands on the README root, mostly from Google. Reddit is
the only social channel that currently sends measurable traffic; HN sends almost
none. The README is the conversion page.

## 2. In-repo fixes (highest impact first)

Comparison set (same space, 55k–118k stars): `openinterpreter/open-interpreter`,
`browser-use/browser-use`, `cline/cline`, `aaif-goose/goose`. All four open their
README with the **project name + a one-sentence pitch** in the first 3 lines; none
opens with a sponsor banner.

- [ ] **Lead with the pitch.** README currently opens with the Sidrune sponsor SVG
      (line 1) and a 1628×1152 screenshot (line 4) before the `# AgentiLoop Agent!`
      heading. Move the heading + the one-liner *"One app. Any AI. Total command over
      your Mac."* to line 1; keep the sponsor banner, but below the badges.
- [ ] **Turn the demo GIF back on.** `docs/table-video.gif` (4.7 MB, 900×628, 12 fps,
      20.7 s) exists but the `<img>` is commented out at README line 3 — deliberately,
      in commit 1d84d448 (2026-10-01), which swapped it for the current UI screenshot;
      the 7 translated READMEs still show the GIF. A moving demo in the first screen is
      the single most common feature of the comparison READMEs. Options: re-record a GIF
      of the current UI, or re-encode this one to ≤2 MB
      (`ffmpeg -i docs/table-video.gif -vf "fps=10,scale=800:-1" …`) and un-comment it.
- [ ] **Set the social-preview image** (Settings → General → Social preview, 1280×640).
      Every link shared on X, Reddit, Slack, Discord and HN uses it; today they show
      GitHub's default auto-generated card. **Ready to upload:** `docs/social-preview.png`
      (1280×640, 835 KB — under GitHub's 1 MB limit): app icon, "Agent! — The native AI
      agent for Mac", one-line pitch, repo URL and the README screenshot as a window card.
      Regenerate with the `MakeSocialPreview` agent script (reads the installed app's
      `AppIcon.icns` and `/tmp/agent-shot.png`).
- [ ] **Star-history chart** near the bottom of README
      (`https://api.star-history.com/svg?repos=AgentiLoop/Agent&type=Date`) — social
      proof that compounds.
- [ ] **Non-pre-release cadence.** 4 of the last 5 releases are pre-releases;
      `releases/latest` (the badge target) still points at v1.1.87 from 2026-10-01.
      Promote a stable release every 1–2 weeks so "Download" is never stale, and use
      the release-notes template in §4.7 so each release links back and asks for a star.
- [ ] **Homebrew discoverability.** `formulae.brew.sh` already sends traffic; make sure
      the cask description matches the GitHub description.
- [ ] **Google is the #1 referrer.** The repo description and the first paragraph of
      README should contain the phrases people search: *"AI agent for Mac"*, *"macOS
      AI agent open source"*, *"MCP client macOS"*, *"Ollama Mac app"*. The current
      description has most of these; add "open source".
- [ ] **Cross-link from the sibling repos** (`AgentiLoopCLI`, `AgentiLoopGo`) and
      from agentiloop.ai with a visible "Star on GitHub" button — agentiloop.ai sent
      52 views but only 7 uniques, i.e. the site's own visitors are not being pointed
      at the repo.

## 3. Curated lists — ready-to-paste entries

Researched 2026-10-15 against each list's live README/CONTRIBUTING. `AgentiLoop`
already appears only in **jaywcjlove/awesome-swift-macos-apps**. The license
(PolyForm Noncommercial 1.0.0, source-available, not OSI) decides eligibility —
lists that require OSI licences are marked and must be skipped. Submit **one PR
per list**, state the licence plainly, link the existing awesome-swift-macos-apps
listing, and never open duplicate PRs.

### 1. jaywcjlove/awesome-mac (116,206★; last commit 2026-10-15)
1. **Repo:** https://github.com/jaywcjlove/awesome-mac (default branch `master`)
2. **Fit:** strong. The section is `## AI Tools` (README.md line 828). Similar apps are already there: Fazm ("voice-controlled AI agent"), LingShu ("model-agnostic macOS agent… computer actions"), Cursor Voice, Witsy (MCP client), and BoltAI, a non-OSS entry.
3. **Rules** (docs/CONTRIBUTING.md):
   - One PR or issue per suggestion.
   - Title-casing in `[List Name](link)` format.
   - Alphabetical order within the category.
   - Update Contents if needed.
   - Useful PR and commit titles; no trailing whitespace.
   - Its `.codex/skills/awesome-mac-maintainer/SKILL.md` asks for one-sentence descriptions, the same entry in README.md, README-zh.md, README-ja.md and README-ko.md, and less marketing language.
   - You can also suggest an addition through the issue form `.github/ISSUE_TEMPLATE/NEW_ADDITION_TO_LIST.yml`.
   - Legend (lines 101–104): OSS icon means **open source**; Freeware icon means free, or a free personal license; Native icon means native app.
   - No minimum stars, age or license requirement is stated.
   - Large PR backlog: the search API returned 1,190 open PRs.
4. **AgentiLoop present:** No.
5. **Entry** (goes between `Agent Teams AI` and `Agenttrace`):
```
* [AgentiLoop Agent!](https://agentiloop.ai) - Autonomous AI agent that drives Mac apps via Accessibility and AppleScript, builds Xcode projects, and runs shell tasks with 23 LLM providers or on-device Apple Intelligence. ![Native App][Native Icon]
```
Leave out the OSS icon, because the legend means "open source" and PolyForm NC isn't. If you want to show the code, you could add `[source](https://github.com/AgentiLoop/Agent)`, but that's a non-standard pattern you'd need to check first. Add `![Freeware][Freeware Icon]` too — the app is free to use (README: no subscription; LICENSE: personal and noncommercial use permitted).

### 2. jaywcjlove/awesome-swift-macos-apps (1,748★; last commit 2026-10-15)
- **Already listed** under `## AI` at README.md line 325: `- [Agent!](https://github.com/AgentiLoop/Agent) … - Native autonomous agent that codes, builds Xcode projects, drives Mac apps via Accessibility, and runs shell tasks with 23 LLM providers or on-device Apple Intelligence.`
- No action needed. You could cite this listing as evidence in other PRs.

### 3. punkpeye/awesome-mcp-clients (6,612★; last commit 2026-06-07)
1. **Repo:** https://github.com/punkpeye/awesome-mcp-clients (`main`)
2. **Fit:** strong, since it's an MCP client. Licenses are mixed and allowed: the License fields count 28 MIT, **20 "Proprietary"**, 19 Apache 2.0, and one "Modified Apache 2.0 (non-commercial)". There's no OSI requirement, so PolyForm NC is acceptable.
3. **Rules** (CONTRIBUTING.md):
   - Fork, branch, then edit README.md.
   - Each entry needs a linked name and a short description, following the existing format.
   - Keep alphabetical order within the category, one client per line, and accurate, concise information.
   - Each entry has two parts: a line in the TOC under `## Clients`, and a `### Name` block with an HTML table (GitHub, Website, License, Type, Platforms, Pricing, Programming Languages), a paragraph, **Key Features**, and optional screenshots in `./screenshots/<name>/`.
   - The search API showed 126 open PRs; the last merge was 2026-06-07.
4. **AgentiLoop present:** No.
5. **Entry.** In the TOC, add `    - [AgentiLoop Agent!](#agentiloop-agent)` after `Agent Bridge`, and put the block between `### Agent Bridge` and `### AgentOne`:
```
### AgentiLoop Agent!

<table>
<tr><th align="left">GitHub</th><td>https://github.com/AgentiLoop/Agent</td></tr>
<tr><th align="left">Website</th><td>https://agentiloop.ai</td></tr>
<tr><th align="left">License</th><td>PolyForm Noncommercial 1.0.0</td></tr>
<tr><th align="left">Type</th><td>Desktop app</td></tr>
<tr><th align="left">Platforms</th><td>macOS 14.6+</td></tr>
<tr><th align="left">Pricing</th><td>Free (noncommercial use)</td></tr>
<tr><th align="left">Programming Languages</th><td>Swift</td></tr>
</table>

Native macOS autonomous AI agent with MCP client support that drives any Mac app through the Accessibility API and AppleScript/JXA.

**Key Features:**
- **MCP Client**: Connect external MCP servers as agent tools
- **23 LLM Providers**: Claude, OpenAI, Gemini, Ollama, LM Studio, on-device Apple Intelligence
- **Mac Automation**: Accessibility API, AppleScript/JXA, Xcode build integration
- **Shell**: User or root execution via SMAppService
- **Remote & Voice**: Voice activation and iMessage remote control
- **Sub-agents**: Parallel sub-agent tasks
```
The anchor `#agentiloop-agent` is how GitHub slugifies the heading; check it in the PR preview.

### 4. e2b-dev/awesome-ai-agents (30,450★; last commit 2026-08-21)
1. **Repo:** https://github.com/e2b-dev/awesome-ai-agents (`main`)
2. **Fit:** good as a general-purpose agent. The README has two parts: `# Open-source projects` (line 71) and `# Closed-source projects and companies` (line 2964). Which part a source-available app belongs in is ambiguous. Ask in the PR, or use the closed-source part to be safe.
3. **Rules** (README "Have anything to add?"):
   - Open a PR or fill in the form at https://forms.gle/UXQFCogLYrPFvfoUA.
   - Keep alphabetical order and the correct category.
   - SDKs and frameworks go to awesome-sdks-for-ai-agents instead.
   - No CONTRIBUTING file exists.
   - Big backlog: the search API showed 979 open PRs, and recent commits are all maintainer docs/UTM edits.
4. **AgentiLoop present:** No.
5. **Entry.** If you use the open-source part, it goes alphabetically between `AgentGPT` and `AgentPilot`; the block follows the AgentPilot format:
```
## [AgentiLoop Agent!](https://github.com/AgentiLoop/Agent)
Autonomous AI agent for macOS that drives any Mac app, codes, and builds Xcode projects

<details>

### Category
General purpose, Coding

### Description
- Native Swift/SwiftUI app (macOS 14.6+), source-available under PolyForm Noncommercial 1.0.0
- 23 LLM providers incl. Ollama, LM Studio and on-device Apple Intelligence; MCP client
- Drives apps via Accessibility API and AppleScript/JXA; shell as user or root
- Voice activation, iMessage remote control, sub-agents

### Links
- [GitHub](https://github.com/AgentiLoop/Agent)
- [Website](https://agentiloop.ai)

</details>
```

### 5. serhii-londar/open-source-mac-os-apps (50,801★; last commit 2026-09-09)
1. **Repo:** https://github.com/serhii-londar/open-source-mac-os-apps (`master`)
2. **Fit:** weak because of the license. The list is "A curated list of open source applications for macOS". Contributing says projects get deleted if they "Lack license", but doesn't name OSI. Fazm, a similar agent, is listed under `productivity` and `utilities`. **Merge risk: PolyForm NC probably conflicts with the list's "open source" scope** (UNVERIFIED how the maintainer would rule).
3. **Rules** (CONTRIBUTING.md, PULL_REQUEST_TEMPLATE.md):
   - Edit **applications.json, not README.md** (the README is generated).
   - One project per PR; search for duplicates first.
   - Short descriptions ending with a period.
   - Clear English README, and a commit within the last 2 years.
   - The PR template asks for Project URL, Category, Description and a checklist.
   - The search API showed 459 open PRs.
4. **AgentiLoop present:** No.
5. **Entry:**
```json
        {
            "title": "AgentiLoop Agent!",
            "short_description": "Autonomous AI agent that drives Mac apps via Accessibility and AppleScript, builds Xcode projects, and runs shell tasks with 23 LLM providers.",
            "categories": ["productivity", "utilities"],
            "repo_url": "https://github.com/AgentiLoop/Agent",
            "icon_url": "",
            "screenshots": [],
            "official_site": "https://agentiloop.ai",
            "languages": ["swift"]
        }
```

### 6. kyrolabs/awesome-agents (2,928★; last commit 2026-10-14, very active)
1. **Repo:** https://github.com/kyrolabs/awesome-agents (`main`)
2. **Fit:** topic fits, but the license doesn't. The sections that would suit are `## Automation` (line 212) or `## Conversational / General Agents` (line 167). CONTRIBUTING says "**The contribution needs to be open source**" and that it won't list anything "not open source". PolyForm NC is likely to be rejected.
3. **Rules:**
   - PR only, no issues.
   - Add new items at the **bottom** of the section.
   - It rejects brand-new repos or users without traction, and anything in the wrong place.
   - It says these criteria are "non-negotiable, managed and applied automatically".
4. **AgentiLoop present:** No.
5. **Entry** (only if they accept source-available; ask first):
```
- [AgentiLoop Agent!](https://github.com/AgentiLoop/Agent): Native macOS autonomous agent that drives any Mac app via Accessibility and AppleScript, builds Xcode projects, and runs shell tasks with 23 LLM providers, MCP tools, and on-device Apple Intelligence. ![GitHub Repo stars](https://img.shields.io/github/stars/AgentiLoop/Agent?style=social)
```

### 7. ranpox/awesome-computer-use (586★; last commit 2026-04-15) — found via web search
1. **Repo:** https://github.com/ranpox/awesome-computer-use (`main`)
2. **Fit:** good. It has a `## Projects` section (line 116) that includes desktop agents such as Fazm, "Claude Computer Use Demo for MacOS" and Terminator (accessibility-API automation).
3. **Rules:** UNVERIFIED. There is no CONTRIBUTING or PR template; the README only says "We welcome contributions". The list isn't alphabetical, and new items look appended at the end (the Fazm, Lumen and Computer Agents PRs were merged 2026-04-15). It doesn't state a license requirement.
4. **AgentiLoop present:** No.
5. **Entry** (append at the end of Projects):
```
- [AgentiLoop Agent!](https://github.com/AgentiLoop/Agent) - Native macOS agent that operates any app through the Accessibility API and AppleScript/JXA, with 23 LLM providers including on-device Apple Intelligence
```

### Not eligible or not a fit (verified)
- **iCHAIT/awesome-macOS** (19,334★): contributing.md bans "software whose main purpose is interfacing with generative tools like LLMs… including agents". The PR template also makes you confirm you read that section. **Do not submit.**
- **matteocrippa/awesome-swift** (26,318★): .github/CONTRIBUTING.md requires the license to be Apache 2.0, BSD 3, BSD 2, GPL, LGPL or MIT. It also has a 15★ minimum and edits go in contents.json. **Ineligible under PolyForm NC.**
- **Shubhamsaboo/awesome-llm-apps** (141,851★): the README is a catalogue of the repo's own tutorial and template folders (for example `starter_ai_agents/...`), not third-party products. There's no CONTRIBUTING file or third-party submission path. **Not a fit.**
- **SamurAIGPT/Best-AI-Agents**: GitHub now 301-redirects to `Anil-matcha/awesome-muse-connectors` (1,362★), a Meta Muse connector catalog. **Not a fit.**
- Also checked but too small to be worth it: louis030195/awesome-agent-product (API reported 0–3★) and macnative/awesome-ai-apps (1★). Their rules weren't reviewed.

---

### Ranking (list stars × fit)
Fit is my own score from 0 to 1, combining topic match, license compatibility and how likely a merge looks.

| Rank | List | Stars | Fit | Score | Main blocker |
|---|---|---|---|---|---|
| 1 | jaywcjlove/awesome-mac | 116,206 | 0.9 | 104,585 | Backlog; 4-language sync |
| 2 | e2b-dev/awesome-ai-agents | 30,450 | 0.5 | 15,225 | 979 open PRs; which part to use |
| 3 | serhii-londar/open-source-mac-os-apps | 50,801 | 0.25 | 12,700 | "open source" scope vs PolyForm NC |
| 4 | punkpeye/awesome-mcp-clients | 6,612 | 1.0 | 6,612 | None (proprietary allowed) |
| 5 | kyrolabs/awesome-agents | 2,928 | 0.3 | 878 | Requires open source |
| 6 | ranpox/awesome-computer-use | 586 | 0.8 | 469 | Rules unverified |
| — | jaywcjlove/awesome-swift-macos-apps | 1,748 | done | — | Already listed |
| ✗ | iCHAIT/awesome-macOS, matteocrippa/awesome-swift, awesome-llm-apps, Best-AI-Agents | — | 0 | 0 | Banned, license, or not a fit |

### Submission order
1. **awesome-mac.** Biggest reach and a clear category. Submit one PR that edits all 4 READMEs, with no OSS icon.
2. **awesome-mcp-clients.** Best chance of a merge; the License field can say "PolyForm Noncommercial 1.0.0" honestly. Add a screenshot.
3. **ranpox/awesome-computer-use.** Small, but recent agent PRs were merged quickly.
4. **e2b-dev/awesome-ai-agents.** Submit both the PR and the Google form, and ask which part fits a source-available project.
5. **serhii-londar** and **kyrolabs**: only after asking in an issue whether PolyForm NC qualifies. Don't spend PRs on lists that explicitly require open source.
6. Never submit to iCHAIT/awesome-macOS or matteocrippa/awesome-swift.

Every PR should state the license plainly and mention the existing awesome-swift-macos-apps listing.

## 4. Launch / announcement drafts

Review before posting. Rules of thumb: one platform per day, answer every comment, never ask for upvotes or stars in the post body (HN and Reddit penalise it), disclose that you are the maintainer.

### Community Norms & Platform Rules (Verified via Web Search)

- **Hacker News (`Show HN`)**: Titles must begin with `Show HN:` and stay under the 80-character submission limit. The submission must be something people can directly try out without signup barriers (signed GitHub Release / Homebrew cask / source repo qualifies; landing pages, newsletters, or blog posts alone are off-topic). Include a plain-spoken backstory and technical context in the text/first comment; never ask for upvotes or paste AI-generated replies.
  - Sources: [Official Show HN Guidelines](https://news.ycombinator.com/showhn.html), [HN Moderator Guidance on Show HN](https://news.ycombinator.com/item?id=22336638), [HN Show HN Overview](https://syften.com/blog/hacker-news-marketing)
- **r/macapps**: Self-promotion is limited to once per developer per 30 days (`Limited Self-Promotion` rule). Requires prior subreddit comment karma (~10 karma), must link to official distribution channels (GitHub Releases / publisher site), and requires disclosing developer affiliation. Open-source / source-available posts conventionally use the `[OS]` prefix and lead with the problem solved rather than marketing copy.
  - Sources: [r/macapps Rules](https://www.reddit.com/r/macapps), [r/macapps Rule Updates](https://www.reddit.com/r/macapps/comments/1o01a9f/rmacapps_rule_updates_on_promotion_vibe_coding), [r/macapps Launch Guide](https://www.welaunch.sh/reddit/macapps)
- **r/swift**: Follows Reddit's sitewide 90/10 self-promotion guideline ("be a redditor with a project, not a project with a reddit account"). Posts in `r/swift` must focus on Swift language, frameworks, or architecture (e.g., Swift 6.4, SwiftUI, `SMAppService`, `dlopen` dylibs, `SwiftSyntax`) rather than generic consumer app promotion, with source code available to inspect. [VERIFY: Check `r/swift` sidebar on launch day for any weekly showcase thread preference.]
  - Sources: [Reddit Self-Promotion Guidelines Summary](https://redship.io/blog/reddit-self-promotion-rules), [Developer Self-Promotion on Reddit](https://vadimkravcenko.com/qa/self-promotion-on-reddit-the-right-way)
- **Product Hunt**: Product name must be the exact name only (no emojis or descriptors appended). Tagline max is **60 characters** (plain description of what it does, no buzzwords). Description should stay within **260 characters** (older PH docs cap at 260 chars; newer launch guide allows up to 500 chars, so ≤260 chars satisfies both). Launch at 12:01 AM PT and post the Maker's first comment immediately.
  - Sources: [Product Hunt Official Launch Guide](https://www.producthunt.com/launch/preparing-for-launch), [Product Hunt Asset & Character Limits Analysis](https://submitator.com/blog/product-hunt-launch-assets), [Appcues Product Hunt Guide](https://www.appcues.com/blog/a-4-step-product-hunt-launch-guide)

---

### 1. Hacker News (`Show HN`)

**Title** (73 chars):
`Show HN: Agent! – Native Swift macOS agent for Xcode, Accessibility, root`

**Submission URL**: `https://github.com/AgentiLoop/Agent`

**Body / First Comment** (208 words):
Hi HN, I built Agent! (`https://github.com/AgentiLoop/Agent`), a native Swift 6.4 / SwiftUI macOS application (macOS 14.6+) that connects 23 LLM providers—plus on-device Apple Intelligence and local servers like Ollama, LM Studio, and vLLM—to an autonomous task loop for coding and desktop automation.

Over the past three years I built several standalone macOS AI tools and ~8 Swift packages (`AgentTools`, `AgentLLM`, `AgentMCP`, `AgentAccess`, `AgentEventBridges`, `AgentD1F`, `AgentSwift`, `AgentAudit`). Once I had a self-verifying task loop where tasks cannot complete until `goal_state` criteria are verified with tool evidence, I combined those libraries into Agent!.

Unlike Electron editors or terminal-only CLIs, Agent! runs natively in-process with macOS TCC grants:
- **Xcode & Code**: Reads/edits files with SHA-256 read-before-edit gates and 1-week snapshot rollbacks, builds Xcode projects natively, and parses ASTs via SwiftSyntax 6.2.
- **Desktop Automation**: Element-based Accessibility API control (25 actions via AXorcist), AppleScript/JXA, and 51 ScriptingBridge app bridges.
- **AgentScript**: Compiles plain Swift files into `.dylib`s at runtime via SwiftPM and `dlopen`s them in-process so custom scripts inherit the app's TCC permissions.
- **Privileged Execution**: Runs user shells via a Launch Agent and root commands via an `SMAppService` + XPC Launch Daemon.

You can install the Apple-notarized binary via `brew install --cask agentiloop-agent` or build from source with `./build.sh`. Feedback and code audits are very welcome.

#### 3 Likely HN Questions & Suggested Answers

**Q1: Giving an LLM a root Launch Daemon (`root_shell`) sounds terrifying. How do you stop prompt injection or a rogue model from wiping my Mac or another local process from hijacking the XPC helper?**
**A1:** First, the root Launch Daemon is completely optional—you have to approve it via `SMAppService` when needed, and you can remove it anytime in Settings. Second, on the XPC side, the helper follows Apple's `EvenBetterAuthorizationSample` pattern: it validates that the calling process is signed with the same Team ID as `Agent!.app` and checks a per-session `agentInstanceID`, rejecting unverified local processes. Third, `ShellSafetyService` hard-blocks destructive patterns (`rm -rf /`, `rm -rf ~`, bare-glob `rm -rf`, `--no-preserve-root`) both client-side and daemon-side so the LLM cannot bypass it. There is also an optional pre-execution review layer called **Jev** (TypeSafe System One) that scores shell commands for destructive risk (default cutoff 70%) before any shell path runs.

**Q2: Why build a native Swift/SwiftUI app and custom `.dylib` scripting (`AgentScript`) instead of a cross-platform CLI or Electron app with MCP?**
**A2:** We actually do have cross-platform terminal siblings (`AgentiLoopCLI` in Rust and `AgentiLoopGo` in Go) for pure terminal workflows, and Agent! supports stdio and HTTP/SSE MCP servers out of the box. The reason Agent! itself is native Swift is macOS TCC (Transparency, Consent, and Control). On macOS, permissions for Accessibility, Automation (Apple Events), Calendar, Mail, Messages, and Screen Recording are bound to the app bundle's code signature. By compiling Swift scripts to `.dylib`s and `dlopen`ing them in-process alongside 51 typed ScriptingBridge headers, custom automation runs at native speed with low RAM overhead and zero IPC/sandbox friction.

**Q3: Why is the license PolyForm Noncommercial 1.0.0 instead of MIT or Apache 2.0, and how do local models perform?**
**A3:** The source code is under PolyForm Noncommercial 1.0.0 so anyone can read, audit, modify, and build it for personal or noncommercial use, while commercial redistribution is reserved to AgentiLoop.ai (Logos InkPen LLC). Official signed/notarized binaries are free to use for personal/noncommercial work. Regarding local models: you can run 100% offline with Local Ollama, LM Studio, or vLLM, plus on-device Apple Intelligence for triage and summaries. To be honest about hardware requirements, a usable 30B+ model for agentic tool-calling (like `GLM-4.7-Turbo` 32B) needs a 64–128GB Apple Silicon Mac (M2/M3/M4 Ultra) or 24GB+ VRAM. On smaller Macs, cheap cloud APIs like GLM-5.3 via Z.ai or DeepSeek are much more practical.

---

### 2. r/macapps Post

**Subreddit Rules Note**:
- Prefix with `[OS]` for open-source/source-available software.
- Disclose that you are the developer.
- Link only to official distribution (`github.com/AgentiLoop/Agent` / `agentiloop.ai`).
- Do not post more than once per 30 days, and ensure you have ≥10 comment karma in `r/macapps` before submitting.

**Title**:
`[OS] Agent! — A native SwiftUI macOS automation & coding agent (23 LLMs, Accessibility API, AppleScript, Xcode)`

**Body** (176 words):
Hi r/macapps — I'm the developer of **Agent!**, a 100% native Swift 6.4 / SwiftUI app for macOS 14.6+ that I built after three years of working on macOS automation tools.

Most AI desktop apps are Electron wrappers or terminal CLIs that can only edit text files. I wanted an app that actually drives macOS natively:
- **Controls Mac apps** via the Accessibility API (25 element-based actions), AppleScript, JXA, and 51 built-in ScriptingBridge app bridges (Music, Mail, Calendar, Pages, Safari, Finder, etc.).
- **Builds & fixes Xcode projects**, manages Git, and snapshots every file edit with 1-week rollback.
- **23 LLM providers + Local AI**: Bring your own API key (Claude, OpenAI, Gemini, DeepSeek, Z.ai, OpenRouter, etc.), run 100% offline with Ollama / LM Studio / vLLM, or use on-device Apple Intelligence.
- **Extras**: On-device voice wake word (*"Agent!"*), iMessage remote control from your iPhone, and MCP client support.

No Electron, no telemetry, no subscription. Free for personal/noncommercial use (PolyForm Noncommercial 1.0.0), and the official binary is signed and notarized by Apple.

- **Install**: `brew install --cask agentiloop-agent`
- **GitHub (646 stars)**: https://github.com/AgentiLoop/Agent
- **Website**: https://agentiloop.ai

---

### 3. r/swift Post (Developer Angle)

**Title**:
`Building a native macOS agent in Swift 6.4: SwiftUI, SMAppService XPC daemons, SwiftSyntax, and dlopen'd Swift dylib plugins`

**Body** (192 words):
I've been working on **Agent!** (https://github.com/AgentiLoop/Agent), a source-available macOS 14.6+ app written in Swift 6.4 and SwiftUI, and wanted to share a few macOS-specific architecture patterns that worked well:

1. **In-process Swift plugin scripting (`dlopen` + TCC)**: Instead of spawning subprocesses that lose the host app's TCC grants (Accessibility, Calendar, Mail, Automation), `AgentScript` compiles user `.swift` files into `.dylib` targets via SwiftPM alongside 51 generated `ScriptingBridge` interfaces (`AgentEventBridges`), then `dlopen`s the entry point (`@_cdecl("script_main")`) in-process.
2. **Privileged execution via `SMAppService` + XPC**: Shell commands run either in a user Launch Agent or a root Launch Daemon registered with `SMAppService`. Both XPC listeners enforce same-team code signing derived from the app's signature plus a per-session instance ID, with a `ShellSafetyService` layer enforced on both client and daemon.
3. **Modular Swift Packages**: The app is split across focused Swift packages (`AgentLLM`, `AgentTools`, `AgentMCP`, `AgentAccess` on top of AXorcist, `AgentSwift` using SwiftSyntax 6.2 for repo indexing, and `AgentD1F` for multi-line diffing).

You can build from source without a paid developer account using `./build.sh` (ad-hoc signed; everything works except `SMAppService` helpers). Would love feedback on the Swift architecture!

---

### 4. r/LocalLLaMA Post (Local / Offline Angle)

**Title**:
`Agent! — Native Swift macOS desktop & coding agent with Local Ollama, LM Studio, vLLM, and Apple Intelligence support`

**Body** (142 words):
I built **Agent!** (https://github.com/AgentiLoop/Agent), a native Swift/SwiftUI macOS agent (no Electron/NPM) that connects local LLM servers—**Ollama**, **LM Studio**, and **vLLM**—plus on-device **Apple Intelligence** directly to macOS system automation and coding tools.

When paired with Local Ollama, LM Studio, or vLLM, everything stays 100% offline on your Mac:
- Automatically detects your local model's real context window.
- Gives local models 25 element-based macOS Accessibility actions, AppleScript/JXA, 51 ScriptingBridge app bridges, native Xcode build/fix loops, file diffs with automatic snapshots/undo, shell execution, and MCP support.
- Uses on-device Apple Intelligence for triage, summaries, and token compression.

**Honest hardware note from my testing**: For heavy multi-step tool calling locally, a 30B+ model like **GLM-4.7-Turbo (32B)** works best and realistically needs a 64–128GB Apple Silicon Mac (M2/M3/M4 Ultra) or a 24GB+ VRAM Linux box on your LAN.

Install via `brew install --cask agentiloop-agent` or grab the source/DMG on GitHub.

---

### 5. Product Hunt Launch Assets

- **Name**: `AgentiLoop Agent!`
- **Tagline** (55 chars):
  `Native macOS AI agent for coding and desktop automation`
- **Description** (249 chars):
  `100% native Swift macOS app connecting 23 LLM providers, Ollama, LM Studio, and Apple Intelligence to an autonomous loop. Builds Xcode projects, controls any Mac app via Accessibility and ScriptingBridge, runs Swift dylib scripts, and supports MCP.`
- **5 Topics**:
  1. `Mac`
  2. `Artificial Intelligence`
  3. `Developer Tools`
  4. `Productivity`
  5. `Open Source` *(Note: if preferring strict OSI filtering on PH, swap for `Automation` since license is PolyForm Noncommercial 1.0.0)* [VERIFY]
- **First Comment from Maker** (143 words):
  Hi Product Hunt! I'm the creator of **AgentiLoop Agent!**.

  I spent the last three years building native macOS AI tools and eight Swift packages. Most coding and desktop agents today are either terminal-only CLIs or heavy Electron forks that can't talk to macOS beyond editing files.

  I built Agent! in 100% native Swift 6.4 and SwiftUI so it can act across your entire Mac:
  - **23 LLM providers + Local AI**: Use Claude, OpenAI, Gemini, DeepSeek, Z.ai, OpenRouter, or run offline with Ollama, LM Studio, vLLM, and Apple Intelligence.
  - **Real macOS control**: Drives any app via the Accessibility API, AppleScript, and 51 ScriptingBridge bridges, plus compiles Swift scripts (`.dylib`) in-process with full TCC permissions.
  - **Xcode & Git**: Native Xcode builds, SHA-256 read-before-edit safety, and 1-week file rollbacks.

  It's free for personal/noncommercial use (`brew install --cask agentiloop-agent`). I'd love your feedback!

---

### 6. X / Twitter + Mastodon (4-Post Thread)

**Post 1/4** (265 chars):
I've been building AgentiLoop Agent! — a 100% native Swift 6.4 / SwiftUI macOS agent that wires 23 LLM providers, local models (Ollama, LM Studio, vLLM), and Apple Intelligence into an autonomous loop for coding & Mac automation.

https://github.com/AgentiLoop/Agent

**Post 2/4** (271 chars):
No Electron, no NPM, no telemetry. Agent! reads & edits code (with SHA-256 read gates + 1-week snapshot undo), builds Xcode projects natively, manages Git, and drives any Mac app via the Accessibility API, AppleScript, JXA, and 51 ScriptingBridge app bridges.

**Post 3/4** (269 chars):
Under the hood:
- AgentScript: compiles Swift files into .dylibs at runtime & dlopens them in-process with full macOS TCC grants
- Optional SMAppService + XPC Launch Agent/Daemon for user & root shell tasks
- Full MCP client (stdio + HTTP), voice wake word, iMessage remote

**Post 4/4** (227 chars):
Every release ships a signed, Apple-notarized binary (free for personal & noncommercial use), or you can build from source with `./build.sh`.

Install via Homebrew:
`brew install --cask agentiloop-agent`

Docs: https://agentiloop.ai

---

### 7. GitHub Release Announcement Template

**Template** (104 words):
### Quick Install & Update
Install or upgrade the signed, Apple-notarized binary via Homebrew:
```sh
brew update && brew install --cask agentiloop-agent
```
Or download the `.dmg` / `.zip` directly from the assets below and drag **Agent!.app** to `/Applications`. (Using the official signed release ensures the `SMAppService` Launch Agent and Launch Daemon helpers stay registered.)

### Resources & Support
- **Repository**: https://github.com/AgentiLoop/Agent
- **Website & Docs**: https://agentiloop.ai
- **Cross-Platform CLIs**: [AgentiLoopCLI (Rust)](https://github.com/AgentiLoop/AgentiLoopCLI) · [AgentiLoopGo (Go)](https://github.com/AgentiLoop/AgentiLoopGo)

⭐ **Enjoying Agent!?** If Agent! saves you time on your Mac, please [star the repository on GitHub](https://github.com/AgentiLoop/Agent) — it helps other macOS developers and power users discover the project!
