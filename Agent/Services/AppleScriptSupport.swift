import AppKit

/// AppleScript (Cocoa Scripting) support. Terminology is in Resources/Agent.sdef,
/// enabled by NSAppleScriptEnabled + OSAScriptingDefinition in Info.plist.
/// Application properties are KVC keys handled by AppDelegate; commands are NSScriptCommand subclasses.
@MainActor
extension AppDelegate {
    private static let scriptingKeys: Set<String> = ["taskRunning", "activityLog", "projectFolder", "taskInput", "providerName"]

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
}

/// `run task "prompt" [in folder "/path"]` — runs in the Main tab.
@objc(AgentRunTaskCommand)
final class AgentRunTaskCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let prompt = (directParameter as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let folder = evaluatedArguments?["folder"] as? String
        let error: String? = MainActor.assumeIsolated {
            guard let vm = AgentViewModel.current else { return "Agent! is not ready." }
            guard !prompt.isEmpty else { return "Task prompt is empty." }
            guard !vm.isRunning else { return "A task is already running in the Main tab." }
            if let folder, !folder.isEmpty { vm.projectFolder = (folder as NSString).expandingTildeInPath }
            vm.taskInput = prompt
            vm.run()
            return nil
        }
        if let error {
            scriptErrorNumber = -10000
            scriptErrorString = error
            return false
        }
        return true
    }
}

/// `stop task` — stops the Main tab task.
@objc(AgentStopTaskCommand)
final class AgentStopTaskCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        MainActor.assumeIsolated {
            guard let vm = AgentViewModel.current, vm.isRunning else { return }
            vm.stop()
        }
        return nil
    }
}
