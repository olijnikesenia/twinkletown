import Foundation

actor PushTokenStore {
    static let shared = PushTokenStore()
    private var token: String?

    func setToken(_ token: String?) { self.token = token }

    /// APNs/FCM may be unavailable; never hold up launch indefinitely.
    func waitForToken() async -> String? {
        for _ in 0..<30 {
            if let token { return token }
            do { try await Task.sleep(for: .milliseconds(100)) } catch { return nil }
        }
        return token
    }
}
