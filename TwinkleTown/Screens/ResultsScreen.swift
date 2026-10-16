import SwiftUI

// MARK: - Screen 9: Level results

struct ResultsScreen: View {
    let result: LevelResult
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @State private var shownStars = 0
    @State private var counted = 0.0

    private var level: LevelDef { LevelDef.level(result.levelID) ?? LevelDef.all[0] }
    private var next: LevelDef? { LevelDef.level(result.levelID + 1) }

    var body: some View {
        ZStack {
            MagicBackground(colors: [Palette.violet, Palette.lilac, Palette.pink])
            ConfettiView()
            ScrollView {
                VStack(spacing: 14) {
                    Text(["Great Job!", "Wonderful!", "Amazing!"][result.rating - 1]).titleStyle(Device.isPad ? 52 : 40)
                        .padding(.top, 20)
                    Text("Level \(result.levelID) complete").font(.game(20)).foregroundStyle(.white)

                    CompanionView(companion: state.data.companion ?? .bibi, appearance: state.data.appearance,
                                  size: Device.isPad ? 200 : 150, happy: true)

                    HStack(spacing: 10) {
                        ForEach(1...3, id: \.self) { i in
                            StarCoin(size: i == 2 ? 74 : 58, face: i <= shownStars)
                                .saturation(i <= shownStars ? 1 : 0)
                                .opacity(i <= shownStars ? 1 : 0.35)
                                .scaleEffect(i <= shownStars ? 1 : 0.7)
                                .offset(y: i == 2 ? -12 : 0)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(result.rating) of 3 stars")

                    VStack(spacing: 12) {
                        if result.isFirstClear { Text("First clear bonus!").font(.game(16)).foregroundStyle(Palette.hotPink) }
                        HStack(spacing: 22) {
                            rewardTile(StarCoin(size: 40), value: Int(Double(result.reward.stars) * counted), label: "stars")
                            rewardTile(DiamondIcon(size: 40), value: Int(Double(result.reward.diamonds) * counted), label: "diamonds")
                            rewardTile(IconView(icon: .plus, color: Palette.green, size: 34), value: Int(Double(result.xp) * counted), label: "XP")
                        }
                        VStack(spacing: 4) {
                            HStack {
                                Text("Diamonds").font(.game(15)).foregroundStyle(Palette.text)
                                Spacer()
                                Text("\(min(state.data.totalDiamonds, 777))/777").font(.game(15)).foregroundStyle(Palette.royal)
                            }
                            GameProgressBar(value: Double(state.data.totalDiamonds) / 777)
                            HStack {
                                Text("Level \(state.data.playerLevel)").font(.game(15)).foregroundStyle(Palette.text)
                                Spacer()
                            }
                            GameProgressBar(value: Double(state.data.xpIntoLevel) / Double(PlayerData.xpPerLevel), colors: [Palette.mint, Palette.green], height: 12)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: 460)
                    .gamePanel()
                    .padding(.horizontal, 20)

                    VStack(spacing: 10) {
                        if let next {
                            BigButton(title: "Next Level", icon: .play, color: Palette.hotPink, height: 62) {
                                router.replace(with: .play(next.id))
                            }
                        } else {
                            Text("You finished every level!").font(.game(20)).foregroundStyle(.white)
                        }
                        HStack(spacing: 10) {
                            BigButton(title: "Replay", icon: .refresh, color: Palette.lilac) { router.replace(with: .play(level.id)) }
                            BigButton(title: "Map", icon: .map, color: Palette.royal) { router.path = [.map] }
                        }
                    }
                    .frame(maxWidth: 460)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            for i in 1...result.rating {
                try? await Task.sleep(for: .seconds(0.35))
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { shownStars = i }
                feedback(.collect, haptic: .medium)
            }
            withAnimation(.easeOut(duration: 1)) { counted = 1 }
            feedback(.reward)
        }
    }

    private func rewardTile<V: View>(_ icon: V, value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            icon
            Text("+\(value)").font(.game(22)).foregroundStyle(Palette.text)
                .contentTransition(.numericText(value: Double(value)))
            Text(label).font(.game(12)).foregroundStyle(Palette.text.opacity(0.6))
        }
        .frame(minWidth: 80)
    }
}
