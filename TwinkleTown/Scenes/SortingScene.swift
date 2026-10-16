import SpriteKit
import SwiftUI

/// Drag crystals into the matching baskets. Wrong baskets just shake their head kindly.
final class SortingScene: SKScene {
    private(set) var engine: SortingEngine
    private var baskets: [(color: Int, node: SKSpriteNode)] = []
    private var crystalNodes: [Int: SKSpriteNode] = [:]
    private var slotOf: [Int: Int] = [:]
    private var queue: [Crystal]
    private var dragging: (id: Int, node: SKSpriteNode, offset: CGPoint)?
    private let visibleSlots = 5
    private let fast: Bool

    var onSorted: ((Int) -> Void)?
    var onMistake: (() -> Void)?

    init(engine: SortingEngine, reduceMotion: Bool) {
        self.engine = engine
        queue = engine.remaining
        fast = reduceMotion
        super.init(size: CGSize(width: 400, height: 500))
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        for color in engine.basketColors {
            let node = SKSpriteNode(texture: TextureCache.basket(color))
            addChild(node)
            baskets.append((color, node))
        }
        for slot in 0..<visibleSlots { spawn(into: slot) }
        layout()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard !baskets.isEmpty else { return }
        layout()
    }

    private var crystalSize: CGFloat { min(size.width / 6, 84) }

    private func slotPoint(_ slot: Int) -> CGPoint {
        let xs: [CGFloat] = [0.15, 0.38, 0.62, 0.85, 0.5]
        let ys: [CGFloat] = [0.8, 0.88, 0.8, 0.88, 0.66]
        return CGPoint(x: xs[slot] * size.width, y: ys[slot] * size.height)
    }

    private func layout() {
        let n = CGFloat(baskets.count)
        let w = min(size.width / n - 8, 150)
        for (i, b) in baskets.enumerated() {
            b.node.size = CGSize(width: w, height: w * 100 / 120)
            b.node.position = CGPoint(x: size.width * (CGFloat(i) + 0.5) / n, y: w * 0.5 + 10)
        }
        for (id, node) in crystalNodes where dragging?.id != id {
            node.size = CGSize(width: crystalSize, height: crystalSize)
            if let slot = slotOf[id] { node.position = slotPoint(slot) }
        }
    }

    private func spawn(into slot: Int) {
        guard !queue.isEmpty else { return }
        let crystal = queue.removeFirst()
        let node = SKSpriteNode(texture: TextureCache.gem(crystal.color, crystal.shape))
        node.size = CGSize(width: crystalSize, height: crystalSize)
        node.position = slotPoint(slot)
        node.name = "crystal"
        node.zPosition = 2
        node.setScale(0)
        node.run(.scale(to: 1, duration: fast ? 0.05 : 0.25))
        if !fast {
            node.run(.repeatForever(.sequence([.moveBy(x: 0, y: 6, duration: 0.8), .moveBy(x: 0, y: -6, duration: 0.8)])), withKey: "float")
        }
        addChild(node)
        crystalNodes[crystal.id] = node
        slotOf[crystal.id] = slot
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, dragging == nil else { return }
        let pt = t.location(in: self)
        // Generous hit area for small fingers.
        guard let (id, node) = crystalNodes.min(by: { hypot($0.value.position.x - pt.x, $0.value.position.y - pt.y) < hypot($1.value.position.x - pt.x, $1.value.position.y - pt.y) }),
              hypot(node.position.x - pt.x, node.position.y - pt.y) < crystalSize * 0.8 else { return }
        node.removeAction(forKey: "float")
        node.removeAction(forKey: "home")
        node.zPosition = 10
        node.run(.scale(to: 1.2, duration: 0.1))
        dragging = (id, node, CGPoint(x: node.position.x - pt.x, y: node.position.y - pt.y))
        AudioManager.shared.play(.tap)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first, let d = dragging else { return }
        let pt = t.location(in: self)
        d.node.position = CGPoint(x: pt.x + d.offset.x, y: pt.y + d.offset.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let d = dragging else { return }
        dragging = nil
        d.node.zPosition = 2
        d.node.run(.scale(to: 1, duration: 0.1))
        let target = baskets.first { b in
            abs(b.node.position.x - d.node.position.x) < b.node.size.width * 0.6 &&
                d.node.position.y < b.node.position.y + b.node.size.height
        }
        guard let basket = target else {
            sendHome(d.id, d.node)
            return
        }
        if engine.drop(d.id, intoBasketColor: basket.color) {
            let slot = slotOf.removeValue(forKey: d.id)
            crystalNodes[d.id] = nil
            d.node.run(.sequence([.group([.move(to: basket.node.position, duration: 0.15), .scale(to: 0.3, duration: 0.15)]), .removeFromParent()]))
            basket.node.run(.sequence([.scaleX(to: 1.15, y: 0.88, duration: 0.1), .scale(to: 1, duration: 0.15)]))
            AudioManager.shared.play(.collect)
            AudioManager.shared.haptic(.medium)
            if let slot { run(.wait(forDuration: 0.3)) { [weak self] in self?.spawn(into: slot) } }
            onSorted?(engine.sorted)
        } else {
            basket.node.run(.sequence([.rotate(toAngle: 0.12, duration: 0.07), .rotate(toAngle: -0.12, duration: 0.1), .rotate(toAngle: 0, duration: 0.07)]))
            AudioManager.shared.play(.gentleOops)
            onMistake?()
            sendHome(d.id, d.node)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let d = dragging else { return }
        dragging = nil
        sendHome(d.id, d.node)
    }

    private func sendHome(_ id: Int, _ node: SKSpriteNode) {
        guard let slot = slotOf[id] else { return }
        node.zPosition = 2
        node.run(.move(to: slotPoint(slot), duration: 0.25), withKey: "home")
    }

    /// Wiggles a crystal and its basket to show what to do.
    func showHint() {
        guard let (id, node) = crystalNodes.first,
              let color = engine.remaining.first(where: { $0.id == id })?.color,
              let basket = baskets.first(where: { $0.color == color }) else { return }
        node.run(.repeat(.sequence([.scale(to: 1.25, duration: 0.2), .scale(to: 1, duration: 0.2)]), count: 3))
        basket.node.run(.repeat(.sequence([.scale(to: 1.12, duration: 0.2), .scale(to: 1, duration: 0.2)]), count: 3))
    }
}
