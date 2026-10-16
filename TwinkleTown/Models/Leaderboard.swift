import Foundation

struct Competitor: Identifiable, Hashable {
    let id: Int
    let name: String
    let species: Companion
    let tint: Int
    let baseScore: Int
}

struct LeaderboardEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let species: Companion
    let tint: Int
    let score: Int
    let rank: Int
    let isPlayer: Bool
}

enum LeaderboardBoard: String, CaseIterable, Identifiable {
    case weekly, allTime
    var id: String { rawValue }
    var title: String { self == .weekly ? "This Week" : "All Time" }
}

enum Competitors {
    private static let names = [
        "Pip the Puppy", "Luna the Owl", "Nibbles the Hamster", "Sunny the Duckling", "Twirl the Squirrel",
        "Poppy the Panda", "Bubbles the Seal", "Maple the Deer", "Ziggy the Zebra", "Honey the Hedgehog",
        "Pebble the Penguin", "Clover the Lamb", "Dash the Otter", "Willow the Koala", "Biscuit the Mouse",
        "Tango the Turtle", "Jelly the Frog", "Snowy the Arctic Fox", "Bloom the Butterfly", "Comet the Raccoon",
        "Pudding the Piglet", "Skye the Sparrow",
    ]

    static let all: [Competitor] = names.enumerated().map { i, name in
        Competitor(id: i, name: name, species: Companion.allCases[i % 4], tint: i % 5,
                   baseScore: 12_000 - i * 520 - (i * i * 7) % 300)
    }

    /// Stable (non-randomized) string hash so weekly scores never change between launches.
    static func stableHash(_ s: String) -> UInt64 {
        s.utf8.reduce(5381) { ($0 &* 33) &+ UInt64($1) }
    }

    static func weeklyScore(_ c: Competitor, weekKey: String) -> Int {
        200 + Int(stableHash(c.name + weekKey) % 2_400)
    }
}
