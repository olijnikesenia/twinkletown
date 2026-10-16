import SpriteKit
import SwiftUI

/// Renders the shared SwiftUI art into SpriteKit textures so both worlds look identical.
enum TextureCache {
    private static var cache: [String: SKTexture] = [:]

    static func texture<V: View>(_ key: String, size: CGSize, _ view: V) -> SKTexture {
        if let t = cache[key] { return t }
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 3
        let texture = SKTexture(image: renderer.uiImage ?? UIImage())
        cache[key] = texture
        return texture
    }

    static func gem(_ color: Int, _ shape: GemShape = .gem) -> SKTexture {
        texture("gem\(color)-\(shape.rawValue)", size: CGSize(width: 64, height: 64),
                GemView(color: Palette.gems[color], shape: shape, size: 64))
    }

    static var sparkle: SKTexture {
        texture("sparkle", size: CGSize(width: 24, height: 24), SparkleShape().fill(.white))
    }

    static func basket(_ color: Int) -> SKTexture {
        texture("basket\(color)", size: CGSize(width: 120, height: 100), BasketArt(color: Palette.gems[color]))
    }
}

/// Swipe (or tap two neighbours) to swap gems and make lines of three.
final class MatchScene: SKScene {
    private(set) var engine: MatchEngine
    private var nodes: [[SKSpriteNode?]]
    private var tiles: [SKShapeNode] = []
    private var cell: CGFloat = 40
    private var origin = CGPoint.zero
    private var touchStart: GridPos?
    private var selected: GridPos?
    private var busy = false
    private let fast: Bool

    var inputEnabled = true
    /// Called once per successful move with gems removed per color during the whole cascade.
    var onMoveResolved: (([Int: Int]) -> Void)?
    var onInvalidSwap: (() -> Void)?
    var onShuffle: (() -> Void)?

    init(engine: MatchEngine, reduceMotion: Bool) {
        self.engine = engine
        fast = reduceMotion
        nodes = Array(repeating: Array(repeating: nil, count: engine.cols), count: engine.rows)
        super.init(size: CGSize(width: 400, height: 400))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        layout()
    }

    // MARK: Layout

    private func layout() {
        cell = min(size.width / CGFloat(engine.cols), size.height / CGFloat(engine.rows))
        origin = CGPoint(x: (size.width - cell * CGFloat(engine.cols)) / 2, y: (size.height - cell * CGFloat(engine.rows)) / 2)
        tiles.forEach { $0.removeFromParent() }
        tiles = []
        for r in 0..<engine.rows {
            for c in 0..<engine.cols {
                let tile = SKShapeNode(rectOf: CGSize(width: cell - 4, height: cell - 4), cornerRadius: cell * 0.22)
                tile.fillColor = UIColor.white.withAlphaComponent((r + c).isMultiple(of: 2) ? 0.55 : 0.35)
                tile.strokeColor = .clear
                tile.position = point(GridPos(row: r, col: c))
                tile.zPosition = -1
                addChild(tile)
                tiles.append(tile)
                if let node = nodes[r][c] {
                    node.position = point(GridPos(row: r, col: c))
                    node.size = CGSize(width: cell * 0.86, height: cell * 0.86)
                }
            }
        }
    }

    private func point(_ p: GridPos) -> CGPoint {
        CGPoint(x: origin.x + (CGFloat(p.col) + 0.5) * cell,
                y: origin.y + (CGFloat(engine.rows - p.row) - 0.5) * cell)
    }

    private func gridPos(at pt: CGPoint) -> GridPos? {
        let c = Int(floor((pt.x - origin.x) / cell))
        let r = engine.rows - 1 - Int(floor((pt.y - origin.y) / cell))
        let p = GridPos(row: r, col: c)
        return engine.contains(p) ? p : nil
    }

    private func makeNode(_ color: Int) -> SKSpriteNode {
        let node = SKSpriteNode(texture: TextureCache.gem(color))
        node.size = CGSize(width: cell * 0.86, height: cell * 0.86)
        addChild(node)
        return node
    }

    private func rebuild() {
        nodes.joined().forEach { $0?.removeFromParent() }
        layout()
        for r in 0..<engine.rows {
            for c in 0..<engine.cols {
                let node = makeNode(engine.grid[r][c])
                node.position = point(GridPos(row: r, col: c))
                node.setScale(0)
                node.run(.sequence([.wait(forDuration: fast ? 0 : Double(r + c) * 0.02), .scale(to: 1, duration: 0.2)]))
                nodes[r][c] = node
            }
        }
    }

    // MARK: Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, inputEnabled, !busy else { return }
        touchStart = gridPos(at: t.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, let start = touchStart, inputEnabled, !busy else { return }
        let d = CGPoint(x: t.location(in: self).x - point(start).x, y: t.location(in: self).y - point(start).y)
        guard max(abs(d.x), abs(d.y)) > cell * 0.45 else { return }
        let target = abs(d.x) > abs(d.y)
            ? GridPos(row: start.row, col: start.col + (d.x > 0 ? 1 : -1))
            : GridPos(row: start.row + (d.y > 0 ? -1 : 1), col: start.col)
        touchStart = nil
        clearSelection()
        if engine.contains(target) { attemptSwap(start, target) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let start = touchStart, inputEnabled, !busy else { return }
        touchStart = nil
        if let sel = selected, MatchEngine.adjacent(sel, start) {
            clearSelection()
            attemptSwap(sel, start)
        } else {
            clearSelection()
            selected = start
            nodes[start.row][start.col]?.run(.repeatForever(.sequence([.scale(to: 1.12, duration: 0.25), .scale(to: 0.95, duration: 0.25)])), withKey: "select")
            AudioManager.shared.play(.tap)
        }
    }

    private func clearSelection() {
        if let sel = selected, let node = nodes[sel.row][sel.col] {
            node.removeAction(forKey: "select")
            node.setScale(1)
        }
        selected = nil
    }

    // MARK: Moves

    private func attemptSwap(_ a: GridPos, _ b: GridPos) {
        guard let na = nodes[a.row][a.col], let nb = nodes[b.row][b.col] else { return }
        busy = true
        let d = fast ? 0.08 : 0.16
        if let steps = engine.trySwap(a, b) {
            nodes[a.row][a.col] = nb
            nodes[b.row][b.col] = na
            na.run(.move(to: point(b), duration: d))
            nb.run(.move(to: point(a), duration: d)) { [weak self] in
                self?.play(steps, index: 0, counts: [:])
            }
        } else {
            onInvalidSwap?()
            na.run(.sequence([.move(to: point(b), duration: d), .move(to: point(a), duration: d)]))
            nb.run(.sequence([.move(to: point(a), duration: d), .move(to: point(b), duration: d)])) { [weak self] in
                self?.busy = false
            }
        }
    }

    private func play(_ steps: [CascadeStep], index: Int, counts: [Int: Int]) {
        guard index < steps.count else {
            finishMove(counts)
            return
        }
        let step = steps[index]
        var counts = counts
        AudioManager.shared.play(index == 0 ? .match : .collect)
        AudioManager.shared.haptic(.light)
        for (p, color) in step.removed {
            counts[color, default: 0] += 1
            if let node = nodes[p.row][p.col] {
                burst(at: node.position, color: color)
                node.run(.sequence([.group([.scale(to: 1.3, duration: 0.08), .fadeAlpha(to: 0.6, duration: 0.08)]),
                                    .scale(to: 0, duration: 0.14), .removeFromParent()]))
            }
            nodes[p.row][p.col] = nil
        }
        let fallDuration = fast ? 0.12 : 0.24
        let removeDelay = fast ? 0.1 : 0.22
        // Move existing gems first (bottom-up order keeps the node grid consistent), then spawn.
        var moved: [(SKSpriteNode, GridPos)] = []
        for fall in step.falls where fall.fromRow >= 0 {
            if let node = nodes[fall.fromRow][fall.col] {
                nodes[fall.fromRow][fall.col] = nil
                moved.append((node, GridPos(row: fall.toRow, col: fall.col)))
            }
        }
        for (node, to) in moved { nodes[to.row][to.col] = node }
        for fall in step.falls where fall.fromRow < 0 {
            let node = makeNode(fall.color)
            node.position = point(GridPos(row: fall.fromRow, col: fall.col))
            node.alpha = 0
            nodes[fall.toRow][fall.col] = node
            moved.append((node, GridPos(row: fall.toRow, col: fall.col)))
        }
        for (node, to) in moved {
            node.run(.sequence([.wait(forDuration: removeDelay),
                                .group([.fadeIn(withDuration: 0.1), .move(to: point(to), duration: fallDuration)])]))
        }
        run(.wait(forDuration: removeDelay + fallDuration + 0.05)) { [weak self] in
            self?.play(steps, index: index + 1, counts: counts)
        }
    }

    private func finishMove(_ counts: [Int: Int]) {
        if engine.shuffleIfStuck() {
            onShuffle?()
            rebuild()
        }
        busy = false
        onMoveResolved?(counts)
    }

    private func burst(at pos: CGPoint, color: Int) {
        guard !fast else { return }
        for i in 0..<5 {
            let s = SKSpriteNode(texture: TextureCache.sparkle)
            s.size = CGSize(width: cell * 0.3, height: cell * 0.3)
            s.color = UIColor(Palette.gems[color])
            s.colorBlendFactor = 0.5
            s.position = pos
            s.zPosition = 5
            addChild(s)
            let a = Double(i) * .pi * 2 / 5
            let v = CGVector(dx: cos(a) * Double(cell) * 0.7, dy: sin(a) * Double(cell) * 0.7)
            s.run(.sequence([.group([.move(by: v, duration: 0.35), .fadeOut(withDuration: 0.35), .rotate(byAngle: 2, duration: 0.35)]), .removeFromParent()]))
        }
    }

    func showHint() {
        guard !busy, let (a, b) = engine.findHint() else { return }
        for p in [a, b] {
            nodes[p.row][p.col]?.run(.repeat(.sequence([.scale(to: 1.25, duration: 0.2), .scale(to: 1, duration: 0.2)]), count: 3))
        }
    }
}

/// Cute basket with a face and its color gem.
struct BasketArt: View {
    let color: Color

    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 6, y: 30)); p.addLine(to: CGPoint(x: 114, y: 30))
                p.addLine(to: CGPoint(x: 100, y: 96)); p.addLine(to: CGPoint(x: 20, y: 96)); p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color(hex: 0xF7C98B), Color(hex: 0xD99A55)], startPoint: .top, endPoint: .bottom))
            Path { p in
                for y in stride(from: 44.0, through: 88, by: 14) { p.move(to: CGPoint(x: 12, y: y)); p.addLine(to: CGPoint(x: 108, y: y)) }
            }
            .stroke(Color(hex: 0xB97A3A).opacity(0.5), lineWidth: 2)
            Capsule().fill(color).frame(width: 116, height: 18).position(x: 60, y: 30)
            Capsule().stroke(.white, lineWidth: 2).frame(width: 116, height: 18).position(x: 60, y: 30)
            HStack(spacing: 18) {
                Capsule().fill(Palette.text).frame(width: 7, height: 10)
                Capsule().fill(Palette.text).frame(width: 7, height: 10)
            }
            .position(x: 60, y: 56)
            Path { p in p.addArc(center: CGPoint(x: 60, y: 62), radius: 8, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false) }
                .stroke(Palette.text, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            GemView(color: color, size: 26).position(x: 60, y: 84)
        }
        .frame(width: 120, height: 100)
    }
}
