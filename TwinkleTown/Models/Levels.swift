import SwiftUI

enum MiniGame: String, Codable, Hashable {
    case match, sorting, memory
    var title: String {
        switch self {
        case .match: "Diamond Match"
        case .sorting: "Crystal Sorting"
        case .memory: "Diamond Memory"
        }
    }
}

enum Objective: Hashable {
    /// Collect `count` gems of `color` within `moves` swaps.
    case collect(color: Int, count: Int, moves: Int, colors: Int)
    /// Sort `crystals` into `baskets` baskets; shapes vary when `shapes` is true.
    case sort(crystals: Int, baskets: Int, shapes: Bool)
    /// Find `pairs` pairs (2 = easy / 4 cards, 4 = medium / 8 cards, 6 = advanced / 12 cards).
    case memory(pairs: Int)
}

struct World: Identifiable {
    let id: Int
    let name: String
    let colors: [Color]

    static let all: [World] = [
        World(id: 0, name: "Crystal Meadow", colors: [Color(hex: 0x8BD9FF), Color(hex: 0xA4F2D0)]),
        World(id: 1, name: "Rainbow Cloud Valley", colors: [Color(hex: 0xFFC3E6), Color(hex: 0xB1F5FF)]),
        World(id: 2, name: "Sparkling Forest", colors: [Color(hex: 0x5FD39A), Color(hex: 0x2F8F86)]),
        World(id: 3, name: "Diamond Ocean", colors: [Color(hex: 0x327CFF), Color(hex: 0x1BB5D6)]),
        World(id: 4, name: "Twinkle Castle", colors: [Color(hex: 0x1747B8), Color(hex: 0xB89BFF)]),
    ]
}

struct LevelDef: Identifiable, Hashable {
    static let perWorld = 6
    static let count = 30

    let id: Int
    let objective: Objective

    var world: Int { (id - 1) / Self.perWorld }
    var indexInWorld: Int { (id - 1) % Self.perWorld }
    var isLast: Bool { id == Self.count }

    var game: MiniGame {
        switch objective {
        case .collect: .match
        case .sort: .sorting
        case .memory: .memory
        }
    }

    var goalText: String {
        switch objective {
        case let .collect(color, count, moves, _):
            "Collect \(count) \(Palette.gemNames[color].lowercased()) diamonds in \(moves) moves"
        case let .sort(crystals, _, _):
            "Sort \(crystals) crystals into matching baskets"
        case let .memory(pairs):
            "Find all \(pairs) matching pairs"
        }
    }

    static let all: [LevelDef] = (1...count).map(make)

    static func level(_ id: Int) -> LevelDef? {
        all.indices.contains(id - 1) ? all[id - 1] : nil
    }

    /// Deterministic level design: difficulty rises with the world and within each world.
    nonisolated static func make(_ id: Int) -> LevelDef {
        let w = (id - 1) / perWorld
        let i = (id - 1) % perWorld
        let objective: Objective
        switch i {
        case 1, 5:
            let baskets = min(5, 2 + w + (i == 5 ? 1 : 0))
            objective = .sort(crystals: 6 + w * 2 + (i == 5 ? 2 : 0), baskets: baskets, shapes: w >= 1)
        case 3:
            objective = .memory(pairs: [2, 4, 4, 6, 6][w])
        default:
            let colors = w == 0 ? 4 : 5
            let count = 8 + w * 3 + i
            objective = .collect(color: (id * 2) % colors, count: count, moves: 16 + w * 2, colors: colors)
        }
        return LevelDef(id: id, objective: objective)
    }
}
