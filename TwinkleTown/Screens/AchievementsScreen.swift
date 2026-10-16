import SwiftUI

// MARK: - Screen 14: Achievements & diamond collection

struct AchievementsScreen: View {
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @State private var claimed: Reward?

    private let milestones = [10, 50, 100, 250, 500, 777]

    var body: some View {
        ZStack {
            MagicBackground(colors: [Palette.violet, Palette.lilac, Palette.pink])
            VStack(spacing: 6) {
                ScreenHeader(title: "Awards", onBack: router.back)
                ScrollView {
                    VStack(spacing: 16) {
                        collection
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: Device.isPad ? 320 : 300), spacing: 12)], spacing: 12) {
                            ForEach(AchievementID.allCases) { id in AchievementCard(id: id, onClaim: { claim(id) }) }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                }
            }
            if let claimed {
                PopupCard {
                    VStack(spacing: 14) {
                        Text("Reward collected!").font(.game(26)).foregroundStyle(Palette.text)
                        RewardRow(reward: claimed, size: 40)
                        BigButton(title: "Yay!", color: Palette.hotPink) { self.claimed = nil }
                    }
                }
            }
        }
    }

    private func claim(_ id: AchievementID) {
        guard state.claim(id) else { return }
        feedback(.reward, haptic: .medium)
        claimed = id.reward
    }

    private var collection: some View {
        let total = state.data.totalDiamonds
        return VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Palette.crystal.opacity(0.6)).frame(width: 90).blur(radius: 8)
                    DiamondIcon(size: 70)
                }
                .floating(5)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Diamond Collection").font(.game(18)).foregroundStyle(Palette.text)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(total)").font(.game(40, .black)).foregroundStyle(Palette.royal)
                        Text("/ 777").font(.game(22)).foregroundStyle(Palette.text.opacity(0.6))
                    }
                }
                Spacer()
                Text("777").font(.game(34, .black))
                    .foregroundStyle(LinearGradient(colors: [Palette.yellow, .white, Palette.sky], startPoint: .top, endPoint: .bottom))
                    .shadow(color: total >= 777 ? Palette.yellow : Palette.deep.opacity(0.4), radius: total >= 777 ? 10 : 0, y: 2)
                    .padding(10).background(Circle().fill(Palette.deep))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    GameProgressBar(value: Double(total) / 777, height: 22)
                    ForEach(milestones, id: \.self) { m in
                        let reached = total >= m
                        VStack(spacing: 2) {
                            GemView(color: reached ? Palette.royal : Color(hex: 0xB9C6DD), size: 22)
                            Text("\(m)").font(.game(11)).foregroundStyle(Palette.text)
                        }
                        .position(x: geo.size.width * Double(m) / 777 - (m == 777 ? 10 : 0), y: 30)
                    }
                }
            }
            .frame(height: 50)
            if total >= 777 {
                BigButton(title: "Watch the celebration", icon: .play, color: Palette.gold) { state.pendingCelebration = true }
            }
        }
        .padding(16)
        .gamePanel()
    }
}

private struct AchievementCard: View {
    let id: AchievementID
    let onClaim: () -> Void
    @Environment(GameState.self) private var state

    var body: some View {
        let unlocked = state.isUnlocked(id)
        let claimed = state.isClaimed(id)
        let progress = id.progress(state.data)
        HStack(spacing: 12) {
            BadgeView(id: id, unlocked: unlocked, size: 62)
            VStack(alignment: .leading, spacing: 4) {
                Text(id.title).font(.game(17)).foregroundStyle(Palette.text)
                Text(id.detail).font(.game(13, .semibold)).foregroundStyle(Palette.text.opacity(0.65))
                if !unlocked {
                    GameProgressBar(value: Double(progress) / Double(id.goal), colors: [Palette.pink, Palette.hotPink], height: 10)
                    Text("\(progress)/\(id.goal)").font(.game(12)).foregroundStyle(Palette.text.opacity(0.6))
                } else {
                    RewardRow(reward: id.reward, size: 20)
                }
            }
            Spacer(minLength: 0)
            if unlocked && !claimed {
                Button("Claim") { onClaim() }
                    .font(.game(16)).foregroundStyle(.white)
                    .padding(.horizontal, 14).frame(height: 44)
                    .buttonStyle(CandyButtonStyle(color: Palette.hotPink))
                    .overlay(alignment: .topTrailing) { NotificationDot().scaleEffect(0.7).offset(x: 6, y: -6) }
            } else if claimed {
                IconView(icon: .check, color: Palette.green, size: 30)
            }
        }
        .padding(12)
        .gamePanel(unlocked ? .white : Color(hex: 0xEEF2FA))
        .opacity(unlocked ? 1 : 0.85)
    }
}

/// Round achievement badge: a medal with an icon that hints at the achievement.
struct BadgeView: View {
    let id: AchievementID
    let unlocked: Bool
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            StarShape(points: 12, inner: 0.85).fill(unlocked ? Palette.gold : Color(hex: 0xC5CFDF))
            Circle().fill(LinearGradient(colors: unlocked ? [Palette.sky, Palette.royal] : [Color(hex: 0xDDE3EE), Color(hex: 0xAEB9CC)],
                                         startPoint: .top, endPoint: .bottom))
                .padding(size * 0.12)
            Circle().stroke(.white, lineWidth: size * 0.04).padding(size * 0.12)
            Group {
                if unlocked { symbol } else { IconView(icon: .lock, color: .white, size: size * 0.36) }
            }
        }
        .frame(width: size, height: size)
        .saturation(unlocked ? 1 : 0.3)
    }

    @ViewBuilder private var symbol: some View {
        switch id {
        case .firstPuzzle, .perfectPuzzle: GemView(color: Palette.gems[1], size: size * 0.45)
        case .levels10, .levels20: IconView(icon: .map, size: size * 0.4)
        case .memoryMaster: MemoryCardBack().frame(width: size * 0.3, height: size * 0.4)
        case .sortingChampion: GemView(color: Palette.gems[3], shape: .square, size: size * 0.45)
        case .firstPurchase: IconView(icon: .shop, size: size * 0.42)
        case .gardenDesigner: FlowerArt(petal: Palette.pink).frame(width: size * 0.42, height: size * 0.42)
        case .diamonds777:
            Text("777").font(.game(size * 0.24, .black)).foregroundStyle(Palette.yellow)
        default: DiamondIcon(size: size * 0.45)
        }
    }
}

// MARK: - The 777 celebration

struct CelebrationView: View {
    let onClose: () -> Void
    @Environment(GameState.self) private var state
    @Environment(\.gameReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var appear = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0E1F5C), Palette.deep, Color(hex: 0x6A4BD8)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { ctx in
                let t = reduceMotion ? 2 : ctx.date.timeIntervalSince(start)
                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    ZStack {
                        // Rainbow light beams.
                        ForEach(0..<6, id: \.self) { i in
                            Capsule().fill(Palette.rainbow[i].opacity(0.25))
                                .frame(width: 40, height: h * 1.4)
                                .rotationEffect(.degrees(Double(i) * 30 + t * 10))
                                .position(x: w / 2, y: h * 0.35)
                        }
                        // Star fireworks.
                        ForEach(0..<4, id: \.self) { burst in
                            let cycle = (t * 0.5 + Double(burst) * 0.25).truncatingRemainder(dividingBy: 1)
                            let center = CGPoint(x: w * [0.2, 0.8, 0.35, 0.7][burst], y: h * [0.2, 0.18, 0.08, 0.32][burst])
                            ForEach(0..<10, id: \.self) { i in
                                let a = Double(i) * .pi / 5
                                StarShape().fill(Palette.rainbow[(i + burst) % 6])
                                    .frame(width: 14, height: 14)
                                    .opacity(1 - cycle)
                                    .position(x: center.x + cos(a) * cycle * 90, y: center.y + sin(a) * cycle * 90)
                            }
                        }
                        CastleArt(lit: true).frame(width: w * 0.55, height: w * 0.5).position(x: w / 2, y: h * 0.62).opacity(0.9)
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer()
                ZStack {
                    Circle().fill(Palette.crystal.opacity(0.5)).frame(width: 200).blur(radius: 30)
                    DiamondIcon(size: 120).rotationEffect(.degrees(appear ? 0 : -30)).floating(10)
                }
                Text("777").font(.game(Device.isPad ? 130 : 96, .black))
                    .foregroundStyle(LinearGradient(colors: [Palette.yellow, .white, Palette.sky], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Palette.yellow, radius: 18)
                    .scaleEffect(appear ? 1 : 0.3)
                Text("Twinkle Town sparkles again!").titleStyle(26).multilineTextAlignment(.center)
                HStack(spacing: -10) {
                    ForEach(Companion.allCases) { c in CompanionView(companion: c, size: Device.isPad ? 120 : 76, happy: true) }
                }
                Spacer()
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        if let cape = Catalog.item(Catalog.celebrationReward) {
                            ItemArt(item: cape).frame(width: 60, height: 60)
                            Text("You earned the exclusive \(cape.name)!").font(.game(17)).foregroundStyle(Palette.text)
                        }
                    }
                    BigButton(title: "Wear it!", icon: .wardrobe, color: Palette.hotPink) {
                        state.equip(Catalog.celebrationReward)
                        onClose()
                    }
                    BigButton(title: "Hooray!", color: Palette.royal, action: onClose)
                }
                .padding(18)
                .frame(maxWidth: 440)
                .gamePanel()
                .padding(20)
            }
            ConfettiView(count: 40)
        }
        .onAppear {
            feedback(.levelComplete, haptic: .heavy)
            withAnimation(.spring(response: 0.8, dampingFraction: 0.55)) { appear = true }
        }
    }
}
