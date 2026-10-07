import AppKit

/// AppleScript (Cocoa Scripting) support. Terminology is in Resources/Agent.sdef,
/// enabled by NSAppleScriptEnabled + OSAScriptingDefinition in Info.plist.
/// Application properties are KVC keys handled by AppDelegate; commands are NSScriptCommand subclasses.
@MainActor
extension AppDelegate {
    private static let scriptingKeys: Set<String> = ["taskRunning", "activityLog", "lastResult", "lastError", "promptHistory", "taskHistory", "errorHistory", "projectFolder", "taskInput", "providerName", "modelName", "scriptingTabs",
        "maxIterations", "maxRetries", "maxTokens", "tokenBudget", "temperature", "reasoningEffort",
        "autoVerify", "criticReview", "visualTests", "autoPR", "autoScaffold", "autoScreenshot", "forceVision",
        "messagesMonitor", "taskAutoComplete", "userAgentEnabled", "launchDaemonEnabled"]

    func application(_ sender: NSApplication, delegateHandlesKey key: String) -> Bool {
        Self.scriptingKeys.contains(key)
    }

    @objc var taskRunning: Bool { AgentViewModel.current?.isRunning ?? false }

    @objc var activityLog: String { AgentViewModel.current?.activityLog ?? "" }

    @objc var lastResult: String { ScriptingTab(tabId: nil).lastResult }

    @objc var lastError: String { ScriptingTab(tabId: nil).lastError }

    @objc var promptHistory: [String] { ScriptingTab(tabId: nil).promptHistory }

    @objc var taskHistory: [String] { ScriptingTab(tabId: nil).taskHistory }

    @objc var errorHistory: [String] { ScriptingTab(tabId: nil).errorHistory }

    @objc var projectFolder: String {
        get { AgentViewModel.current?.projectFolder ?? "" }
        set { AgentViewModel.current?.projectFolder = newValue }
    }

    @objc var taskInput: String {
        get { AgentViewModel.current?.taskInput ?? "" }
        set { AgentViewModel.current?.taskInput = newValue }
    }

    @objc var providerName: String {
        get { ScriptingTab(tabId: nil).providerName }
        set { ScriptingTab(tabId: nil).providerName = newValue }
    }

    @objc var modelName: String {
        get { ScriptingTab(tabId: nil).modelName }
        set { ScriptingTab(tabId: nil).modelName = newValue }
    }

    // MARK: - Settings (same values as the Settings window; persisted to UserDefaults by the view model)

    /// Reads/writes one view-model setting; `nil` VM reads as `fallback` and ignores writes.
    private func setting<T>(_ keyPath: ReferenceWritableKeyPath<AgentViewModel, T>, _ fallback: T) -> T {
        AgentViewModel.current?[keyPath: keyPath] ?? fallback
    }

    private func setSetting<T>(_ keyPath: ReferenceWritableKeyPath<AgentViewModel, T>, _ value: T) {
        AgentViewModel.current?[keyPath: keyPath] = value
    }

    /// Integer settings reject negative values (0 means "no limit / provider default" where it applies).
    private func setCount(_ keyPath: ReferenceWritableKeyPath<AgentViewModel, Int>, _ value: Int, minimum: Int = 0) {
        guard value >= minimum else { return ScriptingTab.scriptError("Value must be \(minimum) or more.") }
        setSetting(keyPath, value)
    }

    @objc var maxIterations: Int {
        get { setting(\.maxIterations, 50) }
        set { setCount(\.maxIterations, newValue, minimum: 1) }
    }

    @objc var maxRetries: Int {
        get { setting(\.maxRetries, 10) }
        set { setCount(\.maxRetries, newValue) }
    }

    @objc var maxTokens: Int {
        get { setting(\.maxTokens, 0) }
        set { setCount(\.maxTokens, newValue) }
    }

    @objc var tokenBudget: Int {
        get { setting(\.tokenBudgetCeiling, 0) }
        set { setCount(\.tokenBudgetCeiling, newValue) }
    }

    /// Temperature of the Main tab's provider.
    @objc var temperature: Double {
        get {
            guard let vm = AgentViewModel.current else { return 0 }
            return vm.temperatures[vm.mainTabProvider]
        }
        set {
            guard let vm = AgentViewModel.current else { return }
            guard (0...2).contains(newValue) else { return ScriptingTab.scriptError("Temperature must be between 0 and 2.") }
            vm.temperatures[vm.mainTabProvider] = newValue
        }
    }

    @objc var reasoningEffort: String {
        get { setting(\.reasoningEffort, "off") }
        set {
            let effort = newValue.lowercased()
            guard ["off", "low", "medium", "high"].contains(effort) else {
                return ScriptingTab.scriptError("Reasoning effort must be off, low, medium or high.")
            }
            setSetting(\.reasoningEffort, effort)
        }
    }

    @objc var autoVerify: Bool {
        get { setting(\.autoVerifyEnabled, false) }
        set { setSetting(\.autoVerifyEnabled, newValue) }
    }

    @objc var criticReview: Bool {
        get { setting(\.criticReviewEnabled, false) }
        set { setSetting(\.criticReviewEnabled, newValue) }
    }

    @objc var visualTests: Bool {
        get { setting(\.visualTestsEnabled, false) }
        set { setSetting(\.visualTestsEnabled, newValue) }
    }

    @objc var autoPR: Bool {
        get { setting(\.autoPREnabled, false) }
        set { setSetting(\.autoPREnabled, newValue) }
    }

    @objc var autoScaffold: Bool {
        get { setting(\.autoScaffoldEnabled, false) }
        set { setSetting(\.autoScaffoldEnabled, newValue) }
    }

    @objc var autoScreenshot: Bool {
        get { setting(\.visionAutoScreenshotEnabled, false) }
        set { setSetting(\.visionAutoScreenshotEnabled, newValue) }
    }

    @objc var forceVision: Bool {
        get { setting(\.forceVision, false) }
        set { setSetting(\.forceVision, newValue) }
    }

    @objc var messagesMonitor: Bool {
        get { setting(\.messagesMonitorEnabled, false) }
        set { setSetting(\.messagesMonitorEnabled, newValue) }
    }

    @objc var taskAutoComplete: Bool {
        get { setting(\.taskAutoComplete, true) }
        set { setSetting(\.taskAutoComplete, newValue) }
    }

    @objc var userAgentEnabled: Bool {
        get { setting(\.userEnabled, true) }
        set { setSetting(\.userEnabled, newValue) }
    }

    @objc var launchDaemonEnabled: Bool {
        get { setting(\.rootEnabled, true) }
        set { setSetting(\.rootEnabled, newValue) }
    }

    // MARK: - tab elements (Main tab first, then every other tab in tab-bar order)

    @objc var scriptingTabs: [ScriptingTab] {
        guard let vm = AgentViewModel.current else { return [] }
        return [ScriptingTab(tabId: nil)] + vm.scriptTabs.map { ScriptingTab(tabId: $0.id) }
    }

    /// `make new tab [with properties {provider:…, model:…, project folder:…, task input:…}]` —
    /// a new LLM tab; provider and model default to the Main tab's.
    @objc(insertObject:inScriptingTabsAtIndex:)
    func insertScriptingTab(_ tab: ScriptingTab, at index: Int) {
        insertInScriptingTabs(tab)
    }

    @objc(insertInScriptingTabs:)
    func insertInScriptingTabs(_ tab: ScriptingTab) {
        guard let vm = AgentViewModel.current, let pending = tab.pending else { return }
        let provider = pending.provider ?? vm.mainTabProvider
        let model = pending.model ?? vm.globalModelForProvider(provider)
        let config = LLMConfig(provider: provider, model: model, displayName: model.isEmpty ? provider.displayName : model)
        let newTab = vm.createMainTab(config: config)
        if let folder = pending.folder { newTab.projectFolder = folder }
        if let input = pending.input { newTab.taskInput = input }
        tab.pending = nil
        tab.tabId = newTab.id
    }
}

/// Scripting proxy for one tab. `tabId == nil` is the Main tab, unless `pending` is set
/// (a `make new tab` proxy not inserted yet — property sets are held until insertion).
@MainActor @objc(ScriptingTab)
final class ScriptingTab: NSObject {
    struct Pending { var provider: APIProvider?, model: String?, folder: String?, input: String? }

    nonisolated(unsafe) var tabId: UUID?
    var pending: Pending?

    init(tabId: UUID?) {
        self.tabId = tabId
    }

    /// Used by `make new tab` before the tab exists.
    override init() {
        tabId = nil
        pending = Pending()
        super.init()
    }

    private var vm: AgentViewModel? { AgentViewModel.current }
    private var tab: ScriptTab? { tabId.flatMap { vm?.tab(for: $0) } }

    @objc nonisolated var uniqueID: String { tabId?.uuidString ?? "main" }

    @objc var name: String { tab?.displayTitle ?? "Main" }

    @objc var taskRunning: Bool {
        guard tabId != nil else { return vm?.isRunning ?? false }
        return tab?.isBusy ?? false
    }

    @objc var activityLog: String {
        guard tabId != nil else { return vm?.activityLog ?? "" }
        return tab?.activityLog ?? ""
    }

    /// Completion summary of the most recent task (cleared when a task starts or is stopped).
    @objc var lastResult: String {
        guard tabId != nil else { return vm?.lastTaskCompletionSummary ?? "" }
        return tab?.lastTaskCompletionSummary ?? ""
    }

    @objc var lastError: String {
        guard tabId != nil else { return vm?.lastTaskError ?? "" }
        return tab?.lastTaskError ?? ""
    }

    @objc var taskInput: String {
        get { pending?.input ?? (tabId == nil ? (vm?.taskInput ?? "") : (tab?.taskInput ?? "")) }
        set {
            if pending != nil { pending?.input = newValue } else if tabId == nil { vm?.taskInput = newValue } else { tab?.taskInput = newValue }
        }
    }

    @objc var projectFolder: String {
        get { pending?.folder ?? (tabId == nil ? (vm?.projectFolder ?? "") : (tab?.projectFolder ?? "")) }
        set {
            let path = (newValue as NSString).expandingTildeInPath
            if pending != nil { pending?.folder = path } else if tabId == nil { vm?.projectFolder = path } else { tab?.projectFolder = path }
        }
    }

    @objc var providerName: String {
        get {
            guard let vm else { return "" }
            if let provider = pending?.provider { return provider.displayName }
            guard let tab else { return vm.mainTabProvider.displayName }
            return vm.resolvedLLMConfig(for: tab).provider.displayName
        }
        set {
            guard let vm else { return }
            guard let provider = APIProvider.selectableProviders.first(where: {
                $0.displayName.caseInsensitiveCompare(newValue) == .orderedSame
                    || $0.rawValue.caseInsensitiveCompare(newValue) == .orderedSame
            }) else {
                let names = APIProvider.selectableProviders.map(\.displayName).joined(separator: ", ")
                return Self.scriptError("Unknown provider \"\(newValue)\". Available: \(names).")
            }
            if pending != nil { pending?.provider = provider; return }
            guard tabId == nil else { return Self.scriptError("Only the Main tab's provider can be changed; other tabs keep the provider they were created with.") }
            vm.mainTabProvider = provider
            if vm.selectedTabId == nil { vm.selectedProvider = provider } else { vm.fetchModelsIfNeeded(for: provider) }
        }
    }

    @objc var modelName: String {
        get {
            guard let vm else { return "" }
            if let pending {
                return pending.model ?? vm.globalModelForProvider(pending.provider ?? vm.mainTabProvider)
            }
            guard let tab else { return vm.globalModelForProvider(vm.mainTabProvider) }
            return vm.resolvedLLMConfig(for: tab).model
        }
        set {
            guard let vm else { return }
            let model = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !model.isEmpty else { return Self.scriptError("Model is empty.") }
            if pending != nil { pending?.model = model; return }
            guard tabId == nil else { return Self.scriptError("Only the Main tab's model can be changed; other tabs keep the model they were created with.") }
            vm.models[vm.mainTabProvider] = model
        }
    }

    /// Reports an error from a property setter back to the running script.
    static func scriptError(_ message: String) {
        guard let command = NSScriptCommand.current() else { return }
        command.scriptErrorNumber = -10000
        command.scriptErrorString = message
    }

    @objc var selected: Bool {
        get { vm?.selectedTabId == tabId }
        set {
            guard newValue, let vm else { return }
            if tabId == nil { vm.selectMainTab() } else if tab != nil { vm.selectedTabId = tabId }
        }
    }

    override var objectSpecifier: NSScriptObjectSpecifier? {
        guard let appDescription = NSScriptClassDescription(for: NSApplication.self) else { return nil }
        return NSUniqueIDSpecifier(containerClassDescription: appDescription, containerSpecifier: nil,
                                   key: "scriptingTabs", uniqueID: uniqueID)
    }

    /// Prompts waiting to run after the current task, in order.
    @objc var queuedTasks: [String] {
        guard tabId != nil else { return vm?.mainTaskQueue ?? [] }
        return tab?.taskQueue ?? []
    }

    // MARK: History (same lists as the History window)

    @objc var promptHistory: [String] { tabExists ? (vm?.promptHistory(for: tab) ?? []) : [] }
    @objc var taskHistory: [String] { tabExists ? (vm?.taskSummaries(for: tab) ?? []) : [] }
    @objc var errorHistory: [String] { tabExists ? (vm?.errorHistory(for: tab) ?? []) : [] }

    /// History kinds of `clear history`: sdef enumerator code → History window type.
    nonisolated static let historyKinds: [FourCharCode: String] = [
        0x41674B50: "Prompts",        // 'AgKP'
        0x41674B53: "Task Summaries", // 'AgKS'
        0x41674B45: "Error History",  // 'AgKE'
    ]

    /// Clears one kind of history. Returns the number of entries removed (all of them, not just
    /// the recent ones listed), or nil when the tab no longer exists.
    func clearHistory(type: String) -> Int? {
        guard let vm, tabExists else { return nil }
        let shared = tab.map { $0.isMainTab } ?? true
        let count = switch type {
        case "Prompts": promptHistory.count
        case "Task Summaries": shared ? vm.history.records.count : (tab?.tabTaskSummaries.count ?? 0)
        default: shared ? ErrorHistory.shared.records.count : (tab?.tabErrors.count ?? 0)
        }
        vm.clearHistory(type: type, of: tab)
        return count
    }

    /// Removes every queued prompt without stopping the running task. Returns the number removed,
    /// or nil when the tab no longer exists.
    func clearQueue() -> Int? {
        guard let vm, tabExists else { return nil }
        let count = queuedTasks.count
        if let tab { tab.taskQueue.removeAll() } else { vm.mainTaskQueue.removeAll() }
        return count
    }

    /// `clear queue tab 2`.
    @objc func handleClearQueueScriptCommand(_ command: NSScriptCommand) -> Any? {
        Self.queueCleared(clearQueue(), command)
    }

    /// Result of `clear queue`: the count removed, or a script error for a closed tab.
    nonisolated static func queueCleared(_ count: Int?, _ command: NSScriptCommand) -> Any? {
        guard let count else {
            command.scriptErrorNumber = -10000
            command.scriptErrorString = "That tab no longer exists."
            return 0
        }
        return count
    }

    /// Starts `prompt` in this tab. Returns an error message, or nil when it started.
    /// With `queue`, a busy tab queues the prompt (same as submitting it in the task field) instead of failing.
    func run(prompt: String, folder: String?, queue: Bool = false) -> String? {
        guard let vm else { return "Agent! is not ready." }
        guard !prompt.isEmpty else { return "Task prompt is empty." }
        guard tabExists else { return "That tab no longer exists." }
        guard queue || !taskRunning else { return "A task is already running in the \(name) tab." }
        if let folder, !folder.isEmpty { projectFolder = folder }
        if tabId == nil {
            vm.selectMainTab()
            vm.taskInput = prompt
            vm.run()
        } else {
            guard let tab else { return "That tab no longer exists." }
            tab.taskInput = prompt
            vm.runTabTask(tab: tab)
        }
        return nil
    }

    func stop() {
        guard let vm else { return }
        if tabId == nil {
            if vm.isRunning { vm.stop() }
        } else if let tab {
            vm.cancelScriptTab(id: tab.id)
        }
    }

    /// Clears this tab's activity log. Returns an error message, or nil when cleared.
    func clearLog() -> String? {
        guard let vm else { return "Agent! is not ready." }
        if tabId == nil { vm.clearLog(of: nil); return nil }
        guard let tab else { return "That tab no longer exists." }
        vm.clearLog(of: tab)
        return nil
    }

    // MARK: Auto-pilot

    @objc var autoPilotRunning: Bool { tabExists && vm?.autoPilotSession(tab) != nil }
    @objc var autoPilotGoal: String { tabExists ? (vm?.autoPilotSession(tab)?.goal ?? "") : "" }
    @objc var autoPilotCycle: Int { tabExists ? (vm?.autoPilotSession(tab)?.cycle ?? 0) : 0 }
    @objc var autoPilotStatus: String { tabExists ? (vm?.autoPilotStatusLine(tab) ?? "") : "" }

    /// Main tab, or a tab that still exists (so a closed tab never falls back to Main).
    private var tabExists: Bool { tabId == nil || tab != nil }

    /// Starts an auto-pilot session in this tab. Returns an error message, or nil when started.
    func startAutoPilot(goal: String, hours: Double?, isolate: Bool?) -> String? {
        guard let vm else { return "Agent! is not ready." }
        guard tabExists else { return "That tab no longer exists." }
        guard vm.autoPilotSession(tab) == nil else { return "Auto-pilot is already running in the \(name) tab — \(vm.autoPilotStatusLine(tab))" }
        guard !projectFolder.isEmpty else { return "Set the \(name) tab's project folder before starting auto-pilot." }
        if let hours, hours <= 0 { return "hours must be greater than 0." }
        vm.recordAutoPilotGoal(goal)
        vm.startAutoPilot(goal: goal, hours: hours, tab: tab, isolate: isolate)
        return nil
    }

    /// Ends this tab's auto-pilot session: after the running cycle (`/auto stop`), or now and
    /// stopping the task (Stop All). Returns an error message, or nil.
    func stopAutoPilot(afterCycle: Bool) -> String? {
        guard let vm else { return "Agent! is not ready." }
        guard tabExists else { return "That tab no longer exists." }
        guard vm.autoPilotSession(tab) != nil else { return "Auto-pilot is not running in the \(name) tab." }
        if afterCycle { vm.requestAutoPilotStop(tab) } else { vm.stopAutoPilotTab(tab) }
        return nil
    }

    /// `stop auto pilot tab 2`.
    @objc func handleStopAutoPilotScriptCommand(_ command: NSScriptCommand) -> Any? {
        let afterCycle = (command.evaluatedArguments?["afterCycle"] as? Bool) ?? false
        if let error = stopAutoPilot(afterCycle: afterCycle) {
            command.scriptErrorNumber = -10000
            command.scriptErrorString = error
        }
        return nil
    }

    /// Closes this tab. Returns an error message, or nil when closed.
    func close() -> String? {
        guard let tabId else { return "The Main tab can't be closed." }
        guard let vm, tab != nil else { return "That tab no longer exists." }
        vm.closeScriptTab(id: tabId)
        return nil
    }

    /// Standard Suite `close tab …`.
    @objc func handleCloseScriptCommand(_ command: NSScriptCommand) -> Any? {
        if let error = close() {
            command.scriptErrorNumber = -10000
            command.scriptErrorString = error
        }
        return nil
    }

    /// `clear log tab 2` / `clear log of tab 2`.
    @objc func handleClearLogScriptCommand(_ command: NSScriptCommand) -> Any? {
        if let error = clearLog() {
            command.scriptErrorNumber = -10000
            command.scriptErrorString = error
        }
        return nil
    }

    /// `stop task tab 2`.
    @objc func handleStopTaskScriptCommand(_ command: NSScriptCommand) -> Any? {
        stop()
        return nil
    }

    /// `select tab 2`.
    @objc func handleSelectScriptCommand(_ command: NSScriptCommand) -> Any? {
        selected = true
        return nil
    }
}

/// Resolves the optional `in tab` argument; Main tab when omitted.
private func scriptingTarget(_ command: NSScriptCommand) -> ScriptingTab {
    let given = command.evaluatedArguments?["tab"] as? ScriptingTab
    return MainActor.assumeIsolated { given ?? ScriptingTab(tabId: nil) }
}

/// `run task "prompt" [in folder "/path"] [in tab tab 2]` — runs in the Main tab unless a tab is given.
@objc(AgentRunTaskCommand)
final class AgentRunTaskCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let prompt = (directParameter as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let folder = evaluatedArguments?["folder"] as? String
        let target = scriptingTarget(self)
        let error: String? = MainActor.assumeIsolated { target.run(prompt: prompt, folder: folder) }
        if let error {
            scriptErrorNumber = -10000
            scriptErrorString = error
            return false
        }
        return true
    }
}

/// `queue task "prompt" [in tab tab 2]` — runs now if the tab is idle, otherwise waits in the tab's queue
/// (same as submitting in the task field while busy). Returns the queue position, 0 when it started now.
@objc(AgentQueueTaskCommand)
final class AgentQueueTaskCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let prompt = (directParameter as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let target = scriptingTarget(self)
        let (error, position): (String?, Int) = MainActor.assumeIsolated {
            let wasRunning = target.taskRunning
            if let error = target.run(prompt: prompt, folder: nil, queue: true) { return (error, 0) }
            return (nil, wasRunning ? target.queuedTasks.count : 0)
        }
        if let error {
            scriptErrorNumber = -10000
            scriptErrorString = error
        }
        return position
    }
}

/// `clear queue [tab 2 | in tab tab 2]` — drops queued prompts (Main tab unless a tab is given); the running
/// task keeps going. Returns how many were removed.
@objc(AgentClearQueueCommand)
final class AgentClearQueueCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let target = scriptingTarget(self)
        let count: Int? = MainActor.assumeIsolated { target.clearQueue() }
        return ScriptingTab.queueCleared(count, self)
    }
}

/// `clear history prompts|task summaries|errors [in tab tab 2]` — Main tab unless a tab is given.
/// Returns how many entries were removed.
@objc(AgentClearHistoryCommand)
final class AgentClearHistoryCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let code = (directParameter as? NSNumber)?.uint32Value, let type = ScriptingTab.historyKinds[code] else {
            scriptErrorNumber = -10000
            scriptErrorString = "Say which history to clear: prompts, task summaries or errors."
            return 0
        }
        let target = scriptingTarget(self)
        let count: Int? = MainActor.assumeIsolated { target.clearHistory(type: type) }
        return ScriptingTab.queueCleared(count, self)
    }
}

/// `stop task [in tab tab 2]` — stops the Main tab task unless a tab is given.
@objc(AgentStopTaskCommand)
final class AgentStopTaskCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let target = scriptingTarget(self)
        MainActor.assumeIsolated { target.stop() }
        return nil
    }
}

/// `start auto pilot ["goal"] [hours 2] [isolated true] [in tab tab 2]` — Main tab unless a tab is given.
@objc(AgentStartAutoPilotCommand)
final class AgentStartAutoPilotCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let goal = (directParameter as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let hours = (evaluatedArguments?["hours"] as? NSNumber)?.doubleValue
        let isolate = evaluatedArguments?["isolated"] as? Bool
        let target = scriptingTarget(self)
        if let error = MainActor.assumeIsolated({ target.startAutoPilot(goal: goal, hours: hours, isolate: isolate) }) {
            scriptErrorNumber = -10000
            scriptErrorString = error
            return false
        }
        return true
    }
}

/// `stop auto pilot [in tab tab 2] [after cycle true]` — Main tab unless a tab is given.
@objc(AgentStopAutoPilotCommand)
final class AgentStopAutoPilotCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let afterCycle = (evaluatedArguments?["afterCycle"] as? Bool) ?? false
        let target = scriptingTarget(self)
        if let error = MainActor.assumeIsolated({ target.stopAutoPilot(afterCycle: afterCycle) }) {
            scriptErrorNumber = -10000
            scriptErrorString = error
        }
        return nil
    }
}

/// `clear log [in tab tab 2]` — clears the Main tab log unless a tab is given.
@objc(AgentClearLogCommand)
final class AgentClearLogCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let target = scriptingTarget(self)
        if let error = MainActor.assumeIsolated({ target.clearLog() }) {
            scriptErrorNumber = -10000
            scriptErrorString = error
        }
        return nil
    }
}
