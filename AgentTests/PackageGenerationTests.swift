import Testing
import Foundation
@testable import Agent_

// NOTE: `createScript` normalizes names to UpperCamelCase; read/delete do not,
// so tests use CamelCase names to match the file actually written.
@Suite("Package.swift Generation")
@MainActor
struct PackageGenerationTests {
    let service = ScriptService()

    @Test("Package.swift exists after ensurePackage via create")
    func packageSwiftCreated() {
        _ = service.createScript(name: "PkgTest", content: "print(\"pkg\")")
        defer { _ = service.deleteScript(name: "PkgTest") }

        let packagePath = ScriptService.agentsDir.appendingPathComponent("Package.swift").path
        #expect(FileManager.default.fileExists(atPath: packagePath))

        let content = try? String(contentsOfFile: packagePath, encoding: .utf8)
        #expect(content?.contains("swift-tools-version") == true)
        #expect(content?.contains("AgentEventBridges") == true)
    }

    @Test("Package.swift lists created script as dynamic library target")
    func packageIncludesScriptTarget() {
        _ = service.createScript(name: "TargetTest", content: "// target")
        defer { _ = service.deleteScript(name: "TargetTest") }

        let packagePath = ScriptService.agentsDir.appendingPathComponent("Package.swift").path
        let content = try? String(contentsOfFile: packagePath, encoding: .utf8)
        #expect(content?.contains("\"TargetTest\"") == true)
    }

    @Test("Package.swift removes deleted script target")
    func packageRemovesDeletedTarget() {
        _ = service.createScript(name: "RemoveTest", content: "// remove")
        _ = service.deleteScript(name: "RemoveTest")

        let packagePath = ScriptService.agentsDir.appendingPathComponent("Package.swift").path
        let content = try? String(contentsOfFile: packagePath, encoding: .utf8)
        #expect(content?.contains("\"RemoveTest\"") != true)
    }
}
