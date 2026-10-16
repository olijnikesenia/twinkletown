import Foundation

// MARK: - Daily rewards & challenges

extension GameState {
    var todayKey: String {
        let c = calendar.dateComponents([.year, .month, .day], from: now())
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Resets challenge progress when the calendar day changes.
    func refreshDaily() {
        let today = todayKey
        guard data.daily.challengeDay != today else { return }
        data.daily.challengeDay = today
        data.daily.progress = [:]
        data.daily.claimedChallenges = []
    }

    /// Three of the five challenges, picked deterministically from the date.
    var todaysChallenges: [DailyChallenge] {
        let all = DailyChallenge.allCases
        let start = Int(Competitors.stableHash(todayKey) % UInt64(all.count))
        return [0, 1, 3].map { all[(start + $0) % all.count] }
    }

    func challengeProgress(_ c: DailyChallenge) -> Int {
        min(c.goal, data.daily.challengeDay == todayKey ? data.daily.progress[c.rawValue, default: 0] : 0)
    }

    func isChallengeClaimed(_ c: DailyChallenge) -> Bool {
        data.daily.challengeDay == todayKey && data.daily.claimedChallenges.contains(c.rawValue)
    }

    func recordChallenge(_ c: DailyChallenge, amount: Int = 1) {
        guard amount > 0 else { return }
        refreshDaily()
        data.daily.progress[c.rawValue] = min(c.goal, data.daily.progress[c.rawValue, default: 0] + amount)
    }

    @discardableResult
    func claimChallenge(_ c: DailyChallenge) -> Bool {
        refreshDaily()
        guard todaysChallenges.contains(c), challengeProgress(c) >= c.goal, !isChallengeClaimed(c) else { return false }
        data.daily.claimedChallenges.insert(c.rawValue)
        grant(c.reward)
        return true
    }

    var canClaimDailyReward: Bool { data.daily.lastRewardDay != todayKey }

    /// Missing a day never resets the calendar — no pressure to come back.
    @discardableResult
    func claimDailyReward() -> Reward? {
        guard canClaimDailyReward else { return nil }
        let reward = DailyCalendar.rewards[data.daily.rewardIndex % DailyCalendar.rewards.count]
        data.daily.rewardIndex = (data.daily.rewardIndex + 1) % DailyCalendar.rewards.count
        data.daily.lastRewardDay = todayKey
        grant(reward)
        return reward
    }

    var hasDailySomething: Bool {
        canClaimDailyReward || todaysChallenges.contains { challengeProgress($0) >= $0.goal && !isChallengeClaimed($0) }
    }
}

// MARK: - Leaderboard

extension GameState {
    var currentWeekKey: String {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = calendar.timeZone
        let c = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now())
        return String(format: "%04d-W%02d", c.yearForWeekOfYear ?? 0, c.weekOfYear ?? 0)
    }

    func refreshWeek() {
        let week = currentWeekKey
        guard data.weekKey != week else { return }
        data.weekKey = week
        data.weeklyScore = 0
        data.lastWeeklyRank = nil
    }

    func addScore(_ points: Int) {
        guard points > 0 else { return }
        refreshWeek()
        data.weeklyScore += points
        data.allTimeScore += points
    }

    func leaderboard(_ board: LeaderboardBoard) -> [LeaderboardEntry] {
        let week = currentWeekKey
        var rows: [(id: String, name: String, species: Companion, tint: Int, score: Int, isPlayer: Bool)] =
            Competitors.all.map { c in
                (String(c.id), c.name, c.species, c.tint,
                 board == .weekly ? Competitors.weeklyScore(c, weekKey: week) : c.baseScore, false)
            }
        let playerScore = board == .weekly ? (data.weekKey == week ? data.weeklyScore : 0) : data.allTimeScore
        rows.append(("player", data.nickname, data.companion ?? .bibi, -1, playerScore, true))
        // Ties favour the player.
        rows.sort { $0.score != $1.score ? $0.score > $1.score : $0.isPlayer }
        return rows.enumerated().map { i, r in
            LeaderboardEntry(id: r.id, name: r.name, species: r.species, tint: r.tint,
                             score: r.score, rank: i + 1, isPlayer: r.isPlayer)
        }
    }

    func playerRank(_ board: LeaderboardBoard) -> Int {
        leaderboard(board).first(where: \.isPlayer)?.rank ?? 0
    }

    /// Returns the previously seen rank (for the change animation) and stores the current one.
    func consumeRankChange(_ board: LeaderboardBoard) -> Int? {
        let rank = playerRank(board)
        switch board {
        case .weekly:
            defer { data.lastWeeklyRank = rank }
            return data.lastWeeklyRank
        case .allTime:
            defer { data.lastAllTimeRank = rank }
            return data.lastAllTimeRank
        }
    }
}
