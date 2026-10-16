import SwiftUI

// MARK: - Screen 15: Settings & profile

struct SettingsScreen: View {
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @Environment(\.launchPrivacyURL) private var privacyURL
    @State private var confirmReset = false
    @State private var webURL: URL?

    var body: some View {
        @Bindable var state = state
        ZStack {
            MagicBackground(colors: [Palette.grape, Palette.violet, Palette.lavender])
            VStack(spacing: 6) {
                ScreenHeader(title: "Settings", onBack: router.back)
                ScrollView {
                    VStack(spacing: 16) {
                        profile
                        VStack(spacing: 10) {
                            toggle("Music", .music, $state.data.settings.music)
                            toggle("Sound effects", .sound, $state.data.settings.sound)
                            toggle("Vibration", .vibration, $state.data.settings.haptics)
                            toggle("Calm motion", .motion, $state.data.settings.reducedMotion)
                        }
                        .padding(16).gamePanel()

                        VStack(spacing: 10) {
                            BigButton(title: "Change friend", icon: .person, color: Palette.royal) { router.go(.characterSelect) }
                            BigButton(title: "Watch the intro again", icon: .play, color: Palette.lilac) { state.restartOnboarding() }
                            BigButton(title: "Website", icon: .map, color: Palette.green) {
                                webURL = URL(string: "https://twinkletown.site")
                            }
                            BigButton(title: "Privacy Policy", icon: .lock, color: Palette.green) { webURL = privacyURL }
                            BigButton(title: "Start over", icon: .trash, color: Palette.hotPink) { confirmReset = true }
                        }
                        .padding(16).gamePanel()
                    }
                    .padding(16)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
            }
            if confirmReset {
                ConfirmDialog(title: "Start over?",
                              message: "This erases all diamonds, stars, items and your garden. Ask a grown-up first!",
                              confirmTitle: "Erase",
                              onConfirm: {
                                  confirmReset = false
                                  state.resetProgress()
                              },
                              onCancel: { confirmReset = false })
            }

        }
        .sheet(isPresented: Binding(get: { webURL != nil }, set: { if !$0 { webURL = nil } }),
               onDismiss: { AudioManager.shared.apply(state.data.settings) }) {
            if let webURL {
                NavigationStack {
                    LaunchWebScreen(url: webURL)
                        .navigationTitle(webURL.host == privacyURL.host && webURL.path == privacyURL.path ? "Privacy Policy" : "Website")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { self.webURL = nil }
                            }
                        }
                }
            }
        }
    }

    private var profile: some View {
        let d = state.data
        return VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(d.companion?.theme ?? Palette.sky)
                    CompanionArt(companion: d.companion ?? .bibi, appearance: d.appearance)
                        .frame(width: 200, height: 240).scaleEffect(0.42).frame(width: 84, height: 100).offset(y: 10)
                }
                .frame(width: 84, height: 84).clipShape(Circle()).overlay(Circle().stroke(.white, lineWidth: 3))
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Name", text: Binding(get: { state.data.nickname },
                                                    set: { state.data.nickname = String($0.prefix(14)) }))
                        .font(.game(22)).foregroundStyle(Palette.text)
                        .padding(.horizontal, 12).frame(height: 44)
                        .background(Capsule().fill(Palette.crystal.opacity(0.5)))
                    Text("Level \(d.playerLevel) · \(d.companion?.name ?? "")").font(.game(15)).foregroundStyle(Palette.text.opacity(0.7))
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                stat("Diamonds", "\(d.totalDiamonds)")
                stat("Stars now", "\(d.stars)")
                stat("Stars earned", "\(d.totalStarsEarned)")
                stat("Levels", "\(d.completedLevels)/\(LevelDef.count)")
                stat("Awards", "\(d.unlockedAchievements.count)/\(AchievementID.allCases.count)")
                stat("Score", "\(d.allTimeScore)")
            }
        }
        .padding(16).gamePanel()
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.game(20)).foregroundStyle(Palette.royal).lineLimit(1).minimumScaleFactor(0.6)
            Text(title).font(.game(12)).foregroundStyle(Palette.text.opacity(0.7))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.crystal.opacity(0.35)))
    }

    private func toggle(_ title: String, _ icon: GameIcon, _ value: Binding<Bool>) -> some View {
        Button {
            feedback()
            withAnimation(.spring(response: 0.3)) { value.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 12) {
                IconView(icon: icon, color: Palette.royal, size: 28)
                Text(title).font(.game(18)).foregroundStyle(Palette.text)
                Spacer()
                ZStack(alignment: value.wrappedValue ? .trailing : .leading) {
                    Capsule().fill(value.wrappedValue ? Palette.green : Color(hex: 0xC5CFDF)).frame(width: 62, height: 34)
                    Circle().fill(.white).frame(width: 28).padding(3).shadow(radius: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(value.wrappedValue ? "On" : "Off")
    }
}
