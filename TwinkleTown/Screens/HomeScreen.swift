import SwiftUI

// MARK: - Screen 4: Home

struct HomeScreen: View {
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width > geo.size.height && geo.size.width > 700
            ZStack {
                // Keep the skyline at its designed aspect so buildings don't stretch on tall screens; it sits just above the menu.
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    NightCityArt(showsMoon: false).frame(height: min(geo.size.width * 0.8, geo.size.height * 0.6))
                    // Night lawn under the houses, running to the bottom edge.
                    LinearGradient(colors: [Color(hex: 0x2E9C7E), Color(hex: 0x1B6656), Color(hex: 0x0F3A3C)], startPoint: .top, endPoint: .bottom)
                        .overlay(alignment: .top) {
                            // Rolling hills along the lawn's top edge, with little glowing flowers.
                            ZStack {
                                Ellipse().fill(Color(hex: 0x37B08C)).frame(width: geo.size.width * 0.9, height: 56).offset(x: -geo.size.width * 0.3)
                                Ellipse().fill(Color(hex: 0x2E9C7E)).frame(width: geo.size.width * 0.9, height: 46).offset(x: geo.size.width * 0.32, y: 4)
                                ForEach(0..<7, id: \.self) { i in
                                    Circle().fill([Palette.pink, Palette.yellow, Palette.crystal][i % 3])
                                        .frame(width: 7, height: 7)
                                        .shadow(color: [Palette.pink, Palette.yellow, Palette.crystal][i % 3], radius: 4)
                                        .offset(x: geo.size.width * (CGFloat(i) / 6 - 0.5) * 0.9, y: CGFloat((i * 7) % 5) - 8)
                                }
                            }
                            .offset(y: -18)
                        }
                        .frame(height: geo.size.height * 0.33)
                }
                .background {
                    ZStack {
                        Color(hex: 0x140A3D)
                        ForEach(0..<14, id: \.self) { i in
                            StarShape().fill(.white.opacity(i % 3 == 0 ? 0.95 : 0.6))
                                .frame(width: i % 3 == 0 ? 11 : 7, height: i % 3 == 0 ? 11 : 7)
                                .position(x: geo.size.width * CGFloat((i * 41 + 11) % 100) / 100,
                                          y: geo.size.height * (0.06 + 0.4 * CGFloat((i * 29 + 5) % 100) / 100))
                        }
                    }
                }
                .ignoresSafeArea()
                CrescentMoon()
                    .frame(width: 64, height: 64)
                    .position(x: geo.size.width * 0.84, y: geo.size.height * 0.25)
                VStack(spacing: 10) {
                    topBar
                    if wide {
                        HStack(spacing: 24) {
                            island(width: min(geo.size.width * 0.45, 460))
                            VStack(spacing: 16) { playButtons; menuGrid(columns: 3) }.frame(maxWidth: 480)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        Spacer(minLength: 0)
                        island(width: min(geo.size.width * 0.82, Device.isPad ? 480 : 340))
                        Spacer(minLength: 0)
                        playButtons.frame(maxWidth: 520)
                        menuGrid(columns: Device.isPad ? 6 : 3).frame(maxWidth: Device.isPad ? 760 : 520)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            state.refreshDaily()
            state.refreshWeek()
        }
    }

    private var topBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(state.data.companion?.theme ?? Palette.sky)
                    CompanionArt(companion: state.data.companion ?? .bibi, appearance: state.data.appearance)
                        .frame(width: 200, height: 240).scaleEffect(0.3).frame(width: 60, height: 72).offset(y: 8)
                }
                .frame(width: 58, height: 58)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white, lineWidth: 3))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(state.data.nickname).font(.game(19)).foregroundStyle(.white).lineLimit(1)
                        Text("Lv \(state.data.playerLevel)").font(.game(14)).foregroundStyle(Palette.text)
                            .padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(Palette.yellow))
                    }
                    GameProgressBar(value: Double(state.data.xpIntoLevel) / Double(PlayerData.xpPerLevel),
                                    colors: [Palette.mint, Palette.green], height: 12)
                        .frame(maxWidth: 160)
                }
                Spacer()
                CounterPill(kind: .stars, value: state.data.stars)
                RoundIconButton(icon: .gear, color: Palette.lilac, size: 46, label: "Settings") { router.go(.settings) }
            }
            HStack(spacing: 8) {
                DiamondIcon(size: 32)
                GameProgressBar(value: Double(state.data.totalDiamonds) / Double(PlayerData.diamondGoal), height: 20)
                Text("\(min(state.data.totalDiamonds, 777))/777").font(.game(17)).foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(state.data.totalDiamonds)))
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Palette.deep.opacity(0.35)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(state.data.totalDiamonds) of 777 diamonds collected")
        }
    }

    private func island(width: CGFloat) -> some View {
        ZStack {
            IslandView(width: width).offset(y: width * 0.22)
            DecorationArt(id: "deco_crystal_tree").frame(width: width * 0.28).offset(x: -width * 0.32, y: -width * 0.04)
            DecorationArt(id: "deco_toadstool").frame(width: width * 0.16).offset(x: width * 0.34, y: width * 0.08)
            CompanionView(companion: state.data.companion ?? .bibi, appearance: state.data.appearance, size: width * 0.45)
                .offset(y: -width * 0.06)
            ForEach(0..<3, id: \.self) { i in
                GemView(color: Palette.gems[[0, 1, 4][i]], size: width * 0.08)
                    .floating(8, duration: 1.2 + Double(i) * 0.4)
                    .offset(x: width * [-0.4, 0.4, 0.2][i], y: -width * [0.3, 0.25, 0.4][i])
            }
        }
        .frame(width: width, height: width * 0.8)
        .floating(6, duration: 2.6)
    }

    private var playButtons: some View {
        HStack(spacing: 12) {
            BigButton(title: "Play \(state.currentLevel.id)", icon: .play, color: Palette.hotPink, height: 66) {
                router.go(.play(state.currentLevel.id))
            }
            BigButton(title: "Map", icon: .map, color: Palette.royal, height: 66) { router.go(.map) }
                .frame(maxWidth: 150)
        }
    }

    private func menuGrid(columns: Int) -> some View {
        let tiles: [(String, GameIcon, Color, Route, Bool)] = [
            ("Shop", .shop, Palette.hotPink, .shop, false),
            ("Dress Up", .wardrobe, Palette.lilac, .customize, false),
            ("Garden", .garden, Palette.green, .garden, false),
            ("Ranks", .trophy, Palette.gold, .leaderboard, false),
            ("Awards", .medal, Palette.orange, .achievements, state.claimableAchievements > 0),
            ("Daily", .gift, Palette.royal, .daily, state.hasDailySomething),
        ]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
            ForEach(tiles, id: \.0) { title, icon, color, route, badge in
                Button {
                    feedback()
                    router.go(route)
                } label: {
                    VStack(spacing: 4) {
                        IconView(icon: icon, size: 30)
                        Text(title).font(.game(15)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity).frame(height: 72)
                }
                .buttonStyle(CandyButtonStyle(color: color, shape: AnyShape(RoundedRectangle(cornerRadius: 22))))
                .overlay(alignment: .topTrailing) { if badge { NotificationDot().offset(x: 4, y: -4) } }
                .accessibilityLabel(title)
            }
        }
    }
}
