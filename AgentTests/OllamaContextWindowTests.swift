import Testing
import Foundation
@testable import Agent_

// Ollama Cloud context detection → compaction threshold.
// Regression guard for the recurring "compacts at 16K" bug: the 32K registry
// fallback (→ 16K threshold) must only apply when no real window is known.
// Windows below are the live /api/show values from Ollama Cloud (Sept 2026).

@MainActor
struct OllamaContextWindowTests {

    /// Live Ollama Cloud windows → expected compaction threshold (maxTokens 0).
    static let cloudWindows: [(model: String, window: Int, threshold: Int)] = [
        ("kimi-k3", 1_048_576, 128_000),
        ("glm-5.3", 1_048_576, 128_000),
        ("deepseek-v4-pro", 1_048_576, 128_000),
        ("minimax-m3", 512_000, 128_000),
        ("kimi-k2.6", 262_144, 128_000),
        ("gemma4:31b", 262_144, 128_000),
        ("minimax-m2.7", 196_608, 98_304),
        ("gpt-oss:120b", 131_072, 65_536),
        ("gpt-oss:20b", 131_072, 65_536),
    ]

    /// Runs `body` with the Ollama window map / override cleared, restoring both after.
    private func withCleanOllamaState(_ body: (AgentViewModel) -> Void) {
        let vm = AgentViewModel()
        let savedWindows = vm.modelContextWindows[.ollama]
        let savedOverride = vm.localOllamaContextSize
        let savedModel = vm.models[.ollama]
        vm.modelContextWindows[.ollama] = [:]
        vm.localOllamaContextSize = 0
        defer {
            vm.modelContextWindows[.ollama] = savedWindows
            vm.localOllamaContextSize = savedOverride
            vm.models[.ollama] = savedModel
        }
        body(vm)
    }

    // MARK: - Threshold at the real windows

    @Test("every Ollama Cloud window compacts at the expected level, never 16K")
    func thresholdsAtCloudWindows() {
        for entry in Self.cloudWindows {
            let t = CompactionState.threshold(for: entry.window)
            #expect(t == entry.threshold, "\(entry.model): \(entry.window) → \(t)")
            #expect(t > 16_000, "\(entry.model) fell to the 32K-fallback threshold")
        }
    }

    @Test("the 16K threshold is exactly the 32K static fallback — its only source")
    func sixteenKIsTheFallbackSignature() {
        #expect(APIProvider.ollama.config.contextSize == 32_000)
        #expect(CompactionState.threshold(for: APIProvider.ollama.config.contextSize) == 16_000)
    }

    @Test("Kimi K3 at 1M: compacts just past 128K, not before")
    func kimiK3Trigger() {
        let state = CompactionState(contextWindow: 1_048_576)
        #expect(state.compactThreshold == 128_000)
        #expect(!state.shouldCompact(estimatedTokens: 16_001))
        #expect(!state.shouldCompact(estimatedTokens: 128_000))
        #expect(state.shouldCompact(estimatedTokens: 128_001))
    }

    @Test("a task started on the 32K fallback picks up the real window mid-task")
    func refreshFromFallback() {
        var state = CompactionState(contextWindow: 32_000)
        #expect(state.compactThreshold == 16_000)
        #expect(state.shouldCompact(estimatedTokens: 20_000))
        state.refreshThreshold(contextWindow: 1_048_576)
        #expect(state.compactThreshold == 128_000)
        #expect(!state.shouldCompact(estimatedTokens: 20_000))
    }

    @Test("reported input_tokens drive the trigger at 1M")
    func reportedUsageDrivesTrigger() {
        var state = CompactionState(contextWindow: 1_048_576)
        let messages: [[String: Any]] = [["role": "user", "content": "hi"], ["role": "assistant", "content": "ok"]]
        state.recordUsage(inputTokens: 130_000, messageCount: messages.count)
        let measured = state.measuredTokens(for: messages)
        #expect(measured == 130_000)
        #expect(state.shouldCompact(estimatedTokens: measured))
    }

    // MARK: - /api/show parsing

    private func showJSON(_ text: String) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any]) ?? [:]
    }

    @Test("parses <arch>.context_length from real JSON (NSNumber-backed)")
    func parsesModelInfo() {
        let json = showJSON(#"{"capabilities":["completion","tools"],"model_info":{"general.architecture":"kimi-k3","kimi-k3.context_length":1048576,"general.parameter_count":1000000000000}}"#)
        #expect(AgentViewModel.ollamaContextLength(fromShow: json) == 1_048_576)
    }

    @Test("num_ctx in Modelfile parameters wins over the architecture max")
    func numCtxWins() {
        let json = showJSON(#"{"parameters":"temperature 0.7\nnum_ctx 65536\nstop \"<|end|>\"","model_info":{"llama.context_length":131072}}"#)
        #expect(AgentViewModel.ollamaContextLength(fromShow: json) == 65_536)
    }

    @Test("num_ctx 0 falls through to model_info; nothing → 0")
    func fallThroughAndEmpty() {
        let zero = showJSON(#"{"parameters":"num_ctx 0","model_info":{"qwen3.context_length":262144}}"#)
        #expect(AgentViewModel.ollamaContextLength(fromShow: zero) == 262_144)
        #expect(AgentViewModel.ollamaContextLength(fromShow: showJSON(#"{"model_info":{"general.architecture":"x"}}"#)) == 0)
        #expect(AgentViewModel.ollamaContextLength(fromShow: [:]) == 0)
    }

    // MARK: - contextWindow(for:model:) resolution

    @Test("fetched windows resolve per model; unknown model falls back to 32K")
    func resolvesFetchedWindows() {
        withCleanOllamaState { vm in
            vm.modelContextWindows[.ollama] = Dictionary(uniqueKeysWithValues: Self.cloudWindows.map { ($0.model, $0.window) })
            for entry in Self.cloudWindows {
                let window = vm.contextWindow(for: .ollama, model: entry.model)
                #expect(window == entry.window)
                #expect(CompactionState(contextWindow: window).compactThreshold == entry.threshold)
            }
            #expect(vm.contextWindow(for: .ollama, model: "not-a-model") == 32_000)
        }
    }

    @Test("a tab model other than the global selection still gets its own window")
    func tabModelUsesOwnWindow() {
        withCleanOllamaState { vm in
            vm.models[.ollama] = "gpt-oss:20b"
            vm.modelContextWindows[.ollama] = ["gpt-oss:20b": 131_072, "kimi-k3": 1_048_576]
            #expect(vm.contextWindow(for: .ollama) == 131_072)
            #expect(vm.contextWindow(for: .ollama, model: "kimi-k3") == 1_048_576)
        }
    }

    @Test("user Ollama context size override wins over the fetched window")
    func overrideWins() {
        withCleanOllamaState { vm in
            vm.modelContextWindows[.ollama] = ["kimi-k3": 1_048_576]
            vm.localOllamaContextSize = 65_536
            #expect(vm.contextWindow(for: .ollama, model: "kimi-k3") == 65_536)
        }
    }

    // MARK: - Persistence (the launch-time 16K root cause)

    @Test("fetched windows persist, so a fresh view model starts with the real window")
    func windowsPersistAcrossInstances() {
        withCleanOllamaState { vm in
            vm.modelContextWindows[.ollama] = ["kimi-k3": 1_048_576]
            let stored = UserDefaults.standard.dictionary(forKey: "modelContextWindows.\(APIProvider.ollama.rawValue)") as? [String: Int]
            #expect(stored?["kimi-k3"] == 1_048_576)
            // A second instance re-runs the property initializer (the launch path).
            let fresh = AgentViewModel()
            #expect(fresh.contextWindow(for: .ollama, model: "kimi-k3") == 1_048_576)
            #expect(CompactionState(contextWindow: fresh.contextWindow(for: .ollama, model: "kimi-k3")).compactThreshold == 128_000)
        }
    }

    @Test("ensureContextWindowKnown is a no-op when the window is already known")
    func ensureSkipsKnown() {
        withCleanOllamaState { vm in
            vm.modelContextWindows[.ollama] = ["kimi-k3": 1_048_576]
            vm.ensureContextWindowKnown(for: .ollama, model: "kimi-k3")
            #expect(!vm.fetchingModels.contains(.ollama))
        }
    }
}
