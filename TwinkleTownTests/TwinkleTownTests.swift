import Foundation
import Testing
@testable import TwinkleTown

@MainActor
final class Clock {
    var date: Date
    init(_ iso: String) { date = ISO8601DateFormatter().date(from: iso)! }
    func advance(days: Int) { date = date.addingTimeInterval(Double(days) * 86_400) }
}

@MainActor
private func makeState(_ clock: Clock? = nil, store: SaveStore = .memory) -> GameState {
    let clock = clock ?? Clock("2026-10-14T10:00:00Z")
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return GameState(store: store, now: { clock.date }, calendar: cal)
}

@MainActor
struct ProgressionTests {
    @Test func newGameStartsEmpty() {
        let s = makeState()
        #expect(s.data.stars == 0)
        #expect(s.data.totalDiamonds == 0)
        #expect(s.data.completedLevels == 0)
        #expect(s.owns(Catalog.defaultBackground))
        #expect(s.isUnlocked(LevelDef.all[0]))
        #expect(!s.isUnlocked(LevelDef.all[1]))
    }

    @Test func levelCatalogHas30LevelsAcrossFiveWorlds() {
        #expect(LevelDef.all.count == 30)
        #expect(Set(LevelDef.all.map(\.world)) == [0, 1, 2, 3, 4])
        #expect(Set(LevelDef.all.map(\.game)) == [.match, .sorting, .memory])
    }

    @Test func completingLevelGrantsRewardsAndUnlocksNext() {
        let s = makeState()
        let r = s.completeLevel(LevelDef.all[0], rating: 3)
        #expect(r.isFirstClear)
        #expect(r.reward == Reward(stars: 30, diamonds: 15))
        #expect(s.data.stars == 30) // achievement rewards are claimed separately
        #expect(s.data.totalDiamonds == 15)
        #expect(s.data.xp == 50)
        #expect(s.isUnlocked(LevelDef.all[1]))
        #expect(s.currentLevel.id == 2)
    }

    @Test func replayPaysLessAndOnlyRewardsNewStars() {
        let s = makeState()
        s.completeLevel(LevelDef.all[0], rating: 1)
        let replay = s.completeLevel(LevelDef.all[0], rating: 3)
        #expect(!replay.isFirstClear)
        #expect(replay.reward == Reward(stars: 5 + 3 + 10, diamonds: 3 + 2))
        let again = s.completeLevel(LevelDef.all[0], rating: 2)
        #expect(again.reward == Reward(stars: 7, diamonds: 3))
        #expect(s.data.ratings[1] == 3)
    }

    @Test func diamondGoalIsReachable() {
        let firstClears = LevelDef.all.map { ScoreCalculator.reward(world: $0.world, rating: 3, previousBest: nil).diamonds }.reduce(0, +)
        let achievements = AchievementID.allCases.map(\.reward.diamonds).reduce(0, +)
        #expect(firstClears + achievements < 777) // replays/daily gifts still matter
        #expect(firstClears + achievements > 600)
    }

    @Test func ratingRules() {
        #expect(ScoreCalculator.matchRating(movesLeft: 8, totalMoves: 20, usedExtraMoves: false) == 3)
        #expect(ScoreCalculator.matchRating(movesLeft: 3, totalMoves: 20, usedExtraMoves: false) == 2)
        #expect(ScoreCalculator.matchRating(movesLeft: 0, totalMoves: 20, usedExtraMoves: false) == 1)
        #expect(ScoreCalculator.matchRating(movesLeft: 15, totalMoves: 20, usedExtraMoves: true) == 1)
        #expect(ScoreCalculator.sortingRating(mistakes: 10) == 2)
        #expect(ScoreCalculator.memoryRating(turns: 4, pairs: 2) == 3)
    }
}

@MainActor
struct ShopTests {
    @Test func purchaseFlow() {
        let s = makeState()
        #expect(s.buy("glasses_star") == .notEnoughStars(missing: 25))
        s.addStars(40)
        #expect(s.buy("glasses_star") == .success)
        #expect(s.data.stars == 15)
        #expect(s.owns("glasses_star"))
        #expect(s.buy("glasses_star") == .alreadyOwned)
        #expect(s.data.stars == 15)
        #expect(s.buy(Catalog.celebrationReward) == .unavailable)
        #expect(s.buy("nope") == .unavailable)
    }

    @Test func balanceNeverNegative() {
        let s = makeState()
        s.addStars(10)
        #expect(!s.spendStars(11))
        #expect(!s.spendStars(-5))
        #expect(s.data.stars == 10)
    }

    @Test func equipOnlyOwnedItems() {
        let s = makeState()
        #expect(!s.equip("hat_rainbow"))
        s.addStars(100)
        s.buy("hat_rainbow")
        #expect(s.equip("hat_rainbow"))
        #expect(s.isEquipped("hat_rainbow"))
        s.unequip(.hat)
        #expect(s.data.appearance.item(.hat) == nil)
    }

    @Test func firstItemAffordableWithinFirstLevels() {
        let s = makeState()
        for level in LevelDef.all.prefix(2) { s.completeLevel(level, rating: 1) }
        let cheapest = Catalog.items.filter(\.inShop).map(\.price).min()!
        #expect(s.data.stars >= cheapest)
    }

    @Test func gardenPlacementAndClamp() {
        let s = makeState()
        #expect(s.placeDecoration("deco_rainbow_tree") == nil) // not owned
        let p = s.placeDecoration("deco_crystal_tree", x: 2, y: -1)!
        #expect(p.x == 1 && p.y == 0)
        s.moveDecoration(p.id, x: 0.3, y: 0.4)
        #expect(s.data.garden[0].x == 0.3)
        s.removeDecoration(p.id)
        #expect(s.data.garden.isEmpty)
    }
}

@MainActor
struct AchievementTests {
    @Test func unlockAutomaticallyAndClaimOnce() {
        let s = makeState()
        #expect(!s.claim(.firstPuzzle))
        s.completeLevel(LevelDef.all[0], rating: 3)
        #expect(s.isUnlocked(.firstPuzzle))
        #expect(s.isUnlocked(.firstDiamond))
        #expect(s.isUnlocked(.diamonds10))
        #expect(s.isUnlocked(.perfectPuzzle))
        let before = s.data.stars
        #expect(s.claim(.firstPuzzle))
        #expect(s.data.stars == before + AchievementID.firstPuzzle.reward.stars)
        #expect(!s.claim(.firstPuzzle))
        #expect(s.data.stars == before + AchievementID.firstPuzzle.reward.stars)
    }

    @Test func gardenDesignerAndPurchase() {
        let s = makeState()
        for _ in 0..<5 { s.placeDecoration("deco_pink_flowers") }
        #expect(s.isUnlocked(.gardenDesigner))
        s.addStars(30)
        s.buy("bow_magical")
        #expect(s.isUnlocked(.firstPurchase))
    }

    @Test func celebrationAt777GrantsExclusiveOnce() {
        let s = makeState()
        s.addDiamonds(776)
        #expect(!s.pendingCelebration)
        s.addDiamonds(1)
        #expect(s.pendingCelebration)
        #expect(s.owns(Catalog.celebrationReward))
        s.finishCelebration()
        s.addDiamonds(10)
        #expect(!s.pendingCelebration)
    }
}

@MainActor
struct DailyTests {
    @Test func dailyRewardOncePerDay() {
        let clock = Clock("2026-10-14T10:00:00Z")
        let s = makeState(clock)
        #expect(s.claimDailyReward() == DailyCalendar.rewards[0])
        #expect(s.claimDailyReward() == nil)
        clock.advance(days: 3) // missed days don't reset
        #expect(s.claimDailyReward() == DailyCalendar.rewards[1])
    }

    @Test func challengesTrackAndResetDaily() {
        let clock = Clock("2026-10-14T10:00:00Z")
        let s = makeState(clock)
        let c = s.todaysChallenges[0]
        #expect(!s.claimChallenge(c))
        s.recordChallenge(c, amount: c.goal + 5)
        #expect(s.challengeProgress(c) == c.goal)
        #expect(s.claimChallenge(c))
        #expect(!s.claimChallenge(c))
        clock.advance(days: 1)
        s.refreshDaily()
        #expect(s.todaysChallenges.allSatisfy { s.challengeProgress($0) == 0 && !s.isChallengeClaimed($0) })
    }

    @Test func todaysChallengesAreThreeDistinct() {
        let s = makeState()
        #expect(Set(s.todaysChallenges).count == 3)
    }
}

@MainActor
struct LeaderboardTests {
    @Test func atLeast20FictionalCompetitors() {
        #expect(Competitors.all.count >= 20)
        #expect(Set(Competitors.all.map(\.name)).count == Competitors.all.count)
    }

    @Test func rankImprovesWithScore() {
        let s = makeState()
        let start = s.playerRank(.allTime)
        #expect(start == Competitors.all.count + 1)
        s.addScore(13_000)
        #expect(s.playerRank(.allTime) == 1)
    }

    @Test func weeklyScoresDeterministicAndResetEachWeek() {
        let clock = Clock("2026-10-14T10:00:00Z")
        let s = makeState(clock)
        #expect(s.leaderboard(.weekly) == s.leaderboard(.weekly))
        s.addScore(500)
        #expect(s.data.weeklyScore == 500)
        clock.advance(days: 7)
        s.refreshWeek()
        #expect(s.data.weeklyScore == 0)
        #expect(s.data.allTimeScore == 500)
    }

    @Test func rankChangeIsRemembered() {
        let s = makeState()
        #expect(s.consumeRankChange(.allTime) == nil)
        let first = s.playerRank(.allTime)
        s.addScore(20_000)
        #expect(s.consumeRankChange(.allTime) == first)
        #expect(s.consumeRankChange(.allTime) == 1)
    }
}

@MainActor
struct PersistenceTests {
    @Test func saveAndRestore() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tt-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = SaveStore(url: url)
        let s = makeState(store: store)
        s.data.nickname = "Ana"
        s.selectCompanion(.lolo)
        s.completeLevel(LevelDef.all[0], rating: 2)
        s.addStars(50)
        s.buy("hat_rainbow")
        s.equip("hat_rainbow")
        s.placeDecoration("deco_sunflower", x: 0.3, y: 0.7)
        s.data.settings.music = false
        s.saveNow()

        let restored = makeState(store: store)
        #expect(restored.data == s.data)
        #expect(restored.data.appearance.item(.hat) == "hat_rainbow")
        #expect(restored.isUnlocked(LevelDef.all[1]))
    }

    @Test func resetKeepsSettingsOnly() {
        let s = makeState()
        s.data.settings.sound = false
        s.addStars(100)
        s.data.onboardingDone = true
        s.resetProgress()
        #expect(s.data.stars == 0)
        #expect(!s.data.onboardingDone)
        #expect(!s.data.settings.sound)
    }
}

@MainActor
struct EngineTests {
    @Test func matchBoardStartsSolvableWithoutMatches() {
        for seed in 1...30 {
            let e = MatchEngine(rows: 7, cols: 7, colors: 5, seed: UInt64(seed))
            #expect(e.findMatches().isEmpty)
            #expect(e.findHint() != nil)
        }
    }

    @Test func invalidSwapLeavesBoardUnchanged() {
        var e = MatchEngine(grid: [[0, 1, 2], [1, 2, 0], [2, 0, 1]], colors: 3)
        let before = e.grid
        let swap = e.trySwap(GridPos(row: 0, col: 0), GridPos(row: 0, col: 1))
        #expect(swap == nil)
        #expect(e.grid == before)
        let far = e.trySwap(GridPos(row: 0, col: 0), GridPos(row: 2, col: 2)) // not adjacent
        #expect(far == nil)
    }

    @Test func validSwapRemovesMatchAndRefills() throws {
        // Swapping (0,2)<->(1,2) makes a row of three 0s on top.
        var e = MatchEngine(grid: [[0, 0, 1, 2], [2, 1, 0, 2], [1, 2, 1, 0]], colors: 3)
        let swapped = e.trySwap(GridPos(row: 0, col: 2), GridPos(row: 1, col: 2))
        let steps = try #require(swapped)
        #expect(steps[0].removed.count == 3)
        #expect(steps[0].removed.values.allSatisfy { $0 == 0 })
        #expect(e.grid.joined().allSatisfy { $0 >= 0 })
        #expect(e.findMatches().isEmpty)
    }

    @Test func sortingCountsMistakesAndCompletes() {
        var e = SortingEngine(crystals: 6, baskets: 3, shapes: true, seed: 3)
        #expect(Set(e.remaining.map(\.color)) == Set(e.basketColors))
        let wrong = e.basketColors.first { $0 != e.remaining[0].color }!
        let accepted = e.drop(e.remaining[0].id, intoBasketColor: wrong)
        #expect(!accepted)
        #expect(e.mistakes == 1)
        while let c = e.remaining.first {
            let ok = e.drop(c.id, intoBasketColor: c.color)
            #expect(ok)
        }
        #expect(e.isComplete)
        #expect(e.sorted == 6)
    }

    @Test func memoryPairsAndTurns() {
        var e = MemoryEngine(pairs: 2, seed: 9)
        #expect(e.cards.count == 4)
        let first = e.cards[0]
        let partner = e.cards.firstIndex { $0.face == first.face && $0.id != first.id }!
        let other = e.cards.indices.first { $0 != 0 && $0 != partner }!
        do { let r = e.flip(0); #expect(r == .first) }
        do { let r = e.flip(0); #expect(r == .ignored) }
        do { let r = e.flip(other); #expect(r == .mismatch) }
        do { let r = e.flip(partner); #expect(r == .ignored) } // must hide first
        e.hideMismatched()
        do { let r = e.flip(0); #expect(r == .first) }
        do { let r = e.flip(partner); #expect(r == .match) }
        #expect(e.turns == 2)
        #expect(e.matchedPairs == 1)
    }
}
