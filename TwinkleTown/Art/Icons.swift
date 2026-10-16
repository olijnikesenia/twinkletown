import SwiftUI

/// Hand-drawn UI icons (no SF Symbols / emoji), drawn in a 24 x 24 design space.
enum GameIcon {
    case play, map, shop, wardrobe, garden, trophy, medal, gift, gear, back, close, check, lock
    case music, sound, vibration, motion, refresh, hint, trash, plus, person, calendar
}

struct IconView: View {
    let icon: GameIcon
    var color: Color = .white
    var size: CGFloat = 24

    var body: some View {
        ZStack { drawing }
            .frame(width: 24, height: 24)
            .scaleEffect(size / 24)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var stroke: StrokeStyle { StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round) }

    @ViewBuilder private var drawing: some View {
        switch icon {
        case .play:
            Path { p in p.move(to: .init(x: 7, y: 4)); p.addLine(to: .init(x: 20, y: 12)); p.addLine(to: .init(x: 7, y: 20)); p.closeSubpath() }
                .fill(color).overlay(Path { p in p.move(to: .init(x: 7, y: 4)); p.addLine(to: .init(x: 20, y: 12)); p.addLine(to: .init(x: 7, y: 20)); p.closeSubpath() }.stroke(color, style: stroke))
        case .map:
            Path { p in
                p.move(to: .init(x: 3, y: 6)); p.addLine(to: .init(x: 9, y: 3)); p.addLine(to: .init(x: 15, y: 6))
                p.addLine(to: .init(x: 21, y: 3)); p.addLine(to: .init(x: 21, y: 18)); p.addLine(to: .init(x: 15, y: 21))
                p.addLine(to: .init(x: 9, y: 18)); p.addLine(to: .init(x: 3, y: 21)); p.closeSubpath()
                p.move(to: .init(x: 9, y: 3)); p.addLine(to: .init(x: 9, y: 18)); p.move(to: .init(x: 15, y: 6)); p.addLine(to: .init(x: 15, y: 21))
            }.stroke(color, style: stroke)
        case .shop:
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 18, height: 14).position(x: 12, y: 15)
            Path { p in p.addArc(center: .init(x: 12, y: 8), radius: 4.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false) }
                .stroke(color, style: stroke)
        case .wardrobe:
            TShirtShape().fill(color).frame(width: 22, height: 20).position(x: 12, y: 12)
        case .garden:
            FlowerArt(petal: color, center: color.opacity(0.5)).frame(width: 18, height: 18).position(x: 12, y: 9)
            Capsule().fill(color).frame(width: 2.6, height: 8).position(x: 12, y: 19)
        case .trophy:
            Path { p in
                p.move(to: .init(x: 6, y: 3)); p.addLine(to: .init(x: 18, y: 3)); p.addLine(to: .init(x: 17, y: 10))
                p.addQuadCurve(to: .init(x: 7, y: 10), control: .init(x: 12, y: 16)); p.closeSubpath()
            }.fill(color)
            Path { p in
                p.addArc(center: .init(x: 5, y: 7), radius: 3, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                p.addArc(center: .init(x: 19, y: 7), radius: 3, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
            }.stroke(color, style: stroke)
            Rectangle().fill(color).frame(width: 3, height: 5).position(x: 12, y: 16)
            RoundedRectangle(cornerRadius: 1.5).fill(color).frame(width: 12, height: 4).position(x: 12, y: 20)
        case .medal:
            Path { p in p.move(to: .init(x: 7, y: 2)); p.addLine(to: .init(x: 11, y: 10)); p.move(to: .init(x: 17, y: 2)); p.addLine(to: .init(x: 13, y: 10)) }
                .stroke(color, style: stroke)
            Circle().fill(color).frame(width: 13).position(x: 12, y: 15)
            StarShape().fill(color.opacity(0.4)).frame(width: 8, height: 8).position(x: 12, y: 15)
        case .gift:
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 18, height: 12).position(x: 12, y: 15)
            RoundedRectangle(cornerRadius: 1.5).fill(color).frame(width: 20, height: 4).position(x: 12, y: 8)
            Path { p in
                p.move(to: .init(x: 12, y: 7)); p.addQuadCurve(to: .init(x: 7, y: 4), control: .init(x: 6, y: 8))
                p.move(to: .init(x: 12, y: 7)); p.addQuadCurve(to: .init(x: 17, y: 4), control: .init(x: 18, y: 8))
            }.stroke(color, style: stroke)
            Rectangle().fill(color.opacity(0.4)).frame(width: 2.5, height: 12).position(x: 12, y: 15)
        case .gear:
            StarShape(points: 8, inner: 0.72).fill(color).frame(width: 21, height: 21).position(x: 12, y: 12)
            Circle().fill(color.opacity(0.35)).frame(width: 7).position(x: 12, y: 12)
        case .back:
            Path { p in p.move(to: .init(x: 15, y: 4)); p.addLine(to: .init(x: 7, y: 12)); p.addLine(to: .init(x: 15, y: 20)) }
                .stroke(color, style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round))
        case .close:
            Path { p in p.move(to: .init(x: 6, y: 6)); p.addLine(to: .init(x: 18, y: 18)); p.move(to: .init(x: 18, y: 6)); p.addLine(to: .init(x: 6, y: 18)) }
                .stroke(color, style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        case .check:
            Path { p in p.move(to: .init(x: 5, y: 12)); p.addLine(to: .init(x: 10, y: 17)); p.addLine(to: .init(x: 19, y: 7)) }
                .stroke(color, style: StrokeStyle(lineWidth: 3.4, lineCap: .round, lineJoin: .round))
        case .lock:
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 16, height: 12).position(x: 12, y: 16)
            Path { p in p.addArc(center: .init(x: 12, y: 10), radius: 4.5, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                p.move(to: .init(x: 7.5, y: 10)); p.addLine(to: .init(x: 7.5, y: 11)); p.move(to: .init(x: 16.5, y: 10)); p.addLine(to: .init(x: 16.5, y: 11)) }
                .stroke(color, style: stroke)
        case .music:
            Circle().fill(color).frame(width: 7).position(x: 7, y: 18)
            Circle().fill(color).frame(width: 7).position(x: 17, y: 16)
            Path { p in p.move(to: .init(x: 10, y: 18)); p.addLine(to: .init(x: 10, y: 5)); p.addLine(to: .init(x: 20, y: 3)); p.addLine(to: .init(x: 20, y: 16)) }
                .stroke(color, style: stroke)
        case .sound:
            Path { p in p.move(to: .init(x: 3, y: 9)); p.addLine(to: .init(x: 7, y: 9)); p.addLine(to: .init(x: 12, y: 4))
                p.addLine(to: .init(x: 12, y: 20)); p.addLine(to: .init(x: 7, y: 15)); p.addLine(to: .init(x: 3, y: 15)); p.closeSubpath() }.fill(color)
            Path { p in p.addArc(center: .init(x: 13, y: 12), radius: 5, startAngle: .degrees(-45), endAngle: .degrees(45), clockwise: false)
                p.addArc(center: .init(x: 13, y: 12), radius: 9, startAngle: .degrees(-45), endAngle: .degrees(45), clockwise: false) }
                .stroke(color, style: stroke)
        case .vibration:
            RoundedRectangle(cornerRadius: 3).stroke(color, style: stroke).frame(width: 10, height: 17).position(x: 12, y: 12)
            Path { p in p.move(to: .init(x: 3, y: 8)); p.addLine(to: .init(x: 3, y: 16)); p.move(to: .init(x: 21, y: 8)); p.addLine(to: .init(x: 21, y: 16)) }
                .stroke(color, style: stroke)
        case .motion:
            Path { p in p.move(to: .init(x: 3, y: 12)); p.addCurve(to: .init(x: 21, y: 12), control1: .init(x: 9, y: 2), control2: .init(x: 15, y: 22)) }
                .stroke(color, style: stroke)
        case .refresh:
            Path { p in p.addArc(center: .init(x: 12, y: 12), radius: 7.5, startAngle: .degrees(-60), endAngle: .degrees(250), clockwise: false) }
                .stroke(color, style: stroke)
            Path { p in p.move(to: .init(x: 14, y: 2)); p.addLine(to: .init(x: 19, y: 5)); p.addLine(to: .init(x: 14, y: 9)) }
                .stroke(color, style: stroke)
        case .hint:
            Circle().fill(color).frame(width: 15).position(x: 12, y: 9)
            RoundedRectangle(cornerRadius: 1.5).fill(color).frame(width: 8, height: 5).position(x: 12, y: 18)
            Capsule().fill(color).frame(width: 6, height: 2.5).position(x: 12, y: 22)
        case .trash:
            Path { p in p.move(to: .init(x: 6, y: 7)); p.addLine(to: .init(x: 7.5, y: 21)); p.addLine(to: .init(x: 16.5, y: 21)); p.addLine(to: .init(x: 18, y: 7)); p.closeSubpath() }
                .fill(color)
            Path { p in p.move(to: .init(x: 4, y: 5)); p.addLine(to: .init(x: 20, y: 5)); p.move(to: .init(x: 10, y: 3)); p.addLine(to: .init(x: 14, y: 3)) }
                .stroke(color, style: stroke)
        case .plus:
            Path { p in p.move(to: .init(x: 12, y: 4)); p.addLine(to: .init(x: 12, y: 20)); p.move(to: .init(x: 4, y: 12)); p.addLine(to: .init(x: 20, y: 12)) }
                .stroke(color, style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        case .person:
            Circle().fill(color).frame(width: 9).position(x: 12, y: 7)
            Path { p in p.addArc(center: .init(x: 12, y: 21), radius: 8, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false) }.fill(color)
        case .calendar:
            RoundedRectangle(cornerRadius: 3).stroke(color, style: stroke).frame(width: 18, height: 16).position(x: 12, y: 13)
            Rectangle().fill(color).frame(width: 18, height: 4).position(x: 12, y: 7)
            StarShape().fill(color).frame(width: 9, height: 9).position(x: 12, y: 15)
        }
    }
}
