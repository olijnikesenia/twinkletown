import Foundation

struct LevelResult: Hashable {
    let levelID: Int
    let rating: Int
    let previousBest: Int?
    let reward: Reward
    let xp: Int
    let score: Int

    var isFirstClear: Bool { previousBest == nil }
}

enum ScoreCalculator {
    /// First clears pay the most; replays still pay a little, plus a bonus for every newly earned star.
    static func reward(world: Int, rating: Int, previousBest: Int?) -> Reward {
        guard let previousBest else {
            return Reward(stars: 15 + 5 * rating, diamonds: 12 + 2 * world + rating)
        }
        let newStars = max(0, rating - previousBest)
        return Reward(stars: 5 + rating + 5 * newStars, diamonds: 3 + newStars)
    }

    static func xp(rating: Int, firstClear: Bool) -> Int {
        firstClear ? 20 + 10 * rating : 10 + 5 * rating
    }

    static func score(rating: Int, bonus: Int) -> Int {
        100 + 50 * rating + max(0, bonus)
    }

    static func matchRating(movesLeft: Int, totalMoves: Int, usedExtraMoves: Bool) -> Int {
        if usedExtraMoves { return 1 }
        let ratio = Double(movesLeft) / Double(max(1, totalMoves))
        return ratio >= 0.35 ? 3 : ratio >= 0.15 ? 2 : 1
    }

    /// Gentle: sorting never rates below two stars.
    static func sortingRating(mistakes: Int) -> Int {
        mistakes <= 2 ? 3 : 2
    }

    /// `turns` = number of pairs of cards turned over.
    static func memoryRating(turns: Int, pairs: Int) -> Int {
        turns <= pairs * 2 ? 3 : turns <= pairs * 3 ? 2 : 1
    }
}
