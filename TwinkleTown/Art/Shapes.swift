import SwiftUI

struct StarShape: Shape {
    var points = 5
    var inner: CGFloat = 0.48

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        for i in 0..<(points * 2) {
            let a = Double(i) * .pi / Double(points) - .pi / 2
            let rr = i.isMultiple(of: 2) ? r : r * inner
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * rr, y: c.y + CGFloat(sin(a)) * rr)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

/// Classic brilliant-cut gem silhouette.
struct GemShape2D: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.25, y: r.minY + r.height * 0.1))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.75, y: r.minY + r.height * 0.1))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.38))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - r.height * 0.04))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.38))
        p.closeSubpath()
        return p
    }
}

struct HeartShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.maxY - r.height * 0.05))
        p.addCurve(to: CGPoint(x: r.minX + r.width * 0.02, y: r.minY + r.height * 0.32),
                   control1: CGPoint(x: r.midX - r.width * 0.15, y: r.maxY - r.height * 0.2),
                   control2: CGPoint(x: r.minX, y: r.midY + r.height * 0.05))
        p.addArc(center: CGPoint(x: r.minX + r.width * 0.27, y: r.minY + r.height * 0.3), radius: r.width * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(-20), clockwise: false)
        p.addArc(center: CGPoint(x: r.maxX - r.width * 0.27, y: r.minY + r.height * 0.3), radius: r.width * 0.25,
                 startAngle: .degrees(200), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY - r.height * 0.05),
                   control1: CGPoint(x: r.maxX, y: r.midY + r.height * 0.05),
                   control2: CGPoint(x: r.midX + r.width * 0.15, y: r.maxY - r.height * 0.2))
        return p
    }
}

struct CloudShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.addEllipse(in: CGRect(x: r.minX, y: r.minY + h * 0.4, width: w * 0.4, height: h * 0.6))
        p.addEllipse(in: CGRect(x: r.minX + w * 0.2, y: r.minY + h * 0.1, width: w * 0.42, height: h * 0.8))
        p.addEllipse(in: CGRect(x: r.minX + w * 0.45, y: r.minY, width: w * 0.35, height: h * 0.75))
        p.addEllipse(in: CGRect(x: r.minX + w * 0.62, y: r.minY + h * 0.35, width: w * 0.38, height: h * 0.65))
        p.addRoundedRect(in: CGRect(x: r.minX + w * 0.15, y: r.minY + h * 0.6, width: w * 0.7, height: h * 0.4),
                         cornerSize: CGSize(width: h * 0.2, height: h * 0.2))
        return p
    }
}

/// Little four-point twinkle.
struct SparkleShape: Shape {
    func path(in r: CGRect) -> Path {
        StarShape(points: 4, inner: 0.28).path(in: r)
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

extension Color {
    func lighter(_ amount: Double = 0.35) -> Color { mix(with: .white, by: amount) }
    func darker(_ amount: Double = 0.3) -> Color { mix(with: Color(hex: 0x10204A), by: amount) }
}
