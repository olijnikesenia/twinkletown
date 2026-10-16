import Foundation

struct Appearance: Codable, Hashable {
    var slots: [EquipSlot: String] = [:]

    func item(_ slot: EquipSlot) -> String? { slots[slot] }
    var background: String { slots[.background] ?? Catalog.defaultBackground }
}

struct GardenPlacement: Codable, Hashable, Identifiable {
    var id = UUID()
    var itemID: String
    /// Normalized 0...1 position inside the garden.
    var x: Double
    var y: Double
}

struct Settings: Codable, Hashable {
    var music = true
    var sound = true
    var haptics = true
    var reducedMotion = false
}

struct DailyState: Codable, Hashable {
    /// Index (0...6) of the next calendar reward.
    var rewardIndex = 0
    var lastRewardDay: String?
    /// Day key the challenge progress belongs to.
    var challengeDay = ""
    var progress: [String: Int] = [:]
    var claimedChallenges: Set<String> = []
}

struct PlayerStats: Codable, Hashable {
    var matchWins = 0
    var sortingWins = 0
    var memoryWins = 0
    var perfectPuzzles = 0
    var purchases = 0
    var gemsMatched = 0
    var crystalsSorted = 0
}

struct PlayerData: Codable, Hashable {
    var nickname = "Twinkler"
    var companion: Companion?
    var onboardingDone = false
    var appearance = Appearance()

    var xp = 0
    var totalDiamonds = 0
    var stars = 0
    var totalStarsEarned = 0
    /// Level id -> best rating (1...3).
    var ratings: [Int: Int] = [:]
    var stats = PlayerStats()

    var owned: Set<String> = Catalog.starterIDs
    var garden: [GardenPlacement] = []
    var gardenBackground = Catalog.defaultBackground

    var unlockedAchievements: Set<String> = []
    var claimedAchievements: Set<String> = []
    var celebrationSeen = false

    var daily = DailyState()

    var allTimeScore = 0
    var weeklyScore = 0
    var weekKey = ""
    var lastAllTimeRank: Int?
    var lastWeeklyRank: Int?

    var settings = Settings()

    var completedLevels: Int { ratings.count }
    var playerLevel: Int { xp / PlayerData.xpPerLevel + 1 }
    var xpIntoLevel: Int { xp % PlayerData.xpPerLevel }
    static let xpPerLevel = 100
    static let diamondGoal = 777
}
