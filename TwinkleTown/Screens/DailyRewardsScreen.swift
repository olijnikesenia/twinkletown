import SwiftUI

// MARK: - Daily rewards & challenges

struct DailyRewardsScreen: View {
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @State private var collected: Reward?

    var body: some View {
        ZStack {
            MagicBackground(colors: [Palette.violet, Palette.lilac, Palette.yellow.opacity(0.8)])
            VStack(spacing: 6) {
                ScreenHeader(title: "Daily Gifts", onBack: router.back)
                ScrollView {
                    VStack(spacing: 16) {
                        calendar
                        challenges
                        Text("Gifts wait for you — there's no rush, and missing a day never resets your calendar.")
                            .font(.game(14, .semibold)).foregroundStyle(.white).multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
            if let collected {
                PopupCard {
                    VStack(spacing: 14) {
                        IconView(icon: .gift, color: Palette.hotPink, size: 64)
                        Text("A gift for you!").font(.game(26)).foregroundStyle(Palette.text)
                        RewardRow(reward: collected, size: 40)
                        BigButton(title: "Thank you!", color: Palette.hotPink) { self.collected = nil }
                    }
                }
            }
        }
        .onAppear { state.refreshDaily() }
    }

    private var calendar: some View {
        let next = state.data.daily.rewardIndex
        let canClaim = state.canClaimDailyReward
        return VStack(spacing: 12) {
            Text("7-Day Gift Calendar").font(.game(20)).foregroundStyle(Palette.text)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(0..<7, id: \.self) { day in
                    let reward = DailyCalendar.rewards[day]
                    let isNext = day == next
                    let done = day < next
                    VStack(spacing: 4) {
                        Text("Day \(day + 1)").font(.game(13)).foregroundStyle(Palette.text)
                        if day == 6 {
                            IconView(icon: .gift, color: Palette.hotPink, size: 34)
                        } else if reward.diamonds > 0 {
                            DiamondIcon(size: 32)
                        } else {
                            StarCoin(size: 32)
                        }
                        Text(reward.stars > 0 && reward.diamonds > 0 ? "\(reward.stars)+\(reward.diamonds)" : "\(max(reward.stars, reward.diamonds))")
                            .font(.game(14)).foregroundStyle(Palette.text)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 16).fill(done ? Palette.mint : isNext ? Palette.yellow : Palette.crystal.opacity(0.5)))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(isNext && canClaim ? Palette.hotPink : .white, lineWidth: isNext && canClaim ? 4 : 2))
                    .overlay(alignment: .topTrailing) {
                        if done { IconView(icon: .check, color: Palette.green, size: 20).padding(4) }
                    }
                    .gridCellColumns(day == 6 ? 1 : 1)
                    .accessibilityElement(children: .combine)
                }
            }
            if canClaim {
                BigButton(title: "Open today's gift", icon: .gift, color: Palette.hotPink, height: 58) {
                    if let r = state.claimDailyReward() {
                        feedback(.reward, haptic: .medium)
                        collected = r
                    }
                }
            } else {
                Text("Come back tomorrow for Day \(next + 1)'s gift!").font(.game(16)).foregroundStyle(Palette.royal)
            }
        }
        .padding(16)
        .gamePanel()
    }

    private var challenges: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Challenges").font(.game(20)).foregroundStyle(Palette.text)
            ForEach(state.todaysChallenges) { c in
                let progress = state.challengeProgress(c)
                let claimed = state.isChallengeClaimed(c)
                HStack(spacing: 12) {
                    IconView(icon: .medal, color: progress >= c.goal ? Palette.gold : Palette.sky, size: 34)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(c.title).font(.game(16)).foregroundStyle(Palette.text)
                        GameProgressBar(value: Double(progress) / Double(c.goal), colors: [Palette.mint, Palette.green], height: 10)
                        HStack {
                            Text("\(progress)/\(c.goal)").font(.game(12)).foregroundStyle(Palette.text.opacity(0.6))
                            Spacer()
                            RewardRow(reward: c.reward, size: 16)
                        }
                    }
                    if claimed {
                        IconView(icon: .check, color: Palette.green, size: 30)
                    } else {
                        Button("Claim") {
                            if state.claimChallenge(c) {
                                feedback(.reward, haptic: .medium)
                                collected = c.reward
                            }
                        }
                        .font(.game(15)).foregroundStyle(.white)
                        .padding(.horizontal, 12).frame(height: 40)
                        .buttonStyle(CandyButtonStyle(color: progress >= c.goal ? Palette.hotPink : Color(hex: 0xA9B6CC)))
                        .disabled(progress < c.goal)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 18).fill(Palette.crystal.opacity(0.35)))
            }
        }
        .padding(16)
        .gamePanel()
    }
}
