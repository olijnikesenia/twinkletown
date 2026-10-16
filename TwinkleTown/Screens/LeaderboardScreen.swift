import SwiftUI

// MARK: - Screen 13: Twinkle Leaderboard

struct LeaderboardScreen: View {
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @State private var board: LeaderboardBoard = .weekly
    @State private var rankChange: [LeaderboardBoard: Int] = [:]
    @State private var shownRank: Int?

    var body: some View {
        let entries = state.leaderboard(board)
        let player = entries.first(where: \.isPlayer)
        ZStack {
            MagicBackground(colors: [Palette.grape, Palette.violet, Palette.lilac])
            VStack(spacing: 6) {
                ScreenHeader(title: "Leaderboard", onBack: router.back)
                CategoryTabs(items: LeaderboardBoard.allCases, selection: $board) { $0.title }
                Text("Friendly race with Twinkle Town's in-game animal friends")
                    .font(.game(13, .semibold)).foregroundStyle(.white.opacity(0.9)).multilineTextAlignment(.center).padding(.horizontal)

                if let change = rankChange[board], change != 0 {
                    HStack(spacing: 8) {
                        IconView(icon: .play, color: change > 0 ? Palette.green : Palette.orange, size: 22)
                            .rotationEffect(.degrees(change > 0 ? -90 : 90))
                        Text(change > 0 ? "You moved up \(change) place\(change == 1 ? "" : "s")!" : "Keep playing to climb back up!")
                            .font(.game(16)).foregroundStyle(Palette.text)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8).gamePanel()
                    .transition(.scale.combined(with: .opacity))
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 10) {
                            podium(Array(entries.prefix(3)))
                            LazyVStack(spacing: 8) {
                                ForEach(entries.dropFirst(3)) { e in
                                    LeaderRow(entry: e).id(e.id)
                                }
                            }
                            .frame(maxWidth: 640)
                        }
                        .padding(16)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: entries.map(\.id))
                    }
                    .onChange(of: board) { _, _ in proxy.scrollTo("player", anchor: .center) }
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { withAnimation { proxy.scrollTo("player", anchor: .center) } } }
                }

                if let player {
                    HStack {
                        Text("Your rank").font(.game(16)).foregroundStyle(Palette.text)
                        Spacer()
                        Text("#\(shownRank ?? player.rank)").font(.game(26)).foregroundStyle(Palette.hotPink)
                            .contentTransition(.numericText(value: Double(shownRank ?? player.rank)))
                        Text("\(player.score) pts").font(.game(16)).foregroundStyle(Palette.royal)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .frame(maxWidth: 640)
                    .gamePanel()
                    .padding(.horizontal, 16).padding(.bottom, 8)
                }
            }
        }
        .onAppear { animateRank() }
        .onChange(of: board) { _, _ in animateRank() }
    }

    /// Counts the rank from the last time this board was seen to now.
    private func animateRank() {
        let current = state.playerRank(board)
        let previous = state.consumeRankChange(board)
        guard let previous, previous != current else {
            shownRank = current
            return
        }
        shownRank = previous
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.spring(response: 0.8)) {
                shownRank = current
                rankChange[board] = previous - current
            }
            if current < previous { feedback(.reward, haptic: .medium) }
        }
    }

    private func podium(_ top: [LeaderboardEntry]) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach([1, 0, 2].filter { $0 < top.count }, id: \.self) { i in
                let e = top[i]
                VStack(spacing: 4) {
                    TrophyArt(rank: e.rank).frame(width: 34, height: 34)
                    LeaderAvatar(entry: e, size: i == 0 ? 74 : 60)
                    Text(e.isPlayer ? "You" : e.name.components(separatedBy: " ").first ?? e.name)
                        .font(.game(14)).foregroundStyle(.white).lineLimit(1)
                    Text("\(e.score)").font(.game(13)).foregroundStyle(Palette.yellow)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [[Palette.gold, Color(hex: 0xCAD6EA), Palette.orange][i], .white.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                        .frame(height: [110, 80, 60][i])
                        .overlay(Text("\(e.rank)").font(.game(30, .black)).foregroundStyle(.white).shadow(color: Palette.deep, radius: 0, y: 2))
                }
                .frame(maxWidth: 140)
                .id(e.id)
            }
        }
        .padding(.top, 6)
    }
}

private struct LeaderRow: View {
    let entry: LeaderboardEntry

    var body: some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)").font(.game(20)).foregroundStyle(Palette.text).frame(width: 36)
            LeaderAvatar(entry: entry, size: 46)
            Text(entry.isPlayer ? "\(entry.name) (You)" : entry.name).font(.game(17)).foregroundStyle(Palette.text).lineLimit(1)
            Spacer()
            Text("\(entry.score)").font(.game(17)).foregroundStyle(Palette.royal)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 18).fill(entry.isPlayer ? Palette.yellow : .white.opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(entry.isPlayer ? Palette.hotPink : .white, lineWidth: entry.isPlayer ? 4 : 2))
        .scaleEffect(entry.isPlayer ? 1.03 : 1)
        .accessibilityElement(children: .combine)
    }
}

struct LeaderAvatar: View {
    let entry: LeaderboardEntry
    var size: CGFloat = 46
    @Environment(GameState.self) private var state

    var body: some View {
        ZStack {
            Circle().fill(entry.isPlayer ? entry.species.theme : Palette.gems[max(0, entry.tint)].lighter(0.4))
            CompanionArt(companion: entry.species, appearance: entry.isPlayer ? state.data.appearance : Appearance())
                .frame(width: 200, height: 240).scaleEffect(size / 190).frame(width: size, height: size * 1.2)
                .offset(y: size * 0.18)
                .hueRotation(.degrees(entry.isPlayer ? 0 : Double(entry.tint) * 40 - 60))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 3))
    }
}

struct TrophyArt: View {
    let rank: Int

    var body: some View {
        let color = rank == 1 ? Palette.gold : rank == 2 ? Color(hex: 0xC9D3E6) : Palette.orange
        ZStack {
            IconView(icon: .trophy, color: color.darker(0.2), size: 34).offset(y: 1.5)
            IconView(icon: .trophy, color: color, size: 34)
            StarShape().fill(.white.opacity(0.85)).frame(width: 9, height: 9).offset(y: -6)
        }
    }
}
