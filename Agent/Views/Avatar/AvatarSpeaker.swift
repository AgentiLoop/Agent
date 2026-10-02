import AVFoundation

/// Text-to-speech that plays through AVAudioEngine and reports a live
/// loudness (RMS) + zero-crossing-rate envelope in sync with playback,
/// which drives the avatar's mouth and "signal" waves.
/// Ported from ~/Documents/Agent-Avatars/AgentAvatar/Sources/AgentAvatar/Speaker.swift.
@MainActor
final class AvatarSpeaker: NSObject, AVSpeechSynthesizerDelegate {
    var onFrame: ((Float, Float) -> Void)?
    var onSpeaking: ((Bool) -> Void)?
    /// Called only when an utterance plays to the end (not on stop()).
    var onFinished: (() -> Void)?
    /// Each slice of the utterance text as its audio starts playing (the word plus any
    /// spacing/punctuation since the previous slice), so text can appear in step with the voice.
    var onWord: ((String) -> Void)?
    var voice: AVSpeechSynthesisVoice? = AvatarSpeaker.bestVoice()

    private let synth = AVSpeechSynthesizer()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    private var converter: AVAudioConverter?
    private let chunk = 256
    private var env: [(Float, Float)] = []
    private var carry: [Float] = []
    private var scheduled: AVAudioFramePosition = 0
    private var generating = false
    private var token = 0
    private var timer: Timer?
    /// Text being spoken; each word's end offset with the sample position its audio starts at
    /// (willSpeakRange arrives just before that word's buffers); how much text has been reported.
    private var text = ""
    private var words: [(end: Int, at: AVAudioFramePosition)] = []
    private var wordsFired = 0
    private var textEnd = 0

    override init() {
        super.init()
        synth.delegate = self
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    /// One voice per name+quality (the same voice ships for several regions, e.g. en-US and en-GB);
    /// the current region's copy wins.
    static func voices() -> [AVSpeechSynthesisVoice] {
        let code = AVSpeechSynthesisVoice.currentLanguageCode()
        let lang = String(code.prefix(2))
        var seen = Set<String>()
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(lang) }
            .sorted { ($0.language == code ? 1 : 0) > ($1.language == code ? 1 : 0) }
            .filter { seen.insert("\($0.name)|\($0.quality.rawValue)").inserted }
            .sorted { ($0.quality.rawValue, $0.name) > ($1.quality.rawValue, $1.name) }
    }

    /// Daniel for now; otherwise the best voice for the current language.
    static func bestVoice() -> AVSpeechSynthesisVoice? {
        let code = AVSpeechSynthesisVoice.currentLanguageCode()
        return voices().first { $0.name == "Daniel" }
            ?? voices().first { $0.language == code } ?? voices().first
    }

    func speak(_ text: String) {
        stop()
        token += 1
        let my = token
        env = []; carry = []; scheduled = 0; generating = true
        self.text = text; words = []; wordsFired = 0; textEnd = 0
        converter?.reset()
        if !engine.isRunning { try? engine.start() }
        onSpeaking?(true)

        let u = AVSpeechUtterance(string: text)
        u.voice = voice
        synth.write(u) { @Sendable [weak self] buf in
            nonisolated(unsafe) let b = buf
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.receive(b, token: my) }
            }
        }
    }

    /// Word boundaries arrive interleaved with the audio buffers; dispatched on the same
    /// queue as receive() so `scheduled` is the sample position where this word starts.
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let spoken = utterance.speechString
        DispatchQueue.main.async { @Sendable [weak self] in
            MainActor.assumeIsolated { self?.noteWord(ending: characterRange.location + characterRange.length, of: spoken) }
        }
    }

    private func noteWord(ending end: Int, of spoken: String) {
        guard generating, spoken == text else { return }
        words.append((end, scheduled))
    }

    private func receive(_ buf: AVAudioBuffer, token my: Int) {
        guard my == token, let pcm = buf as? AVAudioPCMBuffer else { return }
        if pcm.frameLength == 0 {
            generating = false
            // Nothing was ever scheduled (empty/unspeakable text) — finish now.
            if scheduled == 0 { finish() }
            return
        }
        guard let out = convert(pcm) else { return }
        analyze(out)
        player.scheduleBuffer(out)
        if !player.isPlaying { player.play(); startTimer() }
    }

    func stop() {
        token += 1
        synth.stopSpeaking(at: .immediate)
        player.stop()
        timer?.invalidate(); timer = nil
        generating = false
        onFrame?(0, 0)
        onSpeaking?(false)
    }

    /// Natural end of an utterance: report any trailing text (closing punctuation), then finish.
    private func finish() {
        emitText(upTo: (text as NSString).length)
        stop()
        onFinished?()
    }

    private func emitText(upTo end: Int) {
        guard end > textEnd else { return }
        let ns = text as NSString
        let slice = ns.substring(with: NSRange(location: textEnd, length: min(end, ns.length) - textEnd))
        textEnd = max(textEnd, end)
        onWord?(slice)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { @Sendable [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func tick() {
        guard let nt = player.lastRenderTime, let pt = player.playerTime(forNodeTime: nt) else { return }
        while wordsFired < words.count, words[wordsFired].at <= pt.sampleTime {
            emitText(upTo: words[wordsFired].end)
            wordsFired += 1
        }
        let idx = Int(pt.sampleTime) / chunk
        if idx >= 0 && idx < env.count {
            onFrame?(env[idx].0, env[idx].1)
        } else {
            onFrame?(0, 0)
            if !generating && pt.sampleTime >= scheduled { finish() }
        }
    }

    private func convert(_ input: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        if input.format == format { return input }
        if converter == nil || converter!.inputFormat != input.format {
            converter = AVAudioConverter(from: input.format, to: format)
        }
        guard let conv = converter else { return nil }
        let cap = AVAudioFrameCount(Double(input.frameLength) * format.sampleRate / input.format.sampleRate) + 1024
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: cap) else { return nil }
        var fed = false
        var err: NSError?
        conv.convert(to: out, error: &err) { _, status in
            if fed { status.pointee = .noDataNow; return nil }
            fed = true
            status.pointee = .haveData
            return input
        }
        return err == nil && out.frameLength > 0 ? out : nil
    }

    private func analyze(_ b: AVAudioPCMBuffer) {
        guard let p = b.floatChannelData?[0] else { return }
        carry.append(contentsOf: UnsafeBufferPointer(start: p, count: Int(b.frameLength)))
        var i = 0
        while carry.count - i >= chunk {
            var sum: Float = 0, zc = 0
            for j in i..<(i + chunk) {
                sum += carry[j] * carry[j]
                if j > i && (carry[j] >= 0) != (carry[j - 1] >= 0) { zc += 1 }
            }
            env.append((sqrt(sum / Float(chunk)), Float(zc) / Float(chunk)))
            i += chunk
        }
        carry.removeFirst(i)
        scheduled += AVAudioFramePosition(b.frameLength)
    }
}
