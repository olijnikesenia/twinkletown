import SwiftUI
import SpriteKit

/// Screens 6–8 share this shell: header, tutorial card and a single, guarded completion.
struct LevelPlayScreen: View {
    let level: LevelDef
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @State private var showTutorial = false
    @State private var finished = false
    @State private var attempt = 0

    var body: some View {
        ZStack {
            MagicBackground(colors: [Palette.violet] + World.all[level.world].colors, clouds: false)
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    RoundIconButton(icon: .back, size: 46, label: "Back to map") { router.back() }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Level \(level.id)").titleStyle(24)
                        Text(level.game.title).font(.game(15)).foregroundStyle(.white)
                    }
                    Spacer()
                    RoundIconButton(icon: .refresh, color: Palette.lilac, size: 46, label: "Restart") { attempt += 1 }
                }
                .padding(.horizontal, 16)

                Group {
                    switch level.objective {
                    case let .collect(color, count, moves, colors):
                        MatchGameView(level: level, color: color, target: count, moves: moves, colors: colors, onFinish: finish)
                    case let .sort(crystals, baskets, shapes):
                        SortingGameView(level: level, crystals: crystals, baskets: baskets, shapes: shapes, onFinish: finish)
                    case let .memory(pairs):
                        MemoryGameView(level: level, pairs: pairs, onFinish: finish)
                    }
                }
                .id(attempt)
            }
            if showTutorial {
                TutorialCard(game: level.game, goal: level.goalText) { withAnimation { showTutorial = false } }
                    .transition(.opacity)
            }
        }
        .onAppear { showTutorial = state.rating(level) == nil }
    }

    /// Grants rewards exactly once for this play, then shows the results screen.
    private func finish(rating: Int, bonus: Int, gems: Int, crystals: Int) {
        guard !finished else { return }
        finished = true
        let result = state.completeLevel(level, rating: rating, bonusScore: bonus, gemsMatched: gems, crystalsSorted: crystals)
        feedback(.levelComplete, haptic: .heavy)
        Task {
            try? await Task.sleep(for: .seconds(0.7))
            router.replace(with: .results(result))
        }
    }
}

private struct TutorialCard: View {
    let game: MiniGame
    let goal: String
    let onClose: () -> Void
    @State private var handPhase = false

    var body: some View {
        PopupCard {
            VStack(spacing: 16) {
                Text(game.title).font(.game(26)).foregroundStyle(Palette.text)
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(Palette.crystal.opacity(0.6))
                    demo
                }
                .frame(height: 130)
                Text(instruction).font(.game(18, .semibold)).foregroundStyle(Palette.text).multilineTextAlignment(.center)
                Text(goal).font(.game(16)).foregroundStyle(Palette.hotPink).multilineTextAlignment(.center)
                BigButton(title: "Got it!", icon: .check, color: Palette.hotPink, action: onClose)
            }
        }
        .onAppear { withAnimation(.easeInOut(duration: 0.9).repeatForever()) { handPhase = true } }
    }

    private var instruction: String {
        switch game {
        case .match: "Swipe a diamond next to another to make a line of 3 of the same color!"
        case .sorting: "Drag each crystal into the basket with the same color."
        case .memory: "Tap two cards to flip them. Find the matching pairs!"
        }
    }

    @ViewBuilder private var demo: some View {
        switch game {
        case .match:
            HStack(spacing: 6) {
                GemView(color: Palette.gems[0], size: 44)
                GemView(color: Palette.gems[0], size: 44)
                GemView(color: Palette.gems[1], size: 44)
                GemView(color: Palette.gems[0], size: 44).offset(x: handPhase ? -50 : 0)
            }
        case .sorting:
            HStack(spacing: 40) {
                GemView(color: Palette.gems[3], size: 44).offset(x: handPhase ? 70 : 0, y: handPhase ? 30 : -20)
                BasketArt(color: Palette.gems[3]).scaleEffect(0.7).frame(width: 84, height: 70)
            }
        case .memory:
            HStack(spacing: 10) {
                MemoryCardFace(face: 4).frame(width: 60, height: 80)
                MemoryCardBack().frame(width: 60, height: 80)
                MemoryCardFace(face: 4).frame(width: 60, height: 80).opacity(handPhase ? 1 : 0.2)
            }
        }
    }
}

// MARK: - Screen 6: Diamond Match

@Observable
private final class MatchModel {
    var collected = 0
    var movesLeft: Int
    var gemsMatched = 0
    var usedExtra = false
    var outOfMoves = false
    var message: String?
    let target: Int
    let totalMoves: Int
    let color: Int
    let scene: MatchScene

    init(level: LevelDef, color: Int, target: Int, moves: Int, colors: Int, reduceMotion: Bool) {
        self.target = target
        self.color = color
        movesLeft = moves
        totalMoves = moves
        let seed = UInt64(level.id * 7919) &+ UInt64(Date().timeIntervalSince1970)
        scene = MatchScene(engine: MatchEngine(rows: 7, cols: 7, colors: colors, seed: seed), reduceMotion: reduceMotion)
    }
}

private struct MatchGameView: View {
    let level: LevelDef
    let color: Int
    let target: Int
    let moves: Int
    let colors: Int
    let onFinish: (Int, Int, Int, Int) -> Void
    @Environment(\.gameReduceMotion) private var reduceMotion
    @Environment(Router.self) private var router
    @State private var model: MatchModel?

    var body: some View {
        VStack(spacing: 10) {
            if let model {
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        GemView(color: Palette.gems[color], size: 38)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(min(model.collected, target)) / \(target)").font(.game(20)).foregroundStyle(Palette.text)
                                .contentTransition(.numericText(value: Double(model.collected)))
                            GameProgressBar(value: Double(model.collected) / Double(target), colors: [Palette.gems[color].lighter(), Palette.gems[color]], height: 12)
                        }
                    }
                    .padding(10).frame(maxWidth: .infinity).gamePanel()
                    VStack(spacing: 0) {
                        Text("\(model.movesLeft)").font(.game(30)).foregroundStyle(model.movesLeft <= 3 ? Palette.hotPink : Palette.royal)
                            .contentTransition(.numericText(value: Double(model.movesLeft)))
                        Text("moves").font(.game(13)).foregroundStyle(Palette.text)
                    }
                    .frame(width: 84, height: 72).gamePanel()
                }
                .padding(.horizontal, 16)

                SpriteView(scene: model.scene, options: [.allowsTransparency])
                    .aspectRatio(1, contentMode: .fit)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 26).fill(Palette.deep.opacity(0.25)))
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.8), lineWidth: 3))
                    .frame(maxWidth: Device.isPad ? 640 : .infinity)
                    .padding(.horizontal, 12)

                Text(model.message ?? "Make lines of 3 or more!")
                    .font(.game(17)).foregroundStyle(.white).animation(.default, value: model.message)

                HStack(spacing: 14) {
                    BigButton(title: "Hint", icon: .hint, color: Palette.gold, height: 54) { model.scene.showHint() }
                }
                .padding(.bottom, 10)
                Spacer(minLength: 0)
            }
        }
        .overlay {
            if let model, model.outOfMoves {
                PopupCard {
                    VStack(spacing: 14) {
                        CompanionView(companion: .coco, size: 100)
                        Text("Out of moves!").font(.game(26)).foregroundStyle(Palette.text)
                        Text("So close! Want a little help?").font(.game(17, .semibold)).foregroundStyle(Palette.text.opacity(0.8))
                        if !model.usedExtra {
                            BigButton(title: "5 more moves", icon: .plus, color: Palette.green) {
                                model.usedExtra = true
                                model.movesLeft += 5
                                model.outOfMoves = false
                                model.scene.inputEnabled = true
                            }
                        }
                        BigButton(title: "Try again", icon: .refresh, color: Palette.royal) { setUp() }
                        BigButton(title: "Back to Map", icon: .map, color: Palette.lilac) { router.back() }
                    }
                }
            }
        }
        .onAppear { if model == nil { setUp() } }
    }

    private func setUp() {
        let m = MatchModel(level: level, color: color, target: target, moves: moves, colors: colors, reduceMotion: reduceMotion)
        m.scene.onMoveResolved = { [weak m] counts in
            guard let m else { return }
            m.movesLeft -= 1
            m.collected += counts[color, default: 0]
            m.gemsMatched += counts.values.reduce(0, +)
            let total = counts.values.reduce(0, +)
            m.message = total >= 6 ? "Wow, amazing combo!" : total >= 4 ? "Super!" : "Nice match!"
            if m.collected >= m.target {
                m.scene.inputEnabled = false
                let rating = ScoreCalculator.matchRating(movesLeft: m.movesLeft, totalMoves: m.totalMoves, usedExtraMoves: m.usedExtra)
                onFinish(rating, m.movesLeft * 10, m.gemsMatched, 0)
            } else if m.movesLeft <= 0 {
                m.scene.inputEnabled = false
                m.outOfMoves = true
            }
        }
        m.scene.onInvalidSwap = { [weak m] in
            AudioManager.shared.play(.gentleOops)
            m?.message = "Try another swap!"
        }
        m.scene.onShuffle = { [weak m] in m?.message = "New diamonds, fresh moves!" }
        model = m
    }
}

// MARK: - Screen 7: Crystal Sorting

@Observable
private final class SortingModel {
    var sorted = 0
    var mistakes = 0
    var message = "Drag a crystal into its basket!"
    let total: Int
    let scene: SortingScene

    init(level: LevelDef, crystals: Int, baskets: Int, shapes: Bool, reduceMotion: Bool) {
        total = crystals
        let seed = UInt64(level.id * 104_729) &+ UInt64(Date().timeIntervalSince1970)
        scene = SortingScene(engine: SortingEngine(crystals: crystals, baskets: baskets, shapes: shapes, seed: seed), reduceMotion: reduceMotion)
    }
}

private struct SortingGameView: View {
    let level: LevelDef
    let crystals: Int
    let baskets: Int
    let shapes: Bool
    let onFinish: (Int, Int, Int, Int) -> Void
    @Environment(\.gameReduceMotion) private var reduceMotion
    @State private var model: SortingModel?

    private let cheers = ["Great job!", "Yay, correct!", "You're a star!", "Perfect!", "Sparkly!"]

    var body: some View {
        VStack(spacing: 10) {
            if let model {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sorted \(model.sorted) / \(model.total)").font(.game(20)).foregroundStyle(Palette.text)
                        GameProgressBar(value: Double(model.sorted) / Double(model.total), colors: [Palette.mint, Palette.green], height: 14)
                    }
                    Spacer()
                    RoundIconButton(icon: .hint, color: Palette.gold, size: 50, label: "Hint") { model.scene.showHint() }
                }
                .padding(12).gamePanel().padding(.horizontal, 16)

                Text(model.message).font(.game(19)).foregroundStyle(.white)
                    .shadow(color: Palette.deep, radius: 0, y: 2)
                    .animation(.spring, value: model.message)

                SpriteView(scene: model.scene, options: [.allowsTransparency])
                    .background(RoundedRectangle(cornerRadius: 26).fill(.white.opacity(0.25)))
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.8), lineWidth: 3))
                    .frame(maxWidth: Device.isPad ? 760 : .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 12).padding(.bottom, 12)
            }
        }
        .onAppear {
            guard model == nil else { return }
            let m = SortingModel(level: level, crystals: crystals, baskets: baskets, shapes: shapes, reduceMotion: reduceMotion)
            m.scene.onSorted = { [weak m] sorted in
                guard let m else { return }
                m.sorted = sorted
                m.message = cheers[sorted % cheers.count]
                if sorted >= m.total {
                    onFinish(ScoreCalculator.sortingRating(mistakes: m.mistakes), m.total * 5, 0, m.total)
                }
            }
            m.scene.onMistake = { [weak m] in
                m?.mistakes += 1
                m?.message = "Oops! Look for the same color."
            }
            model = m
        }
    }
}
