import Foundation
import Testing
@testable import TwinkleTown

struct PrivacyPageTests {
    @Test func playGameIsOnlyAvailableForOurPrivacyPage() {
        for address in ["https://twinkletown.site/privacy?lang=en", "https://www.twinkletown.site/privacy/"] {
            #expect(AppPages.isPrivacy(URL(string: address)))
        }
        for address in ["https://twinkletown.site/", "https://twinkletown.site/support", "https://example.com/privacy", "http://twinkletown.site/privacy", "https://twinkletown.site.evil.com/privacy", "https://user:pass@twinkletown.site/privacy", "https://twinkletown.site:8443/privacy"] {
            #expect(!AppPages.isPrivacy(URL(string: address)))
        }
        #expect(!AppPages.isPrivacy(nil))
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
