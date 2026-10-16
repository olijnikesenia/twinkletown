import SwiftUI

/// Garden decorations, drawn in a square frame.
struct DecorationArt: View {
    let id: String

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack { art(s) }.frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder private func art(_ s: CGFloat) -> some View {
        switch id {
        case "deco_crystal_fountain":
            Ellipse().fill(Palette.royal).frame(width: s * 0.9, height: s * 0.3).position(x: s / 2, y: s * 0.82)
            Ellipse().fill(Palette.crystal).frame(width: s * 0.75, height: s * 0.2).position(x: s / 2, y: s * 0.78)
            RoundedRectangle(cornerRadius: s * 0.04).fill(Palette.sky).frame(width: s * 0.14, height: s * 0.4).position(x: s / 2, y: s * 0.58)
            ForEach([-1.0, 0, 1.0], id: \.self) { d in
                Capsule().fill(Palette.crystal.opacity(0.9)).frame(width: s * 0.06, height: s * 0.32)
                    .rotationEffect(.degrees(d * 30), anchor: .bottom).position(x: s / 2, y: s * 0.26)
            }
            GemView(color: Palette.royal, size: s * 0.2).position(x: s / 2, y: s * 0.36)
        case "deco_rainbow_tree", "deco_crystal_tree":
            let rainbow = id == "deco_rainbow_tree"
            RoundedRectangle(cornerRadius: s * 0.04).fill(Color(hex: 0x9C6A3C)).frame(width: s * 0.14, height: s * 0.4).position(x: s / 2, y: s * 0.76)
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(rainbow ? Palette.rainbow[i] : [Palette.sky, Palette.crystal, Palette.royal.opacity(0.7), Palette.sky, Palette.crystal][i])
                    .frame(width: s * 0.36)
                    .position(x: s * [0.32, 0.68, 0.5, 0.3, 0.7][i], y: s * [0.42, 0.42, 0.22, 0.24, 0.24][i])
            }
            if !rainbow {
                GemView(color: Palette.royal, size: s * 0.14).position(x: s * 0.4, y: s * 0.32)
                GemView(color: Palette.lilac, size: s * 0.12).position(x: s * 0.64, y: s * 0.28)
            }
        case "deco_mushroom_house":
            RoundedRectangle(cornerRadius: s * 0.08).fill(Color(hex: 0xFFF6EA)).frame(width: s * 0.5, height: s * 0.42).position(x: s / 2, y: s * 0.72)
            RoundedRectangle(cornerRadius: s * 0.1).fill(Palette.deep).frame(width: s * 0.16, height: s * 0.24).position(x: s / 2, y: s * 0.81)
            Circle().fill(Palette.yellow).frame(width: s * 0.1).position(x: s * 0.66, y: s * 0.66)
            Ellipse().fill(Palette.royal).frame(width: s * 0.95, height: s * 0.6).position(x: s / 2, y: s * 0.38)
                .mask(Rectangle().frame(width: s, height: s * 0.32).position(x: s / 2, y: s * 0.24))
            ForEach(0..<4, id: \.self) { i in
                Circle().fill(.white).frame(width: s * 0.09).position(x: s * [0.25, 0.48, 0.7, 0.4][i], y: s * [0.33, 0.18, 0.3, 0.38][i])
            }
        case "deco_diamond_bench":
            RoundedRectangle(cornerRadius: s * 0.04).fill(Palette.sky).frame(width: s * 0.85, height: s * 0.1).position(x: s / 2, y: s * 0.6)
            RoundedRectangle(cornerRadius: s * 0.04).fill(Palette.royal).frame(width: s * 0.85, height: s * 0.16).position(x: s / 2, y: s * 0.44)
            ForEach([0.2, 0.8], id: \.self) { x in
                RoundedRectangle(cornerRadius: s * 0.02).fill(Palette.deep).frame(width: s * 0.08, height: s * 0.24).position(x: s * x, y: s * 0.76)
            }
            GemView(color: Palette.gems[1], size: s * 0.16).position(x: s / 2, y: s * 0.44)
        case "deco_star_lantern":
            RoundedRectangle(cornerRadius: s * 0.02).fill(Palette.deep).frame(width: s * 0.06, height: s * 0.55).position(x: s / 2, y: s * 0.68)
            Circle().fill(Palette.yellow.opacity(0.35)).frame(width: s * 0.55).position(x: s / 2, y: s * 0.3)
            StarCoin(size: s * 0.4).position(x: s / 2, y: s * 0.3)
        case "deco_flower_arch":
            Circle().trim(from: 0.5, to: 1).stroke(Palette.mint, lineWidth: s * 0.1)
                .frame(width: s * 0.8, height: s * 0.8).position(x: s / 2, y: s * 0.55)
            ForEach([0.1, 0.9], id: \.self) { x in
                Rectangle().fill(Palette.mint).frame(width: s * 0.1, height: s * 0.45).position(x: s * x, y: s * 0.77)
            }
            ForEach(0..<7, id: \.self) { i in
                let a = Double.pi + Double(i) * .pi / 6
                FlowerArt(petal: [Palette.pink, Palette.yellow, .white][i % 3], center: Palette.hotPink)
                    .frame(width: s * 0.16, height: s * 0.16)
                    .position(x: s / 2 + cos(a) * s * 0.4, y: s * 0.55 + sin(a) * s * 0.4)
            }
        case "deco_sparkling_pond":
            Ellipse().fill(Palette.royal).frame(width: s * 0.95, height: s * 0.45).position(x: s / 2, y: s * 0.65)
            Ellipse().fill(Palette.sky).frame(width: s * 0.8, height: s * 0.33).position(x: s / 2, y: s * 0.65)
            ForEach(0..<3, id: \.self) { i in
                SparkleShape().fill(.white).frame(width: s * 0.1, height: s * 0.1)
                    .position(x: s * [0.3, 0.6, 0.72][i], y: s * [0.6, 0.7, 0.58][i])
            }
            Ellipse().fill(Palette.green).frame(width: s * 0.18, height: s * 0.08).position(x: s * 0.4, y: s * 0.72)
        case "deco_pink_flowers":
            ForEach(0..<3, id: \.self) { i in
                Rectangle().fill(Palette.green).frame(width: s * 0.04, height: s * 0.4).position(x: s * [0.3, 0.5, 0.7][i], y: s * 0.72)
                FlowerArt(petal: Palette.pink, center: Palette.yellow).frame(width: s * 0.3, height: s * 0.3)
                    .position(x: s * [0.3, 0.5, 0.7][i], y: s * [0.5, 0.38, 0.52][i])
            }
        case "deco_crystal_cluster":
            ForEach(0..<4, id: \.self) { i in
                Capsule().fill(LinearGradient(colors: [Palette.crystal, [Palette.royal, Palette.lilac, Palette.sky, Palette.royal][i]],
                                              startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 2))
                    .frame(width: s * 0.18, height: s * [0.6, 0.45, 0.4, 0.3][i])
                    .rotationEffect(.degrees([0, -25, 25, -45][i]), anchor: .bottom)
                    .position(x: s / 2, y: s * (0.85 - [0.6, 0.45, 0.4, 0.3][i] / 2))
            }
        case "deco_cloud_puff":
            CloudShape().fill(.white).frame(width: s * 0.9, height: s * 0.5).position(x: s / 2, y: s / 2)
                .shadow(color: Palette.sky, radius: 4)
        case "deco_sunflower":
            Rectangle().fill(Palette.green).frame(width: s * 0.06, height: s * 0.5).position(x: s / 2, y: s * 0.72)
            Ellipse().fill(Palette.green).frame(width: s * 0.2, height: s * 0.1).position(x: s * 0.6, y: s * 0.7)
            FlowerArt(petal: Palette.yellow, center: Color(hex: 0xB0712F)).frame(width: s * 0.55, height: s * 0.55).position(x: s / 2, y: s * 0.35)
        case "deco_toadstool":
            RoundedRectangle(cornerRadius: s * 0.06).fill(Color(hex: 0xFFF6EA)).frame(width: s * 0.24, height: s * 0.36).position(x: s / 2, y: s * 0.72)
            Ellipse().fill(Palette.hotPink).frame(width: s * 0.75, height: s * 0.42).position(x: s / 2, y: s * 0.48)
                .mask(Rectangle().frame(width: s, height: s * 0.22).position(x: s / 2, y: s * 0.38))
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(.white).frame(width: s * 0.08).position(x: s * [0.35, 0.52, 0.66][i], y: s * [0.4, 0.32, 0.41][i])
            }
        default:
            GemView(size: s * 0.6).position(x: s / 2, y: s / 2)
        }
    }
}

/// Thumbnail for any catalog item (shop, customization, garden tray).
struct ItemArt: View {
    let item: ShopItem

    var body: some View {
        switch item.category {
        case .decoration: DecorationArt(id: item.id)
        case .background:
            BackgroundArt(id: item.id).clipShape(RoundedRectangle(cornerRadius: 14))
        case .outfit:
            OutfitArt(id: item.id).clipShape(TShirtShape()).overlay(TShirtShape().stroke(Palette.text.opacity(0.3), lineWidth: 2))
                .aspectRatio(1, contentMode: .fit).padding(4)
        case .accessory:
            // Accessories are shown on a tiny mannequin head for context.
            ZStack {
                Circle().fill(Palette.crystal.opacity(0.6)).frame(width: 130).position(x: 100, y: 92)
                switch item.slot {
                case .hat: HatArt(id: item.id)
                case .glasses: GlassesArt(id: item.id)
                case .wings: WingsArt(id: item.id, t: 0)
                case .bow: BowArt(id: item.id).frame(width: 90, height: 56).position(x: 100, y: 110)
                default: EffectArt(id: item.id, t: 1.3)
                }
            }
            .frame(width: 200, height: 220)
            .scaleEffect(0.42)
            .frame(width: 84, height: 92)
        }
    }
}

struct TShirtShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: r.minX + w * 0.35, y: r.minY + h * 0.08))
        p.addQuadCurve(to: CGPoint(x: r.minX + w * 0.65, y: r.minY + h * 0.08), control: CGPoint(x: r.midX, y: r.minY + h * 0.22))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + h * 0.28))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.12, y: r.minY + h * 0.45))
        p.addLine(to: CGPoint(x: r.minX + w * 0.78, y: r.minY + h * 0.38))
        p.addLine(to: CGPoint(x: r.minX + w * 0.78, y: r.maxY - h * 0.05))
        p.addLine(to: CGPoint(x: r.minX + w * 0.22, y: r.maxY - h * 0.05))
        p.addLine(to: CGPoint(x: r.minX + w * 0.22, y: r.minY + h * 0.38))
        p.addLine(to: CGPoint(x: r.minX + w * 0.12, y: r.minY + h * 0.45))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + h * 0.28))
        p.closeSubpath()
        return p
    }
}
