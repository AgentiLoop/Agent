# 🦾 Agent! 适用于 macOS 26.4.1 或更高版本

## 面向苹果 Mac 桌面的 Agentic AI

Agent! 是一款原生 macOS 应用，可将你的 Mac 变成一个智能代理。它能够理解自然语言指令，执行任务，自动化应用程序，编辑文件，构建项目，管理 Git，并且以安全方式控制桌面。

## Agent! 是什么？

Agent! 不只是回答问题，它会真正执行动作。它可以打开应用，搜索网络，操作 Safari，读取和修改文件，构建 Xcode 项目，运行脚本，并自动化系统任务。

它支持本地和云端 AI 模型。你可以使用自己的 API Key，也可以使用 Ollama、vLLM 或 LM Studio 等本地方案。

## 快速开始

1. 从仓库最新发布版本下载 Agent!。
2. 将应用拖到 Applications 文件夹。
3. 打开应用并完成首次配置。
4. 在设置中选择你的 AI 提供商，并添加 API Key 或选择本地模型。

## 它能做什么？

- “在 Music 中播放我的 Workout 播放列表”
- “构建 Xcode 项目并修复任何错误”
- “用 Photo Booth 拍一张照片”
- “给妈妈发一条 iMessage，说我 6 点回家”
- “打开 Safari 并搜索前往东京的航班”
- “把这个类重构成更小的文件”
- “我今天有哪些日程安排？”

只要写下你想做的事，Agent! 就会决定如何执行。

## 主要功能

### Agentic AI
Agent! 结合了推理、执行和自我修正能力。它不仅生成文本，还会观察结果、修复错误，并不断重复直到任务完成。

### Agentic 编程
它可以读取代码库，精确修改文件，运行 shell 命令，构建 Xcode 项目，管理 Git，并在开发流程中保持专注。

### 桌面自动化
Agent! 可通过 Accessibility、AppleScript、JXA、ScriptingBridge 和 Safari Automation 控制 macOS 应用。

### 多模型支持
Agent! 可连接多种 AI 提供商，包括 Claude、OpenAI、Gemini、Grok、Mistral、DeepSeek、Qwen、Z.ai、BigModel、Hugging Face、OpenRouter、Ollama、vLLM、LM Studio 和 Apple Intelligence。

### 隐私与安全
你的数据保留在你的 Mac 上。AI 任务和自动化操作都会记录到日志中，方便你查看具体发生了什么。

## 隐私与安全

- 你的文件和数据保留在本地设备上。
- 只有提示词文本会发送到云端 AI 提供商。
- 你可以在活动日志中查看 Agent! 做了什么。
- 系统会在执行敏感任务前要求必要的 macOS 权限和安全保护。

## 常见问题

### 我需要会编程吗？
不需要。只需要用英文或你的母语描述你想做的事情。

### 它安全吗？
是的。Agent! 会记录活动日志，要求必要的 macOS 权限，并限制危险操作。

### 成本是多少？
应用本身免费且开源。云端 AI 提供商按使用量收费，但本地模型也可使用。

### 我需要什么 Mac？
需要 macOS 26.4.1 或更高版本，以及 Apple Silicon 硬件。本地模型的内存和性能要求取决于模型大小。

## 文档

- [Technical Architecture](docs/TECHNICAL.md)
- [Comparisons](docs/COMPARISON.md)
- [Security Model](docs/SECURITY.md)
- [FAQ](docs/FAQ.md)

## 许可证

MIT - 开源且免费。

---

Agent! 旨在让你的 Mac 更智能、更高效、更自动化，同时保留控制权和安全性。
