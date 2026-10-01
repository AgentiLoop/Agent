import AVFoundation

/// Text-to-speech that plays through AVAudioEngine and reports a live
/// loudness (RMS) + zero-crossing-rate envelope in sync with playback,
/// which drives the avatar's mouth and "signal" waves.
/// Ported from ~/Documents/Agent-Avatars/AgentAvatar/Sources/AgentAvatar/Speaker.swift.
@MainActor
final class AvatarSpeaker {
    var onFrame: ((Float, Float) -> Void)?
    var onSpeaking: ((Bool) -> Void)?
    /// Called only when an utterance plays to the end (not on stop()).
    var onFinished: (() -> Void)?
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

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    static func voices() -> [AVSpeechSynthesisVoice] {
        let lang = String(AVSpeechSynthesisVoice.currentLanguageCode().prefix(2))
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(lang) }
            .sorted { ($0.quality.rawValue, $0.name) > ($1.quality.rawValue, $1.name) }
    }

    static func bestVoice() -> AVSpeechSynthesisVoice? {
        let code = AVSpeechSynthesisVoice.currentLanguageCode()
        return voices().first { $0.language == code } ?? voices().first
    }

    func speak(_ text: String) {
        stop()
        token += 1
        let my = token
        env = []; carry = []; scheduled = 0; generating = true
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

    private func receive(_ buf: AVAudioBuffer, token my: Int) {
        guard my == token, let pcm = buf as? AVAudioPCMBuffer else { return }
        if pcm.frameLength == 0 {
            generating = false
            // Nothing was ever scheduled (empty/unspeakable text) — finish now.
            if scheduled == 0 { stop(); onFinished?() }
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

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { @Sendable [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func tick() {
        guard let nt = player.lastRenderTime, let pt = player.playerTime(forNodeTime: nt) else { return }
        let idx = Int(pt.sampleTime) / chunk
        if idx >= 0 && idx < env.count {
            onFrame?(env[idx].0, env[idx].1)
        } else {
            onFrame?(0, 0)
            if !generating && pt.sampleTime >= scheduled { stop(); onFinished?() }
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
