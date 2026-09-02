# 🦾 AgentiLoop Agent!

## **为你的 Mac 桌面打造的智能体 AI**

[![Latest Release](https://img.shields.io/github/v/release/AgentiLoop/Agent?label=Download&color=blue&style=for-the-badge)](https://github.com/AgentiLoop/Agent/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Stars&color=gold)](https://github.com/AgentiLoop/Agent/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/AgentiLoop/Agent?style=for-the-badge&logo=github&label=Forks&color=white)](https://github.com/AgentiLoop/Agent/fork)
[![macOS 26.4+](https://img.shields.io/badge/macOS-26.4.1-green?style=for-the-badge)](https://github.com/apple)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange?style=for-the-badge)](https://www.swift.org)
<a href="https://www.paypal.com/ncp/payment/9C6RY2UAE5M3S"><img src="https://img.shields.io/badge/Donation-PayPal-00457C?style=for-the-badge&logo=paypal&logoColor=white" alt="Tip Jar" /></a>

## Agent 内置的国际象棋
<img width="1176" height="724" alt="Screenshot 2026-08-23 at 7 34 10 PM" src="https://github.com/user-attachments/assets/d3b2f1e5-1dab-44f7-95f6-008424ee794c" />

## 背后的故事与技术
Agent! 并非一夜之间诞生。它是三年来打造智能体 AI 应用的成果，借鉴了大约十几个在此过程中开发的项目。其中一些曾以 ANIE、Game Changer、BattleScript、XCF MCP Server and Client、D1F 等名义发布，还有大约八个原创的 Swift 包。缺失的那一块拼图是实现一个智能、自主的时间循环。一旦做到这一点，我便把过去三年里最好的成果整合了进来。最终的结果就是适用于 macOS 26.4.1 及更高版本的 Agent!。

最初的目标是打造一个「Cursor 杀手」。而最终诞生的是更有意思的东西：一个真正能「跑起来」的智能体 AI。Agent! 只受限于你的想象力。它能编写代码，包括像 Boss-Man 这样的视频游戏（https://github.com/AgentiLoop/bossman），能创建应用，能通过 AppleScript 在 Pages 中写诗，能生成磁盘映像并将其附加到 GitHub 发布中。它几乎能自动化你 Mac 上的大多数任务。用简单的英语或你的母语告诉它你想要什么，在完成初始配置和用户授权后，它会竭尽全力实现你的愿望。Agent! 不知疲倦，志在取悦。

Agent! 的全部知识产权都是原创且开源的。每一个 Swift 包依赖以及应用本身最初都由同一个人编写。这是一个真正与众不同的生态系统。大多数智能体 AI 应用（比如 Claude Code）依赖 65 个第三方 NPM 包。Agent! 则是 100% 原生的，占用极少的内存，未压缩体积仅为 35.5。这个体积包含了 Xcode 自动化、用于原生应用故障排查的 Swift Syntax 6.2 包、Accessibility、AppleScript、AgentScript/ScriptingBridge、Safari 自动化、MCP 服务器支持等等。开箱即用。

## 新功能 🚀

**v1.0.92 (186) — 自我验证自主性版本** · [完整发布说明 →](https://github.com/AgentiLoop/Agent/releases/tag/v1.0.92.186)

Agent! 现在能证明自己的工作成果。任务只有在成功标准通过证据验证（`goal_state`）后才能被声明完成，一个可选的审核者会在完成前审查差异，且每一个被改动的文件都能一键回滚（`rewind_task`）。为 Claude 提供扩展思考，为兼容 OpenAI 的提供商提供 `reasoning_effort`，以及一个提示词缓存稳定的上下文机制，会压缩到每个模型的真实窗口大小——且可恢复，所有工具结果都会溢出保存到磁盘。类型化的工具错误带有恢复提示，子智能体可以运行各自的模型（最多 6 个只读研究型子智能体），事件钩子已完全接入，57 项通过的测试保证一切诚实可靠。

**一个应用。任意 AI。对你的 Mac 拥有完全掌控权。**

Agent! 将 **18 个 LLM 提供商**——Claude、GPT、Gemini、Grok、Mistral、DeepSeek、Qwen、Z.ai、BigModel、Hugging Face、**OpenRouter**、Ollama（云端和本地）、vLLM、LM Studio、Codestral、Mistral Vibe，以及设备端的 **Apple Intelligence**——整合进一个原生的 macOS 应用中，它不只是「谈论」要做的事情，而是真正把事情做成。

看着它读取你的代码库、修复 bug、构建 Xcode 项目、提交变更，而你只需去泡杯咖啡。让它打开 Safari，把去东京机票的价格发短信告诉你。在房间的另一头说一声 *「Agent!」*，用语音让它运行你的测试套件。从 iMessage 给你的 Mac 发消息，在你走到车边之前就能收到一个精心整理的回复。

它用精确到字符串替换级别的「外科手术式」差异来编辑文件——每一处改动都能通过类似 Time Machine 的回滚一键撤销。它通过 Accessibility API 驱动任何 Mac 应用——无需 AppleScript。它能在多次会话之间记住你的偏好。它能为分支扩展的工作生成并行的子智能体。它能把整个代码库索引为可移植的 JSONL 仓库地图，供任何 LLM 使用。它能以你的身份运行 shell 命令，也能通过一个你只需批准一次的 Launch Daemon 以 root 身份运行命令。

使用你自己的 API 密钥。完全本地运行在 Ollama、vLLM 或 LM Studio 上。或者永久免费地使用 Apple Intelligence。没有订阅。没有遥测。没有供应商锁定。你的密钥，你的机器，你的数据。

下载它。说出你的需求。看着它变为现实。

## 快速开始（下载）

1. **下载** [Agent!](https://github.com/AgentiLoop/Agent/releases/latest) 并拖到「应用程序」中
2. **打开 Agent!** -- 它会自动完成所有设置
3. **选择你的 AI** -- 设置 → 选择一个提供商 → 输入 API 密钥

## 快速开始（从源码构建）

1. **克隆仓库：**
   ```bash
   git clone https://github.com/AgentiLoop/agent.git
   cd Agent
   ```

#### 方式 A：使用 Xcode 构建（需要 Apple Developer 账户）
2. **在 Xcode 中打开 `Agent.xcodeproj`。**
3. **构建并运行 `Agent` target。**
4. **批准辅助工具：** 系统提示时，授权特权守护进程以允许执行 root 级别的命令。

#### 方式 B：无需 Apple Developer 账户构建
2. **运行构建脚本**（只需要 Xcode Command Line Tools）：
   ```bash
   ./build.sh              # Debug 构建
   ./build.sh Release      # Release 构建
   ```
3. 应用会生成在 `build/DerivedData/Build/Products/Debug/Agent!.app`
4. **运行它：** `open "build/DerivedData/Build/Products/Debug/Agent!.app"`

> ⚠️ 没有开发者账户时，应用会以 ad-hoc 方式签名。Launch Agent/Daemon 辅助进程将无法注册（SMAppService 需要 Team ID），但 LLM 循环、所有工具、Accessibility、AppleScript、shell 和 MCP 均可正常工作。

#### 然后：
5. **配置你的 AI 提供商：** 前往设置，输入你的 API 密钥，或选择像 Ollama 这样的本地提供商。

> 💡 **经济实惠的 GLM 配置：** **GLM-5.1** 可在全部四个经济型提供商上运行——**Ollama**、**Hugging Face**、**Z.ai**、**BigModel**——每百万 token 只需几分钱。新手上路？从 **Z.ai** 开始（注册最快，GLM-5.1 是默认模型，无需额外配置）。想本地运行？只有 **GLM-4.7-Turbo**（32B）能装进消费级硬件（M2/M3/M4 Mac，64-128GB，通过 Ollama）——GLM-5 和 GLM-5.1 体积太大（约 1.6TB），请通过上述云端提供商使用它们。


## 它能做什么？

> *「在 Music 中播放我的 Workout 歌单」*
> *「构建 Xcode 项目并修复所有错误」*
> *「用 Photo Booth 拍张照片」*
> *「给妈妈发 iMessage，说我 6 点到家」*
> *「打开 Safari 搜索去东京的航班」*
> *「把这个类重构成更小的文件」*
> *「我今天的日历上有哪些事件？」*

只需输入你想要的东西。Agent! 会想出办法并把它实现。

---

## 主要功能

### 🧠 智能体 AI 框架
内置的自主任务循环，具备推理、执行和自我纠错能力。Agent! 不只是运行代码；它会观察结果、调试错误并不断迭代，直到任务完成。带有证据验证成功标准的目标状态意味着，任务只有在证明自己确实完成后，才能被声明为完成。

### 🛠 智能体编程
内置完整的编程环境。可读取代码库、精确编辑文件、执行 shell 命令、构建 Xcode 项目、管理 git，并自动启用编码模式，让 AI 专注于开发工具。可替代 Claude Code、Cursor 和 Cline——无需终端，无需 IDE 插件，无需月费。具备**类似 Time Machine 的备份**功能，针对每一次文件改动，可让你即时撤销任何编辑。

### 🔍 动态工具发现
根据你的指令自动检测并使用可用工具（Xcode、Playwright、Shell 等）。核心工具无需手动配置。

### 🛡 特权执行
通过专用的 macOS Launch Daemon 安全地执行 root 级别命令。用户只需批准一次该守护进程，之后智能体便可通过 XPC 自主执行命令。

#### 为什么 XPC 监听器上没有手动的 `setCodeSigningRequirement`

用户有时会问，为什么 `AgentHelper` 的 XPC 监听器在接受连接时没有手动调用 `connection.setCodeSigningRequirement(...)` 进行检查。简短的回答是：**SMAppService 已经在你代码的下一层强制执行了签名身份**，因此这项检查是多余的。

这个建议是 SMAppService 出现之前、**SMJobBless** 时代遗留下来的老做法，那时 launchd 并不会替你验证身份，XPC 服务器必须自己设置指定的要求字符串。SMAppService 改变了这一约定：

- 嵌入在应用包中的 plist 加上签名门控的注册机制，**本身就是**代码签名要求。
- Mach 服务名称（`Agent.app.redacted.helper`、`Agent.app.redacted.user`）与注册它们的已签名包绑定——任何其他包都无法冒充。
- 任何签名不匹配（篡改、重新签名、不同的 Team ID、包替换）都会**在 launchd 层直接中断 XPC 通道**——`listener(_:shouldAcceptNewConnection:)` 甚至根本不会被调用。

**实证：** Agent! 自身曾在一次实验中尝试重新签名自己的守护进程，结果立即失去了连接能力。`NSXPCConnection` 到两个 Mach 服务的连接均在 launchd 层就失败了，甚至没有一个字节到达监听器代理——这正是手动调用 `setCodeSigningRequirement` 所要强制实现的效果，只不过 SMAppService 是在内核的 XPC 查找路径中完成的，用户空间无法绕过。

| 强制机制 | 实现方式 | 是否可从用户空间绕过？ |
|---|---|---|
| 辅助程序必须位于已签名的应用包内 | Gatekeeper + SMAppService 注册 | 否 |
| 辅助程序必须匹配应用的 Team ID（469UCUB275） | 代码签名 + SMAppService | 否 |
| Mach 服务名称绑定到已签名的包 | launchd / XPC 命名空间 | 否 |
| 辅助程序二进制文件哈希与已注册身份匹配 | SMAppService + 内核 XPC 查找 | 否（重新签名会中断通道） |
| 用户已批准该辅助程序 | 系统设置 → 登录项与扩展 | 否（需要用户手势） |

显式添加 `setCodeSigningRequirement` 会是一种合理的纵深防御补充（仅在应用未来某天迁移出 SMAppService，或 SIP 被禁用的情况下有用），但在当前架构中它**并不是漏洞**。完整的信任锚说明请参见 [docs/SECURITY.md](docs/SECURITY.md)。

### 🖥 桌面自动化（AXorcist）
通过 Accessibility API 控制任何 Mac 应用。点击按钮、在字段中输入、浏览菜单、滚动、拖拽——全部以编程方式完成。由 [AXorcist](https://github.com/steipete/AXorcist) 提供支持，实现可靠且支持模糊匹配的元素查找。

### 🤖 18 个 AI 提供商

提供商选择器（LLM 设置，工具栏按钮 #7）显示 17 个提供商；Apple Intelligence 通过单独的大脑图标（#8）访问。信息来源：`AgentTools.APIProvider`。

| 提供商 | API 密钥 | 最适合 |
|---|---|---|
| **Claude**（Anthropic） | 付费 | 长时间自主任务、复杂推理、提示词缓存 |
| **OpenAI** | 付费 | 通用用途、工具调用、视觉 |
| **Google Gemini** | 付费（有免费层） | 长上下文、视觉、速度快 |
| **Grok**（xAI） | 付费 | 实时信息 |
| **Mistral** | 付费 | 开放权重云端服务、快速工具调用 |
| **Codestral**（Mistral） | 付费 | 专注代码的 Mistral |
| **Mistral Vibe** | 付费 | Mistral 的聊天/智能体产品 |
| **DeepSeek** | 经济实惠 | 经济型云服务，编程能力强，支持提示词缓存命中报告 |
| **Hugging Face** | 视情况而定 | 无服务器托管或专用端点上的开源模型 |
| **OpenRouter** | 付费 | 通过一个 API 密钥调用 200+ 个模型——Claude、GPT、Gemini、Llama、Mistral 等等。智能协议切换会将 Claude 模型通过 Anthropic 协议路由，其余模型通过 OpenAI 协议路由 |
| **Z.ai** | 经济实惠 | 通过 API 使用 GLM-5.1——推荐的入门起点 |
| **BigModel**（智谱） | 经济实惠 | 通过智谱 API 使用的 GLM 系列 |
| **Qwen**（阿里巴巴） | 经济实惠 | 通过 Dashscope 使用的 Qwen 2.5 / 3 |
| **Ollama**（云端） | 免费层 | 通过 Ollama 的托管端点运行开放模型 |
| **本地 Ollama** | 免费 + 硬件 | 自托管的 Ollama 守护进程——完全离线，无需账户 |
| **vLLM** | 免费 + 硬件 | 带前缀缓存的自托管 vLLM 服务器 |
| **LM Studio** | 免费 + 硬件 | 自托管，本地模型最简单的 GUI |
| **Apple Intelligence** | 免费，设备端 | 分流、摘要、token 压缩（通过大脑图标访问，而非提供商选择器） |

> 💡 **自托管的「免费」提供商（本地 Ollama、vLLM、LM Studio）只是在 API 费用意义上是免费的。** 以可用速度运行 30B 以上的模型需要 M2/M3/M4 Ultra Mac Studio（64-128GB 统一内存）或配备 24GB 以上显存的 Linux 主机。如果你还没有这样的硬件，上述云端方案（Ollama Cloud、Hugging Face、Z.ai、BigModel、DeepSeek）会比购买硬件便宜得多。

## 工具栏按钮

Agent! 的顶部标题栏包含 **15 个按钮**，可快速访问设置、监视器和工具。每个按钮点击后会弹出一个悬浮窗。信息来源：`Agent/Views/HeaderSectionView.swift`。

| # | 图标 | 名称 | 功能 |
|---|------|------|--------------|
| 1 | ⚙️ | **服务** | 切换 Launch Agent / Launch Daemon、管理项目文件夹、扫描命令输出 |
| 2 | 💬 | **消息监视器** | 开启/关闭 iMessage 监听——激活时显示绿色。打开收件人列表和审批界面 |
| 3 | ✋ | **辅助功能** | 打开辅助功能设置面板（权限状态、axorcist 诊断信息） |
| 4 | 🖥️ | **MCP 服务器** | 添加/移除/配置 MCP（模型上下文协议）服务器——为 Agent! 扩展 `mcp_*` 工具 |
| 5 | </> | **编程偏好设置** | 切换自动验证、可视化测试、自动 PR、自动脚手架。任一开启时显示绿色 |
| 6 | 🔧 | **工具** | 按提供商分类的工具开关。可启用/禁用内置及 MCP 的单个工具 |
| 7 | 🧠 | **LLM 设置** | 选择 AI 提供商、模型、API 密钥、基础 URL。任务运行时会有脉冲效果 |
| 8 | 🧬 | **Apple Intelligence** | 配置 FoundationModels（设备端 Apple AI）。可用时会填充显示 |
| 9 | 🎛️ | **智能体选项** | 温度、最大迭代次数、视觉自动截图、计划模式提示等 |
| 10 | 🔄 | **备用链** | 配置提供商备用顺序——某个提供商失败时，Agent! 会自动重试下一个提供商 |
| 11 | 🔲 | **HUD** | 在 LLM 输出视图上切换绿色 CRT 扫描线叠加效果 |
| 12 | 📊 | **LLM 使用情况** | 按模型追踪 token 使用量和费用。有使用记录时显示绿色 |
| 13 | ↩️ | **回滚** | 类似 Time Machine 的文件备份浏览器。可恢复 Agent! 编辑过的任何文件的任意早期版本 |
| 14 | 🕐 | **历史记录** | 当前标签页的过往指令、错误和任务摘要。一键重新运行之前的指令 |
| 15 | 🗑️ | **清除日志** | 删除当前标签页的活动日志（若未选中任何标签页，则清除全部任务历史）。会先要求确认 |

---

### 🎙 语音控制 —— 「Agent!」唤醒词
**通过 `SFSpeechRecognizer` 实现的唤醒词锚定听写功能。** 点击输入栏中的麦克风以启动唤醒词会话，然后说出 **「Agent!」**，接着说出你的任务。转录在设备端实时进行，并会将「agent」识别为一个完整单词（而非「intelligent」或「management」中的子字符串）。在唤醒词之后所说的一切都会成为任务——在约 2.5 秒的静默之后，任务会自动执行。会话会自动循环：一个任务完成后，它会重新开始监听。点击麦克风即可停止。

### 📱 通过 iMessage 远程控制
从你的 iPhone 给你的 Mac 发短信：
```
Agent! 现在在播放什么歌？
Agent! 检查我的邮件
Agent! 下一首歌
```
你的 Mac 会执行任务，并通过短信把结果发给你。只有获得批准的联系人才能发送命令。

### 🌐 网页自动化
免动手操控 Safari——搜索 Google、点击链接、填写表单、读取页面、提取信息。

### 📋 智能规划
对于复杂任务，Agent! 会创建一个分步计划，逐步执行，并实时勾选完成情况。

### 🗂 标签页
可同时处理多个任务。每个标签页都有自己独立的项目文件夹和对话历史。

### 📸 截图与视觉
可截图或粘贴图片。具备视觉能力的 AI 模型会分析看到的内容——描述内容、读取文字、发现界面问题。

### 🌐 Safari 网页自动化（内置）

Agent! 内置通过 JavaScript 和 AppleScript 实现的 Safari 网页自动化。可搜索 Google、点击链接、填写表单、读取页面内容、执行 JavaScript——全部免动手完成。

**启用方法：** 打开 Safari → 设置 → 高级 → 勾选「显示网页开发者功能」。然后进入「开发」菜单 → 勾选「允许来自 Apple 事件的 JavaScript」。

### 🎭 Playwright 网页自动化（可选）

通过 [Microsoft Playwright MCP](https://github.com/microsoft/playwright-mcp) 实现完整的跨浏览器自动化。可在 Chrome、Firefox 或 WebKit 中点击、输入、截图和导航任何网站——全部由 AI 控制。

**设置（一次性）：**

```bash
# 1. 安装 Node.js（如果尚未安装）
brew install node

# 2. 全局安装 Playwright MCP 服务器
npm install -g @playwright/mcp@latest

# 3. 安装浏览器二进制文件（选择一个或全部）
npx playwright install chromium          # Chrome (~165MB)
npx playwright install firefox           # Firefox (~97MB)
npx playwright install webkit            # Safari/WebKit (~75MB)
npx playwright install                   # 所有浏览器
```

**在 Agent! 中配置：**

前往 设置 → MCP 服务器 → 添加服务器，粘贴以下 JSON：

```json
{
    "mcpServers": {
        "playwright": {
            "command": "npx",
            "args": ["@playwright/mcp"],
            "transport": "stdio"
        }
    }
}
```

> **注意：** 如果找不到 `npx`，请使用完整路径：在终端中运行 `which npx`，并将 `"npx"` 替换为其结果（例如 `"/opt/homebrew/bin/npx"`）。

开启后，Playwright 工具会自动出现。AI 现在可以直接控制浏览器。

### 工具 —— `list_tools` 实际返回的内容

以下是定义在 `AgentTools.Name.*` 中并通过 `AgentTools.tools(for:)` 暴露给每个 LLM 提供商的规范工具名称。信息来源：`~/Documents/GitHub/AgentTools/Sources/AgentTools/AgentTools.swift`。应用中的用户偏好开关可以按提供商隐藏某些单独的工具，但下面的列表是 LLM 能看到的完整工具集。

#### 核心 / 发现

| 工具 | 操作 / 参数 | 功能 |
|---|---|---|
| **done** | `summary` | 表示任务已完成。每个任务结束时必须调用 |
| **list_tools** | — | 返回当前提供商可用的实时工具列表（内置 + MCP） |
| **search** | `query` | 通过 Exa、Tavily 或 DuckDuckGo（视配置的密钥而定）进行网页搜索 |
| **chat** | `write` / `transform` / `fix` / `about` | 撰写文章、转换/修正文本、描述 Agent 的能力 |
| **memory** | `read` / `write` / `append` / `clear` | 持久化的用户偏好设置。「记住 X」→ `append` |
| **plan** | `create` / `update` / `read` / `list` / `delete` | 支持多计划增删改查，并按步骤追踪状态 |
| **goal_state** | `set` / `get` / `mark` / `clear` | 持久化的目标 + 成功标准；标记完成需要提供证据 |
| **restore_tool_result** | `tool_use_id` | 恢复因压缩而被截断的工具结果的完整文本 |
| **directory** | `get` / `set` / `home` / `documents` / `library` / `none` / `cd` | 当前标签页的项目文件夹 |
| **fetch** | `url` | 获取 URL，去除 HTML，上限 8K 字符 |
| **skill** | `list` / `invoke` / `save` / `delete` | 可复用的提示词模板 |
| **ask_user** | `question` | 任务过程中与用户对话（最多等待 5 分钟） |

#### 代码 / 文件 / 构建

| 工具 | 操作 / 参数 | 功能 |
|---|---|---|
| **file** | `read` / `write` / `edit` / `create` / `apply` / `undo` / `diff_apply` / `list` / `search` / `read_dir` / `mkdir` / `cd` / `if_to_switch` / `extract_function` | 所有文件操作。`edit` = 单字符串替换。`diff_apply` = 用于多行代码编辑的首选方式 |
| **git** | `status` / `diff` / `log` / `commit` / `diff_patch` / `branch` / `worktree` | Git 操作——应使用此工具，而非 shell git |
| **xcode** | `build` / `run` / `list_projects` / `select_project` / `add_file` / `remove_file` / `grant_permission` / `analyze` / `snippet` / `code_review` / `get_version` / `bump_version` / `bump_build` | 原生 Xcode 集成。活动日志中的错误可点击 |
| **agent_script** | `list` / `read` / `create` / `update` / `edit` / `run` / `delete` / `combine` / `restore` / `pull` / `list_backups` | 位于 `~/Documents/AgentScript/agents/` 的 Swift dylib 脚本，具备完整 TCC 权限 |

#### Shell / 权限层级

| 工具 | 参数 | 功能 |
|---|---|---|
| **user_shell** | `command` | 通过 Launch Agent 以当前用户身份运行 shell。主要的 shell 工具 |
| **root_shell** | `command` | 通过 Launch Daemon 以 ROOT 身份运行 shell。仅用于管理任务——不使用 sudo |
| **shell** | `command` | 进程内的备用 shell（Launch Agent 关闭时使用） |
| **batch** | `commands` | 在一次调用中执行多条 shell 命令（以换行分隔） |
| **multi** | `description`, `tasks` | 在一个批次中执行多个工具调用 |

#### macOS 自动化

| 工具 | 操作 / 参数 | 功能 |
|---|---|---|
| **accessibility** | `open_app` / `find_element` / `click_element` / `type_into_element` / `scroll_to_element` / `list_windows` / `inspect_element` / `get_properties` / `perform_action` / `set_properties` / `get_focused_element` / `get_children` / `read_focused` / `wait_for_element` / `wait_adaptive` / `highlight_element` / `manage_app` / `show_menu` / `click_menu_item` / `set_window_frame` / `get_window_frame` / `screenshot` / `check_permission` / `request_permission` / `get_audit_log` | 基于元素的 AXorcist 自动化。每个操作都接受 `role`+`title`+`appBundleId`——无需坐标 |
| **applescript** | `execute` / `lookup_sdef` / `list` / `run` / `save` / `delete` | 进程内运行的 NSAppleScript，带 TCC 权限 |
| **javascript** | `execute` / `list` / `run` / `save` / `delete` | JXA（用于自动化的 JavaScript） |

#### 网页自动化

| 工具 | 操作 / 参数 | 功能 |
|---|---|---|
| **safari** | `open` / `find` / `click` / `type` / `execute_js` / `get_url` / `get_title` / `read_content` / `google_search` / `scroll_to` / `select` / `submit` / `navigate` / `list_tabs` / `switch_tab` / `list_windows` / `scan` / `search` | 通过 JavaScript + AppleScript 实现的 Safari 自动化 |
| **selenium** | `start` / `stop` / `navigate` / `find` / `click` / `type` / `execute` / `screenshot` / `wait` | Selenium WebDriver 会话——正常使用 Safari 时请用 `safari` |
| **mcp_playwright_browser_\*** | （见 Playwright MCP） | 可选。通过 Playwright MCP 实现的跨浏览器自动化 |

#### 子智能体

| 工具 | 参数 | 功能 |
|---|---|---|
| **spawn_agent** | `name`、`prompt`、`tools`、`model`、`max_iterations` | 生成一个隔离的子智能体。最多 3 个并发（其中最多 6 个为只读）。可选的模型覆盖 + 基于文件的结果 |
| **tell_agent** | `to`、`message` | 向正在运行的子智能体的消息箱发送消息 |

> 💡 **注意：** 设备端应用会按提供商过滤此列表——可在**工具**弹出面板（上方工具栏中的 #6 按钮）中切换单个工具。由于上下文窗口较小，Apple Intelligence 有自己独立的最小默认工具集。MCP 工具会在运行时以 `mcp_<服务器>_<工具>` 的形式追加，并由 `list_tools` 列在「--- MCP Tools ---」下方。

## 隐私与安全

- **你的数据留在你的 Mac 上。** 文件、屏幕内容和个人数据永远不会被上传。
- **云端 AI 只能看到你的提示词文本。** 使用本地 AI 可实现 100% 离线。
- **一切尽在你的掌控。** Agent! 会展示它所做的一切，并记录每一个操作。
- **构建于苹果的安全模型之上。** macOS 权限系统保护你的系统安全。

### 防御层级

| 层级 | 功能 |
|---|---|
| **Shell 安全服务** | 在 Process 被构造之前，就严格阻止灾难性命令（`rm -rf /`、`rm -rf ~`、指向 `/dev/disk` 的 `dd`、fork bomb、`--no-preserve-root`）。LLM 无法绕过此机制。 |
| **TCC 进程内路由** | 一个包含 17 个关键词的检测器会将 AppleScript、osascript、JXA、screencapture、accessibility、Shortcuts 和 ScriptingBridge 命令路由到进程内运行，在该进程中 Agent! 持有 TCC 授权——绝不会通过 Launch Agent/Daemon 运行（不同的包标识符意味着没有 TCC 权限）。 |
| **每次编辑都进行文件备份** | `FileBackupService` 会在执行 `write_file`、`edit_file` 和 `diff_apply` 之前自动为每个文件创建快照。可通过 `file(action:"restore")` 或回滚界面恢复。存活时间为 1 周。 |
| **Agent Script 回收站** | `delete_agent` 会在删除脚本前将其复制到 `~/Documents/AgentScript/agents/.Trash/`。可通过 `agent_script(action:"restore")` 恢复。 |
| **工作目录规范化** | 每一条 shell 执行路径（`executeTCC`、`UserService`、`HelperService`）都会对工作目录进行规范化——如果不小心把文件路径当作 cwd 传入，会被裁剪为父目录，而不是以「Not a directory」崩溃。 |
| **启动新任务前先排空旧任务** | 启动新任务前，会先等待上一个任务完全终止——防止孤立的重试循环在不同提供商之间混淆日志输出。 |
| **备用链** | 当主 LLM 失败（429、超时、网络问题）时，在连续 2 次失败后，Agent! 会自动切换到用户配置的备用链中的下一个提供商。 |
| **可操作的错误信息** | 每个工具错误都包含一个 `Recovery:` 提示，明确告诉 LLM 接下来该尝试什么——不会有让回合白白浪费的死胡同式错误信息。 |
| **读缓存失效机制** | 无论编辑成功还是失败，文件读取缓存都会失效，因此 LLM 在下次读取时总能获得最新内容。 |
| **基础文件名搜索** | 当 `read_file` 或 `edit_file` 收到错误路径时，Agent! 会在附近的目录中搜索同名文件，并在结果中直接返回正确路径——LLM 可在一个回合内自我纠正。 |
| **工具执行门控** | LLM 无法伪造工具结果。所有工具调用都要经过应用的 `dispatchTool()` → 实际执行（XPC、shell、进程内）→ 以 `tool_result` 形式返回的真实输出。LLM 只能看到并总结真实发生过的输出。如果某个工具失败，会返回真实的错误——LLM 无法在没有匹配执行事件的情况下宣称成功。 |
| **action_not_performed** | 针对虚假操作声明的双层防御机制：**（1）提示词层面** —— 系统提示词会指示 LLM，如果本回合没有调用任何工具，就应该说「操作未执行」。**（2）应用层面** —— 如果 LLM 返回的文本声称「我已经搜索/打开/点击」，但该回合实际上没有进行任何工具调用，系统会插入一条纠正指令，强制它使用真实的工具。 |

---

## 键盘快捷键

信息来源：`Agent/Views/InputSectionView.swift` 中 TextField 的 `.onSubmit`（对应 `Return`），以及 `Agent/Views/ContentView.swift` 中内联的 `NSEvent.addLocalMonitorForEvents` 代码块（对应其余快捷键）。

| 快捷键 | 操作 |
|---|---|
| `Return` | 运行当前任务（TextField 提交——无需修饰键） |
| `⌘ .` / `Escape` | 取消正在运行的任务 |
| `⌘ B` | 切换 LLM 输出叠加层（显示/隐藏） |
| `⌘ D` | 切换当前标签页上的两个 LLM 折叠箭头（展开/折叠） |
| `⌘ T` | 新建标签页 |
| `⌘ W` | 关闭当前标签页（若没有标签页则退出） |
| `⌘ 1`–`⌘ 9` | 切换标签页。`⌘1` 是主标签页；`⌘2`–`⌘9` 是脚本标签页 |
| `⌘ Shift ←` / `⌘ Shift →` | 上一个 / 下一个标签页 |
| `⌘ F` | 切换活动日志搜索栏 |
| `⌘ L` | 清除当前标签页的日志 |
| `⌘ V` | 从剪贴板粘贴图片 |
| `↑` / `↓` | 提示词历史记录（在输入框中） |
| `⌘ Shift M` | 开启/关闭消息监视器 |
| `⌘ Shift P` | 打开设置（系统提示词编辑器就在此处） |
| `⌘ Shift K` | 清除全部（完全重置） |
| `⌘ Shift L` | 仅清除 LLM 输出面板 |
| `⌘ Shift H` | 清除提示词历史记录 |
| `⌘ Shift J` | 清除任务历史记录 |
| `⌘ Shift U` | 清除 token 计数器 |

## 斜杠命令

在输入框中输入以下内容并按 Return——它们会在本地执行，不会发送给任何 LLM。信息来源：`AgentViewModel+RunStop.swift`。

| 命令 | 操作 |
|---|---|
| `/clear` 或 `/clear log` | 清除当前标签页的活动日志 |
| `/clear all` | 清除全部内容（日志、LLM 输出、提示词历史、任务历史、token） |
| `/clear llm` | 仅清除 LLM 输出面板 |
| `/clear history` | 清除提示词历史记录 |
| `/clear tasks` | 清除任务历史记录 |
| `/clear tokens` | 重置 token 计数器（任务级 + 会话级） |
| `/memory` 或 `/memory show` | 在活动日志中打印当前记忆文件的内容 |
| `/memory clear` | 清空记忆 |
| `/memory edit` | 在系统默认编辑器中打开 `~/Documents/AgentScript/memory.md` |
| `/memory <文本>` | 将 `<文本>` 追加到记忆中（`/memory` 之后的所有内容都会成为新的一行） |

---

## 常见问题

**我需要会编程吗？** 不需要。只需用简单的英语输入你想要的内容即可。

**它安全吗？** 是的。标准的 macOS 自动化，完整的活动日志记录，权限均由你本人批准。

**它要花多少钱？** Agent! 应用本身是免费的（MIT 许可证）。云端 AI 提供商会按 API 使用量收费——对于正式工作来说，最经济的选择是通过 Z.ai、BigModel 或 Hugging Face 使用 GLM-5/5.1（每百万 token 只需几分钱），或者使用 DeepSeek 进行经济型编程。自托管的本地模型（Ollama、vLLM、LM Studio）没有 API 费用，但只有在你已经拥有运行它们所需的硬件时才划算——参见下方的硬件说明。

**我需要什么样的 Mac？** macOS 26.4.1。需要 Apple Silicon。对于云端提供商，任何现代 Mac 都能良好运行。对于自托管的本地模型（Ollama、vLLM、LM Studio）：7B 模型需要 16GB 统一内存，13B 模型需要 24GB，30B 模型需要 64GB 以上（属于 M2/M3/M4 Ultra Mac Studio 的范畴）。Apple Intelligence（负责分流/token 压缩的设备端中介）需要一台开启了 Apple Intelligence（在系统设置中）的 Apple Silicon Mac。

**它和 Siri 有什么不同？** Siri 负责回答问题。Agent! 则*执行操作*——控制应用、管理文件、构建代码、自动化工作流程。

---

## 文档

- [技术架构](docs/TECHNICAL.md) -- 工具、脚本编写、开发者细节
- [对比](docs/COMPARISON.md) -- 与 Claude Code、Cursor、Cline、OpenClaw 的对比
- [安全模型](docs/SECURITY.md) -- XPC 架构、权限分离
- [常见问题](docs/FAQ.md) -- 常见问题解答

---

## 内置 Xcode 工具

Agent! 包含无需任何 MCP 服务器配置即可使用的原生 Xcode 集成。这些内置工具通常比 MCP 替代方案更快、更可靠，因为它们直接在应用内部运行。

| 工具 | 功能 |
|---|---|
| **xcode build** | 构建当前的 Xcode 项目，捕获错误和警告。活动日志中的错误**可点击**，可直接在 Xcode 中打开。 |
| **xcode run** | 构建并运行应用 |
| **xcode list_projects** | 发现已打开的 Xcode 工作区和项目 |
| **xcode select_project** | 切换当前活动项目 |
| **xcode grant_permission** | 授予对 Xcode 项目文件夹的文件访问权限 |
| **xcode get_version** | 从 Xcode 项目中读取当前的营销版本号和构建号 |
| **xcode bump_version** | 提升营销版本号（主版本、次版本或补丁版本），更新构建号，构建以验证，并自动提交 |
| **xcode bump_build** | 仅递增构建号 |

只需说一声 *「提升版本号」*，Agent! 就会读取当前版本，询问是主版本/次版本/补丁版本，更新 Info.plist 和项目设置，构建以验证，然后提交变更。无需手动编辑 plist，也不会漏掉构建号。

当你要求它构建、修复错误或处理 Xcode 项目时，AI 会自动使用这些工具。无需任何配置——只需在 Xcode 中打开你的项目即可。

> 🚀 **iOS/iPadOS 支持：** 即将推出！直接从 Agent! 构建、运行和测试 iOS 及 iPadOS 应用的原生支持正在开发中。

> **提示：** 对于大多数编程工作流程，内置工具已经足够。下方的 MCP Xcode 服务器会额外提供 SwiftUI Preview 渲染和文档搜索等功能。


---

<img width="1349" height="1438" alt="Screenshot 2026-04-02 at 12 00 03 PM" src="https://github.com/user-attachments/assets/b0d9346e-f807-4089-bab3-29c7058868d8" />

## 两种与 Agent! 对话的方式 —— 语音和 iMessage

两种功能使用相同的唤醒词：**「Agent!」**（不区分大小写——`Agent!`、`agent!`、`AGENT!`，甚至只输入 `Agent ` 或 `agent ` 也都可以）。

### 🎤 语音（听写唤醒词）

点击输入栏中的麦克风，启动唤醒词会话，然后开始说话。Agent! 使用 `SFSpeechRecognizer` 实时转录，并将「agent」识别为一个完整单词（而非「intelligent」或「management」中的子字符串）。你在「agent」之后所说的一切都会成为任务。在约 2.5 秒的静默之后，任务会自动执行。

示例：
- *「Agent，现在在播放什么歌？」*
- *「Agent，给 Safari 截个图」*
- *「Agent，构建 Xcode 项目」*

唤醒词会话会自动循环——一个任务完成后，它会重新开始监听。再次点击麦克风即可停止。

### 📱 iMessage（远程控制）

从你的 iPhone 给你的 Mac 发短信。Agent! 每 5 秒会轮询一次 `~/Library/Messages/chat.db` 以获取新消息，并对任何以 **`Agent!`** 开头的消息作出响应（不区分大小写，感叹号可选）。

示例：
```
Agent! 现在在播放什么歌？
agent! 检查我的邮件
AGENT! 下一首歌
Agent  打开 Safari
```

Agent! 会立即发送一条「正在处理中……」的确认消息，使用你主标签页的 LLM 配置，在专用的 Messages 标签页中执行任务，然后通过短信将结果发回给你。

**设置（一次性）：**

1. **授予「完全磁盘访问权限」** —— 系统设置 → 隐私与安全性 → 完全磁盘访问权限 → 启用 Agent!（直接通过 SQLite 读取 `chat.db` 需要此权限）
2. **打开消息监视器** —— 工具栏按钮 #2（聊天气泡图标，开启时会变绿）
3. **批准发送者** —— 当来自新联系人的消息到达时，该联系人会出现在收件人列表中。打开开关即可批准。

只有获得批准的发送者才能执行任务。未获批准的消息会被记录但会被忽略。你的回复会通过 AppleScript 发送回发送该命令的同一个句柄，上限为 4000 个字符。

发出的回复中会去除开头的「Agent!」，以免接收方的 Mac 触发自己的命令循环。

---

Agent! 支持 [MCP](https://modelcontextprotocol.io) 服务器以扩展功能。可在 设置 → MCP 服务器 中进行配置。

### Xcode MCP 服务器

将 Agent! 直接连接到 Xcode，以进行了解项目上下文的操作：

```json
{
  "mcpServers" : {
    "xcode" : {
      "command" : "xcrun",
      "args" : [
        "mcpbridge"
      ],
      "transport" : "stdio"
    }
  }
}
```

**Xcode MCP 提供：**
- 了解项目上下文的文件操作（读取/写入/编辑/删除）
- 构建与测试集成
- SwiftUI Preview 渲染
- 代码片段执行
- Apple 开发者文档搜索
- 实时问题追踪


---

## 许可证

MIT —— 自由且开源。

---

<div align="center">

### **Agent! —— 为你的 Mac 桌面打造的智能体 AI，适用于 macOS 26.4.1**
> 说明：Claude 指的是集成在 Agent! 中用于提供 LLM 功能的 Anthropic AI 模型。它不是 Agent! 的人类贡献者。
</div>

---

## Agent! 与 Claude Code 的架构对比

Agent! 是一个 100% 原创的纯 Swift macOS 应用程序。它不是任何其他项目的移植版本、分支或衍生作品。

| | Claude Code | Agent! |
|---|---|---|
| **语言** | TypeScript/JavaScript | 纯 Swift 6.2 |
| **UI 框架** | Ink（终端版 React） | SwiftUI（原生 macOS） |
| **平台** | CLI —— Linux、macOS、Windows | 仅原生 macOS 26.4.1 |
| **运行时** | Node.js/Bun | 原生编译二进制文件 |
| **架构** | 带流式输出的终端 REPL | 带 XPC 守护进程的桌面应用 |
| **辅助功能** | 无（CLI） | 通过 AXorcist 实现完整的 macOS AX 支持（25 个顶层操作，通过 `perform_action` 支持 30 多种 AX 子类型） |
| **AppleScript** | 无 | 进程内完整支持 NSAppleScript + JXA，带 TCC 权限 |
| **Xcode 集成** | 通过 Bash（`xcodebuild`） | 原生集成（build/run/analyze/snippet/add_file/bump_version/code_review —— 共 13 种操作） |
| **Apple Intelligence** | 无 | 设备端 FoundationModels —— 负责问候/闲聊分流、任务摘要、错误解释以及第一级 token 压缩。UI 自动化由主 LLM 通过 `accessibility` 工具处理，而非由 Apple AI 处理 |
| **ScriptingBridge** | 无 | 完整的 SDEF + 51 个事件桥（Finder、Mail、Music、Safari、Calendar 等） |
| **视觉** | 通过 API 输入图像 | 通过 API 输入图像 |
| **自动截图** | 无（没有 UI） | UI 操作后可选的自动验证（默认关闭——参见 `visionAutoScreenshotEnabled`） |
| **iMessage** | 无 | 通过 Messages 实现远程智能体（读取 `chat.db` 需要完全磁盘访问权限） |
| **语音** | 无 | 通过 SFSpeechRecognizer 实现的唤醒词锚定听写 |
| **CRT 效果** | 无 | 可选的 SwiftUI Canvas 扫描线叠加效果（通过 HUD 按钮切换） |
| **权限模型** | 用户沙盒 | XPC Launch Agent（用户）+ Launch Daemon（root） |
| **子智能体** | Task 工具（已公开文档化；Anthropic 未说明实现细节） | 最多 3 个并发（其中 6 个只读）的隔离智能体，支持消息箱通信以及按智能体覆盖模型 |
| **MCP** | Node.js stdio/SSE | Swift AgentMCP 包 |
| **脚本** | 无 | 运行时编译 Swift dylib，进程内以 dlopen 加载，带完整 TCC 权限 |
| **提示词缓存** | Anthropic 的临时性 `cache_control` | Anthropic 的临时性 `cache_control` + 针对 OpenAI/Z.ai/Grok/Mistral/Gemini/Qwen/DeepSeek 的自动前缀缓存命中追踪；Ollama 的 `keep_alive: 30m` |
| **上下文压缩** | 云端 Claude（付费 token；对话会重新发送给 Anthropic） | 分层处理：第一级 = 设备端 Apple Intelligence 摘要（免费、私密、不消耗 API token）。第二级 = 若 Apple AI 不可用，则进行激进裁剪。阈值会随模型上下文窗口大小而变化（约 55%，2K–400K），摘要会被记忆化处理，具备 3 次失败熔断机制，截断前会先将完整的工具结果溢出保存到磁盘 |

## Agent! 与 Cursor 的快速对比

Cursor 是一款出色的 AI 代码编辑器。Agent! 玩的是另一种游戏：它是为你**整台 Mac** 服务的智能体，而不仅仅是你的代码库。

| | Cursor | Agent! |
|---|---|---|
| **它是什么** | AI 代码编辑器（VS Code 分支，基于 Electron） | 原生 SwiftUI macOS 智能体应用 |
| **范围** | 你的代码库 | 你整台 Mac —— 代码、应用、文件、系统 |
| **定价** | 订阅制 | 免费且开源（MIT）——使用你自己的 API 密钥或本地运行 |
| **本地模型** | 以云端为主 | Ollama、vLLM、LM Studio、设备端 Apple Intelligence |
| **Mac 应用自动化** | 无 | Accessibility API、AppleScript/JXA、ScriptingBridge（51 个应用桥接） |
| **root 级管理任务** | 无 | 通过 XPC 的特权 Launch Daemon（只需批准一次） |
| **语音 / iMessage 控制** | 无 | 唤醒词听写 + 通过 Messages 实现的远程智能体 |
| **Xcode 集成** | 终端中的 `xcodebuild` | 原生的构建/运行/分析/代码审查工具 |
| **遥测** | 需要云端账户 | 无 —— 你的密钥，你的机器，你的数据 |

如果你一整天都待在同一个仓库里，Cursor 是很棒的选择。如果你想要一个既能构建你的 Xcode 项目、操控 Safari、把结果发短信给你，又能以 root 身份安装软件的智能体——那就是 Agent!。

## 参与贡献

想为 Agent! 贡献代码吗？请查看 [CONTRIBUTING.md](./CONTRIBUTING.md)——你只需使用 Xcode Command Line Tools（`./build.sh`），大约 5 分钟即可从源码完成构建，无需 Apple Developer 账户。可查看 [good first issues](https://github.com/AgentiLoop/Agent/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) 获取范围明确的入门任务。

---


> ⚠️ **法律声明与署名**
>
> ### 商标声明
>
> 「🦾 Agent! for macOS26」是一个独立的软件项目，**并未**与 Apple Inc. 存在任何关联、认可、赞助或其他形式的关系。「Apple」、「Mac」、「Mac mini」、「MacBook」、「macOS」及相关标志均为 Apple Inc. 在美国及其他国家/地区注册的商标。此处提及的所有其他商标、服务标志和商号均归其各自所有者所有，仅用于标识目的。
>
> 「🦾 Agent!」及 🦾 Agent! 标志均为 AgentiLoop Agent 的商标。使用这些标志需事先获得书面许可。以下的 MIT 许可证仅授予源代码方面的权利——**不**授予任何商标权利。
>
> ### 源代码许可证（MIT）
>
> 「🦾 Agent! for macOS26」的源代码是开源的，并采用 **MIT 许可证**授权。你可以自由使用、复制、修改、合并、发布、分发、再许可和/或出售源代码的副本，但须遵守 [LICENSE](./LICENSE) 文件中的条件（在软件的所有副本或实质性部分中保留版权声明及 MIT 许可声明）。
>
> ### 已编译的二进制文件与发布版本
>
> 通过本项目的 GitHub Releases、[AgentiLoop.ai](https://AgentiLoop.ai) 或任何其他官方渠道分发的已编译二进制文件、安装程序、经过代码签名的构建版本以及发布产物，均属 AgentiLoop Agent 拥有版权的作品，**不**受管辖源代码的 MIT 许可证覆盖。官方二进制文件的所有权利——包括「🦾 Agent!」名称、标志、代码签名身份和 Developer ID——均予保留。
>
> Copyright © 2000, 2023–2026 AgentiLoop Agent，保留所有权利。
>
> 你可以在 MIT 许可证下自由地从源代码构建你自己的二进制文件，前提是不使用「🦾 Agent!」名称、标志或品牌来标识你的产品。
>
> ### 免责声明
>
> 本软件按**「原样」**提供，不附带任何形式的明示或暗示担保，包括但不限于对适销性、特定用途适用性和不侵权的担保。在任何情况下，作者或版权持有人均不对因本软件或使用本软件或与之相关的其他交易而产生的任何索赔、损害或其他责任负责，无论是基于合同、侵权行为还是其他原因。
>
> ---
>
> 感谢你对 🦾 Agent! 的关注——这是一款专为运行 macOS 26.4 及以上版本、使用正版 Mac 硬件和软件的 Mac mini、MacBook 以及 Mac Studio 电脑打造的应用程序。
>
> - Website: https://AgentiLoop.ai
> - Github : https://github.com/AgentiLoop/agent
