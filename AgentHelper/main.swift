import Foundation
import AgentAudit

final class HelperCommandHandler: NSObject, HelperToolProtocol, @unchecked Sendable {
    weak var connection: NSXPCConnection?
    private let inFlightLock = NSLock()
    private var inFlight: Set<String> = []

    func execute(script: String, instanceID: String, withReply reply: @escaping (Int32, String) -> Void) {
        execute(script: script, instanceID: instanceID, workingDirectory: "", withReply: reply)
    }

    func execute(script: String, instanceID: String, workingDirectory: String, withReply reply: @escaping (Int32, String) -> Void) {
        let proxy = connection?.remoteObjectProxy as? HelperProgressProtocol
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
    /// kill every command this connection started so nothing keeps running as root.
    func connectionInvalidated() {
        inFlightLock.lock()
        let ids = inFlight
        inFlight.removeAll()
        inFlightLock.unlock()
        guard !ids.isEmpty else { return }
        AuditLog.log(.launchDaemon, "connection invalidated — cancelling \(ids.count) in-flight command(s)")
        DaemonCore.cancelAll(instanceIDs: ids)
    }
}

final class HelperDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        // Same-team clients only — without this, ANY local process could
        // execute commands as root through the mach service. The team is
        // read from our own signature, never hardcoded (XPCClientTrust).
        guard XPCClientTrust.harden(connection, label: "AgentHelper") else { return false }
        let handler = HelperCommandHandler()
        handler.connection = connection
        connection.exportedInterface = NSXPCInterface(with: HelperToolProtocol.self)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProgressProtocol.self)
        connection.exportedObject = handler
        connection.invalidationHandler = { handler.connectionInvalidated() }
        connection.interruptionHandler = { handler.connectionInvalidated() }
        connection.resume()
        return true
    }
}

DaemonCore.auditCategory = .launchDaemon
AuditLog.log(.launchDaemon, "AgentHelper daemon started (uid \(getuid()))")
let delegate = HelperDelegate()
// Mach service name == our own bundle ID (PRODUCT_BUNDLE_IDENTIFIER = $(APP_BUNDLE_ID).helper),
// read from the __info_plist section Xcode embeds in this tool. Must match MachServices in the
// generated LaunchDaemons plist — both derive from Project.xcconfig.
guard let machServiceName = Bundle.main.bundleIdentifier else {
    AuditLog.log(.launchDaemon, "AgentHelper: missing embedded CFBundleIdentifier — cannot start XPC listener")
    exit(1)
}
let listener = NSXPCListener(machServiceName: machServiceName)
listener.delegate = delegate
listener.resume()
RunLoop.current.run()
