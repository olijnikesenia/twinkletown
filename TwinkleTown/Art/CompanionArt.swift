import SwiftUI

/// Animated companion with idle motion, blinking and layered cosmetics.
struct CompanionView: View {
    let companion: Companion
    var appearance = Appearance()
    var size: CGFloat = 160
    var happy = false
    @Environment(\.gameReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { ctx in
            let t = reduceMotion ? 0.5 : ctx.date.timeIntervalSinceReferenceDate
            CompanionArt(companion: companion, appearance: appearance, t: t, happy: happy)
                .modifier(IdleMotion(companion: companion, t: t, happy: happy, still: reduceMotion))
        }
        .frame(width: 200, height: 240)
        .scaleEffect(size / 200)
        .frame(width: size, height: size * 1.2)
        .accessibilityElement()
        .accessibilityLabel(companion.name)
    }
}

private struct IdleMotion: ViewModifier {
    let companion: Companion
    let t: Double
    let happy: Bool
    let still: Bool

    func body(content: Content) -> some View {
        if still { content } else {
            switch companion {
            case .bibi: content.offset(y: -abs(sin(t * (happy ? 6 : 3))) * (happy ? 16 : 7))
            case .mimi: content.rotationEffect(.degrees(sin(t * 2) * (happy ? 8 : 4)), anchor: .bottom)
            case .coco: content.scaleEffect(x: 1 - sin(t * 2) * 0.015, y: 1 + sin(t * 2) * 0.03, anchor: .bottom)
                .offset(y: happy ? -abs(sin(t * 5)) * 10 : 0)
            case .lolo: content.offset(x: sin(t * 1.5) * 4, y: happy ? -abs(sin(t * 5)) * 10 : 0)
            }
        }
    }
}

/// Static drawing in a 200 x 240 design space; `t` drives tail, wings, blinking and effects.
struct CompanionArt: View {
    let companion: Companion
    var appearance = Appearance()
    /// Defaults past the blink window so static thumbnails have open eyes.
    var t: Double = 1
    var happy = false

    private var fur: Color { companion.fur }
    private var shade: Color { companion.furShade }
    private var blinking: Bool { t.truncatingRemainder(dividingBy: 4) < 0.14 }
    private var outline: Color { shade.darker(0.35) }

    var body: some View {
        ZStack {
            if let wings = appearance.item(.wings) { WingsArt(id: wings, t: t) }
            if appearance.item(.outfit) == Catalog.celebrationReward { cape }
            tail
            torso
            if companion == .coco { scarf }
            if let bow = appearance.item(.bow) { BowArt(id: bow).frame(width: 56, height: 34).position(x: 100, y: 140) }
            ears
            head
            face
            if companion == .bibi { StarCoin(size: 26, face: false).rotationEffect(.degrees(15)).position(x: 136, y: 52) }
            if let hat = appearance.item(.hat) { HatArt(id: hat) }
            if let glasses = appearance.item(.glasses) { GlassesArt(id: glasses) }
            if let effect = appearance.item(.effect) { EffectArt(id: effect, t: t) }
        }
        .frame(width: 200, height: 240)
    }

    // MARK: Body

    private var torso: some View {
        ZStack {
            // Arms
            ForEach([-1.0, 1.0], id: \.self) { side in
                Ellipse().fill(fur).overlay(Ellipse().stroke(outline, lineWidth: 3))
                    .frame(width: 30, height: 46)
                    .rotationEffect(.degrees(side * (happy ? -40 : 22)))
                    .position(x: 100 + side * 54, y: happy ? 150 : 172)
            }
            // Feet
            ForEach([-1.0, 1.0], id: \.self) { side in
                Ellipse().fill(shade).overlay(Ellipse().stroke(outline, lineWidth: 3))
                    .frame(width: 42, height: 24)
                    .position(x: 100 + side * 28, y: 222)
            }
            Ellipse().fill(fur).frame(width: 116, height: 98).position(x: 100, y: 178)
            if let outfit = appearance.item(.outfit) {
                OutfitArt(id: outfit).frame(width: 116, height: 98).clipShape(Ellipse()).position(x: 100, y: 178)
            } else {
                Ellipse().fill(.white.opacity(0.55)).frame(width: 66, height: 58).position(x: 100, y: 188)
            }
            Ellipse().stroke(outline, lineWidth: 3).frame(width: 116, height: 98).position(x: 100, y: 178)
        }
    }

    private var tail: some View {
        let wag = sin(t * 4) * 12
        return Group {
            switch companion {
            case .lolo:
                ZStack(alignment: .top) {
                    Ellipse().fill(fur).frame(width: 50, height: 96)
                    Ellipse().fill(Color(hex: 0xFFF6EA)).frame(width: 34, height: 32).offset(y: -2)
                }
                .overlay(Ellipse().stroke(outline, lineWidth: 3))
                .frame(width: 50, height: 96)
                .rotationEffect(.degrees(48 + wag), anchor: .bottom)
                .position(x: 148, y: 156)
            case .mimi:
                Capsule().fill(fur).overlay(Capsule().stroke(outline, lineWidth: 3))
                    .frame(width: 16, height: 76)
                    .rotationEffect(.degrees(35 + wag), anchor: .bottom)
                    .position(x: 150, y: 170)
            case .bibi:
                Circle().fill(.white).overlay(Circle().stroke(outline, lineWidth: 3))
                    .frame(width: 32).position(x: 154, y: 200)
            case .coco:
                Circle().fill(shade).overlay(Circle().stroke(outline, lineWidth: 3))
                    .frame(width: 24).position(x: 152, y: 204)
            }
        }
    }

    private var scarf: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Palette.royal).frame(width: 34, height: 18)
                .rotationEffect(.degrees(14)).position(x: 126, y: 152)
            Capsule().fill(Palette.royal).frame(width: 100, height: 20).position(x: 100, y: 138)
            Capsule().stroke(Palette.deep, lineWidth: 2).frame(width: 100, height: 20).position(x: 100, y: 138)
        }
    }

    private var cape: some View {
        Path { p in
            p.move(to: CGPoint(x: 60, y: 135))
            p.addLine(to: CGPoint(x: 140, y: 135))
            p.addQuadCurve(to: CGPoint(x: 100, y: 230), control: CGPoint(x: 175, y: 230))
            p.addQuadCurve(to: CGPoint(x: 60, y: 135), control: CGPoint(x: 25, y: 230))
        }
        .fill(LinearGradient(colors: [Palette.deep, Color(hex: 0x6A4BD8)], startPoint: .top, endPoint: .bottom))
    }

    // MARK: Head

    private var ears: some View {
        Group {
            switch companion {
            case .bibi:
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ZStack {
                        Ellipse().fill(Palette.sky).overlay(Ellipse().stroke(Palette.deep.opacity(0.6), lineWidth: 3))
                        Ellipse().fill(Palette.royal.opacity(0.8)).padding(.horizontal, 9).padding(.vertical, 14)
                    }
                    .frame(width: 34, height: 92)
                    .rotationEffect(.degrees(side * (12 + sin(t * 2 + side) * 4)), anchor: .bottom)
                    .position(x: 100 + side * 26, y: 34)
                }
            case .mimi, .lolo:
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ZStack {
                        Triangle().fill(fur)
                        Triangle().fill(companion == .mimi ? Palette.hotPink.opacity(0.7) : Color(hex: 0xFFF3E4))
                            .padding(.horizontal, 11).padding(.top, 14).padding(.bottom, 4)
                        Triangle().stroke(outline, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
                    }
                    .frame(width: companion == .lolo ? 50 : 46, height: companion == .lolo ? 60 : 50)
                    .rotationEffect(.degrees(side * 20))
                    .position(x: 100 + side * 42, y: 44)
                }
            case .coco:
                ForEach([-1.0, 1.0], id: \.self) { side in
                    ZStack {
                        Circle().fill(fur).overlay(Circle().stroke(outline, lineWidth: 3))
                        Circle().fill(shade).padding(11)
                    }
                    .frame(width: 46).position(x: 100 + side * 46, y: 46)
                }
            }
        }
    }

    private var head: some View {
        ZStack {
            Ellipse().fill(fur).frame(width: 130, height: 116)
            Ellipse().fill(.white.opacity(0.35)).frame(width: 60, height: 22).offset(x: -24, y: -38)
            switch companion {
            case .coco: Ellipse().fill(Color(hex: 0xFFE0AE)).frame(width: 58, height: 42).offset(y: 22)
            case .lolo:
                HStack(spacing: 6) {
                    Ellipse().fill(Color(hex: 0xFFF6EA)).frame(width: 52, height: 44)
                    Ellipse().fill(Color(hex: 0xFFF6EA)).frame(width: 52, height: 44)
                }.offset(y: 24)
            default: EmptyView()
            }
            Ellipse().stroke(outline, lineWidth: 3).frame(width: 130, height: 116)
        }
        .position(x: 100, y: 92)
    }

    private var face: some View {
        ZStack {
            eyes
            ForEach([-1.0, 1.0], id: \.self) { side in
                Ellipse().fill(Palette.hotPink.opacity(0.45)).frame(width: 22, height: 13)
                    .position(x: 100 + side * 38, y: 112)
            }
            nose
            mouth
            if companion == .mimi { whiskers }
        }
    }

    private var eyes: some View {
        let eyeSize: CGSize = switch companion {
        case .mimi: CGSize(width: 19, height: 24)
        case .coco: CGSize(width: 13, height: 15)
        default: CGSize(width: 16, height: 21)
        }
        return ForEach([-1.0, 1.0], id: \.self) { side in
            Group {
                if happy || blinking {
                    Path { p in
                        if happy {
                            p.move(to: CGPoint(x: 0, y: 12)); p.addQuadCurve(to: CGPoint(x: 20, y: 12), control: CGPoint(x: 10, y: -4))
                        } else {
                            p.move(to: CGPoint(x: 2, y: 9)); p.addQuadCurve(to: CGPoint(x: 18, y: 9), control: CGPoint(x: 10, y: 14))
                        }
                    }
                    .stroke(Palette.text, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 20, height: 16)
                } else {
                    ZStack {
                        Ellipse().fill(Palette.text).frame(width: eyeSize.width, height: eyeSize.height)
                        if companion == .mimi {
                            SparkleShape().fill(.white).frame(width: 10, height: 10).offset(x: -3, y: -4)
                        } else {
                            Circle().fill(.white).frame(width: 6).offset(x: -3, y: -4)
                        }
                        Circle().fill(.white.opacity(0.8)).frame(width: 3).offset(x: 3, y: 5)
                    }
                }
            }
            .position(x: 100 + side * 24, y: 96)
            .overlay {
                if companion == .lolo && !happy {
                    Capsule().fill(Palette.text.opacity(0.75)).frame(width: 16, height: 4)
                        .rotationEffect(.degrees(side * 14))
                        .position(x: 100 + side * 25, y: 78)
                }
            }
        }
    }

    private var nose: some View {
        Group {
            switch companion {
            case .bibi: Ellipse().fill(Palette.hotPink).frame(width: 12, height: 8)
            case .mimi: Triangle().fill(Palette.hotPink).frame(width: 12, height: 8).rotationEffect(.degrees(180))
            case .coco: Ellipse().fill(Color(hex: 0x6B4120)).frame(width: 20, height: 13)
            case .lolo: Ellipse().fill(Palette.text).frame(width: 15, height: 10)
            }
        }
        .position(x: 100, y: 110)
    }

    private var mouth: some View {
        ZStack {
            if happy {
                Ellipse().fill(Color(hex: 0x8A2E4D)).frame(width: 20, height: 16)
                    .overlay(alignment: .bottom) { Ellipse().fill(Palette.hotPink).frame(width: 12, height: 7) }
                    .clipShape(Ellipse())
                    .position(x: 100, y: 126)
            } else {
                Path { p in
                    switch companion {
                    case .mimi:
                        p.move(to: CGPoint(x: 90, y: 118))
                        p.addQuadCurve(to: CGPoint(x: 100, y: 118), control: CGPoint(x: 95, y: 126))
                        p.addQuadCurve(to: CGPoint(x: 110, y: 118), control: CGPoint(x: 105, y: 126))
                    case .lolo:
                        p.move(to: CGPoint(x: 92, y: 120))
                        p.addQuadCurve(to: CGPoint(x: 112, y: 116), control: CGPoint(x: 104, y: 128))
                    default:
                        p.move(to: CGPoint(x: 90, y: 119))
                        p.addQuadCurve(to: CGPoint(x: 110, y: 119), control: CGPoint(x: 100, y: 129))
                    }
                }
                .stroke(Palette.text, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                if companion == .bibi {
                    RoundedRectangle(cornerRadius: 2).fill(.white)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Palette.text, lineWidth: 1.5))
                        .frame(width: 10, height: 8).position(x: 100, y: 127)
                }
            }
        }
    }

    private var whiskers: some View {
        Path { p in
            for side in [-1.0, 1.0] {
                for dy in [-4.0, 4.0] {
                    p.move(to: CGPoint(x: 100 + side * 28, y: 112 + dy))
                    p.addLine(to: CGPoint(x: 100 + side * 52, y: 108 + dy * 2))
                }
            }
        }
        .stroke(Palette.text.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}
