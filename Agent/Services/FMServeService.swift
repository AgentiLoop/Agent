import Foundation

/// Manages the macOS 27 `fm serve` process (Apple Foundation Models CLI) that backs
/// the experimental "Apple fm serve" provider. The server is loopback-only on
/// 127.0.0.1:1976 and exposes an OpenAI-style Chat Completions API.
///
/// Start/restart/stop are best-effort: an instance started outside Agent! (e.g. from
/// Terminal) is detected via `/health` and left alone unless the user asks to restart.
@MainActor
@Observable
final class FMServeService {
    static let shared = FMServeService()

    static let binaryPath = "/usr/bin/fm"
    static let healthURL = URL(string: "http://127.0.0.1:1976/health")!

    private(set) var isRunning = false
    private(set) var isBusy = false
    private(set) var lastError: String?

    /// The `fm serve` process launched by Agent! (nil when the server was started elsewhere).
    private var process: Process?

    private init() {}

    /// `fm` ships with macOS 27; older systems have no binary.
    var isAvailable: Bool { FileManager.default.isExecutableFile(atPath: Self.binaryPath) }

    /// Poll `/health` and update `isRunning`.
    func checkHealth() async {
        var request = URLRequest(url: Self.healthURL)
        request.timeoutInterval = 2
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let http = response as? HTTPURLResponse, http.statusCode == 200 {
            isRunning = true
        } else {
            isRunning = false
            if let p = process, !p.isRunning { process = nil }
        }
    }

    func start() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        lastError = nil

        await checkHealth()
        if isRunning { return }

        guard isAvailable else {
            lastError = "\(Self.binaryPath) not found — fm serve requires macOS 27."
            return
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: Self.binaryPath)
        p.arguments = ["serve"]
        let errPipe = Pipe()
        p.standardOutput = FileHandle.nullDevice
        p.standardError = errPipe
        do {
            try p.run()
        } catch {
            lastError = "Failed to launch fm serve: \(error.localizedDescription)"
            return
        }
        process = p

        // Give the server a moment to bind, then verify.
        for _ in 0..<10 {
            try? await Task.sleep(for: .milliseconds(300))
            await checkHealth()
            if isRunning { return }
            if !p.isRunning { break }
        }
        if !isRunning {
            let err = String(data: errPipe.fileHandleForReading.availableData, encoding: .utf8)?
                .replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            lastError = err.isEmpty
                ? "fm serve did not come up on 127.0.0.1:1976."
                : err
            if err.localizedCaseInsensitiveContains("license") {
                lastError = "fm license not accepted — run `sudo fm license` in Terminal, then start again."
            }
            process = nil
        }
    }

    func stop() async {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        lastError = nil

        if let p = process {
            p.terminate()
            p.waitUntilExit()
            process = nil
        } else {
            // Instance started outside Agent! — best effort.
            let kill = Process()
            kill.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            kill.arguments = ["-x", "-f", "fm serve"]
            try? kill.run()
            kill.waitUntilExit()
        }
        try? await Task.sleep(for: .milliseconds(300))
        await checkHealth()
    }

    func restart() async {
        await stop()
        await start()
    }
}
