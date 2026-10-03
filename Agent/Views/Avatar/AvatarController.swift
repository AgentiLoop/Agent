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
    private static let mutedKey = "avatarMuted"
    /// Voices offered in the pane's voice menu (current language, best quality first).
    static let voices = AvatarSpeaker.voices()
    /// Spoken when an avatar tab opens, and by the pane's Speak button before any reply exists.
    static let greeting = "Hello, I'm Agent! Type or speak a goal and I'll work on it."

    @ObservationIgnored let webView: WKWebView
    @ObservationIgnored private let speaker = AvatarSpeaker()
    @ObservationIgnored private var queue: [(text: String, expression: String)] = []
    @ObservationIgnored private var jevTask: Task<Void, Never>?
    /// Paces the queue while muted (no audio to wait for).
    @ObservationIgnored private var muteTask: Task<Void, Never>?
    /// Gets each slice of spoken text as the voice reaches it (word by word, sentences joined
    /// with a space), so the owner can put the words on screen in step with the voice.
    @ObservationIgnored var onWord: ((String) -> Void)?
    /// Prepended to the next word: " " once a previous sentence has been spoken.
    @ObservationIgnored private var separator = ""
    /// Sentences of the streaming `done` summary already queued; -1 = not streaming.
    @ObservationIgnored private var streamedSentences = -1
    /// The streaming segment's text so far.
    @ObservationIgnored private var streamPartial = ""
    /// The last summary spoken while streaming, so sayReply doesn't repeat it.
    @ObservationIgnored private var streamedSummary = ""

    var speaking = false
    @ObservationIgnored private var working = false
    var expression = "neutral" { didSet { js("avatar.setExpression('\(expression)')") } }
    /// Muted: the face still changes expression sentence by sentence (and the words still appear
    /// on screen), but nothing is spoken and the lips don't move.
    var muted: Bool = UserDefaults.standard.bool(forKey: AvatarController.mutedKey) {
        didSet {
            UserDefaults.standard.set(muted, forKey: Self.mutedKey)
            guard speaking else { return }
            // Switching mid-reply: drop the current sentence's playback/timer and carry on in the new mode.
            muteTask?.cancel(); muteTask = nil
            speaker.stop()
            speakNext()
        }
    }
    var mode: String = UserDefaults.standard.string(forKey: AvatarController.modeKey) ?? "both" {
        didSet {
            UserDefaults.standard.set(mode, forKey: Self.modeKey)
            js("avatar.setMode('\(mode)')")
        }
    }
    /// Selected TTS voice identifier; falls back to AvatarSpeaker.bestVoice() (Daniel) when unset or no longer listed.
    var voiceID: String = UserDefaults.standard.string(forKey: AvatarController.voiceKey)
        .flatMap { id in AvatarController.voices.contains { $0.identifier == id } ? id : nil }
        ?? AvatarSpeaker.bestVoice()?.identifier ?? "" {
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
        speaker.onWord = { [weak self] w in
            guard let self else { return }
            self.onWord?(self.separator + w)
            self.separator = ""
        }
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
    /// Words reach `onWord` as the voice says them.
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

    /// Speak reply text / a `done` summary while it streams: each call gets the segment so far
    /// and queues the sentences that are now complete. "" starts a new segment, first flushing
    /// the previous one (a text block followed by `done`) — it never cuts off speech already queued.
    func streamSummary(_ partial: String) {
        if partial.isEmpty {
            if streamedSentences >= 0 { finishStreamedSummary() }
            streamedSentences = 0
            streamPartial = ""
            return
        }
        guard streamedSentences >= 0 else { return } // late update after finishStreamedSummary
        streamPartial = partial
        // Hold back an unclosed code block until it closes (speakable drops whole blocks).
        var text = partial
        if text.components(separatedBy: "```").count % 2 == 0, let open = text.range(of: "```", options: .backwards) {
            text = String(text[..<open.lowerBound])
        }
        let ready = Self.sentences(in: Self.speakable(text)).dropLast() // last one may still be growing
        enqueue(Array(ready.dropFirst(streamedSentences)))
    }

    /// The segment finished streaming — queue the rest of it (`full` defaults to the text streamed so far).
    func finishStreamedSummary(_ full: String? = nil) {
        guard streamedSentences >= 0 else { return }
        let text = full ?? streamPartial
        enqueue(Array(Self.sentences(in: Self.speakable(text)).dropFirst(streamedSentences)))
        streamedSentences = -1
        streamedSummary = text
    }

    /// Read the task's reply aloud unless it was already spoken while streaming.
    func sayReply(_ text: String) {
        defer { streamedSummary = "" }
        if text != streamedSummary { say(text) }
    }

    private func enqueue(_ sentences: [String]) {
        guard !sentences.isEmpty else { return }
        streamedSentences += sentences.count
        queue += sentences.map { ($0, Self.expression(for: $0)) }
        if !speaking {
            speaking = true
            speakNext()
        }
    }

    func stop() {
        jevTask?.cancel()
        jevTask = nil
        muteTask?.cancel()
        muteTask = nil
        queue.removeAll()
        speaker.stop()
        speaking = false
        separator = ""
        streamedSentences = -1
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
        if muted {
            // No voice: show the whole sentence at once, hold the face for roughly its reading time, then move on.
            onWord?(separator + next.text)
            let hold = min(6.0, max(1.2, Double(next.text.count) * 0.05))
            muteTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(hold))
                guard !Task.isCancelled, let self else { return }
                self.muteTask = nil
                self.speakNext()
            }
        } else {
            speaker.speak(next.text)
        }
        separator = " "
    }

    // MARK: - Text helpers

    /// Strip things that sound bad read aloud: code blocks, markdown, the auto-pilot marker, URLs.
    static func speakable(_ text: String) -> String {
        var t = text.replacingOccurrences(of: "```[\\s\\S]*?```", with: " ", options: .regularExpression)
        t = t.replacingOccurrences(of: AgentViewModel.autoPilotGoalReachedMarker, with: "Goal reached.", options: .caseInsensitive)
        t = t.replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^)]*\\)", with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: "https?://\\S+", with: "link", options: .regularExpression)
        // File paths are read as just the file name: "/Users/x/Agent/Foo.swift" or "Agent/Views/Foo.swift" → "Foo.swift".
        t = t.replacingOccurrences(of: "(?<![\\w/])(?:~|\\.{1,2})?/(?:[\\w.\\-]+/)*([\\w.\\-]+)", with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: "(?<![\\w/])(?:[\\w.\\-]+/)+([\\w\\-]+\\.[A-Za-z]\\w*)", with: "$1", options: .regularExpression)
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
