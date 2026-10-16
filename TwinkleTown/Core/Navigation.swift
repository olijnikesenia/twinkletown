import SwiftUI

enum Route: Hashable {
    case map, play(Int), results(LevelResult)
    case shop, customize, garden, leaderboard, achievements, settings, daily, characterSelect
}

@Observable
final class Router {
    var path: [Route] = []

    func go(_ route: Route) { path.append(route) }
    func back() { if !path.isEmpty { path.removeLast() } }
    func home() { path.removeAll() }

    /// Replaces the current screen (e.g. game -> results, results -> next level).
    func replace(with route: Route) {
        if !path.isEmpty { path.removeLast() }
        path.append(route)
    }
}

struct RootView: View {
    enum Phase { case splash, onboarding, chooseCompanion, home }

    @Environment(GameState.self) private var state
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var router = Router()
    @State private var phase: Phase = .splash

    var body: some View {
        @Bindable var router = router
        ZStack {
            switch phase {
            case .splash:
                SplashScreen { phase = nextPhase() }
            case .onboarding:
                OnboardingScreen {
                    state.data.onboardingDone = true
                    withAnimation { phase = nextPhase() }
                }
                .transition(.opacity)
            case .chooseCompanion:
                CharacterSelectScreen(firstTime: true) { withAnimation { phase = .home } }
                    .transition(.move(edge: .trailing))
            case .home:
                NavigationStack(path: $router.path) {
                    HomeScreen()
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: Route.self) { route in
                            destination(route).toolbar(.hidden, for: .navigationBar)
                        }
                }
                .transition(.opacity)
            }

            AchievementBanner()

            if state.pendingCelebration && phase == .home {
                CelebrationView { state.finishCelebration() }
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .environment(router)
        .environment(\.gameReduceMotion, systemReduceMotion || state.data.settings.reducedMotion)
        .onAppear { AudioManager.shared.apply(state.data.settings) }
        .onDisappear { AudioManager.shared.stopMusic() }
        .onChange(of: state.data.settings) { _, new in AudioManager.shared.apply(new) }
        .onChange(of: state.data.onboardingDone) { _, done in
            if !done {
                router.home()
                withAnimation { phase = .onboarding }
            }
        }
    }

    private func nextPhase() -> Phase {
        if !state.data.onboardingDone { return .onboarding }
        return state.data.companion == nil ? .chooseCompanion : .home
    }

    @ViewBuilder private func destination(_ route: Route) -> some View {
        switch route {
        case .map: AdventureMapScreen()
        case let .play(id): LevelPlayScreen(level: LevelDef.level(id) ?? LevelDef.all[0])
        case let .results(result): ResultsScreen(result: result)
        case .shop: ShopScreen()
        case .customize: CustomizationScreen()
        case .garden: GardenScreen()
        case .leaderboard: LeaderboardScreen()
        case .achievements: AchievementsScreen()
        case .settings: SettingsScreen()
        case .daily: DailyRewardsScreen()
        case .characterSelect: CharacterSelectScreen(firstTime: false) { router.back() }
        }
    }
}

/// Pops a friendly banner for every newly unlocked achievement.
struct AchievementBanner: View {
    @Environment(GameState.self) private var state

    var body: some View {
        VStack {
            if let id = state.unlockQueue.first {
                HStack(spacing: 12) {
                    BadgeView(id: id, unlocked: true, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Achievement unlocked!").font(.game(14)).foregroundStyle(Palette.hotPink)
                        Text(id.title).font(.game(18)).foregroundStyle(Palette.text)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .frame(maxWidth: 420)
                .gamePanel()
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .id(id)
                .task(id: id) {
                    feedback(.achievement, haptic: .medium)
                    try? await Task.sleep(for: .seconds(2.6))
                    withAnimation(.spring) { _ = state.unlockQueue.removeFirst() }
                }
            }
            Spacer()
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: state.unlockQueue.first)
        .allowsHitTesting(false)
    }
}
