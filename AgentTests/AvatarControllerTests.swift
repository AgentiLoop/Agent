import Testing
import Foundation
import WebKit
@testable import Agent_

// Avatar tabs (AvatarController.swift): the offline text helpers that decide
// what the avatar says and which face it shows per sentence, plus the bundled
// avatar.html JS API. Speech and the Jev expression request are not exercised here.

@MainActor
struct AvatarControllerTests {

    @Test func sentencesSplitAndTrim() {
        #expect(AvatarController.sentences(in: "Build passed. Tests ran!  Ready?") == ["Build passed.", "Tests ran!", "Ready?"])
        #expect(AvatarController.sentences(in: "   ").isEmpty)
    }

    @Test func speakableStripsCodeMarkdownAndURLs() {
        let s = AvatarController.speakable("**Done** see https://example.com/x\n```swift\nlet a = 1\n```\n`foo`")
        #expect(!s.contains("```"))
        #expect(!s.contains("let a"))
        #expect(!s.contains("https://"))
        #expect(!s.contains("*"))
        #expect(s.contains("link"))
        #expect(s.hasPrefix("Done"))
    }

    @Test func speakableRewritesGoalReachedMarker() {
        #expect(AvatarController.speakable("AUTOPILOT: GOAL REACHED all good").hasPrefix("Goal reached."))
    }

    @Test func speakableShortensPathsToFileNames() {
        let s = AvatarController.speakable("Edited `Agent/Views/Avatar/AvatarController.swift` and /Users/x/Agent/.agent/progress.md, see [docs](https://a.b/c). Pick red and/or blue.")
        #expect(s == "Edited AvatarController.swift and progress.md, see docs. Pick red and/or blue.")
    }

    @Test func expressionKeywords() {
        #expect(AvatarController.expression(for: "The build failed.") == "sad")
        #expect(AvatarController.expression(for: "I can\u{2019}t reach the server.") == "sad")
        #expect(AvatarController.expression(for: "Wow, that was fast.") == "surprised")
        #expect(AvatarController.expression(for: "Never do that again!") == "angry")
        #expect(AvatarController.expression(for: "All done.") == "happy")
        #expect(AvatarController.expression(for: "Should I continue?") == "thinking")
        #expect(AvatarController.expression(for: "I'm investigating the logs.") == "thinking")
        #expect(AvatarController.expression(for: "The file is here.") == "neutral")
    }

    @Test func expressionMatchesWholeWordsOnly() {
        #expect(AvatarController.expression(for: "The branch was abandoned.") == "neutral")
        #expect(AvatarController.expression(for: "A terror film.") == "neutral")
        #expect(AvatarController.expression(for: "Never mind.") == "neutral") // angry needs "!"
    }

    /// The bundled avatar.html loads in a WKWebView and exposes the JS API
    /// AvatarController calls, with the same expression names Swift offers Jev.
    @Test func bundledAvatarPageExposesControllerAPI() async throws {
        let url = try #require(Bundle.main.url(forResource: "avatar", withExtension: "html"))
        let web = WKWebView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        var ready = false
        for _ in 0..<100 where !ready {
            try await Task.sleep(for: .milliseconds(100))
            ready = (try? await web.evaluateJavaScript("typeof avatar")) as? String == "object"
        }
        #expect(ready)
        let names = try await web.evaluateJavaScript("avatar.expressions") as? [String]
        #expect(names == AvatarController.expressions)
        _ = try await web.evaluateJavaScript("avatar.setMode('\(AvatarController.mode)');avatar.setLevel(0.3,0.1);avatar.setSpeaking(false);avatar.setEmbedded();1")
    }
}

