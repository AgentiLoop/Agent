## Agent! 1.1.95.295 — Release

![Agent! 1.1.95](https://github.com/AgentiLoop/Agent/releases/download/v1.1.95.295/Agent-1.1.95-screenshot.png)

Follows the latest pre-release, **Agent! 1.1.94.294**. Covers all changes since the last public release, **Agent! 1.1.87.287**. Pre-releases 1.1.88.288 – 1.1.94.294 are rolled into this release.

### 🕹️ Reverse Engineering with Agent!
Agent! reads disc images and ROMs, writes the extraction tools, studies decompiled code and rebuilds games in the browser. Four racing games and a fighter were built this way:
- **[CrazyTaxi](https://github.com/AgentiLoop/CrazyTaxi)**: Sega Dreamcast *Crazy Taxi* rebuilt in Three.js from your own disc, with collision code ported from the decomp
- **[MarioKart64JS](https://github.com/AgentiLoop/MarioKart64JS)**: Mario Kart 64 rebuilt in Three.js (not emulated) from the original N64 ROM. Play at [mk64js.gokart.games](https://mk64js.gokart.games/play)
- **[F1](https://github.com/AgentiLoop/F1)**: 18 real circuits rebuilt from OpenF1 car positions and telemetry. Play at [f1.gokart.games](https://f1.gokart.games)
- **[GoKart](https://github.com/AgentiLoop/GoKart)**: an original Godot 4 kart racer that recreates Mario Kart 64's rules, with everything generated from code. Play at [gokart.games](https://gokart.games)
- **[BvS](https://github.com/AgentiLoop/bvs)**: Batman v Superman, a Three.js fighting game where every pixel is drawn from code. Play at [bvs.agentiloop.ai](https://bvs.agentiloop.ai/)

No game assets are in these repos. All are fan-made for personal and educational use.

### 🔌 MCP
- One-step install with the `mcp` tool (for example, "add sentry mcp server"). Secrets are stored only in the Keychain ([`146c9a3a`](https://github.com/AgentiLoop/Agent/commit/146c9a3a))
- API keys pasted into chat stay out of the LLM. SecretRedactor moves them to the Keychain and the MCP prompt fills them in for you ([`c0217be5`](https://github.com/AgentiLoop/Agent/commit/c0217be5))
- Built-in **Sign in with Browser** (OAuth 2.1 + PKCE, discovery, dynamic client registration) for Sentry, Linear and Notion. It doesn't need npx or mcp-remote, and tokens stay in the Keychain and refresh automatically ([`efc3724c`](https://github.com/AgentiLoop/Agent/commit/efc3724c))
- Browser sign-in is detected automatically for any remote server that supports OAuth, with no preset needed ([`ac24351b`](https://github.com/AgentiLoop/Agent/commit/ac24351b))
- Fixed: servers with names like `127.0.0.1` or `my_server` couldn't be reached ([`fb110a37`](https://github.com/AgentiLoop/Agent/commit/fb110a37))
- New presets: **Cohesivity**, **Keenable Search** and **deed.page** ([`a6d0ac15`](https://github.com/AgentiLoop/Agent/commit/a6d0ac15), [`9b562699`](https://github.com/AgentiLoop/Agent/commit/9b562699), [`32541370`](https://github.com/AgentiLoop/Agent/commit/32541370))

### 🔌 New LLM Provider
- **TheRouter.ai**, an OpenAI-compatible gateway, with tests ([`0ebb3ad1`](https://github.com/AgentiLoop/Agent/commit/0ebb3ad1), [`5fece081`](https://github.com/AgentiLoop/Agent/commit/5fece081))
- When an Ollama model isn't found, Agent! lists the installed models and suggests `ollama pull`, then tries the fallback chain. Previously it showed the raw error JSON ([`c24f8a1c`](https://github.com/AgentiLoop/Agent/commit/c24f8a1c))

### 🗣️ Avatar Tabs
- New talking-face avatar pane. The New Tab sheet has **Avatar** and **Default to Auto-Pilot** toggles ([`bef43d3b`](https://github.com/AgentiLoop/Agent/commit/bef43d3b), [`5035a31e`](https://github.com/AgentiLoop/Agent/commit/5035a31e))
- Replies are spoken sentence by sentence as they stream. Each sentence gets its own expression, chosen by Jev with a keyword fallback ([`26aeffc0`](https://github.com/AgentiLoop/Agent/commit/26aeffc0), [`847c028c`](https://github.com/AgentiLoop/Agent/commit/847c028c))
- Shows a thinking face while the AI works and greets you aloud when the tab opens ([`e6097c84`](https://github.com/AgentiLoop/Agent/commit/e6097c84), [`65a9bb67`](https://github.com/AgentiLoop/Agent/commit/65a9bb67))
- Voice picker (default Daniel), mute option and dictation that sends automatically. HUD text stays in sync with the speech ([`04069c45`](https://github.com/AgentiLoop/Agent/commit/04069c45), [`5cf1f1a9`](https://github.com/AgentiLoop/Agent/commit/5cf1f1a9), [`030ac20c`](https://github.com/AgentiLoop/Agent/commit/030ac20c), [`a0f2c776`](https://github.com/AgentiLoop/Agent/commit/a0f2c776))

### 🤖 Auto-Pilot
- Multiple Auto-Pilot tabs per project, each with its own progress, goals and plans. Optional git worktree isolation ([`566014f6`](https://github.com/AgentiLoop/Agent/commit/566014f6), [`beb30ab6`](https://github.com/AgentiLoop/Agent/commit/beb30ab6))
- **Stop All** ends only the current tab's session ([`9f80ed21`](https://github.com/AgentiLoop/Agent/commit/9f80ed21))
- Endless loops that make no progress now stop ([`c4f6e737`](https://github.com/AgentiLoop/Agent/commit/c4f6e737))
- A blue goal bar is shown while Auto-Pilot runs ([`96c50476`](https://github.com/AgentiLoop/Agent/commit/96c50476))
- Attached images are carried into every cycle ([`bbbb76c9`](https://github.com/AgentiLoop/Agent/commit/bbbb76c9))

### 🖱️ Accessibility Automation (AgentAccess 2.10.26 – 2.10.43)
- New actions:
  - **`read_text`** reads an app's front window or a browser web page as text ([`226711a6`](https://github.com/AgentiLoop/Agent/commit/226711a6), [`76ebcf40`](https://github.com/AgentiLoop/Agent/commit/76ebcf40))
  - **`select_option`** sets popups, checkboxes, sliders, radio groups, tabs and web `<select>` menus ([`05471d0f`](https://github.com/AgentiLoop/Agent/commit/05471d0f), [`242d2dd2`](https://github.com/AgentiLoop/Agent/commit/242d2dd2))
  - **`select_row`** picks rows in tables, lists and sidebars, plus Finder desktop icons ([`fee21b3a`](https://github.com/AgentiLoop/Agent/commit/fee21b3a), [`e8632ec8`](https://github.com/AgentiLoop/Agent/commit/e8632ec8))
  - **`press_key`** sends keys and shortcuts ([`5d09ba12`](https://github.com/AgentiLoop/Agent/commit/5d09ba12))
- `click_menu_item` clicks menu items without opening the menu on screen and can list a menu's items. It also reaches menu-bar extras (Wi‑Fi, Focus, Control Center) and reads the panels they open ([`ede6bedc`](https://github.com/AgentiLoop/Agent/commit/ede6bedc), [`6e28a923`](https://github.com/AgentiLoop/Agent/commit/6e28a923), [`4d9d8cdc`](https://github.com/AgentiLoop/Agent/commit/4d9d8cdc))
- You can address elements with AppleScript-style references, for example `button 2 of toolbar 1 of window 1` ([`159854f9`](https://github.com/AgentiLoop/Agent/commit/159854f9))
- `set_properties` works like AppleScript `set … to …` and reads each value back to confirm it ([`4a3970d1`](https://github.com/AgentiLoop/Agent/commit/4a3970d1), [`163724c0`](https://github.com/AgentiLoop/Agent/commit/163724c0), [`b834af9a`](https://github.com/AgentiLoop/Agent/commit/b834af9a))
- `click_element` presses elements the way AppleScript does and reports what changed. `type_into_element` fills web forms and adds `submit:true` ([`ce33824c`](https://github.com/AgentiLoop/Agent/commit/ce33824c), [`76d8a790`](https://github.com/AgentiLoop/Agent/commit/76d8a790), [`3ddf8f36`](https://github.com/AgentiLoop/Agent/commit/3ddf8f36))
- Better ranking when searching for elements, and Pages, Numbers and Keynote document canvases can now be read ([`7a4913fc`](https://github.com/AgentiLoop/Agent/commit/7a4913fc))
- Tabs can control Safari's toolbar, menus and other browser controls again ([`cbe824e8`](https://github.com/AgentiLoop/Agent/commit/cbe824e8))

### ♿ App Accessibility (VoiceOver, keyboard, display settings)
- VoiceOver labels and announcements throughout the app: tabs, the task field, Tools, History, MCP, Settings, the token badge, the Avatar and Messages Monitor ([`4d3d4cd6`](https://github.com/AgentiLoop/Agent/commit/4d3d4cd6) … [`730ef462`](https://github.com/AgentiLoop/Agent/commit/730ef462))
- Full support for Increase Contrast, Reduce Motion, Reduce Transparency and Differentiate Without Color. Status colors are easier to read in Light mode ([`b55fb514`](https://github.com/AgentiLoop/Agent/commit/b55fb514), [`41413c23`](https://github.com/AgentiLoop/Agent/commit/41413c23), [`b6142834`](https://github.com/AgentiLoop/Agent/commit/b6142834), [`51e4ee6a`](https://github.com/AgentiLoop/Agent/commit/51e4ee6a))
- **View > Bigger Text / Smaller Text / Actual Size Text** (⌘= / ⌘- / ⌘0) for the activity log ([`c5b01a74`](https://github.com/AgentiLoop/Agent/commit/c5b01a74))
- **Go to Activity Log** (⌥⌘L) and **Go to Task Field** (⌥⌘I), plus Full Keyboard Access for tool groups, folder tree rows and resize handles ([`40450926`](https://github.com/AgentiLoop/Agent/commit/40450926), [`c8a5a8a4`](https://github.com/AgentiLoop/Agent/commit/c8a5a8a4), [`5aed2d61`](https://github.com/AgentiLoop/Agent/commit/5aed2d61))

### 🛠️ Tool Reliability
- Every shell command has a hard timeout (default 10 min; change it in **Options > Shell timeout**, 0 turns it off) ([`965e68f3`](https://github.com/AgentiLoop/Agent/commit/965e68f3))
- Fixed the in-process shell hanging when an orphaned background job held the pipe open ([`7f0c1e9b`](https://github.com/AgentiLoop/Agent/commit/7f0c1e9b))
- After 2 failures, scripting tools point the model to accessibility actions. Tabs get the same advice ([`3a3f4144`](https://github.com/AgentiLoop/Agent/commit/3a3f4144), [`e330ae39`](https://github.com/AgentiLoop/Agent/commit/e330ae39))
- A tool marked as chronically failing is cleared after an app update, so fixed tools aren't avoided ([`577a767e`](https://github.com/AgentiLoop/Agent/commit/577a767e))
- Fixed: `web navigate`, `web switch_tab`, `agent_script update` and `xcode select_project` with a single project ([`424b34b0`](https://github.com/AgentiLoop/Agent/commit/424b34b0), [`b94ebbc2`](https://github.com/AgentiLoop/Agent/commit/b94ebbc2), [`2a619ca7`](https://github.com/AgentiLoop/Agent/commit/2a619ca7), [`ad101ec6`](https://github.com/AgentiLoop/Agent/commit/ad101ec6))
- The critic's diff is cut at a line or file boundary and marked as truncated ([`99881915`](https://github.com/AgentiLoop/Agent/commit/99881915))

### 🐞 Other Fixes
- Script tabs no longer take or clear screenshots pasted into the main tab ([`b7d07012`](https://github.com/AgentiLoop/Agent/commit/b7d07012))
- Debug builds have their own SwiftData store, so release and debug builds no longer wipe each other's tabs ([`1e28b209`](https://github.com/AgentiLoop/Agent/commit/1e28b209))
- Red/green stripes now show correctly on tab-indented edit diffs (AgentColorSyntax 1.2.13) ([`76b8df7e`](https://github.com/AgentiLoop/Agent/commit/76b8df7e))

### 💜 Sponsor
- Sidrune AI replaces Fluxion AI in the READMEs, with promo code **SDRAGENTLOOP** ([`cbaa3e49`](https://github.com/AgentiLoop/Agent/commit/cbaa3e49))
