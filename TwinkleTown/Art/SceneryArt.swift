import SwiftUI

/// Animated sky used behind most screens: gradient, drifting clouds and twinkling sparkles.
struct MagicBackground: View {
    var colors: [Color] = [Palette.violet, Palette.lilac, Palette.lavender]
    var clouds = true
    @Environment(\.gameReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { ctx in
            let t = reduceMotion ? 0 : ctx.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                    ForEach(0..<14, id: \.self) { i in
                        let x = Double((i * 37) % 100) / 100, y = Double((i * 53) % 90) / 100
                        SparkleShape().fill(.white)
                            .frame(width: CGFloat(8 + i % 3 * 5), height: CGFloat(8 + i % 3 * 5))
                            .opacity(0.35 + 0.55 * abs(sin(t * 1.2 + Double(i))))
                            .position(x: x * w, y: y * h)
                    }
                    if clouds {
                        ForEach(0..<4, id: \.self) { i in
                            let speed = 8.0 + Double(i) * 4
                            let span = w + 240
                            let x = (Double(i) * 0.31 * span + t * speed).truncatingRemainder(dividingBy: span) - 120
                            CloudShape().fill(.white.opacity(0.75))
                                .frame(width: 130 - CGFloat(i) * 12, height: 60 - CGFloat(i) * 5)
                                .position(x: x, y: h * (0.1 + Double(i) * 0.2))
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// Floating crystal island (grass top, crystal underside).
struct IslandView: View {
    var width: CGFloat = 300
    var flowers = true

    var body: some View {
        let h = width * 0.5
        ZStack(alignment: .top) {
            Path { p in
                p.move(to: CGPoint(x: width * 0.05, y: h * 0.3))
                p.addLine(to: CGPoint(x: width * 0.95, y: h * 0.3))
                p.addLine(to: CGPoint(x: width * 0.62, y: h * 0.85))
                p.addLine(to: CGPoint(x: width * 0.5, y: h))
                p.addLine(to: CGPoint(x: width * 0.38, y: h * 0.85))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Palette.sky, Palette.royal, Palette.deep], startPoint: .top, endPoint: .bottom))
            Path { p in
                p.move(to: CGPoint(x: width * 0.3, y: h * 0.32)); p.addLine(to: CGPoint(x: width * 0.45, y: h * 0.9))
                p.move(to: CGPoint(x: width * 0.7, y: h * 0.32)); p.addLine(to: CGPoint(x: width * 0.55, y: h * 0.9))
            }
            .stroke(.white.opacity(0.5), lineWidth: 2)
            Ellipse()
                .fill(LinearGradient(colors: [Color(hex: 0x8EF0B4), Palette.green], startPoint: .top, endPoint: .bottom))
                .frame(width: width, height: h * 0.45)
                .overlay(Ellipse().stroke(Color(hex: 0x3FAF7A), lineWidth: 3))
            if flowers {
                HStack(spacing: width * 0.12) {
                    FlowerArt(petal: Palette.pink).frame(width: width * 0.07, height: width * 0.07)
                    FlowerArt(petal: Palette.yellow, center: Palette.hotPink).frame(width: width * 0.06, height: width * 0.06)
                    FlowerArt(petal: .white).frame(width: width * 0.07, height: width * 0.07)
                    FlowerArt(petal: Palette.sky).frame(width: width * 0.06, height: width * 0.06)
                }
                .offset(y: h * 0.08)
            }
        }
        .frame(width: width, height: h)
    }
}

/// Selectable backgrounds (character + garden skies).
struct BackgroundArt: View {
    let id: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                switch id {
                case "bg_crystal_sky":
                    LinearGradient(colors: [Palette.crystal, Palette.sky], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<6, id: \.self) { i in
                        GemView(color: [Palette.royal, Palette.sky, Palette.lilac][i % 3], size: w * 0.09)
                            .opacity(0.8)
                            .position(x: w * [0.15, 0.8, 0.5, 0.3, 0.9, 0.65][i], y: h * [0.15, 0.2, 0.08, 0.4, 0.5, 0.35][i])
                    }
                case "bg_rainbow_clouds":
                    LinearGradient(colors: [Palette.pink, Palette.sky], startPoint: .top, endPoint: .bottom)
                    RainbowArc().frame(width: w * 0.95, height: w * 0.48).position(x: w / 2, y: h * 0.35)
                    CloudShape().fill(.white).frame(width: w * 0.35, height: w * 0.16).position(x: w * 0.12, y: h * 0.42)
                    CloudShape().fill(.white).frame(width: w * 0.35, height: w * 0.16).position(x: w * 0.88, y: h * 0.42)
                case "bg_night_city":
                    NightCityArt()
                case "bg_magical_night":
                    LinearGradient(colors: [Color(hex: 0x0E1F5C), Color(hex: 0x3B2A8C), Palette.deep], startPoint: .top, endPoint: .bottom)
                    Circle().fill(Palette.yellow).frame(width: w * 0.16).position(x: w * 0.8, y: h * 0.14)
                    Circle().fill(Color(hex: 0x0E1F5C)).frame(width: w * 0.14).position(x: w * 0.84, y: h * 0.12)
                    ForEach(0..<12, id: \.self) { i in
                        StarShape().fill(.white.opacity(0.9)).frame(width: w * 0.03, height: w * 0.03)
                            .position(x: w * Double((i * 29) % 100) / 100, y: h * Double((i * 17) % 60) / 100)
                    }
                case "bg_sparkling_forest":
                    LinearGradient(colors: [Palette.mint, Color(hex: 0x3FAF7A)], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<5, id: \.self) { i in
                        Triangle().fill(Color(hex: 0x2F8F6A).opacity(0.8))
                            .frame(width: w * 0.25, height: h * 0.4)
                            .position(x: w * (0.1 + Double(i) * 0.2), y: h * 0.35)
                    }
                    ForEach(0..<10, id: \.self) { i in
                        Circle().fill(Palette.yellow).frame(width: 5).shadow(color: Palette.yellow, radius: 4)
                            .position(x: w * Double((i * 41) % 100) / 100, y: h * Double((i * 23) % 70) / 100)
                    }
                case "bg_pastel_dreamland":
                    LinearGradient(colors: [Palette.pink, Palette.lilac.opacity(0.7), Palette.yellow], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<8, id: \.self) { i in
                        Circle().stroke(.white.opacity(0.8), lineWidth: 2)
                            .background(Circle().fill(.white.opacity(0.2)))
                            .frame(width: w * CGFloat(0.05 + Double(i % 3) * 0.03))
                            .position(x: w * Double((i * 37) % 100) / 100, y: h * Double((i * 19) % 70) / 100)
                    }
                default: // bg_twinkle_sky
                    LinearGradient(colors: [Palette.royal, Palette.sky], startPoint: .top, endPoint: .bottom)
                    CloudShape().fill(.white.opacity(0.85)).frame(width: w * 0.35, height: w * 0.16).position(x: w * 0.25, y: h * 0.18)
                    CloudShape().fill(.white.opacity(0.85)).frame(width: w * 0.3, height: w * 0.14).position(x: w * 0.78, y: h * 0.3)
                    ForEach(0..<6, id: \.self) { i in
                        SparkleShape().fill(.white).frame(width: w * 0.04, height: w * 0.04)
                            .position(x: w * Double((i * 43) % 100) / 100, y: h * Double((i * 31) % 60) / 100)
                    }
                }
            }
            .frame(width: w, height: h)
            .clipped()
        }
    }
}

/// Twinkle Town at night: starry sky, glowing skyline and a crystal tower.
struct NightCityArt: View {
    var showsMoon = true
    // (x, width, height) as fractions of the canvas.
    private let back: [(CGFloat, CGFloat, CGFloat)] = [(0.0, 0.14, 0.34), (0.12, 0.12, 0.42), (0.27, 0.1, 0.3), (0.56, 0.13, 0.4),
                                                      (0.88, 0.12, 0.33)]
    private let front: [(CGFloat, CGFloat, CGFloat)] = [(0.0, 0.17, 0.24), (0.15, 0.13, 0.3), (0.3, 0.12, 0.2), (0.58, 0.14, 0.27),
                                                       (0.71, 0.12, 0.19), (0.83, 0.19, 0.26)]
    private let windowColors = [Palette.yellow, Palette.pink, Palette.crystal]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                LinearGradient(colors: [Color(hex: 0x140A3D), Palette.grape, Color(hex: 0x7A4FE0)], startPoint: .top, endPoint: .bottom)
                Ellipse().fill(Palette.hotPink.opacity(0.35)).frame(width: w * 1.2, height: h * 0.35).blur(radius: 30)
                    .position(x: w / 2, y: h * 0.82)
                ForEach(0..<18, id: \.self) { i in
                    StarShape().fill(.white.opacity(i % 3 == 0 ? 1 : 0.7))
                        .frame(width: w * (i % 3 == 0 ? 0.03 : 0.018), height: w * (i % 3 == 0 ? 0.03 : 0.018))
                        .position(x: w * CGFloat((i * 37 + 7) % 100) / 100, y: h * CGFloat((i * 23 + 3) % 45) / 100)
                }
                if showsMoon {
                    CrescentMoon().frame(width: w * 0.17, height: w * 0.17).position(x: w * 0.19, y: h * 0.12)
                }

                ForEach(back.indices, id: \.self) { i in
                    let b = back[i]
                    Rectangle().fill(Color(hex: 0x2E1A7A))
                        .frame(width: w * b.1, height: h * b.2)
                        .position(x: w * (b.0 + b.1 / 2), y: h * (1 - b.2 / 2))
                }
                crystalTower(w: w, h: h)
                ForEach(front.indices, id: \.self) { i in
                    building(front[i], index: i, w: w, h: h)
                }
            }
            .frame(width: w, height: h)
        }
    }

    private func building(_ b: (CGFloat, CGFloat, CGFloat), index i: Int, w: CGFloat, h: CGFloat) -> some View {
        let bw = w * b.1, bh = h * b.2
        let cols = 3, rows = max(2, Int(b.2 * 14))
        return ZStack(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: i.isMultiple(of: 2) ? bw * 0.3 : 4, topTrailingRadius: 4)
                .fill(Color(hex: 0x1D0F52))
            VStack(spacing: bh / CGFloat(rows) * 0.45) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: bw * 0.12) {
                        ForEach(0..<cols, id: \.self) { c in
                            let lit = (i * 7 + r * 3 + c * 5) % 4 != 0
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(lit ? windowColors[(i + r + c) % 3] : Color(hex: 0x3A2A80))
                                .frame(width: bw * 0.16, height: bh / CGFloat(rows) * 0.5)
                                .shadow(color: lit ? windowColors[(i + r + c) % 3].opacity(0.8) : .clear, radius: 2)
                        }
                    }
                }
            }
            .padding(.top, bh * 0.12)
        }
        .frame(width: bw, height: bh)
        .position(x: w * (b.0 + b.1 / 2), y: h - bh / 2)
    }

    private func crystalTower(w: CGFloat, h: CGFloat) -> some View {
        let tw = w * 0.12, th = h * 0.5
        return ZStack {
            Rectangle().fill(LinearGradient(colors: [Palette.crystal, Palette.sky, Palette.royal], startPoint: .top, endPoint: .bottom))
                .frame(width: tw, height: th).position(x: w * 0.78, y: h - th / 2)
            Rectangle().fill(.white.opacity(0.45)).frame(width: tw * 0.18, height: th).position(x: w * 0.78 - tw * 0.22, y: h - th / 2)
            Triangle().fill(Palette.lilac).frame(width: tw * 1.4, height: h * 0.1).position(x: w * 0.78, y: h - th - h * 0.05)
            Circle().fill(Palette.crystal.opacity(0.6)).frame(width: w * 0.16).blur(radius: 10).position(x: w * 0.78, y: h - th - h * 0.14)
            GemView(color: Palette.royal, size: w * 0.09).position(x: w * 0.78, y: h - th - h * 0.14)
        }
    }
}

struct RainbowArc: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                ForEach(Palette.rainbow.indices, id: \.self) { i in
                    Circle().trim(from: 0.5, to: 1)
                        .stroke(Palette.rainbow[i], lineWidth: w * 0.035)
                        .frame(width: w - CGFloat(i) * w * 0.07, height: w - CGFloat(i) * w * 0.07)
                }
            }
            .frame(width: w, height: w)
            .offset(y: w * 0.25)
        }
    }
}

/// Glowing crescent: a yellow disc with a real cut-out, so it works on any sky.
struct CrescentMoon: View {
    var body: some View {
        GeometryReader { geo in
            let d = min(geo.size.width, geo.size.height)
            Circle().fill(LinearGradient(colors: [Color(hex: 0xFFF3B0), Palette.yellow, Palette.gold], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: d * 0.9, height: d * 0.9)
                .mask {
                    ZStack {
                        Rectangle()
                        Circle().frame(width: d * 0.78, height: d * 0.78).offset(x: d * 0.26, y: -d * 0.14).blendMode(.destinationOut)
                    }
                    .compositingGroup()
                }
                .shadow(color: Palette.yellow.opacity(0.9), radius: d * 0.1)
                .shadow(color: Palette.yellow.opacity(0.5), radius: d * 0.3)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
