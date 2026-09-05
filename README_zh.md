# 🦾 AgentiLoop Agent!

### **为你的 Mac 桌面打造的智能体 AI**

[![Latest Release](https://img.shields.io/github/v/release/AgentiLoop/Agent?label=Download&color=blue&style=for-the-badge)](https://github.com/AgentiLoop/Agent/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Stars&color=gold)](https://github.com/AgentiLoop/Agent/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/AgentiLoop/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donation-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Tip Jar" /></a>

## README 翻译

- [English](README.md)
- [Español](README_es.md)
- [Français](README_fr.md)
- [Deutsch](README_de.md)
- [中文 (简体)](README_zh.md)

## 在 Agent 中下棋
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## Agent! 是什么？

**一个应用。任意 AI。完全掌控你的 Mac。**

Agent! 是一款 100% 原生的 Swift 6.2 / SwiftUI 应用，将 **18 家 LLM 提供商**——Claude、GPT、Gemini、Grok、Mistral、DeepSeek、Qwen、Z.ai、BigModel、Hugging Face、OpenRouter、Ollama（云端和本地）、vLLM、LM Studio、Codestral、Mistral Vibe 以及设备端的 **Apple Intelligence**——接入一个真正*会做事*的自主任务循环：读取你的代码库、修复 bug、构建 Xcode 项目、提交 diff、通过辅助功能 API 驱动任何 Mac 应用、以你的身份或 root 运行 shell 命令、通过 iMessage 把结果发给你，并响应你说出的 *「Agent!」*。

没有 NPM，没有 Electron，没有订阅，没有遥测。使用你自己的 API 密钥，完全本地运行，或用 Apple Intelligence 免费运行。它依赖的每个 Swift 包都出自同一位作者之手。详见下方的[项目背景](#项目背景)。

## 最新动态 🚀

**v1.1.x — Hardened Harness 版本** · [Releases →](https://github.com/AgentiLoop/Agent/releases/latest)

- **上下文压缩全面重建。** 阈值 = 模型窗口 − 预留输出 − 缓冲，由真实的 `input_tokens` 驱动。提供商侧的 9 段式 LLM 摘要取代了设备端的 4K 摘要；每次压缩后都会重新附加未完成的目标、计划清单和已编辑文件。过大的工具结果在产生时即落盘，可通过 `restore_tool_result` 恢复。413 溢出会走强制压缩并以更短的请求重试；`max_tokens` 超限先升级、再以自身计数继续。
- **先读后改门禁。** `edit_file` / `apply_diff` / `diff_apply` 拒绝修改 LLM 在本次任务中未读取过、或自上次读取后在磁盘上已变更（SHA-256）的文件。拒绝时会自动读取文件，使下一次调用即为编辑。外部文件变更会在每一轮以 diff 片段呈现。
- **本地模型的真实上下文窗口。** LM Studio、Ollama 和 vLLM 报告各自模型的实际上下文长度——不再硬编码假设 32K。
- **更快的回合。** 只读工具在 Claude 响应仍在流式输出时就开始运行；感知输入的 shell 并发；429/529 时带抖动的指数退避重试并遵循 `Retry-After`；所有提供商的 SSE 流中错误都会被暴露。
- **纵深防御。** `ShellSafetyService` 现在同时在守护进程侧（AgentHelper + AgentUser）和客户端侧执行；Release 构建拒绝无团队签名的 XPC 客户端；两个 XPC 监听器都要求由应用自身签名派生的同团队代码签名。
- **活动日志。** 不再有 50K 截断或重启时的 500K 裁剪——大日志在主线程外渲染并显示「Processing tab data…」遮罩；可选的「Activity Log Below HUD」布局。
- **应用菜单：** 检查更新…（GitHub Releases）、网站、GitHub。每个 PR 都运行 CI Build & Test 工作流；**273 个测试全部通过**。
- 此外：带证据验证标准的 `goal_state`、完成前可选的评审者 diff 审查、任务级 `rewind_task`、Claude 的扩展思考、`reasoning_effort` 透传、可按代理指定模型的子代理（3 个并发，6 个只读）、带恢复提示的类型化工具错误、事件钩子。

## 快速开始（下载）

1. **下载** [Agent!](https://github.com/AgentiLoop/Agent/releases/latest) 并拖入「应用程序」
2. **打开 Agent!** —— 一切自动配置
3. **选择你的 AI** —— 设置 → 选择提供商 → 输入 API 密钥

## 快速开始（从源码构建）

```bash
git clone https://github.com/AgentiLoop/agent.git
cd Agent
```

**方案 A —— Xcode（Apple Developer 账户）：** 打开 `Agent.xcodeproj`，设置你的 Development Team，构建并运行 `Agent` target，按提示批准 helper。

**方案 B —— 无开发者账户（仅需 Xcode Command Line Tools）：**
```bash
./build.sh              # Debug
./build.sh Release      # Release
open "build/DerivedData/Build/Products/Debug/Agent!.app"
```

> ⚠️ 方案 B 的构建为临时签名。Launch Agent/Daemon helper 无法注册（SMAppService 需要 Team ID），但 LLM 循环、所有工具、辅助功能、AppleScript、shell 和 MCP 仍可正常使用。

> 💡 **低成本方案：** 通过 **Z.ai** 使用 **GLM-5.1**（注册最快，默认模型），每百万 token 只需几分钱。本地运行？只有 **GLM-4.7-Turbo**（32B）能在消费级硬件上运行（64–128GB Apple Silicon，通过 Ollama）。

### 故障排除（从源码构建）

- **`xcode-select` 指向 Command Line Tools** → `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- **拉取后出现奇怪的 `BUILD FAILED`** → DerivedData 过期：`./build.sh clean && ./build.sh`
- **helper 始终无法注册** → 方案 B 的预期行为；需要 helper 请使用方案 A
- **Deployment target / SDK 错误** → Agent! 面向 macOS 26；请更新 macOS 和 Xcode
- **配置参数区分大小写** → `./build.sh`（Debug）或 `./build.sh Release`

## 它能做什么？

> *「构建 Xcode 项目并修复所有错误」* · *「在音乐中播放我的 Workout 播放列表」* · *「用 Photo Booth 拍张照片」* · *「给妈妈发 iMessage 说我 6 点到家」* · *「打开 Safari 搜索飞往东京的航班」* · *「把这个类重构成更小的文件」* · *「我今天有哪些日历事件？」*

只需输入你想要的。Agent! 会想办法实现。

---

## 核心功能

- **🧠 自我验证的任务循环** —— 推理、执行、观察结果、自我纠正。在 `goal_state` 标准被附证据标记完成之前，任务不能宣告完成；可选的评审者会先审查 diff。
- **🛠 智能体编码** —— 读取代码库，用字符串替换 diff 精确编辑，原生构建 Xcode 项目（错误可点击），管理 git，将仓库索引为可移植的 JSONL 仓库地图。每次编辑都有快照——一键回滚或整任务 `rewind_task`。
- **🖥 桌面自动化** —— 通过辅助功能 API（[AXorcist](https://github.com/steipete/AXorcist)）驱动任何 Mac 应用，基于元素并带模糊自动重试。另有 NSAppleScript、JXA 和 51 个 ScriptingBridge 应用桥接，全部进程内运行并持有 TCC 权限。
- **📜 AgentScript** —— 运行时编译的 Swift dylib，以 `dlopen` 在进程内加载并拥有完整 TCC。删除的脚本进入 `.Trash`，可恢复。
- **🛡 特权执行** —— 通过 Launch Agent 以你的身份运行 shell，或通过你只需批准一次的 Launch Daemon 以 root 运行（SMAppService + XPC）。关于 SMAppService 为何已强制签名身份，见 [docs/SECURITY.md](docs/SECURITY.md)。
- **🎙 语音** —— 说出 **「Agent!」** 再说任务；设备端 `SFSpeechRecognizer`，静默约 2.5 秒后自动运行，循环监听。
- **📱 iMessage 远程控制** —— 从 iPhone 发送 `Agent! next song`；仅限已批准的发送者。读取 `chat.db` 需要「完全磁盘访问权限」。
- **🌐 Web** —— 内置 Safari 自动化（JavaScript + AppleScript）；可选 Selenium 和 [Playwright MCP](https://github.com/microsoft/playwright-mcp) 实现跨浏览器。
- **🤝 子代理** —— 最多 3 个并发（6 个只读）的隔离代理，支持邮箱消息和按代理指定模型。
- **🧩 MCP** —— 在设置 → MCP 服务器中添加任意 MCP 服务器；工具以 `mcp_<server>_<tool>` 形式出现。Xcode MCP：`{"mcpServers":{"xcode":{"command":"xcrun","args":["mcpbridge"],"transport":"stdio"}}}`。
- **🗂 标签页、历史、记忆、计划、技能** —— 每个标签页有独立的项目文件夹和日志；持久化用户记忆；多计划清单出现在每个提示词中。
- **🔄 回退链** —— 遇到 429/超时/网络故障时自动切换到下一个已配置的提供商。

## 🤖 18 家 AI 提供商

| 提供商 | 费用 | 适合 |
|---|---|---|
| **Claude** | 付费 | 长时间自主任务、扩展思考、提示词缓存 |
| **OpenAI** | 付费 | 通用、工具调用、视觉、`reasoning_effort` |
| **Google Gemini** | 付费（有免费额度） | 长上下文、视觉 |
| **Grok** (xAI) | 付费 | 实时信息 |
| **Mistral** / **Codestral** / **Mistral Vibe** | 付费 | 开放权重云端、代码、智能体产品 |
| **DeepSeek** | 便宜 | 低成本编码、缓存命中报告 |
| **Hugging Face** | 不定 | 开源模型，serverless 或专用端点 |
| **OpenRouter** | 付费 | 200+ 模型，一把密钥；Claude 经 Anthropic 协议路由 |
| **Z.ai** / **BigModel** | 便宜 | GLM-5.1 —— 推荐起点 |
| **Qwen**（阿里巴巴） | 便宜 | 通过 Dashscope 使用 Qwen 2.5 / 3 |
| **Ollama**（云端） | 免费额度 | 托管的开源模型 |
| **本地 Ollama** / **vLLM** / **LM Studio** | 免费 + 硬件 | 完全离线；自动检测各模型真实上下文窗口 |
| **Apple Intelligence** | 免费，设备端 | 分流、摘要、token 压缩（大脑图标，而非提供商选择器） |

> 💡 自托管提供商只是在 API 费用意义上免费——要以可用速度运行 30B+ 模型，需要 M2/M3/M4 Ultra Mac Studio（64–128GB）。没有这类硬件的话，上面的低价云端方案要便宜得多。

## 工具

规范名称来自 `AgentTools.Name.*`（真实来源：[AgentTools](https://github.com/AgentiLoop/AgentTools) 包）。可按提供商隐藏单个工具。

| 分组 | 工具 |
|---|---|
| **Core** | `done` · `list_tools` · `search` · `web_search` · `fetch` · `chat` · `memory` · `plan` · `goal_state` · `restore_tool_result` · `directory` · `skill` · `ask_user` · `index` |
| **代码 / 构建** | `file`（read/write/edit/diff_apply/undo/list/search/mkdir/…）· `git` · `xcode`（build/run/analyze/snippet/code_review/add_file/bump_version/…）· `agent_script` |
| **Shell** | `user_shell`（Launch Agent）· `root_shell`（Launch Daemon）· `shell`（进程内回退）· `batch` · `multi` |
| **macOS 自动化** | `accessibility`（25 个基于元素的操作）· `applescript`（含 `lookup_sdef`）· `javascript`（JXA） |
| **Web** | `safari` · `selenium` · `mcp_playwright_browser_*`（可选） |
| **子代理** | `spawn_agent` · `tell_agent` |

完整的逐操作参考：[docs/TECHNICAL.md](docs/TECHNICAL.md)。

## AgentScript —— 拥有完整 TCC 的 Swift 脚本

AgentScript 就是位于 `~/Documents/AgentScript/agents/Sources/Scripts/` 的普通 Swift 文件。Agent! 用 SwiftPM 将每个脚本编译为 `.dylib`（`Package.swift` 列出了所有脚本以及 51 个 ScriptingBridge 应用桥接），再以 `dlopen` 加载，并使用 Agent! 自身的 TCC 授权——辅助功能、自动化、日历、通讯录、邮件、照片等。LLM 通过 `agent_script`（`create` / `edit` / `run` / `delete` / `restore` / `pull`）管理它们；文件夹内自带约 35 个示例（`Hello`、`TodayEvents`、`NowPlaying`、`CheckMail`、`CreateDmg`、`ArchiveXcode`……）。

**入口点** —— 没有顶层代码，不调用 `exit()`；`stdout` 会返回给 LLM，返回值即退出状态：

```swift
import Foundation
import CalendarBridge   // 任何 `import XBridge` 都会自动接线——无需修改 Package.swift

@_cdecl("script_main")
public func scriptMain() -> Int32 {
    print("Hello from AgentScript! 👋")
    return 0
}
```

**环境变量 —— 如何被设置（SET）。** LLM 从不直接触碰环境。它只调用工具，由 Agent! 的 `ScriptService` 把变量导出到脚本进程中（`ScriptService+Execution.swift` 里的 `env["AGENT_PROJECT_FOLDER"] = cwd`、`env["AGENT_SCRIPT_ARGS"] = arguments`；进程内变体使用 `setenv(...)`）。同样这两个变量也会导出给每条 `user_shell` / `root_shell` / `shell` 命令。

```text
LLM 工具调用                                            Agent! 导出给脚本的内容
─────────────────────────────────────────────────────  ─────────────────────────────────────────────
agent_script(action:"run", name:"TodayEvents")         AGENT_PROJECT_FOLDER=/Users/you/Documents/GitHub/Agent
                                                       （AGENT_SCRIPT_ARGS 不会被设置）

agent_script(action:"run", name:"TodayEvents",         AGENT_PROJECT_FOLDER=/Users/you/Documents/GitHub/Agent
             arguments:"days=3,location=false,json=true")   AGENT_SCRIPT_ARGS="days=3,location=false,json=true"
```

| 变量 | 何时设置 | 含义 |
|---|---|---|
| `AGENT_PROJECT_FOLDER` | 始终 | 当前标签页的项目文件夹（没有则为 `$HOME`）。运行器的 cwd 也会设为该目录。 |
| `AGENT_SCRIPT_ARGS` | 仅当 LLM 传入 `arguments:"…"` 时 | LLM 传入的原始字符串。内置示例采用 `key=value,key=value` 约定。 |

**环境变量 —— 如何被读入（READ IN）。** 在脚本内部，二者都来自 `ProcessInfo.processInfo.environment`。下面就是 `Hello.swift` / `TodayEvents.swift` 使用的解析模式：

```swift
import Foundation

@_cdecl("script_main")
public func scriptMain() -> Int32 {
    let env = ProcessInfo.processInfo.environment

    // 1. 项目文件夹 —— 始终存在；保险起见回退到 cwd
    let folder = env["AGENT_PROJECT_FOLDER"] ?? FileManager.default.currentDirectoryPath

    // 2. 参数 —— 除非 LLM 传入了 `arguments:"…"`，否则不存在
    let argsString = env["AGENT_SCRIPT_ARGS"] ?? ""

    // 3. 默认值，然后解析 "key=value,key=value"
    var daysAhead    = 0
    var showLocation = true
    var outputJSON   = false

    for pair in argsString.split(separator: ",") {
        let parts = pair.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { continue }
        switch parts[0] {
        case "days":     daysAhead    = Int(parts[1]) ?? 0
        case "location": showLocation = parts[1].lowercased() == "true"
        case "json":     outputJSON   = parts[1].lowercased() == "true"
        default: break
        }
    }

    print("项目文件夹：\(folder)")
    print("days=\(daysAhead) location=\(showLocation) json=\(outputJSON)")
    return 0
}
```

这两个变量相互独立——切勿从 `AGENT_SCRIPT_ARGS` 中解析项目文件夹。`user_shell` 中的 Bash 等价写法：`ls "$AGENT_PROJECT_FOLDER/Sources"`（cwd 已在该目录，无需 `cd`）。

**内置脚本中真实的 `AGENT_SCRIPT_ARGS` 约定**（`~/Documents/AgentScript/agents/Sources/Scripts/`）：

| 脚本 | LLM 传入的 `arguments:` | 风格 |
|---|---|---|
| `TodayEvents` | `days=3,location=false,json=true` | `key=value,…` |
| `CheckMail` | `unreadOnly=true,inboxCount=true,json=true` | `key=value,…` |
| `ListReminders` | `completed=false,limit=5` | `key=value,…` |
| `QuitApps` | `excluded=Xcode,Agent,Terminal` | `key=value` 带列表 |
| `NowPlaying` | `json=true,artwork=true` | `key=value,…` |
| `ArchiveXcode` | `/path/to/Project.xcodeproj MyScheme 469UCUB275` | 位置参数，空格分隔（省略时自动检测 scheme/teamID） |
| `CreateDmg` | `--app /path/to/App.app --output /path/out.dmg --name "My App" --compress` | 标志风格，空格分隔，支持引号 |

**JSON 输入 / 输出 —— 与环境变量完全独立的另一套机制。** 环境变量由 Agent! 导出到进程中；JSON 文件则是磁盘上的普通文件，由*脚本自己*用 `FileManager` / `JSONSerialization` 读写。Agent! 不会创建、传递或解析它们。以下是内置脚本中的两种真实模式：

*1. 仅 JSON 输入（`SendMessage`）* —— 完全不用环境参数；脚本要求存在 `SendMessage_input.json`，缺失时返回 `1`：

```json
// ~/Documents/AgentScript/json/SendMessage_input.json   （运行前由 LLM 通过 file(action:"write") 写入）
{ "recipient": "妈妈", "message": "6 点到家", "imagePath": "~/Pictures/Photos Library.photoslibrary/originals/A/IMG_0001.jpeg" }

// ~/Documents/AgentScript/json/SendMessage_output.json  （由脚本写入）
{ "success": true, "timestamp": "2026-09-03T21:14:02Z", "recipient": "妈妈", "message": "6 点到家" }
// 失败时：{ "success": false, "timestamp": "…", "error": "Missing required field: recipient" }
```

```swift
// SendMessage.swift —— 脚本如何读取
let inputPath  = "\(NSHomeDirectory())/Documents/AgentScript/json/SendMessage_input.json"
guard let inputData = FileManager.default.contents(atPath: inputPath) else {
    writeOutput(outputPath, success: false, error: "Input file not found: \(inputPath)"); return 1
}
guard let json = try? JSONSerialization.jsonObject(with: inputData) as? [String: Any],
      let recipientHandle = json["recipient"] as? String else { /* … */ return 1 }
let message   = json["message"]   as? String
let imagePath = json["imagePath"] as? String
```

*2. 环境参数传选项，JSON 输出结构化结果（`TodayEvents`、`NowPlaying`、`CheckMail`、`ListReminders`）* —— 选项来自 `AGENT_SCRIPT_ARGS`（或可选的 `<Name>_input.json`）；当 `json=true` 时，脚本在返回给 LLM 的人类可读 stdout 之外，再写入 `<Name>_output.json`：

```json
// agent_script(action:"run", name:"TodayEvents", arguments:"days=3,json=true")
// → ~/Documents/AgentScript/json/TodayEvents_output.json
{ "success": true, "timestamp": "…", "count": 2,
  "events": [ { "summary": "Standup", "calendar": "Work", "startTime": "…", "endTime": "…", "allDay": false, "location": "…" }, … ] }

// agent_script(action:"run", name:"NowPlaying", arguments:"json=true,artwork=true")
// → ~/Documents/AgentScript/json/NowPlaying_output.json
{ "success": true, "playerState": "playing",
  "track": { "name": "…", "artist": "…", "album": "…", "duration": 240 },
  "artwork": { "saved": true, "path": "~/Documents/AgentScript/images/….png", "width": 500, "height": 500 } }
```

```swift
// TodayEvents.swift —— 脚本如何写入
func writeTodayEventsOutput(_ path: String, success: Bool, error: String? = nil,
                            events: [[String: Any]]? = nil, count: Int? = nil, outputJSON: Bool) {
    guard outputJSON else { return }
    var result: [String: Any] = ["success": success, "timestamp": ISO8601DateFormatter().string(from: Date())]
    if !success, let error { result["error"] = error }
    if success { if let events { result["events"] = events }; if let count { result["count"] = count } }
    try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    if let out = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted) {
        try? out.write(to: URL(fileURLWithPath: path))
    }
}
```

删除的脚本进入 `~/Documents/AgentScript/agents/.Trash/`（`agent_script(action:"restore")`）；`action:"pull"` 从 [AgentScripts](https://github.com/AgentiLoop/AgentScripts) 仓库获取上游版本。

## 隐私与安全

你的文件、屏幕内容和个人数据永远不会离开你的 Mac——云端提供商只看到提示词文本；本地提供商让一切保持离线。每个操作都有记录。

| 层级 | 作用 |
|---|---|
| **Shell Safety Service** | 硬性拦截 `rm -rf /`、`rm -rf ~`、裸通配符 `rm -rf`、`--no-preserve-root`——客户端**和**守护进程侧同时执行。LLM 无法绕过。 |
| **XPC 客户端信任** | 两个监听器都要求由应用自身签名派生的同团队代码签名；Release 构建拒绝无团队签名的客户端。 |
| **先读后改门禁** | 拒绝编辑未读取或被外部修改的文件（SHA-256），拒绝时自动读取。 |
| **文件备份 + 回退** | 每次编辑都有快照（保留 1 周）；Rollback 界面、`file(action:"undo")` 或任务级 `rewind_task`。 |
| **TCC 进程内路由** | AppleScript/JXA/screencapture/辅助功能命令在 Agent! 持有 TCC 授权的进程内运行，绝不经过守护进程。 |
| **工具执行门控** | LLM 无法伪造结果——每次调用都经过 `dispatchTool()` 并返回真实输出。没有工具调用却声称「我点击/搜索了…」会被注入纠正。 |
| **类型化错误 + 守卫** | 每个失败的工具结果都带有恢复提示；重复调用与卡死守卫先提醒后停止；完成门禁每任务最多拒绝 3 次。 |
| **控制台审计轨迹** | 每次工具调用和每条 helper 命令都被记录。 |

## 键盘快捷键与斜杠命令

| 快捷键 | 操作 |
|---|---|
| `Return` | 运行任务 · `⌘ .` / `Esc` 取消 |
| `⌘ T` / `⌘ W` / `⌘ 1–9` / `⌘ ⇧ ←→` | 新建 / 关闭 / 切换 / 上一个-下一个标签页 |
| `⌘ B` / `⌘ D` | 切换 LLM 输出浮层 / 折叠箭头 |
| `⌘ F` / `⌘ L` / `⌘ V` | 搜索日志 / 清除日志 / 粘贴图片 |
| `↑` / `↓` | 提示词历史 |
| `⌘ ⇧ M` / `⌘ ⇧ P` | 信息监视器 / 设置 |
| `⌘ ⇧ K` `L` `H` `J` `U` | 清除全部 / LLM 面板 / 提示词历史 / 任务历史 / token 计数器 |

斜杠命令在本地执行：`/clear [log|all|llm|history|tasks|tokens]`、`/memory [show|clear|edit|<文本>]`。

## 常见问题

**需要会编程吗？** 不需要——用自然语言（或你的母语）即可。
**费用多少？** 应用免费（MIT）。你只需支付提供商费用；正经工作最便宜的是通过 Z.ai/BigModel 使用 GLM-5.1 或 DeepSeek。拥有硬件的话本地模型免费。
**需要什么 Mac？** Apple Silicon，macOS 26.4.1+。云端提供商任何现代 Mac 都行；30B 本地模型需要 64GB+。
**和 Siri 有什么不同？** Siri 回答问题。Agent! *执行操作*——应用、文件、代码、系统。

更多：[docs/FAQ.md](docs/FAQ.md) · [技术架构](docs/TECHNICAL.md) · [对比](docs/COMPARISON.md)（vs Claude Code、Cursor、Cline、OpenClaw）· [安全模型](docs/SECURITY.md)

## 项目背景

Agent! 是三年智能体 AI 应用开发的结晶——ANIE、Game Changer、BattleScript、XCF MCP Server and Client、D1F 以及约八个原创 Swift 包。缺失的一环是智能的自主循环；一旦实现，这些项目的精华便汇聚成了 Agent!。它写过电子游戏（[Boss-Man](https://github.com/AgentiLoop/bossman)）、创建过应用、通过 AppleScript 在 Pages 中写诗、生成磁盘映像并附加到 GitHub Release。Claude Code 依赖约 65 个第三方 NPM 包，而 Agent! 100% 原生、内存占用极低，开箱即带 Xcode 自动化、Swift Syntax 6.2 分析、辅助功能、AppleScript、AgentScript/ScriptingBridge、Safari 自动化和 MCP 支持。

## 参与贡献

见 [CONTRIBUTING.md](./CONTRIBUTING.md)——用 `./build.sh` 约 5 分钟即可从源码构建，无需开发者账户。Pull request 会运行 CI Build & Test 工作流。可查看 [good first issues](https://github.com/AgentiLoop/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)。

## 许可证

MIT —— 免费且开源。

---

> ⚠️ **法律声明与署名**
>
> ### 商标声明
>
> 「AgentiLoop Agent! for Mac」是一个独立的软件项目，**并未**与 Apple Inc. 存在任何关联、认可、赞助或其他形式的关系。「Apple」、「Mac」、「Mac mini」、「MacBook」、「macOS」及相关标志均为 Apple Inc. 在美国及其他国家/地区注册的商标。此处提及的所有其他商标、服务标志和商号均归其各自所有者所有，仅用于标识目的。
>
> 「AgentiLoop Agent!」及 AgentiLoop Agent! 标志均为 AgentiLoop Agent 的商标。使用这些标志需事先获得书面许可。以下的 MIT 许可证仅授予源代码方面的权利——**不**授予任何商标权利。
>
> ### 源代码许可证（MIT）
>
> 「AgentiLoop Agent! for Mac」的源代码是开源的，并采用 **MIT 许可证**授权。你可以自由使用、复制、修改、合并、发布、分发、再许可和/或出售源代码的副本，但须遵守 [LICENSE](./LICENSE) 文件中的条件（在软件的所有副本或实质性部分中保留版权声明及 MIT 许可声明）。
>
> ### 已编译的二进制文件与发布版本
>
> 通过本项目的 GitHub Releases、[AgentiLoop.ai](https://AgentiLoop.ai) 或任何其他官方渠道分发的已编译二进制文件、安装程序、经过代码签名的构建版本以及发布产物，均属 AgentiLoop Agent 拥有版权的作品，**不**受管辖源代码的 MIT 许可证覆盖。官方二进制文件的所有权利——包括「AgentiLoop Agent!」名称、标志、代码签名身份和 Developer ID——均予保留。
>
> Copyright © 2000, 2023–2026 AgentiLoop Agent，保留所有权利。
>
> 你可以在 MIT 许可证下自由地从源代码构建你自己的二进制文件，前提是不使用「AgentiLoop Agent!」名称、标志或品牌来标识你的产品。
>
> ### 免责声明
>
> 本软件按**「原样」**提供，不附带任何形式的明示或暗示担保，包括但不限于对适销性、特定用途适用性和不侵权的担保。在任何情况下，作者或版权持有人均不对因本软件或使用本软件或与之相关的其他交易而产生的任何索赔、损害或其他责任负责，无论是基于合同、侵权行为还是其他原因。
>
> ---
>
> 感谢你对 AgentiLoop Agent! 的关注——这是一款专为运行 macOS 26.4 及以上版本、使用正版 Mac 硬件和软件的 Mac mini、MacBook 以及 Mac Studio 电脑打造的应用程序。
>
> - Website: https://AgentiLoop.ai
> - Github : https://github.com/AgentiLoop/agent
