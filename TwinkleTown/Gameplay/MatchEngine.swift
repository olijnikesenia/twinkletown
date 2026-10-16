import Foundation

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct GridPos: Hashable {
    let row: Int
    let col: Int
}

/// One cascade step: gems removed, then gems falling (from row < 0 means newly spawned).
struct CascadeStep {
    struct Fall { let fromRow: Int; let toRow: Int; let col: Int; let color: Int }
    let removed: [GridPos: Int]
    let falls: [Fall]
}

/// Pure swap-to-match-3 logic. Row 0 is the top row; gems fall towards higher rows.
struct MatchEngine {
    let rows: Int
    let cols: Int
    let colorCount: Int
    private(set) var grid: [[Int]]
    private var rng: SeededRNG

    init(rows: Int = 7, cols: Int = 7, colors: Int = 5, seed: UInt64 = 1) {
        self.rows = rows
        self.cols = cols
        colorCount = colors
        rng = SeededRNG(seed: seed)
        grid = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        fillWithoutMatches()
    }

    /// For tests: start from a fixed board.
    init(grid: [[Int]], colors: Int, seed: UInt64 = 1) {
        rows = grid.count
        cols = grid[0].count
        colorCount = colors
        self.grid = grid
        rng = SeededRNG(seed: seed)
    }

    subscript(_ p: GridPos) -> Int { grid[p.row][p.col] }

    func contains(_ p: GridPos) -> Bool { p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols }

    static func adjacent(_ a: GridPos, _ b: GridPos) -> Bool {
        abs(a.row - b.row) + abs(a.col - b.col) == 1
    }

    mutating func fillWithoutMatches() {
        repeat {
            for r in 0..<rows {
                for c in 0..<cols {
                    var color: Int
                    repeat {
                        color = Int.random(in: 0..<colorCount, using: &rng)
                    } while (c >= 2 && grid[r][c - 1] == color && grid[r][c - 2] == color)
                        || (r >= 2 && grid[r - 1][c] == color && grid[r - 2][c] == color)
                    grid[r][c] = color
                }
            }
        } while findHint() == nil
    }

    /// All gems that are part of a horizontal or vertical line of 3+.
    func findMatches() -> Set<GridPos> {
        var result = Set<GridPos>()
        for r in 0..<rows {
            var c = 0
            while c < cols {
                var end = c
                while end + 1 < cols, grid[r][end + 1] == grid[r][c], grid[r][c] >= 0 { end += 1 }
                if end - c >= 2 { (c...end).forEach { result.insert(GridPos(row: r, col: $0)) } }
                c = end + 1
            }
        }
        for c in 0..<cols {
            var r = 0
            while r < rows {
                var end = r
                while end + 1 < rows, grid[end + 1][c] == grid[r][c], grid[r][c] >= 0 { end += 1 }
                if end - r >= 2 { (r...end).forEach { result.insert(GridPos(row: $0, col: c)) } }
                r = end + 1
            }
        }
        return result
    }

    private mutating func swapCells(_ a: GridPos, _ b: GridPos) {
        let t = grid[a.row][a.col]
        grid[a.row][a.col] = grid[b.row][b.col]
        grid[b.row][b.col] = t
    }

    func wouldMatch(_ a: GridPos, _ b: GridPos) -> Bool {
        guard contains(a), contains(b), Self.adjacent(a, b) else { return false }
        var copy = self
        copy.swapCells(a, b)
        return !copy.findMatches().isEmpty
    }

    /// A valid swap, or nil when the board is stuck.
    func findHint() -> (GridPos, GridPos)? {
        for r in 0..<rows {
            for c in 0..<cols {
                let a = GridPos(row: r, col: c)
                for b in [GridPos(row: r, col: c + 1), GridPos(row: r + 1, col: c)] where wouldMatch(a, b) {
                    return (a, b)
                }
            }
        }
        return nil
    }

    /// Swaps two gems. Returns nil (board unchanged) when the swap makes no match,
    /// otherwise every cascade step until the board settles.
    mutating func trySwap(_ a: GridPos, _ b: GridPos) -> [CascadeStep]? {
        guard wouldMatch(a, b) else { return nil }
        swapCells(a, b)
        var steps: [CascadeStep] = []
        var matches = findMatches()
        while !matches.isEmpty {
            steps.append(resolve(matches))
            matches = findMatches()
        }
        return steps
    }

    /// Removes the given gems, drops the rest and spawns new ones on top.
    private mutating func resolve(_ matches: Set<GridPos>) -> CascadeStep {
        var removed: [GridPos: Int] = [:]
        for p in matches {
            removed[p] = grid[p.row][p.col]
            grid[p.row][p.col] = -1
        }
        var falls: [CascadeStep.Fall] = []
        for c in 0..<cols {
            var write = rows - 1
            for r in stride(from: rows - 1, through: 0, by: -1) where grid[r][c] >= 0 {
                if r != write {
                    falls.append(.init(fromRow: r, toRow: write, col: c, color: grid[r][c]))
                    grid[write][c] = grid[r][c]
                    grid[r][c] = -1
                }
                write -= 1
            }
            var spawn = -1
            while write >= 0 {
                let color = Int.random(in: 0..<colorCount, using: &rng)
                grid[write][c] = color
                falls.append(.init(fromRow: spawn, toRow: write, col: c, color: color))
                spawn -= 1
                write -= 1
            }
        }
        return CascadeStep(removed: removed, falls: falls)
    }

    /// Reshuffles until there is no immediate match and at least one valid move.
    mutating func shuffleIfStuck() -> Bool {
        guard findHint() == nil else { return false }
        fillWithoutMatches()
        return true
    }
}
