import Foundation
import AgentLLM

/// The single identity for every LLM provider Agent! knows about.
/// Adding a case here forces `LLMProviderSetup.config(for:)` to describe it
/// (endpoint, protocol, capabilities, defaults) — nothing else needs a new switch.
enum APIProvider: String, CaseIterable, Codable, Sendable {
    case claude = "claude"
    case codex = "codex"
    case openAI = "openAI"
    case gemini = "gemini"
    case grok = "grok"
    case mistral = "mistral"
    case vibe = "vibe"
    case deepSeek = "deepSeek"
    case huggingFace = "huggingFace"
    case zAI = "zAI"
    case bigModel = "bigModel"
    case qwen = "qwen"
    case ollama = "ollama"
    case localOllama = "localOllama"
    case vLLM = "vLLM"
    case lmStudio = "lmStudio"
    case miniMax = "miniMax"
    case openRouter = "openRouter"
    case requesty = "requesty"
    case foundationModel = "foundationModel"

    var displayName: String {
        switch self {
        case .claude: "Claude"
        case .codex: "Codex"
        case .openAI: "OpenAI"
        case .gemini: "Google Gemini"
        case .grok: "Grok"
        case .mistral: "Mistral"
        case .vibe: "Mistral Vibe"
        case .deepSeek: "DeepSeek"
        case .huggingFace: "Hugging Face"
        case .ollama: "Ollama"
        case .localOllama: "Local Ollama"
        case .vLLM: "vLLM"
        case .lmStudio: "LM Studio"
        case .zAI: "Z.ai"
        case .bigModel: "BigModel"
        case .qwen: "Qwen"
        case .miniMax: "MiniMax"
        case .openRouter: "OpenRouter"
        case .requesty: "Requesty"
        case .foundationModel: "Apple Intelligence"
        }
    }

    /// Providers offered in the picker UI (Apple Intelligence is surfaced separately).
    static var selectableProviders: [APIProvider] {
        allCases.filter { $0 != .foundationModel }
    }

    /// Keychain account string for this provider's API key. The strings are the
    /// exact legacy values so keys users already stored keep working.
    var keychainAccount: String {
        switch self {
        case .claude, .ollama, .openAI, .deepSeek, .huggingFace, .vLLM:
            "agent.\(rawValue)APIKey"
        default:
            "com.agent.\(rawValue.lowercased())-api-key"
        }
    }

    /// UserDefaults key for the selected model (legacy: Claude's lives under "agentModel").
    var modelDefaultsKey: String { self == .claude ? "agentModel" : "\(rawValue)Model" }

    /// UserDefaults key for the per-provider temperature.
    var temperatureDefaultsKey: String { "\(rawValue)Temperature" }

    /// Registered configuration (endpoint, protocol, capabilities, defaults).
    @MainActor var config: LLMProviderConfig {
        LLMRegistry.shared.provider(rawValue) ?? LLMProviderSetup.config(for: self)
    }

    @MainActor var apiProtocol: LLMAPIProtocol { config.apiProtocol }
}
