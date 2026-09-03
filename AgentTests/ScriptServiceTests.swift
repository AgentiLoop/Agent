import Testing
import Foundation
@testable import Agent_

// NOTE: `createScript` normalizes names to UpperCamelCase ("test_hello" → "TestHello").
// read/update/delete/compileCommand do NOT normalize, so tests use CamelCase names
// throughout to match the file actually written to Sources/Scripts/.
@Suite("ScriptService")
@MainActor
struct ScriptServiceTests {
    let service = ScriptService()

    // MARK: - Create

    @Test("Create script produces Sources/Scripts/{name}.swift")
    func createScript() {
        let result = service.createScript(name: "TestHello", content: "print(\"hello\")")
        #expect(result.contains("Created TestHello"))

        let source = service.readScript(name: "TestHello")
        #expect(source == "print(\"hello\")")

        _ = service.deleteScript(name: "TestHello")
    }

    @Test("Create script converts snake_case name to UpperCamelCase")
    func createScriptCamelCasesName() {
        let result = service.createScript(name: "camel_case_test", content: "// camel")
        #expect(result.contains("Created CamelCaseTest"))

        let source = service.readScript(name: "CamelCaseTest")
        #expect(source == "// camel")

        _ = service.deleteScript(name: "CamelCaseTest")
    }

    @Test("Create script strips .swift suffix from name")
    func createScriptStripsSuffix() {
        let result = service.createScript(name: "SuffixTest.swift", content: "// test")
        #expect(result.contains("Created SuffixTest"))

        let source = service.readScript(name: "SuffixTest")
        #expect(source == "// test")

        _ = service.deleteScript(name: "SuffixTest")
    }

    @Test("Create duplicate script returns error")
    func createDuplicateScript() {
        _ = service.createScript(name: "DupTest", content: "// first")
        let result = service.createScript(name: "DupTest", content: "// second")
        #expect(result.contains("already exists"))

        _ = service.deleteScript(name: "DupTest")
    }

    // MARK: - Read

    @Test("Read nonexistent script returns nil")
    func readNonexistent() {
        let source = service.readScript(name: "DoesNotExist\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))")
        #expect(source == nil)
    }

    // MARK: - Update

    @Test("Update existing script changes content")
    func updateScript() {
        _ = service.createScript(name: "UpdateTest", content: "// v1")
        let result = service.updateScript(name: "UpdateTest", content: "// v2")
        #expect(result.contains("Updated UpdateTest"))

        let source = service.readScript(name: "UpdateTest")
        #expect(source == "// v2")

        _ = service.deleteScript(name: "UpdateTest")
    }

    @Test("Update nonexistent script returns error")
    func updateNonexistent() {
        let result = service.updateScript(name: "NoSuchScript\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))", content: "// x")
        #expect(result.contains("not found"))
    }

    // MARK: - Delete

    @Test("Delete existing script succeeds")
    func deleteScript() {
        _ = service.createScript(name: "DeleteMe", content: "// bye")
        let result = service.deleteScript(name: "DeleteMe")
        #expect(result.contains("Deleted DeleteMe"))

        let source = service.readScript(name: "DeleteMe")
        #expect(source == nil)
    }

    @Test("Delete nonexistent script is idempotent")
    func deleteNonexistent() {
        let name = "GhostScript\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let result = service.deleteScript(name: name)
        // deleteScript is idempotent: it succeeds even if the file is already gone.
        #expect(result.contains("Deleted \(name)"))
    }

    // MARK: - List

    @Test("List scripts includes created script")
    func listScripts() {
        _ = service.createScript(name: "ListTest", content: "// listed")
        let scripts = service.listScripts()
        let names = scripts.map(\.name)
        #expect(names.contains("ListTest"))

        _ = service.deleteScript(name: "ListTest")
    }

    // MARK: - Compile Command

    @Test("compileCommand returns swift build command")
    func compileCommand() {
        _ = service.createScript(name: "CmdTest", content: "print(\"hi\")")
        let cmd = service.compileCommand(name: "CmdTest")
        #expect(cmd?.contains("swift build --product 'CmdTest'") == true)

        _ = service.deleteScript(name: "CmdTest")
    }

    @Test("compileCommand returns nil for missing script")
    func compileCommandMissing() {
        let cmd = service.compileCommand(name: "NoSuch\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))")
        #expect(cmd == nil)
    }

    @Test("dylibPath returns path with lib prefix and .dylib extension")
    func dylibPathFormat() {
        let path = service.dylibPath(name: "MyScript")
        #expect(path.contains("libMyScript.dylib"))
        #expect(path.contains(".build/debug/"))
    }

    // MARK: - AGENT_SCRIPT_ARGS

    @Test("loadAndRunScript passes arguments via AGENT_SCRIPT_ARGS env var")
    func argsPassedViaEnvVar() async {
        let script = """
        import Foundation

        @_cdecl("script_main")
        public func scriptMain() -> Int32 {
            printArgs()
            return 0
        }

        func printArgs() {
            if let args = ProcessInfo.processInfo.environment["AGENT_SCRIPT_ARGS"] {
                print("ARGS:\\(args)")
            } else {
                print("ARGS:none")
            }
        }
        """
        _ = service.createScript(name: "TestArgs", content: script)
        defer { _ = service.deleteScript(name: "TestArgs") }

        // Compile
        guard let cmd = service.compileCommand(name: "TestArgs") else {
            Issue.record("compileCommand returned nil")
            return
        }
        let compileResult = shell(cmd)
        guard compileResult.status == 0 else {
            Issue.record("Compile failed: \(compileResult.output)")
            return
        }

        // Run with arguments
        let result = await service.loadAndRunScript(name: "TestArgs", arguments: "/Applications/Safari.app")
        #expect(result.output.contains("ARGS:/Applications/Safari.app"))
        #expect(result.status == 0)
    }

    @Test("loadAndRunScript with empty arguments does not set AGENT_SCRIPT_ARGS")
    func emptyArgsNotSet() async {
        let script = """
        import Foundation

        @_cdecl("script_main")
        public func scriptMain() -> Int32 {
            checkArgs()
            return 0
        }

        func checkArgs() {
            if let args = ProcessInfo.processInfo.environment["AGENT_SCRIPT_ARGS"] {
                print("ARGS:\\(args)")
            } else {
                print("ARGS:none")
            }
        }
        """
        _ = service.createScript(name: "TestNoArgs", content: script)
        defer { _ = service.deleteScript(name: "TestNoArgs") }

        guard let cmd = service.compileCommand(name: "TestNoArgs") else {
            Issue.record("compileCommand returned nil")
            return
        }
        let compileResult = shell(cmd)
        guard compileResult.status == 0 else {
            Issue.record("Compile failed: \(compileResult.output)")
            return
        }

        let result = await service.loadAndRunScript(name: "TestNoArgs", arguments: "")
        #expect(result.output.contains("ARGS:none"))
        #expect(result.status == 0)
    }

    @Test("AGENT_SCRIPT_ARGS is cleaned up after script runs")
    func argsCleanedUp() async {
        let script = """
        import Foundation

        @_cdecl("script_main")
        public func scriptMain() -> Int32 {
            print("ok")
            return 0
        }
        """
        _ = service.createScript(name: "TestCleanup", content: script)
        defer { _ = service.deleteScript(name: "TestCleanup") }

        guard let cmd = service.compileCommand(name: "TestCleanup") else {
            Issue.record("compileCommand returned nil")
            return
        }
        let compileResult = shell(cmd)
        guard compileResult.status == 0 else {
            Issue.record("Compile failed: \(compileResult.output)")
            return
        }

        _ = await service.loadAndRunScript(name: "TestCleanup", arguments: "secret_data")

        // After the call, env var should be unset
        let envVal = ProcessInfo.processInfo.environment["AGENT_SCRIPT_ARGS"]
        #expect(envVal == nil)
    }

    // MARK: - JSON I/O

    @Test("Script reads JSON input and writes JSON output")
    func jsonInputOutput() async {
        let agentDir = ScriptService.agentDir.path
        let inputPath = "\(agentDir)/test_json_io_input.json"
        let outputPath = "\(agentDir)/test_json_io_output.json"

        // Clean up any previous run
        try? FileManager.default.removeItem(atPath: inputPath)
        try? FileManager.default.removeItem(atPath: outputPath)
        defer {
            try? FileManager.default.removeItem(atPath: inputPath)
            try? FileManager.default.removeItem(atPath: outputPath)
            _ = service.deleteScript(name: "TestJsonIo")
        }

        // Write input JSON
        let input: [String: Any] = ["greeting": "hello", "count": 42]
        guard let inputData = try? JSONSerialization.data(withJSONObject: input, options: .prettyPrinted) else {
            Issue.record("Could not serialize input JSON")
            return
        }
        try? inputData.write(to: URL(fileURLWithPath: inputPath))

        // Create script that reads input and writes output
        let script = """
        import Foundation

        @_cdecl("script_main")
        public func scriptMain() -> Int32 {
            processJSON()
            return 0
        }

        func processJSON() {
            let home = NSHomeDirectory()
            let inputPath = "\\(home)/Documents/AgentScript/test_json_io_input.json"
            let outputPath = "\\(home)/Documents/AgentScript/test_json_io_output.json"

            guard let data = FileManager.default.contents(atPath: inputPath),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Failed to read input")
                return
            }

            let greeting = json["greeting"] as? String ?? "unknown"
            let count = json["count"] as? Int ?? 0

            let result: [String: Any] = [
                "success": true,
                "echo_greeting": greeting,
                "echo_count": count,
                "doubled": count * 2
            ]

            guard let outData = try? JSONSerialization.data(withJSONObject: result, options: .prettyPrinted) else { return }
            try? outData.write(to: URL(fileURLWithPath: outputPath))
            print("JSON processed")
        }
        """
        _ = service.createScript(name: "TestJsonIo", content: script)

        guard let cmd = service.compileCommand(name: "TestJsonIo") else {
            Issue.record("compileCommand returned nil")
            return
        }
        let compileResult = shell(cmd)
        guard compileResult.status == 0 else {
            Issue.record("Compile failed: \(compileResult.output)")
            return
        }

        let result = await service.loadAndRunScript(name: "TestJsonIo")
        #expect(result.status == 0)
        #expect(result.output.contains("JSON processed"))

        // Read and verify output JSON
        guard let outData = FileManager.default.contents(atPath: outputPath),
              let outJSON = try? JSONSerialization.jsonObject(with: outData) as? [String: Any] else {
            Issue.record("Could not read output JSON at \(outputPath)")
            return
        }

        #expect(outJSON["success"] as? Bool == true)
        #expect(outJSON["echo_greeting"] as? String == "hello")
        #expect(outJSON["echo_count"] as? Int == 42)
        #expect(outJSON["doubled"] as? Int == 84)
    }

    @Test("Script handles missing JSON input gracefully")
    func jsonMissingInput() async {
        let agentDir = ScriptService.agentDir.path
        let inputPath = "\(agentDir)/test_missing_json_input.json"

        // Make sure input doesn't exist
        try? FileManager.default.removeItem(atPath: inputPath)
        defer { _ = service.deleteScript(name: "TestMissingJson") }

        let script = """
        import Foundation

        @_cdecl("script_main")
        public func scriptMain() -> Int32 {
            checkInput()
        }

        func checkInput() -> Int32 {
            let home = NSHomeDirectory()
            let inputPath = "\\(home)/Documents/AgentScript/test_missing_json_input.json"

            guard let _ = FileManager.default.contents(atPath: inputPath) else {
                print("ERROR:input_not_found")
                return 1
            }
            return 0
        }
        """
        _ = service.createScript(name: "TestMissingJson", content: script)

        guard let cmd = service.compileCommand(name: "TestMissingJson") else {
            Issue.record("compileCommand returned nil")
            return
        }
        let compileResult = shell(cmd)
        guard compileResult.status == 0 else {
            Issue.record("Compile failed: \(compileResult.output)")
            return
        }

        let result = await service.loadAndRunScript(name: "TestMissingJson")
        #expect(result.output.contains("ERROR:input_not_found"))
        #expect(result.status == 1)
    }

    // MARK: - Helper

    private func shell(_ command: String) -> (output: String, status: Int32) {
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        try? process.run()
        // Read before waitUntilExit — otherwise a >64KB compile log deadlocks the pipe.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (output, process.terminationStatus)
    }
}
