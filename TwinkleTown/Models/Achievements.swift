import Foundation

struct Reward: Hashable, Codable {
    var stars = 0
    var diamonds = 0
}

enum AchievementID: String, CaseIterable, Identifiable, Codable {
    case firstDiamond, firstPuzzle
    case diamonds10, diamonds50, diamonds100, diamonds250, diamonds500, diamonds777
    case levels10, levels20
    case perfectPuzzle, memoryMaster, sortingChampion, firstPurchase, gardenDesigner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstDiamond: "First Diamond"
        case .firstPuzzle: "First Puzzle"
        case .diamonds10: "Collect 10 Diamonds"
        case .diamonds50: "Collect 50 Diamonds"
        case .diamonds100: "Collect 100 Diamonds"
        case .diamonds250: "Collect 250 Diamonds"
        case .diamonds500: "Collect 500 Diamonds"
        case .diamonds777: "Collect 777 Diamonds"
        case .levels10: "Complete 10 Levels"
        case .levels20: "Complete 20 Levels"
        case .perfectPuzzle: "Perfect Puzzle"
        case .memoryMaster: "Memory Master"
        case .sortingChampion: "Sorting Champion"
        case .firstPurchase: "First Shop Purchase"
        case .gardenDesigner: "Garden Designer"
        }
    }

    var detail: String {
        switch self {
        case .firstDiamond: "Find your very first diamond"
        case .firstPuzzle: "Finish any puzzle level"
        case .perfectPuzzle: "Get 3 stars in a Diamond Match level"
        case .memoryMaster: "Win 3 memory games"
        case .sortingChampion: "Win 5 sorting games"
        case .firstPurchase: "Buy something in the Twinkle Shop"
        case .gardenDesigner: "Place 5 decorations in your garden"
        case .levels10, .levels20: "Finish \(goal) different levels"
        default: "Collect \(goal) magical diamonds"
        }
    }

    var goal: Int {
        switch self {
        case .firstDiamond, .firstPuzzle, .perfectPuzzle, .firstPurchase: 1
        case .diamonds10, .levels10: 10
        case .diamonds50: 50
        case .diamonds100: 100
        case .diamonds250: 250
        case .diamonds500: 500
        case .diamonds777: 777
        case .levels20: 20
        case .memoryMaster: 3
        case .sortingChampion, .gardenDesigner: 5
        }
    }

    var reward: Reward {
        switch self {
        case .firstDiamond: Reward(stars: 10)
        case .firstPuzzle: Reward(stars: 10, diamonds: 5)
        case .diamonds10: Reward(stars: 15)
        case .diamonds50: Reward(stars: 25)
        case .diamonds100: Reward(stars: 40)
        case .diamonds250: Reward(stars: 60)
        case .diamonds500: Reward(stars: 80)
        case .diamonds777: Reward(stars: 150)
        case .levels10: Reward(stars: 40, diamonds: 10)
        case .levels20: Reward(stars: 60, diamonds: 15)
        case .perfectPuzzle: Reward(stars: 20, diamonds: 5)
        case .memoryMaster: Reward(stars: 25, diamonds: 5)
        case .sortingChampion: Reward(stars: 25, diamonds: 5)
        case .firstPurchase: Reward(stars: 10, diamonds: 3)
        case .gardenDesigner: Reward(stars: 30, diamonds: 5)
        }
    }

    func progress(_ d: PlayerData) -> Int {
        let value: Int
        switch self {
        case .firstDiamond, .diamonds10, .diamonds50, .diamonds100, .diamonds250, .diamonds500, .diamonds777:
            value = d.totalDiamonds
        case .firstPuzzle, .levels10, .levels20: value = d.completedLevels
        case .perfectPuzzle: value = d.stats.perfectPuzzles
        case .memoryMaster: value = d.stats.memoryWins
        case .sortingChampion: value = d.stats.sortingWins
        case .firstPurchase: value = d.stats.purchases
        case .gardenDesigner: value = d.garden.count
        }
        return min(value, goal)
    }
}

enum DailyChallenge: String, CaseIterable, Identifiable {
    case puzzles2, match20, memory1, sort15, levels3
    var id: String { rawValue }

    var title: String {
        switch self {
        case .puzzles2: "Complete two puzzles"
        case .match20: "Match 20 diamonds"
        case .memory1: "Finish one memory game"
        case .sort15: "Sort 15 crystals"
        case .levels3: "Complete three levels"
        }
    }

    var goal: Int {
        switch self {
        case .puzzles2: 2
        case .match20: 20
        case .memory1: 1
        case .sort15: 15
        case .levels3: 3
        }
    }

    var reward: Reward {
        switch self {
        case .puzzles2: Reward(stars: 15, diamonds: 2)
        case .match20: Reward(stars: 10, diamonds: 2)
        case .memory1: Reward(stars: 10, diamonds: 1)
        case .sort15: Reward(stars: 10, diamonds: 2)
        case .levels3: Reward(stars: 20, diamonds: 3)
        }
    }
}

enum DailyCalendar {
    static let rewards: [Reward] = [
        Reward(stars: 10), Reward(diamonds: 3), Reward(stars: 15), Reward(diamonds: 5),
        Reward(stars: 20), Reward(stars: 10, diamonds: 5), Reward(stars: 40, diamonds: 10),
    ]
}
