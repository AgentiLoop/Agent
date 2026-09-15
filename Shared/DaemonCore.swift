import Foundation
import AgentAudit

/// Shared output context for streaming command output via XPC.
final class OutputContext: @unchecked Sendable {
    var output = ""
    let outputLock = NSLock()
    let progressHandler: ((String) -> Void)?

    init(progressHandler: ((String) -> Void)?) {
        self.progressHandler = progressHandler
    }
}

/// Shared command execution logic for both AgentHelper (root) and AgentUser (user) daemons.
/// The only differences are the XPC protocol types and Mach service name.
enum DaemonCore {
    nonisolated(unsafe) static var runningProcesses: [String: Process] = [:]
    static let lock = NSLock()

    /// Console category for this process — .launchDaemon in AgentHelper (root),
    /// .launchAgent in AgentUser. Set once at startup in each main.swift so
    /// every executed command is attributable in Console.app.
    nonisolated(unsafe) static var auditCategory: AuditLog.Category = .launchDaemon

    static func execute(
        script: String,
        instanceID: String,
        workingDirectory: String,
        progressHandler: ((String) -> Void)?,
        reply: @escaping (Int32, String) -> Void
    ) {
        lock.lock()
        if let old = runningProcesses[instanceID], old.isRunning {
            killTree(rootPID: old.processIdentifier)
            old.waitUntilExit()
        }
        runningProcesses[instanceID] = nil
        lock.unlock()

        AuditLog.log(auditCategory, "exec [\(instanceID)]\(workingDirectory.isEmpty ? "" : " cwd=\(workingDirectory)"): \(script.prefix(500))")

        // Defense-in-depth: the app already runs this same check before
        // dispatching, but any same-team-signed client can reach the mach
        // service directly. Same rules as the client side — the root daemon
        // only refuses the three catastrophic rm patterns.
        let verdict = ShellSafetyService.check(
            script,
            context: auditCategory == .launchDaemon ? .rootDaemon : .userAgent
        )
        if !verdict.allowed {
            let reason = verdict.reason ?? "blocked by shell safety guardrail"
            AuditLog.denied(auditCategory, "exec [\(instanceID)] BLOCKED (\(verdict.rule ?? "?")): \(script.prefix(200))")
            reply(126, reason)
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", script]

        if !workingDirectory.isEmpty {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }

        var env = ProcessInfo.processInfo.environment
        env["CLICOLOR_FORCE"] = "1"
        env["TERM"] = env["TERM"] ?? "xterm-256color"
        let extraPaths = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = extraPaths + ":" + (env["PATH"] ?? "")
        if !workingDirectory.isEmpty {
            env["PWD"] = workingDirectory
        }
          // Defense-in-depth: set AGENT_PROJECT_FOLDER on process.environment too.
        env["AGENT_PROJECT_FOLDER"] = workingDirectory.isEmpty
            ? FileManager.default.homeDirectoryForCurrentUser.path
            : workingDirectory
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        lock.lock()
        runningProcesses[instanceID] = process
        lock.unlock()

        let ctx = OutputContext(progressHandler: progressHandler)

        pipe.fileHandleForReading.readabilityHandler = { [ctx] handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            ctx.outputLock.lock()
            ctx.output += chunk
            ctx.outputLock.unlock()
            ctx.progressHandler?(chunk)
        }

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            AuditLog.denied(auditCategory, "exec [\(instanceID)] failed to launch: \(error.localizedDescription)")
            reply(-1, error.localizedDescription)
            return
        }

        pipe.fileHandleForReading.readabilityHandler = nil

        let remainingData = pipe.fileHandleForReading.readDataToEndOfFile()
        if !remainingData.isEmpty, let chunk = String(data: remainingData, encoding: .utf8) {
            ctx.outputLock.lock()
            ctx.output += chunk
            ctx.outputLock.unlock()
            ctx.progressHandler?(chunk)
        }

        ctx.outputLock.lock()
        let output = ctx.output
        ctx.outputLock.unlock()

        AuditLog.log(auditCategory, "exec [\(instanceID)] exited \(process.terminationStatus) (\(output.count) bytes)")
        reply(process.terminationStatus, output)

        lock.lock()
        runningProcesses.removeValue(forKey: instanceID)
        lock.unlock()
    }

    static func cancel(instanceID: String) {
        AuditLog.log(auditCategory, "cancel [\(instanceID)]")
        lock.lock()
        let process = runningProcesses.removeValue(forKey: instanceID)
        lock.unlock()
        if let process, process.isRunning {
            killTree(rootPID: process.processIdentifier)
        }
    }

    /// Cancel every in-flight command owned by a set of instance IDs. Used by the XPC
    /// connection invalidation handler so an app crash / quit / client-side timeout
    /// never leaves a shell running detached (as root, in the helper's case).
    static func cancelAll(instanceIDs: Set<String>) {
        for id in instanceIDs { cancel(instanceID: id) }
    }

    // MARK: - Process tree kill

    /// SIGTERM the shell AND every descendant (children reparent to launchd when only
    /// the shell dies, so `Process.terminate()` alone leaks them), then SIGKILL anything
    /// still alive after a grace period. Shared implementation lives in ProcessTree.
    static func killTree(rootPID: pid_t) {
        AuditLog.log(auditCategory, "killTree root=\(rootPID) pids=\(ProcessTree.descendants(of: rootPID))")
        ProcessTree.kill(rootPID: rootPID)
    }
}

