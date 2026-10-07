import AppKit

/// AppleScript (Cocoa Scripting) support. Terminology is in Resources/Agent.sdef,
/// enabled by NSAppleScriptEnabled + OSAScriptingDefinition in Info.plist.
/// Application properties are KVC keys handled by AppDelegate; commands are NSScriptCommand subclasses.
@MainActor
extension AppDelegate {
    private static let scriptingKeys: Set<String> = ["taskRunning", "activityLog", "projectFolder", "taskInput", "providerName", "scriptingTabs"]

    func application(_ sender: NSApplication, delegateHandlesKey key: String) -> Bool {
        Self.scriptingKeys.contains(key)
    }

    @objc var taskRunning: Bool { AgentViewModel.current?.isRunning ?? false }

    @objc var activityLog: String { AgentViewModel.current?.activityLog ?? "" }

    @objc var projectFolder: String {
        get { AgentViewModel.current?.projectFolder ?? "" }
        set { AgentViewModel.current?.projectFolder = newValue }
    }

    @objc var taskInput: String {
        get { AgentViewModel.current?.taskInput ?? "" }
        set { AgentViewModel.current?.taskInput = newValue }
    }

    @objc var providerName: String { AgentViewModel.current?.selectedProvider.displayName ?? "" }

    // MARK: - tab elements (Main tab first, then every other tab in tab-bar order)

    @objc var scriptingTabs: [ScriptingTab] {
        guard let vm = AgentViewModel.current else { return [] }
        return [ScriptingTab(tabId: nil)] + vm.scriptTabs.map { ScriptingTab(tabId: $0.id) }
    }

    /// `make new tab` — a new LLM tab using the Main tab's provider and model.
    @objc(insertObject:inScriptingTabsAtIndex:)
    func insertScriptingTab(_ tab: ScriptingTab, at index: Int) {
        insertInScriptingTabs(tab)
    }

    @objc(insertInScriptingTabs:)
    func insertInScriptingTabs(_ tab: ScriptingTab) {
        guard let vm = AgentViewModel.current else { return }
        let provider = vm.mainTabProvider
        let model = vm.globalModelForProvider(provider)
        let config = LLMConfig(provider: provider, model: model, displayName: model.isEmpty ? provider.displayName : model)
        tab.tabId = vm.createMainTab(config: config).id
    }
}

/// Scripting proxy for one tab. `tabId == nil` is the Main tab.
@MainActor @objc(ScriptingTab)
final class ScriptingTab: NSObject {
    nonisolated(unsafe) var tabId: UUID?

    init(tabId: UUID?) {
        self.tabId = tabId
    }

    /// Used by `make new tab` before the tab exists.
    override init() {
        tabId = nil
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

    @objc var taskInput: String {
        get { tabId == nil ? (vm?.taskInput ?? "") : (tab?.taskInput ?? "") }
        set { if tabId == nil { vm?.taskInput = newValue } else { tab?.taskInput = newValue } }
    }

    @objc var projectFolder: String {
        get { tabId == nil ? (vm?.projectFolder ?? "") : (tab?.projectFolder ?? "") }
        set {
            let path = (newValue as NSString).expandingTildeInPath
            if tabId == nil { vm?.projectFolder = path } else { tab?.projectFolder = path }
        }
    }

    @objc var providerName: String {
        guard let vm else { return "" }
        guard let tab else { return vm.mainTabProvider.displayName }
        return vm.resolvedLLMConfig(for: tab).provider.displayName
    }

    @objc var modelName: String {
        guard let vm else { return "" }
        guard let tab else { return vm.globalModelForProvider(vm.mainTabProvider) }
        return vm.resolvedLLMConfig(for: tab).model
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

    /// Starts `prompt` in this tab. Returns an error message, or nil when it started.
    func run(prompt: String, folder: String?) -> String? {
        guard let vm else { return "Agent! is not ready." }
        guard !prompt.isEmpty else { return "Task prompt is empty." }
        guard !taskRunning else { return "A task is already running in the \(name) tab." }
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

/// `stop task [in tab tab 2]` — stops the Main tab task unless a tab is given.
@objc(AgentStopTaskCommand)
final class AgentStopTaskCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let target = scriptingTarget(self)
        MainActor.assumeIsolated { target.stop() }
        return nil
    }
}
