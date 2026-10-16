import Foundation

enum GemShape: Int, CaseIterable {
    case gem, round, square, heart
}

struct Crystal: Identifiable, Hashable {
    let id: Int
    let color: Int
    let shape: GemShape
}

/// Drag crystals into the basket of the same color. Mistakes are counted but never fail the level.
struct SortingEngine {
    let basketColors: [Int]
    private(set) var remaining: [Crystal]
    private(set) var sorted = 0
    private(set) var mistakes = 0
    let total: Int

    init(crystals: Int, baskets: Int, shapes: Bool, seed: UInt64) {
        var rng = SeededRNG(seed: seed)
        let colors = Array(Array(0..<5).shuffled(using: &rng).prefix(max(1, min(5, baskets))))
        basketColors = colors
        total = crystals
        remaining = (0..<crystals).map { i in
            // Every basket gets at least one crystal.
            let color = i < colors.count ? colors[i] : colors.randomElement(using: &rng)!
            let shape = shapes ? GemShape.allCases.randomElement(using: &rng)! : .gem
            return Crystal(id: i, color: color, shape: shape)
        }.shuffled(using: &rng)
    }

    var isComplete: Bool { remaining.isEmpty }

    /// Returns true when the crystal was accepted by the basket.
    @discardableResult
    mutating func drop(_ crystalID: Int, intoBasketColor color: Int) -> Bool {
        guard let i = remaining.firstIndex(where: { $0.id == crystalID }) else { return false }
        guard remaining[i].color == color else {
            mistakes += 1
            return false
        }
        remaining.remove(at: i)
        sorted += 1
        return true
    }
}

struct MemoryCard: Identifiable, Hashable {
    let id: Int
    /// 0...3 companions, 4 diamond, 5 star.
    let face: Int
    var isFaceUp = false
    var isMatched = false
}

enum FlipResult: Equatable {
    case ignored, first, match, mismatch
}

struct MemoryEngine {
    private(set) var cards: [MemoryCard]
    private(set) var turns = 0
    private var openIndex: Int?
    /// Two face-up mismatched cards waiting to be hidden.
    private(set) var pendingHide: [Int] = []

    init(pairs: Int, seed: UInt64) {
        var rng = SeededRNG(seed: seed)
        let faces = Array(Array(0..<6).shuffled(using: &rng).prefix(pairs))
        cards = (faces + faces).shuffled(using: &rng).enumerated().map { MemoryCard(id: $0, face: $1) }
    }

    var pairs: Int { cards.count / 2 }
    var matchedPairs: Int { cards.filter(\.isMatched).count / 2 }
    var isComplete: Bool { cards.allSatisfy(\.isMatched) }

    mutating func flip(_ index: Int) -> FlipResult {
        guard cards.indices.contains(index), pendingHide.isEmpty,
              !cards[index].isFaceUp, !cards[index].isMatched else { return .ignored }
        cards[index].isFaceUp = true
        guard let first = openIndex else {
            openIndex = index
            return .first
        }
        openIndex = nil
        turns += 1
        if cards[first].face == cards[index].face {
            cards[first].isMatched = true
            cards[index].isMatched = true
            return .match
        }
        pendingHide = [first, index]
        return .mismatch
    }

    mutating func hideMismatched() {
        for i in pendingHide { cards[i].isFaceUp = false }
        pendingHide = []
    }
}
