import SwiftUI
import WebKit

struct LaunchDecision: Codable, Equatable {
    enum Flow: String, Codable { case game, twinkletown }
    let twinkleFlow: Flow
    let twinkleState: Int
    let url: URL?

    static let game = LaunchDecision(twinkleFlow: .game, twinkleState: 1, url: nil)

    static let defaultPrivacyURL = URL(string: "https://twinkletown.site/privacy?lang=en")!

    var privacyURL: URL? {
        guard isValid, let url,
              ["twinkletown.site", "www.twinkletown.site"].contains(url.host?.lowercased() ?? "") else { return nil }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return path == "privacy" || (path.isEmpty && url.fragment == "privacy") ? url : nil
    }

    var opensGame: Bool { twinkleFlow == .game || privacyURL != nil }

    var isValid: Bool {
        switch twinkleFlow {
        case .game:
            return twinkleState == 1 && url == nil
        case .twinkletown:
            guard twinkleState == 0, let url else { return false }
            return url.scheme?.lowercased() == "https" && url.host != nil
                && url.user == nil && url.password == nil
        }
    }
}

struct LaunchClient {
    var session: URLSession = .shared
    var endpoint = URL(string: "https://twinkletown.site/api/twinkletown-launch")!

    func fetchDecision() async throws -> LaunchDecision {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 12
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Notification consent gates the optional FCM token. No advertising or vendor IDs.
        var payload = ["appid": Bundle.main.bundleIdentifier ?? "com.twinkletown.sparklefriends"]
        if await AppDelegate.authorizationTask?.value == true,
           let token = await PushTokenStore.shared.waitForToken() {
            payload["pushToken"] = token
        }
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decision = try JSONDecoder().decode(LaunchDecision.self, from: data)
        guard decision.isValid else { throw URLError(.badServerResponse) }
        return decision
    }
}

@Observable
final class LaunchConnection {
    private(set) var decision: LaunchDecision?
    private var started = false
    private let defaults: UserDefaults
    static let saveKey = "twinkletown.launchDecision.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.saveKey),
           let cached = try? JSONDecoder().decode(LaunchDecision.self, from: data), cached.isValid {
            decision = cached
        }
    }

    func resolve(fetch: () async throws -> LaunchDecision) async {
        guard decision == nil, !started else { return }
        started = true
        do {
            let result = try await fetch()
            guard result.isValid else { throw URLError(.badServerResponse) }
            let encoded = try JSONEncoder().encode(result)
            defaults.set(encoded, forKey: Self.saveKey)
            decision = result
        } catch {
            // Temporary failures must not permanently pin the installation to a fallback.
            decision = .game
        }
    }
}

private struct LaunchPrivacyURLKey: EnvironmentKey {
    static let defaultValue = LaunchDecision.defaultPrivacyURL
}

extension EnvironmentValues {
    var launchPrivacyURL: URL {
        get { self[LaunchPrivacyURLKey.self] }
        set { self[LaunchPrivacyURLKey.self] = newValue }
    }
}

struct LaunchRootView: View {
    @State private var connection = LaunchConnection()

    var body: some View {
        Group {
            if connection.decision?.opensGame == true {
                RootView()
            } else if let url = connection.decision?.url {
                LaunchWebScreen(url: url)
            } else {
                ZStack {
                    MagicBackground()
                    VStack(spacing: 24) {
                        TwinkleLogo()
                        ProgressView().tint(.white)
                        Text("Connecting to Twinkle Town…")
                            .font(.game(17)).foregroundStyle(.white)

                    }
                    .padding(24)
                }
            }
        }
        .environment(\.launchPrivacyURL, connection.decision?.privacyURL ?? LaunchDecision.defaultPrivacyURL)
        .task { await connection.resolve { try await LaunchClient().fetchDecision() } }
    }
}

