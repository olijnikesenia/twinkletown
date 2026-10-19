import SwiftUI

enum AppPages {
    static let privacy = URL(string: "https://twinkletown.site/privacy?lang=en")!

    static func isWebsite(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.user == nil && url.password == nil
            && ["twinkletown.site", "www.twinkletown.site"].contains(url.host?.lowercased() ?? "")
            && (url.port == nil || url.port == 443)
    }

    static func isPrivacy(_ url: URL?) -> Bool {
        guard let url, isWebsite(url) else { return false }
        return url.path == "/privacy" || url.path == "/privacy/"
    }
}
