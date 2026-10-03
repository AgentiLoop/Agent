import SwiftUI
import WebKit

/// Right-hand pane shown for Avatar tabs: the talking face plus speak / listen controls.
struct AvatarPaneView: View {
    @Bindable var viewModel: AgentViewModel
    let tab: ScriptTab
    @Bindable private var avatar = AvatarController.shared

    var body: some View {
        VStack(spacing: 0) {
            AvatarWebView(webView: avatar.webView)
            HStack(spacing: 8) {
                Button {
                    if avatar.speaking {
                        avatar.stop()
                    } else {
                        let last = tab.lastTaskCompletionSummary
                        avatar.say(last.isEmpty ? AvatarController.greeting : last)
                    }
                } label: {
                    Image(systemName: avatar.speaking ? "stop.fill" : "speaker.wave.2.fill")
                }
                .help(avatar.speaking ? "Stop Speaking" : "Speak Last Reply")

                Button {
                    if avatar.speaking { avatar.stop() } // don't let the mic hear the avatar
                    viewModel.toggleDictation()
                } label: {
                    Image(systemName: viewModel.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(viewModel.isListening ? .red : .primary)
                }
                .help(viewModel.isListening ? "Stop Listening" : "Listen")

                Toggle(isOn: $avatar.muted) {
                    Image(systemName: avatar.muted ? "speaker.slash.fill" : "speaker.fill")
                }
                .toggleStyle(.button)
                .help(avatar.muted ? "Unmute — speak replies aloud" : "Mute — facial expressions only, no voice")

                Spacer()
                Picker("Voice", selection: $avatar.voiceID) {
                    ForEach(AvatarController.voices, id: \.identifier) { v in
                        Text(v.quality == .default ? v.name : "\(v.name) (\(v.quality == .premium ? "Premium" : "Enhanced"))").tag(v.identifier)
                    }
                }
                .labelsHidden()
                .frame(minWidth: 70, maxWidth: 120)
                .help("Avatar Voice")

                Picker("Face", selection: $avatar.expression) {
                    ForEach(AvatarController.expressions, id: \.self) { Text($0.capitalized).tag($0) }
                }
                .labelsHidden()
                .frame(minWidth: 70, maxWidth: 110)
            }
            .padding(8)
        }
        .frame(minWidth: 260, idealWidth: 340, maxWidth: 480)
        .onChange(of: tab.isLLMRunning || tab.isLLMThinking, initial: true) { _, working in
            avatar.setWorking(working)
        }
        .background(Color(red: 0.043, green: 0.059, blue: 0.078))
        .environment(\.colorScheme, .dark)
    }
}

/// Hosts the shared avatar WKWebView (re-parented when the pane reappears).
struct AvatarWebView: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView { webView }
    func updateNSView(_ v: WKWebView, context: Context) {}
}
