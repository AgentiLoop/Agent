import Testing
import Foundation
@testable import Agent_

// Avatar tabs (AvatarController.swift): the offline text helpers that decide
// what the avatar says and which face it shows per sentence. Speech, the
// WKWebView face and the Jev expression request are not exercised here.

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
}
