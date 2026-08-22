import AgentAccess
import Foundation
import FoundationModels
import SwiftUI


/// Apple Intelligence mediator — middleman that rephrases/annotates requests for the LLM.
/// Never refuses/blocks. [AI→User]=annotation, [AI→LLM]=rephrased context, [AI→Both]=shared info.
@MainActor
final class AppleIntelligenceMediator: ObservableObject {
    static let shared = AppleIntelligenceMediator()

    /// Timeout for Apple Intelligence to start responding (seconds).
    private static let startTimeout: TimeInterval = 1
    /// Timeout for Apple Intelligence to finish once started (seconds).
    private static let finishTimeout: TimeInterval = 2

    /// Maximum context window size — reads dynamically from the on-device model (macOS 26.4+).
    /// Falls back to 4096 if the model isn't available yet.
    private static var maxContextTokens: Int {
        if case .available = SystemLanguageModel.default.availability {
            return SystemLanguageModel.default.contextSize
        }
        return 4096
    }

    /// Whether Apple Intelligence mediation is enabled.
    /// Defaults to OFF — on-device triage was failing/misfiring in most real-world
    /// tasks (misclassifying intents, wasting a turn before the real LLM ran).
    /// Users can opt back in from the brain-icon popover.
    ///
    /// NOTE: new key name (`...EnabledV2`) so this rollout flips existing installs
    /// back to OFF regardless of what they had stored under the old key.
    @Published var isEnabled: Bool = UserDefaults.standard.object(forKey: "appleIntelligenceMediatorEnabledV2") as? Bool ?? false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "appleIntelligenceMediatorEnabledV2")
        }
    }

    /// Whether to show Apple Intelligence annotations to the user
    @Published var showAnnotationsToUser: Bool = UserDefaults.standard.bool(forKey: "appleIntelligenceShowToUser") {
        didSet {
            UserDefaults.standard.set(showAnnotationsToUser, forKey: "appleIntelligenceShowToUser")
        }
    }

    /// On-device summarization for context compaction (Tier 1). Off → falls through to Tier 2 aggressive pruning.
    @Published var tokenCompressionEnabled: Bool = UserDefaults.standard.object(forKey: "appleIntelligenceTokenCompression") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(tokenCompressionEnabled, forKey: "appleIntelligenceTokenCompression")
        }
    }

    /// Conversational triage — Apple AI answers greetings / small-talk on-device
    /// before the cloud LLM is invoked. Independent of the accessibility-intent
    /// and annotation features so users can turn triage off while still getting
    /// task summaries or on-device UI automation.
    @Published var triageEnabled: Bool = UserDefaults.standard.object(forKey: "appleIntelligenceTriage") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(triageEnabled, forKey: "appleIntelligenceTriage")
        }
    }

    /// Brain icon style is a live blend of every active sub-feature's toggle
    /// color, so a glance at the toolbar shows what the mediator is allowed to
    /// do. Disabled master = gray. Only the master on = Apple-AI blue. Otherwise
    /// the active colors are rendered as an `AngularGradient` so multiple hues
    /// appear simultaneously instead of averaging into a single muddy tint.
    var brainIconColor: AnyShapeStyle {
        if !isEnabled { return AnyShapeStyle(Color.gray) }

        // Active toggle colors. Master always contributes so the icon never
        // drifts away from "Apple-AI blue" entirely.
        var colors: [Color] = []
        colors.append(Color(red: 0.0,  green: 0.48, blue: 1.00))   // system blue (master)
        if triageEnabled            { colors.append(Color(red: 0.20, green: 0.78, blue: 0.35)) } // system green
        if showAnnotationsToUser    { colors.append(Color(red: 1.00, green: 0.40, blue: 0.75)) } // hot pink
        if tokenCompressionEnabled  { colors.append(Color(red: 0.69, green: 0.32, blue: 0.87)) } // system purple

        // Only the master is on → flat blue, no gradient.
        if colors.count == 1 { return AnyShapeStyle(colors[0]) }

        // Multiple toggles → angular gradient that wraps around the icon so
        // every active color is visible simultaneously.
        var stops = colors
        stops.append(colors[0]) // close the loop so the gradient seams cleanly
        return AnyShapeStyle(
            AngularGradient(
                gradient: Gradient(colors: stops),
                center: .center
            )
        )
    }



    // MARK: - Conversation Context (for Apple AI session)

    /// Known agent script names (lowercase) for direct command matching.
    /// Updated by the ViewModel when scripts are loaded/changed.
    static var knownAgentNames: Set<String> = []

    /// Last task prompt from the user
    private var lastUserPrompt: String?

    /// Last Apple AI annotation (for context continuity)
    private var lastAppleAIMessage: String?

    /// Last LLM response summary (truncated to fit context window)
    private var lastLLMResponse: String?

    /// Running summary of conversation for context
    private var conversationSummary: String?

    private var session: LanguageModelSession?

    /// Represents an Apple Intelligence annotation
    struct Annotation {
        enum Target {
            case user // Only show to user
            case llm // Inject into LLM context
            case both // Show to both
        }

        let target: Target
        let content: String
        let timestamp: Date

        /// Formatted output with appropriate flow tag
        var formatted: String {
            let arrow: String
            switch target {
            case .user: arrow = "🍎 👉 👤"
            case .llm: arrow = "🍎 👉 🧠"
            case .both: arrow = "🍎 👉 👤🧠"
            }
            return "\(arrow) \(content)"
        }
    }

    private init() {
        // Initialize with defaults
        if !UserDefaults.standard.bool(forKey: "appleIntelligenceMediatorConfigured") {
            showAnnotationsToUser = true
            UserDefaults.standard.set(true, forKey: "appleIntelligenceMediatorConfigured")
        }
    }

    /// Check if Apple Intelligence is available
    static var isAvailable: Bool {
        switch SystemLanguageModel.default.availability {
        case .available: return true
        case .unavailable: return false
        }
    }

    static var unavailabilityReason: String {
        switch SystemLanguageModel.default.availability {
        case .available: return ""
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence is not enabled in System Settings."
            case .deviceNotEligible:
                return "This device is not eligible for Apple Intelligence."
            case .modelNotReady:
                return "Apple Intelligence model is downloading or not ready."
            @unknown default:
                return "Apple Intelligence is not available."
            }
        }
    }

    // MARK: - Context Management

    /// Update the conversation context after each exchange
    func updateContext(userPrompt: String?, appleAIMessage: String?, llmResponse: String?) {
        if let prompt = userPrompt {
            // Keep prompts within context limits
            lastUserPrompt = String(prompt.prefix(500))
        }
        if let aiMsg = appleAIMessage {
            // Keep AI messages brief
            lastAppleAIMessage = String(aiMsg.prefix(200))
        }
        if let llm = llmResponse {
            // Truncate LLM response to avoid blowing context window
            lastLLMResponse = String(llm.prefix(1000))
        }
    }

    /// Build context string for the session instructions (fits within ~4096 token window)
    /// System instructions for Apple AI. Injects previous turn so "again" / "do it again" resolves.
    private func buildContextInstructions() -> String {
        var contextBlock = ""
        if let prev = lastUserPrompt, !prev.isEmpty {
            contextBlock += "\nPrevious conversation:"
            contextBlock += "\n- User said: \"\(prev)\""
            if let aiMsg = lastAppleAIMessage, !aiMsg.isEmpty {
                contextBlock += "\n- Assistant annotated: \"\(aiMsg)\""
            }
            if let llmResp = lastLLMResponse, !llmResp.isEmpty {
                let snippet = String(llmResp.prefix(300))
                contextBlock += "\n- AI responded: \"\(snippet)\""
            }
            contextBlock += "\n\nNow the user says something new. Resolve pronouns and vague references using the previous conversation."
        }
        return """
        You rephrase user requests to help an AI assistant understand them better. You are a middleman, NOT a gatekeeper.
        \(contextBlock)

        Rules:
        - NEVER refuse, block, or judge a request. You do NOT decide what is allowed.
        - Reply with 1 sentence only. Never multiple lines.
        - Rephrase or add brief context to clarify the user's intent for the AI.
        - If the request references a previous action (e.g. "again", "do it again", "same thing"), expand it to the full action.
        - If the request is already clear and self-contained, reply with nothing.
        - Never include tags, labels, or prefixes like [AI], LLM:, User:, CLEAR, etc.
        - NEVER change agent names, tool names, script names, or identifiers.
        - Just give the plain helpful text. Nothing else.
        """
    }

    /// Deterministic generation options for intent parsing — low temperature for consistent results.
    private static let deterministicOptions = GenerationOptions(sampling: .greedy, temperature: 0.0)

    /// Slightly creative generation options for annotations and summaries.
    private static let annotationOptions = GenerationOptions(temperature: 0.3)

    private func ensureSession() -> LanguageModelSession {
        // Always create a fresh session with current context to avoid stale/stuck state
        let s = LanguageModelSession(
            model: .default,
            instructions: Instructions(buildContextInstructions())
        )
        session = s
        return s
    }

    /// Wraps a session.respond call with timeout.
    /// Returns nil on timeout so the request goes straight to the LLM.
    private func respondWithTimeout(_ session: LanguageModelSession, prompt: String, label: String, options: GenerationOptions? = nil) async -> String? {

        let startLimit = Self.startTimeout
        let finishLimit = Self.finishTimeout

        do {
            let content: String = try await withThrowingTaskGroup(of: String.self) { group in
                group.addTask {
                    // Start timeout — must begin responding within startTimeout
                    let startDeadline = CFAbsoluteTimeGetCurrent()
                    let response = if let opts = options {
                        try await session.respond(to: prompt, options: opts)
                    } else {
                        try await session.respond(to: prompt)
                    }
                    let startElapsed = CFAbsoluteTimeGetCurrent() - startDeadline
                    if startElapsed > startLimit {
                        throw CancellationError()
                    }
                    return response.content
                }
                group.addTask {
                    // Finish timeout — entire call must complete within finishTimeout
                    try await Task.sleep(for: .seconds(finishLimit))
                    throw CancellationError()
                }
                guard let result = try await group.next() else {
                    throw CancellationError()
                }
                group.cancelAll()
                return result
            }

            return content
        } catch {
            self.session = nil
            return nil
        }
    }

    /// Generate summary annotation after LLM task completion; updates context. Paraphrases when no tool calls.
    func summarizeCompletion(summary: String, commandsRun: [String]) async -> Annotation? {
        guard isEnabled && showAnnotationsToUser && Self.isAvailable else { return nil }

        // Store a truncated version for context (keep within token limits)
        let summaryForContext: String
        if summary.count > 500 {
            summaryForContext = String(summary.prefix(200)) + "..."
        } else {
            summaryForContext = summary
        }
        lastLLMResponse = summaryForContext

        let session = ensureSession()

        // Different behavior based on whether tools were used
        let prompt: String
        if commandsRun.isEmpty {
            prompt = """
            The AI responded: "\(String(summary.prefix(800)))"

            Summarize the key point in 1 sentence. If trivial, reply with nothing.
            """
        } else {
            prompt = """
            Task completed. Summary: "\(summary)"
            Commands: \(commandsRun.joined(separator: ", "))

            Summarize the outcome in 1 sentence. If trivial, reply with nothing.
            """
        }

        do {
            guard let content = await respondWithTimeout(session, prompt: prompt, label: "summarize", options: Self.annotationOptions) else {
                return nil
            }
            let trimmed = sanitize(content)
            if trimmed.isEmpty {
                return nil
            }
            return Annotation(target: .both, content: trimmed, timestamp: Date())
        }
    }

    /// Explain an error that occurred during tool execution
    func explainError(toolName: String, error: String) async -> Annotation? {
        guard isEnabled && showAnnotationsToUser && Self.isAvailable else { return nil }

        let session = ensureSession()
        let prompt = """
        Error in \(toolName): \(error.prefix(300))

        Explain in 1 sentence and suggest a fix.
        """

        guard let content = await respondWithTimeout(session, prompt: prompt, label: "explainError", options: Self.annotationOptions) else {
            return nil
        }
        let trimmed = sanitize(content)
        if trimmed.isEmpty {
            return nil
        }
        return Annotation(target: .user, content: trimmed, timestamp: Date())
    }

    /// Provide suggestions for what the user might want to do next
    func suggestNextSteps(context: String) async -> Annotation? {
        guard isEnabled && showAnnotationsToUser && Self.isAvailable else { return nil }

        let session = ensureSession()
        let prompt = """
        Context: \(context.prefix(500))

        Suggest the next step in 1 sentence. If none obvious, reply with nothing.
        """

        guard let content = await respondWithTimeout(session, prompt: prompt, label: "nextSteps", options: Self.annotationOptions) else {
            return nil
        }
        let trimmed = sanitize(content)
        if trimmed.isEmpty {
            return nil
        }
        return Annotation(target: .user, content: trimmed, timestamp: Date())
    }

    // MARK: - Conversation Triage

    /// Triage result: Apple AI answers, or pass through to the LLM.
    enum TriageResult {
        case answered(String) // Apple AI handled it — show this text and skip LLM
        case passThrough // Needs tools/LLM — proceed normally
    }

    // extractGoogleQuery + matchDirectCommand removed. Run/list/read/delete/google
    // commands now flow through the cloud LLM's tools (agent_script, web_search, etc.).

    /// Resolve common site names to their URLs (e.g. "linkedin" → "linkedin.com")
    private static let siteNames: [String: String] = [
        "linkedin": "linkedin.com", "linked in": "linkedin.com",
        "facebook": "facebook.com", "face book": "facebook.com",
        "twitter": "twitter.com", "x": "x.com",
        "instagram": "instagram.com", "insta": "instagram.com",
        "youtube": "youtube.com", "yt": "youtube.com",
        "reddit": "reddit.com",
        "github": "github.com",
        "gmail": "gmail.com", "google mail": "gmail.com",
        "google": "google.com",
        "amazon": "amazon.com",
        "ebay": "ebay.com",
        "netflix": "netflix.com",
        "spotify": "spotify.com",
        "pinterest": "pinterest.com",
        "tiktok": "tiktok.com", "tik tok": "tiktok.com",
        "wikipedia": "wikipedia.org", "wiki": "wikipedia.org",
        "stackoverflow": "stackoverflow.com", "stack overflow": "stackoverflow.com",
        "apple": "apple.com",
        "microsoft": "microsoft.com",
        "slack": "slack.com",
        "discord": "discord.com",
        "twitch": "twitch.tv",
        "hacker news": "news.ycombinator.com", "hackernews": "news.ycombinator.com", "hn": "news.ycombinator.com",
    ]

    private static func resolveSiteName(_ token: String) -> String {
        let lower = token.lowercased()
        if let url = siteNames[lower] { return url }
        return token
    }

    /// Local pattern check for purely conversational messages. Defaults to passThrough — when in doubt, let the LLM handle it.
    private static func isConversationalPrompt(_ message: String) -> Bool {
        let lower = message.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Must be short — long prompts are almost always tasks
        guard lower.count < 80 else { return false }
        // Known social patterns
        let greetings = [
            "hello",
            "hi",
            "hey",
            "howdy",
            "hola",
            "yo",
            "sup",
            "good morning",
            "good afternoon",
            "good evening",
            "good night"
        ]
        let thanks = ["thanks", "thank you", "thx", "ty", "appreciated", "cheers"]
        let farewells = ["bye", "goodbye", "see you", "later", "goodnight", "cya"]
        let social = [
            "how are you",
            "what are you",
            "who are you",
            "what can you do",
            "how's it going",
            "what's up",
            "whats up",
            "tell me about yourself",
            "nice to meet you",
            "i'm doing",
            "i am doing",
            "doing well",
            "doing good",
            "not bad",
            "i'm fine",
            "i am fine"
        ]
        // Check exact match or starts-with for greetings (e.g. "hi agent", "hello there")
        for g in greetings {
            if lower == g || lower.hasPrefix(g + " ") { return true }
        }
        for t in thanks {
            if lower == t || lower.hasPrefix(t + " ") { return true }
        }
        for f in farewells {
            if lower == f || lower.hasPrefix(f + " ") { return true }
        }
        for s in social {
            if lower.contains(s) { return true }
        }
        return false
    }

    /// Triage a prompt: answer greetings / small-talk on-device. Everything
    /// else — including UI automation — falls through to the cloud LLM, which
    /// drives the accessibility tools directly.
    func triagePrompt(
        _ message: String,
        appendLog: @escaping @Sendable @MainActor (String) -> Void
    ) async -> TriageResult {
        guard isEnabled && Self.isAvailable else {
            if !isEnabled { appendLog("🍎 ⏭ Mediator disabled") }
            else { appendLog("🍎 ⏭ Apple AI unavailable — \(Self.unavailabilityReason)") }
            return .passThrough
        }
        // Local classification — no AI needed. Triage can be disabled separately
        // from the other Apple-AI features; when off we never spend an on-device
        // turn answering greetings / small-talk.
        guard triageEnabled else { return .passThrough }
        guard Self.isConversationalPrompt(message) else { return .passThrough }
        // Ask Apple AI to answer (not classify)
        let session = ensureSession()
        let prompt = """
        You are Agent, a friendly macOS assistant. Reply to the user in 1-2 sentences. Be warm and concise.

        User: "\(message)"
        """
        guard let content = await respondWithTimeout(session, prompt: prompt, label: "triage", options: Self.deterministicOptions) else {
            return .passThrough
        }
        let trimmed = sanitize(content)
        let upper = trimmed.uppercased()
        // If Apple AI refused, gave a useless response, or expressed uncertainty, pass through to LLM.
        // Never let Apple AI claim completion unless the response is substantive.
        let giveUpPhrases = [
            "I CAN'T", "I CANNOT", "I'M UNABLE", "NOT ABLE TO",
            "I DON'T KNOW", "NOT SURE", "I'M NOT SURE",
            "COULDN'T", "COULD NOT", "TRY AGAIN", "NO RESULT"
        ]
        if trimmed.count < 5 || giveUpPhrases.contains(where: { upper.contains($0) }) {
            return .passThrough
        }
        lastAppleAIMessage = String(trimmed.prefix(200))
        return .answered(trimmed)
    }

    /// Clear the session and conversation context to start fresh (call when switching contexts or starting a new conversation)
    func resetSession() {
        session = nil
        lastUserPrompt = nil
        lastAppleAIMessage = nil
        lastLLMResponse = nil
        conversationSummary = nil
    }

    /// Clear all conversation context (call when user clears the chat)
    func clearContext() {
        lastUserPrompt = nil
        lastAppleAIMessage = nil
        lastLLMResponse = nil
        conversationSummary = nil
        session = nil
    }

    /// Strip tags, labels, and junk that Apple AI sometimes echoes back
    private func sanitize(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove any [AI ...] tags, [AI → User], LLM:, CLEAR, etc.
        let patterns = [
            #"\[AI\s*→?\s*(?:User|LLM|Both)\]"#,
            #"\[AI\s+Context\]"#,
            #"(?i)^CLEAR$"#,
            #"(?i)^LLM:\s*$"#,
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) {
                text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
            }
        }
        // Collapse multiple newlines/whitespace into single space, trim again
        text = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return text
    }

    /// The current session's transcript — the framework's built-in conversation history.
    /// Useful for inspecting what the on-device model has seen in the current session.
    var transcript: Transcript? {
        session?.transcript
    }

    /// Get the current conversation context for debugging/inspection
    func getContextStatus() -> String {
        var parts: [String] = []
        if let prompt = lastUserPrompt { parts.append("Last user prompt: \(prompt.prefix(100))...") }
        if let aiMsg = lastAppleAIMessage { parts.append("Last Apple AI: \(aiMsg.prefix(100))...") }
        if let llm = lastLLMResponse { parts.append("Last LLM: \(String(llm.prefix(100)))...") }
        if let summary = conversationSummary { parts.append("Summary: \(summary)") }
        if let t = session?.transcript {
            parts.append("Transcript entries: \(t.count)")
        }
        return parts.isEmpty ? "No context stored" : parts.joined(separator: "\n")
    }

}
