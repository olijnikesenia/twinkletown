import SwiftUI

// MARK: - Screen 5: Adventure map

struct AdventureMapScreen: View {
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            MagicBackground(colors: [Palette.grape, Palette.violet, Palette.lilac])
            VStack(spacing: 0) {
                ScreenHeader(title: "Adventure Map", onBack: router.back)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: Device.isPad ? 2 : 1), spacing: 18) {
                            ForEach(World.all) { world in
                                WorldCard(world: world).id(world.id)
                            }
                        }
                        .padding(16)
                    }
                    .onAppear { proxy.scrollTo(state.currentLevel.world, anchor: .center) }
                }
            }
        }
    }
}

private struct WorldCard: View {
    let world: World
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router

    private var levels: [LevelDef] { LevelDef.all.filter { $0.world == world.id } }
    private var unlocked: Bool { state.isWorldUnlocked(world.id) }
    private var earned: Int { levels.compactMap { state.rating($0) }.reduce(0, +) }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(world.id + 1). \(world.name)").font(.game(21)).foregroundStyle(.white)
                    .shadow(color: Palette.deep, radius: 0, y: 2)
                Spacer()
                StarCoin(size: 22, face: false)
                Text("\(earned)/18").font(.game(16)).foregroundStyle(.white)
            }
            ZStack {
                WorldScenery(world: world.id)
                path
                GeometryReader { geo in
                    ForEach(Array(levels.enumerated()), id: \.element.id) { i, level in
                        LevelNode(level: level)
                            .position(nodePoint(i, in: geo.size))
                    }
                }
                if !unlocked {
                    RoundedRectangle(cornerRadius: 22).fill(Palette.deep.opacity(0.55))
                    VStack(spacing: 6) {
                        IconView(icon: .lock, size: 44)
                        Text("Finish \(world.id > 0 ? World.all[world.id - 1].name : "") to open")
                            .font(.game(16)).foregroundStyle(.white).multilineTextAlignment(.center)
                    }
                }
            }
            .frame(height: Device.isPad ? 330 : 290)
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 28).fill(LinearGradient(colors: world.colors, startPoint: .topLeading, endPoint: .bottomTrailing)))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white, lineWidth: 3))
        .shadow(color: Palette.deep.opacity(0.3), radius: 8, y: 5)
    }

    private func nodePoint(_ i: Int, in size: CGSize) -> CGPoint {
        let xs: [CGFloat] = [0.2, 0.5, 0.8, 0.8, 0.5, 0.2]
        let ys: [CGFloat] = [0.3, 0.38, 0.3, 0.7, 0.78, 0.7]
        return CGPoint(x: xs[i] * size.width, y: ys[i] * size.height)
    }

    private var path: some View {
        GeometryReader { geo in
            Path { p in
                for i in 0..<levels.count {
                    let pt = nodePoint(i, in: geo.size)
                    i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                }
            }
            .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round, dash: [2, 14]))
        }
    }
}

private struct LevelNode: View {
    let level: LevelDef
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @State private var bounce = false

    var body: some View {
        let unlocked = state.isUnlocked(level)
        let rating = state.rating(level)
        let isCurrent = unlocked && rating == nil
        let size: CGFloat = Device.isPad ? 72 : 62
        Button {
            guard unlocked else { feedback(.gentleOops); return }
            feedback(.flip, haptic: .medium)
            router.go(.play(level.id))
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    Circle().fill(unlocked ? (rating != nil ? Palette.yellow : .white) : Color(hex: 0xB9C6DD))
                    Circle().stroke(isCurrent ? Palette.hotPink : Palette.deep.opacity(0.4), lineWidth: isCurrent ? 5 : 3)
                    if unlocked {
                        VStack(spacing: 0) {
                            gameBadge
                            Text("\(level.id)").font(.game(size * 0.32)).foregroundStyle(Palette.text)
                        }
                    } else {
                        IconView(icon: .lock, color: .white, size: size * 0.4)
                    }
                }
                .frame(width: size, height: size)
                .scaleEffect(bounce ? 1.1 : 1)
                RatingStars(rating: rating ?? 0, size: 16).opacity(rating == nil ? 0.5 : 1)
            }
            .overlay(alignment: .top) {
                if isCurrent {
                    CompanionArt(companion: state.data.companion ?? .bibi, appearance: state.data.appearance)
                        .frame(width: 200, height: 240).scaleEffect(0.2).frame(width: 40, height: 48)
                        .offset(y: -44)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Level \(level.id), \(level.game.title)\(unlocked ? "" : ", locked")")
        .onAppear {
            if isCurrent { withAnimation(.easeInOut(duration: 0.8).repeatForever()) { bounce = true } }
        }
    }

    @ViewBuilder private var gameBadge: some View {
        switch level.game {
        case .match: GemView(color: Palette.gems[0], size: 18)
        case .sorting: GemView(color: Palette.gems[3], shape: .square, size: 18)
        case .memory: GemView(color: Palette.gems[1], shape: .heart, size: 18)
        }
    }
}

/// Little themed props for each world.
private struct WorldScenery: View {
    let world: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                switch world {
                case 0:
                    ForEach(0..<6, id: \.self) { i in
                        FlowerArt(petal: i.isMultiple(of: 2) ? Palette.sky : .white, center: Palette.yellow)
                            .frame(width: 26, height: 26).position(x: w * Double((i * 37 + 10) % 100) / 100, y: h * 0.5 + Double(i % 3) * 18)
                    }
                    DecorationArt(id: "deco_crystal_cluster").frame(width: 60).position(x: w * 0.92, y: h * 0.45)
                case 1:
                    RainbowArc().frame(width: w * 0.7, height: w * 0.35).position(x: w / 2, y: h * 0.42).opacity(0.7)
                    CloudShape().fill(.white).frame(width: 90, height: 42).position(x: w * 0.12, y: h * 0.5)
                    CloudShape().fill(.white).frame(width: 90, height: 42).position(x: w * 0.88, y: h * 0.5)
                case 2:
                    ForEach(0..<4, id: \.self) { i in
                        DecorationArt(id: i.isMultiple(of: 2) ? "deco_crystal_tree" : "deco_toadstool")
                            .frame(width: i.isMultiple(of: 2) ? 70 : 40).position(x: w * [0.05, 0.35, 0.65, 0.95][i], y: h * 0.5)
                    }
                case 3:
                    ForEach(0..<8, id: \.self) { i in
                        Circle().stroke(.white.opacity(0.7), lineWidth: 2).frame(width: CGFloat(10 + i % 3 * 8))
                            .position(x: w * Double((i * 41) % 100) / 100, y: h * Double((i * 29 + 20) % 100) / 100)
                    }
                    GemView(color: Palette.gems[1], shape: .round, size: 36).position(x: w * 0.06, y: h * 0.5)
                default:
                    CastleArt().frame(width: 120, height: 110).position(x: w / 2, y: h * 0.52).opacity(0.85)
                    GemView(size: 34).position(x: w * 0.1, y: h * 0.48)
                    GemView(color: Palette.lilac, size: 30).position(x: w * 0.9, y: h * 0.48)
                }
            }
        }
        .background(Color.white.opacity(0.18))
    }
}

struct CastleArt: View {
    var lit = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let wall = LinearGradient(colors: [Palette.crystal, Palette.sky], startPoint: .top, endPoint: .bottom)
            ZStack {
                if lit { Circle().fill(Palette.yellow.opacity(0.5)).frame(width: w * 1.2).blur(radius: 20).position(x: w / 2, y: h / 2) }
                Rectangle().fill(wall).frame(width: w * 0.6, height: h * 0.5).position(x: w / 2, y: h * 0.72)
                ForEach([0.15, 0.85, 0.5], id: \.self) { x in
                    let tall = x == 0.5
                    Rectangle().fill(wall).frame(width: w * 0.2, height: h * (tall ? 0.7 : 0.55))
                        .position(x: w * x, y: h * (tall ? 0.6 : 0.68))
                    Triangle().fill(Palette.royal).frame(width: w * 0.26, height: h * 0.25)
                        .position(x: w * x, y: h * (tall ? 0.15 : 0.3))
                }
                Capsule().fill(Palette.deep).frame(width: w * 0.16, height: h * 0.26).position(x: w / 2, y: h * 0.86)
                ForEach([0.15, 0.5, 0.85], id: \.self) { x in
                    RoundedRectangle(cornerRadius: 3).fill(lit ? Palette.yellow : Palette.deep.opacity(0.6))
                        .frame(width: w * 0.06, height: h * 0.08).position(x: w * x, y: h * 0.55)
                }
                GemView(size: w * 0.14).position(x: w / 2, y: h * 0.03)
            }
        }
    }
}
