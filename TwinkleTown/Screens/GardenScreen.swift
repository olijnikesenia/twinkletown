import SwiftUI

// MARK: - Screen 12: My Magical Garden

struct GardenScreen: View {
    @Environment(GameState.self) private var state
    @Environment(Router.self) private var router
    @State private var selected: UUID?
    @State private var drag: (id: UUID, offset: CGSize)?
    @State private var pickingSky = false

    var body: some View {
        ZStack {
            MagicBackground(colors: [Palette.lilac, Palette.lavender, Palette.mint])
            VStack(spacing: 6) {
                ScreenHeader(title: "My Garden", onBack: router.back)
                garden
                    .padding(.horizontal, 12)
                tray
            }
        }
    }

    private var garden: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let itemSize = min(w, h) * 0.22
            ZStack {
                BackgroundArt(id: state.data.gardenBackground)
                Ellipse()
                    .fill(LinearGradient(colors: [Color(hex: 0x9CF3C0), Palette.green], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 1.3, height: h * 0.75)
                    .position(x: w / 2, y: h * 0.95)
                GardenLife(width: w, height: h)

                ForEach(state.data.garden.sorted { $0.y < $1.y }) { p in
                    let offset = drag?.id == p.id ? drag!.offset : .zero
                    DecorationArt(id: p.itemID)
                        .frame(width: itemSize, height: itemSize)
                        .scaleEffect(selected == p.id ? 1.12 : 1)
                        .overlay(alignment: .topTrailing) {
                            if selected == p.id {
                                Button {
                                    feedback(.gentleOops)
                                    withAnimation(.spring) { state.removeDecoration(p.id) }
                                    selected = nil
                                } label: {
                                    IconView(icon: .trash, color: .white, size: 20).frame(width: 40, height: 40)
                                }
                                .buttonStyle(CandyButtonStyle(color: Palette.hotPink, shape: AnyShape(Circle())))
                                .accessibilityLabel("Remove decoration")
                                .offset(x: 10, y: -10)
                            }
                        }
                        .position(x: p.x * w + offset.width, y: p.y * h + offset.height)
                        .gesture(
                            DragGesture(minimumDistance: 4)
                                .onChanged { v in
                                    selected = p.id
                                    drag = (p.id, v.translation)
                                }
                                .onEnded { v in
                                    state.moveDecoration(p.id, x: p.x + v.translation.width / w, y: p.y + v.translation.height / h)
                                    drag = nil
                                    feedback(.place)
                                }
                        )
                        .onTapGesture { withAnimation(.spring) { selected = selected == p.id ? nil : p.id } }
                        .accessibilityLabel(Catalog.item(p.itemID)?.name ?? "Decoration")
                }

                CompanionView(companion: state.data.companion ?? .bibi, appearance: state.data.appearance, size: min(w, h) * 0.28)
                    .position(x: w * 0.5, y: h * 0.78)
                    .allowsHitTesting(false)

                if state.data.garden.isEmpty {
                    Text("Tap a decoration below to add it!")
                        .font(.game(18)).foregroundStyle(Palette.text)
                        .padding(12).gamePanel().position(x: w / 2, y: h * 0.3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white, lineWidth: 4))
            .contentShape(Rectangle())
            .onTapGesture { selected = nil }
        }
    }

    private var tray: some View {
        VStack(spacing: 6) {
            HStack {
                Text(pickingSky ? "Pick a sky" : "Decorations \(state.data.garden.count)/\(GameState.gardenLimit)")
                    .font(.game(16)).foregroundStyle(Palette.text)
                Spacer()
                Button(pickingSky ? "Decorations" : "Change sky") {
                    feedback()
                    withAnimation { pickingSky.toggle() }
                }
                .font(.game(15)).foregroundStyle(.white)
                .padding(.horizontal, 14).frame(height: 36)
                .buttonStyle(CandyButtonStyle(color: Palette.royal))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if pickingSky {
                        ForEach(Catalog.items.filter { $0.category == .background }) { item in
                            let owned = state.owns(item.id)
                            trayButton(selected: state.data.gardenBackground == item.id, locked: !owned) {
                                ItemArt(item: item)
                            } action: {
                                if owned { state.setGardenBackground(item.id) } else { router.go(.shop) }
                            }
                        }
                    } else {
                        ForEach(state.ownedDecorations) { item in
                            trayButton(selected: false, locked: false) { DecorationArt(id: item.id).padding(6) } action: {
                                let n = Double(state.data.garden.count)
                                if let placed = state.placeDecoration(item.id, x: 0.2 + (n * 0.17).truncatingRemainder(dividingBy: 0.6),
                                                                      y: 0.55 + (n * 0.07).truncatingRemainder(dividingBy: 0.3)) {
                                    selected = placed.id
                                }
                            }
                        }
                        trayButton(selected: false, locked: false) {
                            VStack(spacing: 2) { IconView(icon: .shop, color: Palette.hotPink, size: 30); Text("More").font(.game(13)).foregroundStyle(Palette.text) }
                        } action: { router.go(.shop) }
                    }
                }
                .padding(.horizontal, 4).padding(.vertical, 6)
            }
        }
        .padding(12)
        .gamePanel()
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func trayButton<V: View>(selected: Bool, locked: Bool, @ViewBuilder content: () -> V, action: @escaping () -> Void) -> some View {
        Button {
            feedback(.place)
            withAnimation(.spring) { action() }
        } label: {
            content()
                .frame(width: Device.isPad ? 92 : 74, height: Device.isPad ? 92 : 74)
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.crystal.opacity(0.5)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? Palette.hotPink : .white, lineWidth: selected ? 4 : 2))
                .overlay(alignment: .bottomTrailing) {
                    if locked { IconView(icon: .lock, color: .white, size: 14).padding(4).background(Circle().fill(Palette.text.opacity(0.6))).padding(3) }
                }
        }
        .buttonStyle(.plain)
    }
}

/// Butterflies and twinkling crystals drifting around the garden.
private struct GardenLife: View {
    let width: CGFloat
    let height: CGFloat
    @Environment(\.gameReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { ctx in
            let t = reduceMotion ? 1 : ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    let k = Double(i)
                    Butterfly(color: [Palette.pink, Palette.yellow, Palette.crystal][i], flap: sin(t * 12 + k))
                        .frame(width: 30, height: 24)
                        .position(x: width * (0.5 + 0.38 * sin(t * 0.3 + k * 2)), y: height * (0.35 + 0.15 * sin(t * 0.5 + k)))
                }
                ForEach(0..<6, id: \.self) { i in
                    SparkleShape().fill(.white).frame(width: 14, height: 14)
                        .opacity(abs(sin(t + Double(i))))
                        .position(x: width * Double((i * 37 + 5) % 100) / 100, y: height * (0.15 + Double(i % 3) * 0.12))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct Butterfly: View {
    let color: Color
    let flap: Double

    var body: some View {
        HStack(spacing: 0) {
            Ellipse().fill(color).frame(width: 14, height: 20).scaleEffect(x: 0.4 + 0.6 * abs(flap), anchor: .trailing)
            Capsule().fill(Palette.text).frame(width: 3, height: 16)
            Ellipse().fill(color).frame(width: 14, height: 20).scaleEffect(x: 0.4 + 0.6 * abs(flap), anchor: .leading)
        }
        .overlay(Ellipse().stroke(.white.opacity(0.6), lineWidth: 1))
    }
}
