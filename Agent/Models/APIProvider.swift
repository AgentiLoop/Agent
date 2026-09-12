import Foundation

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

    static var selectableProviders: [APIProvider] {
        [.claude, .codex, .openAI, .gemini, .grok, .mistral, .vibe, .deepSeek, .huggingFace, .zAI, .bigModel, .qwen, .miniMax, .openRouter, .requesty, .ollama, .localOllama, .vLLM, .lmStudio]
    }
}
