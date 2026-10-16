import Foundation

// MARK: - Economy

extension GameState {
    func addStars(_ amount: Int) {
        guard amount > 0 else { return }
        data.stars += amount
        data.totalStarsEarned += amount
    }

    /// Returns false (and changes nothing) when the balance is too small.
    @discardableResult
    func spendStars(_ amount: Int) -> Bool {
        guard amount >= 0, data.stars >= amount else { return false }
        data.stars -= amount
        return true
    }

    func addDiamonds(_ amount: Int) {
        guard amount > 0 else { return }
        let before = data.totalDiamonds
        data.totalDiamonds += amount
        if before < PlayerData.diamondGoal && data.totalDiamonds >= PlayerData.diamondGoal && !data.celebrationSeen {
            data.owned.insert(Catalog.celebrationReward)
            pendingCelebration = true
        }
    }

    func grant(_ reward: Reward) {
        addStars(reward.stars)
        addDiamonds(reward.diamonds)
        checkAchievements()
    }

    func finishCelebration() {
        data.celebrationSeen = true
        pendingCelebration = false
    }
}

// MARK: - Level progress

extension GameState {
    func isUnlocked(_ level: LevelDef) -> Bool {
        level.id == 1 || data.ratings[level.id - 1] != nil
    }

    func isWorldUnlocked(_ world: Int) -> Bool {
        LevelDef.level(world * LevelDef.perWorld + 1).map(isUnlocked) ?? false
    }

    func rating(_ level: LevelDef) -> Int? { data.ratings[level.id] }

    /// First unlocked level that has not been completed yet (or the last level).
    var currentLevel: LevelDef {
        LevelDef.all.first { data.ratings[$0.id] == nil } ?? LevelDef.all[LevelDef.count - 1]
    }

    /// Applies all rewards for one finished play. Call exactly once per completion.
    @discardableResult
    func completeLevel(_ level: LevelDef, rating rawRating: Int, bonusScore: Int = 0,
                       gemsMatched: Int = 0, crystalsSorted: Int = 0) -> LevelResult {
        let rating = min(3, max(1, rawRating))
        let previous = data.ratings[level.id]
        let reward = ScoreCalculator.reward(world: level.world, rating: rating, previousBest: previous)
        let xp = ScoreCalculator.xp(rating: rating, firstClear: previous == nil)
        let score = ScoreCalculator.score(rating: rating, bonus: bonusScore)

        data.ratings[level.id] = max(previous ?? 0, rating)
        data.xp += xp
        data.stats.gemsMatched += gemsMatched
        data.stats.crystalsSorted += crystalsSorted
        switch level.game {
        case .match:
            data.stats.matchWins += 1
            if rating == 3 { data.stats.perfectPuzzles += 1 }
            recordChallenge(.puzzles2)
        case .sorting: data.stats.sortingWins += 1
        case .memory:
            data.stats.memoryWins += 1
            recordChallenge(.memory1)
        }
        recordChallenge(.levels3)
        recordChallenge(.match20, amount: gemsMatched)
        recordChallenge(.sort15, amount: crystalsSorted)
        addScore(score)
        grant(reward)

        return LevelResult(levelID: level.id, rating: rating, previousBest: previous,
                           reward: reward, xp: xp, score: score)
    }
}

// MARK: - Achievements

extension GameState {
    func checkAchievements() {
        for id in AchievementID.allCases where !data.unlockedAchievements.contains(id.rawValue) {
            if id.progress(data) >= id.goal {
                data.unlockedAchievements.insert(id.rawValue)
                unlockQueue.append(id)
            }
        }
    }

    func isUnlocked(_ id: AchievementID) -> Bool { data.unlockedAchievements.contains(id.rawValue) }
    func isClaimed(_ id: AchievementID) -> Bool { data.claimedAchievements.contains(id.rawValue) }

    var claimableAchievements: Int {
        AchievementID.allCases.filter { isUnlocked($0) && !isClaimed($0) }.count
    }

    /// Duplicate-safe: a reward is paid once, only after the achievement is unlocked.
    @discardableResult
    func claim(_ id: AchievementID) -> Bool {
        guard isUnlocked(id), !isClaimed(id) else { return false }
        data.claimedAchievements.insert(id.rawValue)
        grant(id.reward)
        return true
    }
}
