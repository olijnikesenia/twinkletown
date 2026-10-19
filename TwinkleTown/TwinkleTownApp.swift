import SwiftUI

@main
struct TwinkleTownApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var state = GameState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(state)
                // Dark scheme only to get a white status bar; every game color is set explicitly.
                .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { state.saveNow() }
            if phase == .active {
                state.refreshDaily()
                state.refreshWeek()
            }
        }
    }
}
