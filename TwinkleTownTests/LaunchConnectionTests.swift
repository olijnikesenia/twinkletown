import Foundation
import Testing
@testable import TwinkleTown

@MainActor
struct LaunchConnectionTests {
    private func isolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "launch-tests-\(UUID().uuidString)")!
    }

    @Test func nativeAndWebDecisionsAreRestoredWithoutRequestingAgain() async throws {
        let web = LaunchDecision(twinkleFlow: .twinkletown, twinkleState: 0,
                                 url: URL(string: "https://example.com/experience"))
        for expected in [LaunchDecision.game, web] {
            let defaults = isolatedDefaults()
            defer { defaults.removeObject(forKey: LaunchConnection.saveKey) }
            var requests = 0
            let first = LaunchConnection(defaults: defaults)
            await first.resolve { requests += 1; return expected }
            #expect(first.decision == expected)
            let second = LaunchConnection(defaults: defaults)
            await second.resolve { requests += 1; throw URLError(.notConnectedToInternet) }
            #expect(second.decision == expected)
            #expect(requests == 1)
        }
    }

    @Test func privacyDecisionOpensGameAndKeepsStatusAndURLAcrossLaunches() async {
        let defaults = isolatedDefaults()
        defer { defaults.removeObject(forKey: LaunchConnection.saveKey) }
        let privacy = LaunchDecision(twinkleFlow: .twinkletown, twinkleState: 0,
                                     url: URL(string: "https://twinkletown.site/privacy?lang=en"))
        let first = LaunchConnection(defaults: defaults)
        await first.resolve { privacy }
        #expect(first.decision?.opensGame == true)
        #expect(first.decision?.privacyURL == privacy.url)
        let restored = LaunchConnection(defaults: defaults)
        await restored.resolve { Issue.record("Saved privacy must not request API again"); return .game }
        #expect(restored.decision == privacy)
        #expect(restored.decision?.twinkleState == 0)
        #expect(restored.decision?.opensGame == true)
        #expect(restored.decision?.privacyURL == privacy.url)
        let unrelated = LaunchDecision(twinkleFlow: .twinkletown, twinkleState: 0,
                                       url: URL(string: "https://example.com/privacy"))
        #expect(!unrelated.opensGame)
        #expect(unrelated.privacyURL == nil)
    }

    @Test func networkFailureOpensGameButRetriesOnNextLaunch() async {
        let defaults = isolatedDefaults()
        defer { defaults.removeObject(forKey: LaunchConnection.saveKey) }
        let first = LaunchConnection(defaults: defaults)
        await first.resolve { throw URLError(.timedOut) }
        #expect(first.decision == .game)
        #expect(defaults.data(forKey: LaunchConnection.saveKey) == nil)
        let second = LaunchConnection(defaults: defaults)
        #expect(second.decision == nil)
        await second.resolve { .game }
        #expect(second.decision == .game)
    }

    @Test func invalidAndCorruptedDecisionsAreNeverUsed() async {
        let defaults = isolatedDefaults()
        defer { defaults.removeObject(forKey: LaunchConnection.saveKey) }
        let invalid = [
            LaunchDecision(twinkleFlow: .game, twinkleState: 0, url: nil),
            LaunchDecision(twinkleFlow: .twinkletown, twinkleState: 0, url: nil),
            LaunchDecision(twinkleFlow: .twinkletown, twinkleState: 0, url: URL(string: "http://example.com")),
            LaunchDecision(twinkleFlow: .twinkletown, twinkleState: 0, url: URL(string: "https://user:pass@example.com"))
        ]
        for decision in invalid {
            #expect(!decision.isValid)
            let connection = LaunchConnection(defaults: defaults)
            await connection.resolve { decision }
            #expect(connection.decision == .game)
            #expect(defaults.data(forKey: LaunchConnection.saveKey) == nil)
        }
        defaults.set(Data("bad json".utf8), forKey: LaunchConnection.saveKey)
        #expect(LaunchConnection(defaults: defaults).decision == nil)
    }
}

struct PushTokenStoreTests {
    @Test func tokenCallbackResolvesPendingLaunch() async {
        let store = PushTokenStore()
        let waiting = Task { await store.waitForToken() }
        await store.setToken("test-fcm-token")
        #expect(await waiting.value == "test-fcm-token")
    }

    @Test func cancellationDoesNotBlockLaunch() async {
        let store = PushTokenStore()
        let waiting = Task { await store.waitForToken() }
        waiting.cancel()
        #expect(await waiting.value == nil)
    }
}
