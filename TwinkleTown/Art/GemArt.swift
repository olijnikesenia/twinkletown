import SwiftUI

/// Glossy faceted gem. Used by SwiftUI screens and rendered to SpriteKit textures.
struct GemView: View {
    var color: Color = Palette.royal
    var shape: GemShape = .gem
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            switch shape {
            case .gem: brilliant
            case .round: round
            case .square: square
            case .heart: heart
            }
            // Twinkle highlight.
            SparkleShape()
                .fill(.white)
                .frame(width: size * 0.22, height: size * 0.22)
                .offset(x: -size * 0.2, y: -size * 0.22)
                .shadow(color: .white, radius: size * 0.04)
        }
        .frame(width: size, height: size)
    }

    private var fill: LinearGradient {
        LinearGradient(colors: [color.lighter(0.55), color, color.darker(0.25)], startPoint: .top, endPoint: .bottom)
    }

    private var outline: Color { color.darker(0.45) }

    private var brilliant: some View {
        let s = size
        return ZStack {
            GemShape2D().fill(fill)
            // Table facet.
            Path { p in
                p.move(to: CGPoint(x: s * 0.25, y: s * 0.1))
                p.addLine(to: CGPoint(x: s * 0.75, y: s * 0.1))
                p.addLine(to: CGPoint(x: s * 0.66, y: s * 0.38))
                p.addLine(to: CGPoint(x: s * 0.34, y: s * 0.38))
                p.closeSubpath()
            }
            .fill(color.lighter(0.6).opacity(0.9))
            // Facet lines.
            Path { p in
                p.move(to: CGPoint(x: 0, y: s * 0.38)); p.addLine(to: CGPoint(x: s, y: s * 0.38))
                p.move(to: CGPoint(x: s * 0.34, y: s * 0.38)); p.addLine(to: CGPoint(x: s * 0.5, y: s * 0.96))
                p.move(to: CGPoint(x: s * 0.66, y: s * 0.38)); p.addLine(to: CGPoint(x: s * 0.5, y: s * 0.96))
                p.move(to: CGPoint(x: s * 0.25, y: s * 0.1)); p.addLine(to: CGPoint(x: s * 0.34, y: s * 0.38))
                p.move(to: CGPoint(x: s * 0.75, y: s * 0.1)); p.addLine(to: CGPoint(x: s * 0.66, y: s * 0.38))
            }
            .stroke(.white.opacity(0.55), lineWidth: max(1, s * 0.025))
            GemShape2D().stroke(outline, style: StrokeStyle(lineWidth: max(1.2, s * 0.05), lineJoin: .round))
        }
        .frame(width: s, height: s)
    }

    private var round: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [color.lighter(0.6), color, color.darker(0.3)],
                                         center: .init(x: 0.35, y: 0.3), startRadius: 1, endRadius: size * 0.6))
            StarShape(points: 8, inner: 0.75)
                .stroke(.white.opacity(0.55), lineWidth: max(1, size * 0.025))
                .padding(size * 0.2)
            Circle().stroke(outline, lineWidth: max(1.2, size * 0.05))
        }
        .padding(size * 0.06)
    }

    private var square: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18).fill(fill)
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(color.lighter(0.5).opacity(0.8))
                .padding(size * 0.22)
            RoundedRectangle(cornerRadius: size * 0.1)
                .stroke(.white.opacity(0.6), lineWidth: max(1, size * 0.025))
                .padding(size * 0.22)
            RoundedRectangle(cornerRadius: size * 0.18).stroke(outline, lineWidth: max(1.2, size * 0.05))
        }
        .padding(size * 0.08)
    }

    private var heart: some View {
        ZStack {
            HeartShape().fill(fill)
            HeartShape().fill(color.lighter(0.6).opacity(0.7)).scaleEffect(0.45).offset(y: -size * 0.05)
            HeartShape().stroke(outline, style: StrokeStyle(lineWidth: max(1.2, size * 0.05), lineJoin: .round))
        }
        .padding(size * 0.05)
    }
}

/// The friendly smiling star used for the star currency.
struct StarCoin: View {
    var size: CGFloat = 32
    var face = true

    var body: some View {
        ZStack {
            StarShape(inner: 0.56)
                .fill(LinearGradient(colors: [Color(hex: 0xFFF3A6), Palette.gold, Color(hex: 0xF5A623)],
                                     startPoint: .top, endPoint: .bottom))
            StarShape(inner: 0.56)
                .stroke(Color(hex: 0xD98A12), style: StrokeStyle(lineWidth: max(1, size * 0.05), lineJoin: .round))
            if face {
                HStack(spacing: size * 0.14) {
                    Capsule().fill(Palette.text).frame(width: size * 0.07, height: size * 0.12)
                    Capsule().fill(Palette.text).frame(width: size * 0.07, height: size * 0.12)
                }
                .offset(y: size * 0.02)
                Path { p in
                    p.addArc(center: CGPoint(x: size * 0.5, y: size * 0.58), radius: size * 0.08,
                             startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                }
                .stroke(Palette.text, style: StrokeStyle(lineWidth: max(1, size * 0.04), lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

/// The main progress diamond (always royal blue).
struct DiamondIcon: View {
    var size: CGFloat = 32
    var body: some View { GemView(color: Palette.royal, shape: .gem, size: size) }
}
