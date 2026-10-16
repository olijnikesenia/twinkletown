import SwiftUI

// MARK: - Screen 8: Diamond Memory

struct MemoryGameView: View {
    let level: LevelDef
    let pairs: Int
    let onFinish: (Int, Int, Int, Int) -> Void
    @State private var engine: MemoryEngine
    @State private var message = "Find the matching pairs!"

    init(level: LevelDef, pairs: Int, onFinish: @escaping (Int, Int, Int, Int) -> Void) {
        self.level = level
        self.pairs = pairs
        self.onFinish = onFinish
        _engine = State(initialValue: MemoryEngine(pairs: pairs, seed: UInt64(level.id) &+ UInt64(Date().timeIntervalSince1970)))
    }

    private var difficulty: String { pairs <= 2 ? "Easy" : pairs <= 4 ? "Medium" : "Advanced" }
    private var columns: Int { pairs <= 2 ? 2 : pairs <= 4 ? 4 : (Device.isPad ? 4 : 3) }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(difficulty) · Pairs \(engine.matchedPairs)/\(engine.pairs)").font(.game(19)).foregroundStyle(Palette.text)
                    GameProgressBar(value: Double(engine.matchedPairs) / Double(engine.pairs), colors: [Palette.pink, Palette.hotPink], height: 14)
                }
                Spacer()
                VStack(spacing: 0) {
                    Text("\(engine.turns)").font(.game(26)).foregroundStyle(Palette.royal)
                    Text("turns").font(.game(12)).foregroundStyle(Palette.text)
                }
            }
            .padding(12).gamePanel().padding(.horizontal, 16)

            Text(message).font(.game(19)).foregroundStyle(.white).shadow(color: Palette.deep, radius: 0, y: 2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
                ForEach(Array(engine.cards.enumerated()), id: \.element.id) { i, card in
                    FlipCard(card: card)
                        .aspectRatio(0.75, contentMode: .fit)
                        .onTapGesture { tap(i) }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityLabel(card.isFaceUp || card.isMatched ? "Card \(MemoryCardFace.name(card.face))" : "Hidden card")
                }
            }
            .frame(maxWidth: Device.isPad ? 620 : 420)
            .padding(.horizontal, 20)
            Spacer(minLength: 0)
        }
    }

    private func tap(_ i: Int) {
        let result = withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { engine.flip(i) }
        switch result {
        case .ignored: return
        case .first: feedback(.flip)
        case .match:
            feedback(.match, haptic: .medium)
            message = ["A match!", "Wonderful!", "You remembered!"][engine.matchedPairs % 3]
            if engine.isComplete {
                message = "All pairs found!"
                onFinish(ScoreCalculator.memoryRating(turns: engine.turns, pairs: engine.pairs), max(0, engine.pairs * 30 - engine.turns * 5), 0, 0)
            }
        case .mismatch:
            feedback(.flip)
            message = "Not a pair — try again!"
            Task {
                try? await Task.sleep(for: .seconds(0.9))
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { engine.hideMismatched() }
            }
        }
    }
}

private struct FlipCard: View {
    let card: MemoryCard

    var body: some View {
        let up = card.isFaceUp || card.isMatched
        ZStack {
            MemoryCardBack().opacity(up ? 0 : 1)
            MemoryCardFace(face: card.face)
                .opacity(up ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
                .overlay {
                    if card.isMatched {
                        RoundedRectangle(cornerRadius: 16).stroke(Palette.yellow, lineWidth: 5).shadow(color: Palette.yellow, radius: 6)
                            .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
                    }
                }
        }
        .rotation3DEffect(.degrees(up ? 180 : 0), axis: (0, 1, 0), perspective: 0.5)
        .scaleEffect(card.isMatched ? 0.95 : 1)
    }
}

struct MemoryCardBack: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Palette.royal, Palette.deep], startPoint: .top, endPoint: .bottom))
            GeometryReader { geo in
                ForEach(0..<6, id: \.self) { i in
                    SparkleShape().fill(.white.opacity(0.35)).frame(width: 12, height: 12)
                        .position(x: geo.size.width * [0.2, 0.8, 0.5, 0.2, 0.8, 0.5][i], y: geo.size.height * [0.15, 0.15, 0.3, 0.85, 0.85, 0.7][i])
                }
            }
            DiamondIcon(size: 36).opacity(0.9)
            RoundedRectangle(cornerRadius: 16).stroke(.white, lineWidth: 4)
        }
    }
}

struct MemoryCardFace: View {
    let face: Int

    static func name(_ face: Int) -> String {
        face < 4 ? Companion.allCases[face].shortName : face == 4 ? "Diamond" : "Star"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(face < 4 ? Companion.allCases[face].theme.lighter(0.3) : Palette.crystal)
            Group {
                if face < 4 {
                    CompanionArt(companion: Companion.allCases[face]).frame(width: 200, height: 240).scaleEffect(0.32).frame(width: 64, height: 77)
                } else if face == 4 {
                    DiamondIcon(size: 50)
                } else {
                    StarCoin(size: 54)
                }
            }
            RoundedRectangle(cornerRadius: 16).stroke(.white, lineWidth: 4)
        }
    }
}
