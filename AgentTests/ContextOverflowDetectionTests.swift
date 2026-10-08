import Testing
import Foundation
@testable import Agent_

/// Overflow / output-cap classification across providers' real error phrasing.
struct ContextOverflowDetectionTests {

    @Test func detectsEveryProvidersOverflowPhrasing() {
        let overflows = [
            "prompt is too long: 210000 tokens > 200000 maximum",                                    // Claude
            "input length and `max_tokens` exceed context limit: 180000 + 64000 > 200000",           // Claude
            "This model's maximum context length is 128000 tokens. However, your messages resulted in 130000 tokens.", // OpenAI
            "Your input exceeds the context window of this model. Please adjust your input and try again. (context_length_exceeded)", // Codex
            "'max_tokens' or 'max_completion_tokens' is too large: 32000. This model's maximum context length is 32768 tokens and your request has 1000 input tokens (32000 > 32768 - 1000).", // vLLM
            "Trying to keep the first 9000 tokens when context the overflows. However, the model is loaded with context length of only 8192 tokens", // LM Studio
            "Context length exceeded",                                                                // LM Studio
            "the request exceeds the available context size, try increasing it",                     // llama.cpp / Ollama
            "input length exceeds the context length"                                                 // Ollama
        ]
        for msg in overflows {
            #expect(AgentViewModel.isContextOverflowMessage(msg), "missed: \(msg)")
        }
    }

    @Test func ignoresUnrelatedErrors() {
        let others = [
            "max_tokens must be a positive integer",
            "Rate limit reached for gpt-4o on tokens per min (TPM)",
            "model 'foo' not found"
        ]
        for msg in others {
            #expect(!AgentViewModel.isContextOverflowMessage(msg), "false positive: \(msg)")
        }
    }

    @Test func parsesReportedWindow() {
        #expect(AgentViewModel.parseReportedContextWindow("This model's maximum context length is 32768 tokens.") == 32768)
        #expect(AgentViewModel.parseReportedContextWindow("loaded with context length of only 8192 tokens") == 8192)
        #expect(AgentViewModel.parseReportedContextWindow("prompt is too long: 210000 tokens > 200000 maximum") == 200000)
        #expect(AgentViewModel.parseReportedContextWindow("model not found") == nil)
    }

    @Test func parsesInputPlusOutputOverflow() {
        let claude = AgentViewModel.parseInputPlusMaxTokensOverflow(
            "input length and `max_tokens` exceed context limit: 180000 + 64000 > 200000")
        #expect(claude?.input == 180000 && claude?.maxTokens == 64000 && claude?.limit == 200000)

        let vllm = AgentViewModel.parseInputPlusMaxTokensOverflow(
            "'max_tokens' or 'max_completion_tokens' is too large: 32000. This model's maximum context length is 32768 tokens and your request has 1000 input tokens (32000 > 32768 - 1000).")
        #expect(vllm?.input == 1000 && vllm?.maxTokens == 32000 && vllm?.limit == 32768)

        let openAI = AgentViewModel.parseInputPlusMaxTokensOverflow(
            "This model's maximum context length is 8192 tokens. However, you requested 9000 tokens (1000 in the messages, 8000 in the completion).")
        #expect(openAI?.input == 1000 && openAI?.maxTokens == 8000 && openAI?.limit == 8192)
    }

    @Test func parsesOutputCaps() {
        let claude = AgentViewModel.parseMaxOutputCap(
            "max_tokens: 500000 > 128000, which is the maximum allowed number of output tokens for claude-opus-4")
        #expect(claude?.requested == 500000 && claude?.limit == 128000 && claude?.model == "claude-opus-4")

        let openAI = AgentViewModel.parseMaxOutputCap(
            "max_tokens is too large: 100000. This model supports at most 16384 completion tokens, whereas you provided 100000.")
        #expect(openAI?.requested == 100000 && openAI?.limit == 16384 && openAI?.model == "")
    }

    @Test func parsesOllamaMissingModel() {
        #expect(AgentViewModel.parseOllamaMissingModel(
            "API error (404): {\"error\": \"model 'nonexistent-model-xyz' not found\"}") == "nonexistent-model-xyz")
        #expect(AgentViewModel.parseOllamaMissingModel(
            "model \"llama3:8b\" not found, try pulling it first") == "llama3:8b")
        #expect(AgentViewModel.parseOllamaMissingModel("API error (404): page not found") == nil)
        #expect(AgentViewModel.parseOllamaMissingModel("model 'x' is loading") == nil)
    }
}
