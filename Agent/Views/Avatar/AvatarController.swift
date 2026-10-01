import AppKit
import AVFoundation
import WebKit

/// Shared avatar face for Avatar tabs: a WKWebView running avatar.html (from
/// ~/Documents/Agent-Avatars) driven by AvatarSpeaker's live audio envelope.
/// Text is spoken sentence by sentence; each sentence gets its own expression.
@MainActor @Observable
final class AvatarController: NSObject, WKNavigationDelegate {
    static let shared = AvatarController()
    static let expressions = ["neutral", "happy", "sad", "surprised", "angry", "thinking"]
    /// The three animation styles avatar.html supports.
    static let modes: [(id: String, label: String)] = [("mouth", "Mouth"), ("waves", "Waves"), ("both", "Both")]
    private static let modeKey = "avatarAnimationMode"
    private static let voiceKey = "avatarVoiceIdentifier"
    /// Voices offered in the pane's voice menu (current language, best quality first).
    static let voices = AvatarSpeaker.voices()
    /// Spoken when an avatar tab opens, and by the pane's Speak button before any reply exists.
    static let greeting = "Hello, I'm Agent! Type or speak a goal and I'll work on it."

    @ObservationIgnored let webView: WKWebView
    @ObservationIgnored private let speaker = AvatarSpeaker()
    @ObservationIgnored private var queue: [(text: String, expression: String)] = []
    @ObservationIgnored private var jevTask: Task<Void, Never>?

    var speaking = false
    @ObservationIgnored private var working = false
    var expression = "neutral" { didSet { js("avatar.setExpression('\(expression)')") } }
    var mode: String = UserDefaults.standard.string(forKey: AvatarController.modeKey) ?? "both" {
        didSet {
            UserDefaults.standard.set(mode, forKey: Self.modeKey)
            js("avatar.setMode('\(mode)')")
        }
    }
    /// Selected TTS voice identifier; empty = AvatarSpeaker's best default.
    var voiceID: String = UserDefaults.standard.string(forKey: AvatarController.voiceKey) ?? "" {
        didSet {
            UserDefaults.standard.set(voiceID, forKey: Self.voiceKey)
            speaker.voice = AVSpeechSynthesisVoice(identifier: voiceID) ?? AvatarSpeaker.bestVoice()
        }
    }

    override private init() {
        webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        super.init()
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = self
        if let url = Bundle.main.url(forResource: "avatar", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        speaker.onFrame = { [weak self] rms, zcr in self?.js("avatar.setLevel(\(rms),\(zcr))") }
        speaker.onSpeaking = { [weak self] on in self?.js("avatar.setSpeaking(\(on))") }
        speaker.onFinished = { [weak self] in self?.speakNext() }
        if let saved = AVSpeechSynthesisVoice(identifier: voiceID) { speaker.voice = saved }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        js("avatar.setEmbedded();avatar.setExpression('\(expression)');avatar.setMode('\(mode)')")
    }

    private func js(_ s: String) { webView.evaluateJavaScript(s, completionHandler: nil) }

    // MARK: - Speech

    /// Speak `text`, choosing an expression for each sentence. Starts at once
    /// with the keyword faces; if Jev is configured its picks replace them for
    /// the sentences not yet finished when the answer arrives.
    func say(_ text: String) {
        stop()
        let sentences = Self.sentences(in: Self.speakable(text))
        queue = sentences.map { ($0, Self.expression(for: $0)) }
        guard !queue.isEmpty else { return }
        speaking = true
        speakNext()
        jevTask = Task { [weak self] in
            guard let picks = await JevAdvisor.avatarExpressions(for: sentences, options: Self.expressions),
                  !Task.isCancelled, let self else { return }
            let offset = sentences.count - self.queue.count
            for i in self.queue.indices { if let pick = picks[offset + i] { self.queue[i].expression = pick } }
            if self.speaking, offset > 0, let pick = picks[offset - 1] { self.expression = pick }
        }
    }

    func stop() {
        jevTask?.cancel()
        jevTask = nil
        queue.removeAll()
        speaker.stop()
        speaking = false
    }

    /// Show the "thinking" face while the tab's AI works; speech overrides it.
    func setWorking(_ on: Bool) {
        working = on
        if !speaking { expression = on ? "thinking" : "neutral" }
    }

    private func speakNext() {
        guard !queue.isEmpty else {
            speaking = false
            expression = working ? "thinking" : "neutral"
            return
        }
        let next = queue.removeFirst()
        expression = next.expression
        speaker.speak(next.text)
    }

    // MARK: - Text helpers

    /// Strip things that sound bad read aloud: code blocks, markdown, the auto-pilot marker, URLs.
    static func speakable(_ text: String) -> String {
        var t = text.replacingOccurrences(of: "```[\\s\\S]*?```", with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: AgentViewModel.autoPilotGoalReachedMarker, with: "Goal reached.", options: .caseInsensitive)
        t = t.replacingOccurrences(of: "https?://\\S+", with: "link", options: .regularExpression)
        t = t.replacingOccurrences(of: "[`*_#>|]", with: "", options: .regularExpression)
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func sentences(in text: String) -> [String] {
        var out: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { s, _, _, _ in
            if let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { out.append(s) }
        }
        return out
    }

    /// Keyword fallback for picking a face for a sentence. Whole-word matches only
    /// ("abandoned" isn't "done", "terror" isn't "error"); curly apostrophes count as straight.
    nonisolated static func expression(for sentence: String) -> String {
        let t = sentence.lowercased().replacingOccurrences(of: "\u{2019}", with: "'")
        func has(_ words: [String]) -> Bool {
            t.range(of: "\\b(?:" + words.joined(separator: "|") + ")\\b", options: .regularExpression) != nil
        }
        if has(["error", "errors", "failed", "failure", "sorry", "unfortunately", "can't", "cannot", "unable", "blocker", "blockers", "broke", "broken"]) { return "sad" }
        if has(["wow", "amazing", "surprising", "unexpected", "whoa", "incredible"]) { return "surprised" }
        if has(["never", "stop", "forbidden", "denied", "refuse"]) && t.hasSuffix("!") { return "angry" }
        if has(["done", "success", "successful", "complete", "completed", "fixed", "great", "glad", "hello", "welcome", "thanks", "goal reached", "works", "green"]) { return "happy" }
        if t.hasSuffix("?") || has(["let me", "thinking", "consider", "maybe", "perhaps", "investigat\\w*", "remains", "next"]) { return "thinking" }
        return "neutral"
    }
}
