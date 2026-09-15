import Foundation
import AgentAudit

final class UserCommandHandler: NSObject, UserToolProtocol, @unchecked Sendable {
    weak var connection: NSXPCConnection?
    private let inFlightLock = NSLock()
    private var inFlight: Set<String> = []

    func execute(script: String, instanceID: String, withReply reply: @escaping (Int32, String) -> Void) {
        execute(script: script, instanceID: instanceID, workingDirectory: "", withReply: reply)
    }

    func execute(script: String, instanceID: String, workingDirectory: String, withReply reply: @escaping (Int32, String) -> Void) {
        let proxy = connection?.remoteObjectProxy as? UserProgressProtocol
        inFlightLock.lock(); inFlight.insert(instanceID); inFlightLock.unlock()
        DaemonCore.execute(
            script: script,
            instanceID: instanceID,
            workingDirectory: workingDirectory,
            progressHandler: { proxy?.progressUpdate($0) },
            reply: { [weak self] status, output in
                if let self { self.inFlightLock.lock(); self.inFlight.remove(instanceID); self.inFlightLock.unlock() }
                reply(status, output)
            }
        )
    }

    func cancelOperation(instanceID: String, withReply reply: @escaping () -> Void) {
        DaemonCore.cancel(instanceID: instanceID)
        reply()
    }

    /// Connection dropped (app quit, crash, or client-side timeout invalidated it):
    /// kill every command this connection started so nothing keeps running detached.
    func connectionInvalidated() {
        inFlightLock.lock()
        let ids = inFlight
        inFlight.removeAll()
        inFlightLock.unlock()
        guard !ids.isEmpty else { return }
        AuditLog.log(.launchAgent, "connection invalidated — cancelling \(ids.count) in-flight command(s)")
        DaemonCore.cancelAll(instanceIDs: ids)
    }
}

final class UserDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        // Same-team gate as the root daemon — the user agent runs arbitrary
        // shell as the logged-in user. Team read from our own signature.
        guard XPCClientTrust.harden(connection, label: "AgentUser") else { return false }
        let handler = UserCommandHandler()
        handler.connection = connection
        connection.exportedInterface = NSXPCInterface(with: UserToolProtocol.self)
        connection.remoteObjectInterface = NSXPCInterface(with: UserProgressProtocol.self)
        connection.exportedObject = handler
        connection.invalidationHandler = { handler.connectionInvalidated() }
        connection.interruptionHandler = { handler.connectionInvalidated() }
        connection.resume()
        return true
    }
}

DaemonCore.auditCategory = .launchAgent
AuditLog.log(.launchAgent, "AgentUser agent started (uid \(getuid()))")
let delegate = UserDelegate()
// Mach service name == our own bundle ID (PRODUCT_BUNDLE_IDENTIFIER = $(APP_BUNDLE_ID).user),
// read from the __info_plist section Xcode embeds in this tool. Must match MachServices in the
// generated LaunchAgents plist — both derive from Project.xcconfig.
guard let machServiceName = Bundle.main.bundleIdentifier else {
    AuditLog.log(.launchAgent, "AgentUser: missing embedded CFBundleIdentifier — cannot start XPC listener")
    exit(1)
}
let listener = NSXPCListener(machServiceName: machServiceName)
listener.delegate = delegate
listener.resume()
RunLoop.current.run()
