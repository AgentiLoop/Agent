import Foundation
import AgentAudit

final class UserCommandHandler: NSObject, UserToolProtocol, @unchecked Sendable {
    weak var connection: NSXPCConnection?

    func execute(script: String, instanceID: String, withReply reply: @escaping (Int32, String) -> Void) {
        execute(script: script, instanceID: instanceID, workingDirectory: "", withReply: reply)
    }

    func execute(script: String, instanceID: String, workingDirectory: String, withReply reply: @escaping (Int32, String) -> Void) {
        let proxy = connection?.remoteObjectProxy as? UserProgressProtocol
        DaemonCore.execute(
            script: script,
            instanceID: instanceID,
            workingDirectory: workingDirectory,
            progressHandler: { proxy?.progressUpdate($0) },
            reply: reply
        )
    }

    func cancelOperation(instanceID: String, withReply reply: @escaping () -> Void) {
        DaemonCore.cancel(instanceID: instanceID)
        reply()
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
        connection.resume()
        return true
    }
}

DaemonCore.auditCategory = .launchAgent
AuditLog.log(.launchAgent, "AgentUser agent started (uid \(getuid()))")
let delegate = UserDelegate()
// Mach service name == our own bundle ID (PRODUCT_BUNDLE_IDENTIFIER = $(APP_BUNDLE_ID).user),
// read from the __info_plist section Xcode embeds in this tool. Must match MachServices in the
// generated LaunchAgents plist — both derive from BundleID.xcconfig.
guard let machServiceName = Bundle.main.bundleIdentifier else {
    AuditLog.log(.launchAgent, "AgentUser: missing embedded CFBundleIdentifier — cannot start XPC listener")
    exit(1)
}
let listener = NSXPCListener(machServiceName: machServiceName)
listener.delegate = delegate
listener.resume()
RunLoop.current.run()
