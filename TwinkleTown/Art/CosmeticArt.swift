import SwiftUI

/// Fills its frame; the companion clips it to the body shape.
struct OutfitArt: View {
    let id: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                switch id {
                case "outfit_rainbow_hoodie":
                    VStack(spacing: 0) { ForEach(Palette.rainbow.indices, id: \.self) { Palette.rainbow[$0] } }
                    Capsule().fill(.white).frame(width: 4, height: h * 0.3).offset(x: -w * 0.1, y: -h * 0.25)
                    Capsule().fill(.white).frame(width: 4, height: h * 0.3).offset(x: w * 0.1, y: -h * 0.25)
                    RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.35)).frame(width: w * 0.45, height: h * 0.2).offset(y: h * 0.22)
                case "outfit_blue_wizard":
                    LinearGradient(colors: [Palette.royal, Palette.deep], startPoint: .top, endPoint: .bottom)
                    pattern(count: 6, w: w, h: h) { StarShape().fill(Palette.yellow).frame(width: 12, height: 12) }
                    Rectangle().fill(Palette.gold).frame(height: 8).offset(y: h * 0.38)
                case "outfit_crystal_explorer":
                    Palette.mint
                    Rectangle().fill(Color(hex: 0x9C6A3C)).frame(height: 10).offset(y: h * 0.12)
                    GemView(color: Palette.sky, size: 18).offset(y: h * 0.12)
                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0x6CD3A8)).frame(width: 22, height: 18).offset(x: -w * 0.22, y: -h * 0.12)
                case "outfit_star_pajamas":
                    Palette.lilac
                    pattern(count: 8, w: w, h: h) { StarShape().fill(.white.opacity(0.85)).frame(width: 10, height: 10) }
                    VStack(spacing: 10) { ForEach(0..<3, id: \.self) { _ in Circle().fill(Palette.yellow).frame(width: 7) } }
                case "outfit_cloud":
                    Color.white
                    HStack(spacing: -8) { ForEach(0..<5, id: \.self) { _ in Circle().fill(Palette.crystal).frame(width: 30) } }
                        .offset(y: h * 0.42)
                    pattern(count: 5, w: w, h: h) { Circle().fill(Palette.sky.opacity(0.6)).frame(width: 8) }
                case "outfit_flower":
                    Palette.pink
                    pattern(count: 5, w: w, h: h) { FlowerArt(petal: .white, center: Palette.yellow).frame(width: 20, height: 20) }
                    Rectangle().fill(Palette.mint).frame(height: 8).offset(y: -h * 0.36)
                case Catalog.celebrationReward:
                    LinearGradient(colors: [Color(hex: 0x223C9E), Color(hex: 0x6A4BD8)], startPoint: .top, endPoint: .bottom)
                    pattern(count: 7, w: w, h: h) { SparkleShape().fill(Palette.yellow).frame(width: 12, height: 12) }
                    Capsule().fill(Palette.gold).frame(width: w * 0.7, height: 10).offset(y: -h * 0.36)
                    DiamondIcon(size: 18).offset(y: -h * 0.3)
                default:
                    Palette.sky
                }
            }
            .frame(width: w, height: h)
        }
    }

    /// Fixed scatter positions so patterns don't jump between renders.
    private func pattern<V: View>(count: Int, w: CGFloat, h: CGFloat, @ViewBuilder item: () -> V) -> some View {
        let spots: [CGPoint] = [.init(x: 0.25, y: 0.3), .init(x: 0.7, y: 0.25), .init(x: 0.45, y: 0.55), .init(x: 0.2, y: 0.7),
                                .init(x: 0.75, y: 0.65), .init(x: 0.5, y: 0.85), .init(x: 0.85, y: 0.45), .init(x: 0.12, y: 0.48)]
        let v = item()
        return ZStack {
            ForEach(0..<min(count, spots.count), id: \.self) { i in v.position(x: spots[i].x * w, y: spots[i].y * h) }
        }
    }
}

struct FlowerArt: View {
    var petal: Color = Palette.pink
    var center: Color = Palette.yellow

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<5, id: \.self) { i in
                    Ellipse().fill(petal).frame(width: s * 0.38, height: s * 0.5)
                        .offset(y: -s * 0.24).rotationEffect(.degrees(Double(i) * 72))
                }
                Circle().fill(center).frame(width: s * 0.36)
            }
            .frame(width: s, height: s)
        }
    }
}

/// Drawn in the companion's 200 x 240 space.
struct HatArt: View {
    let id: String

    var body: some View {
        switch id {
        case "hat_diamond_crown":
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 64, y: 44))
                    p.addLine(to: CGPoint(x: 60, y: 10)); p.addLine(to: CGPoint(x: 80, y: 28))
                    p.addLine(to: CGPoint(x: 100, y: 2)); p.addLine(to: CGPoint(x: 120, y: 28))
                    p.addLine(to: CGPoint(x: 140, y: 10)); p.addLine(to: CGPoint(x: 136, y: 44))
                    p.closeSubpath()
                }
                .fill(LinearGradient(colors: [Color(hex: 0xFFF1A0), Palette.gold], startPoint: .top, endPoint: .bottom))
                .overlay(Path { p in
                    p.move(to: CGPoint(x: 64, y: 44))
                    p.addLine(to: CGPoint(x: 60, y: 10)); p.addLine(to: CGPoint(x: 80, y: 28))
                    p.addLine(to: CGPoint(x: 100, y: 2)); p.addLine(to: CGPoint(x: 120, y: 28))
                    p.addLine(to: CGPoint(x: 140, y: 10)); p.addLine(to: CGPoint(x: 136, y: 44))
                    p.closeSubpath()
                }.stroke(Color(hex: 0xD98A12), style: StrokeStyle(lineWidth: 3, lineJoin: .round)))
                GemView(color: Palette.royal, size: 20).position(x: 100, y: 32)
                GemView(color: Palette.gems[1], shape: .round, size: 12).position(x: 76, y: 36)
                GemView(color: Palette.gems[3], shape: .round, size: 12).position(x: 124, y: 36)
            }
        case "hat_rainbow":
            ZStack {
                ForEach(Palette.rainbow.indices, id: \.self) { i in
                    Circle().trim(from: 0.5, to: 1).fill(Palette.rainbow[i])
                        .frame(width: 104 - CGFloat(i) * 12, height: 104 - CGFloat(i) * 12)
                        .position(x: 100, y: 56)
                }
                Capsule().fill(.white).frame(width: 108, height: 14).position(x: 100, y: 52)
                Circle().fill(.white).frame(width: 20).position(x: 100, y: 2)
            }
        case "hat_bunny_ears":
            ZStack {
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ZStack {
                        Ellipse().fill(.white)
                        Ellipse().fill(Palette.hotPink.opacity(0.6)).padding(.horizontal, 8).padding(.vertical, 12)
                    }
                    .overlay(Ellipse().stroke(Palette.hotPink, lineWidth: 2.5))
                    .frame(width: 26, height: 66)
                    .rotationEffect(.degrees(side * 18), anchor: .bottom)
                    .position(x: 100 + side * 20, y: 8)
                }
                Capsule().fill(Palette.hotPink).frame(width: 100, height: 10).position(x: 100, y: 42)
            }
        default:
            EmptyView()
        }
    }
}

struct GlassesArt: View {
    let id: String

    var body: some View {
        ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                ZStack {
                    StarShape(inner: 0.55).fill(Palette.pink.opacity(0.45))
                    StarShape(inner: 0.55).stroke(Palette.hotPink, style: StrokeStyle(lineWidth: 3.5, lineJoin: .round))
                }
                .frame(width: 42, height: 42)
                .position(x: 100 + side * 25, y: 96)
            }
            Capsule().fill(Palette.hotPink).frame(width: 12, height: 4).position(x: 100, y: 94)
        }
    }
}

struct BowArt: View {
    let id: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Triangle().fill(Palette.hotPink).rotationEffect(.degrees(-90)).frame(width: h, height: w * 0.45).position(x: w * 0.24, y: h / 2)
                Triangle().fill(Palette.hotPink).rotationEffect(.degrees(90)).frame(width: h, height: w * 0.45).position(x: w * 0.76, y: h / 2)
                GemView(color: Palette.sky, shape: .heart, size: h * 0.7).position(x: w / 2, y: h / 2)
            }
        }
    }
}

struct WingsArt: View {
    let id: String
    let t: Double

    var body: some View {
        let flap = sin(t * 3) * 8
        ZStack {
            ForEach([-1.0, 1.0], id: \.self) { side in
                ZStack {
                    Ellipse().fill(LinearGradient(colors: [Palette.crystal.opacity(0.9), Palette.sky.opacity(0.7), Palette.lilac.opacity(0.6)],
                                                  startPoint: .top, endPoint: .bottom))
                    Ellipse().stroke(.white, lineWidth: 3)
                    Ellipse().fill(.white.opacity(0.5)).frame(width: 18, height: 40).offset(x: -side * 8, y: -10)
                }
                .frame(width: 64, height: 96)
                .rotationEffect(.degrees(side * (40 + flap)), anchor: .bottom)
                .position(x: 100 + side * 40, y: 128)
            }
        }
    }
}

struct EffectArt: View {
    let id: String
    let t: Double

    var body: some View {
        ZStack {
            if id == "effect_hearts" {
                ForEach(0..<5, id: \.self) { i in
                    let phase = (t * 0.4 + Double(i) / 5).truncatingRemainder(dividingBy: 1)
                    HeartShape().fill(Palette.hotPink.opacity(1 - phase))
                        .frame(width: 18, height: 16)
                        .position(x: 40 + Double(i) * 30 + sin(t * 2 + Double(i)) * 6, y: 220 - phase * 210)
                }
            } else {
                ForEach(0..<7, id: \.self) { i in
                    let a = t * 0.8 + Double(i) * .pi * 2 / 7
                    SparkleShape().fill(i.isMultiple(of: 2) ? Palette.yellow : .white)
                        .frame(width: 16, height: 16)
                        .shadow(color: Palette.yellow, radius: 4)
                        .position(x: 100 + cos(a) * 92, y: 130 + sin(a) * 104)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
