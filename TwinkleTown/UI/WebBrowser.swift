import Combine
import SwiftUI
import WebKit

private struct WebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

@MainActor
final class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var isLoading = false
    @Published private(set) var progress = 0.0

    let webView: WKWebView
    private var downloadDestination: URL?

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.userContentController.addUserScript(WKUserScript(
            source: """
            (() => {
              const clearAutomaticFocus = () => {
                document.querySelectorAll('[autofocus]').forEach(element => element.removeAttribute('autofocus'));
                const active = document.activeElement;
                if (active && /^(INPUT|TEXTAREA|SELECT)$/.test(active.tagName)) active.blur();
              };
              clearAutomaticFocus();
              document.addEventListener('DOMContentLoaded', clearAutomaticFocus, { once: true });
              window.addEventListener('load', clearAutomaticFocus, { once: true });
              setTimeout(clearAutomaticFocus, 300);
              setTimeout(clearAutomaticFocus, 900);
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        ))

        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
    }

    func load(_ url: URL) {
        guard webView.url == nil else { return }
        webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30))
    }

    func goBack() { if webView.canGoBack { webView.goBack() } }
    func goForward() { if webView.canGoForward { webView.goForward() } }
    func reload() { webView.reload() }

    private func refreshState() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progress = 0.12
        refreshState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        progress = 0.65
        refreshState()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progress = 1
        refreshState()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        refreshState()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        refreshState()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased() else {
            decisionHandler(.cancel)
            return
        }

        if scheme == "http" || scheme == "https" || scheme == "about" {
            if navigationAction.shouldPerformDownload {
                decisionHandler(.download)
            } else if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
            return
        }

        decisionHandler(.cancel)
        let externalURL = fallbackURL(for: url) ?? url
        UIApplication.shared.open(externalURL)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(navigationResponse.canShowMIMEType ? .allow : .download)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let requestURL = navigationAction.request.url {
            webView.load(URLRequest(url: requestURL))
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        guard let presenter = Self.topViewController() else { completionHandler(); return }
        let alert = UIAlertController(title: webView.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let presenter = Self.topViewController() else { completionHandler(false); return }
        let alert = UIAlertController(title: webView.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        guard let presenter = Self.topViewController() else { completionHandler(nil); return }
        let alert = UIAlertController(title: webView.title, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(.prompt)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        let safeName = suggestedFilename.replacingOccurrences(of: "/", with: "-")
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent(safeName)
        try? FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        downloadDestination = destination
        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let destination = downloadDestination,
              let presenter = Self.topViewController() else { return }
        let share = UIActivityViewController(activityItems: [destination], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = presenter.view
        share.popoverPresentationController?.sourceRect = CGRect(
            x: presenter.view.bounds.midX,
            y: presenter.view.bounds.midY,
            width: 1,
            height: 1
        )
        presenter.present(share, animated: true)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloadDestination = nil
    }

    private func fallbackURL(for url: URL) -> URL? {
        guard url.scheme?.lowercased() == "intent",
              let marker = url.absoluteString.components(separatedBy: "S.browser_fallback_url=").last,
              marker != url.absoluteString,
              let encoded = marker.components(separatedBy: ";").first,
              let decoded = encoded.removingPercentEncoding else { return nil }
        return URL(string: decoded)
    }

    private static func topViewController(from base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?.rootViewController
        if let navigation = root as? UINavigationController { return topViewController(from: navigation.visibleViewController) }
        if let tab = root as? UITabBarController { return topViewController(from: tab.selectedViewController) }
        if let presented = root?.presentedViewController { return topViewController(from: presented) }
        return root
    }
}

struct LaunchWebScreen: View {
    let url: URL
    @StateObject private var browser = WebViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if browser.isLoading && browser.progress < 1 {
                ProgressView(value: browser.progress).progressViewStyle(.linear).tint(Palette.hotPink)
            }
            WebView(webView: browser.webView).accessibilityIdentifier("webBrowser.webView")
            HStack(spacing: 8) {
                Button(action: browser.goBack) { Image(systemName: "chevron.left") }
                    .disabled(!browser.canGoBack).accessibilityLabel("Previous page")
                Button(action: browser.goForward) { Image(systemName: "chevron.right") }
                    .disabled(!browser.canGoForward).accessibilityLabel("Next page")
                Spacer()
                Button(action: browser.reload) { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Reload")
            }
            .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
            .padding(.horizontal, 12).frame(height: 36).background(.black)
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            AudioManager.shared.stopMusic()
            OrientationLock.apply(.portrait)
            browser.load(url)
        }
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            OrientationLock.apply(.allButUpsideDown)
        }
        .onDisappear { OrientationLock.apply(UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait) }
    }
}
