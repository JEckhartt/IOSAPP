import SpriteKit

/// Rain-slick street seen from above: lane markings, light pools from neon signs, the odd manhole.
final class CityBackdrop: SKNode {
    private static let signs = ["NO FUTURE", "OPEN 24H", "MOTEL", "LIQUOR", "NO GODS", "VOID", "PAWN", "BAR", "CASH 4 CHROME"]

    func build(for size: CGSize) {
        removeAllChildren()
        removeAllActions()
        zPosition = -10

        let half = CGSize(width: size.width / 2, height: size.height / 2)

        let ground = SKSpriteNode(color: Palette.asphalt, size: size)
        ground.zPosition = 0
        addChild(ground)

        // Faint city grid.
        let grid = CGMutablePath()
        let step: CGFloat = 80
        var x = -half.width - (-half.width).truncatingRemainder(dividingBy: step)
        while x < half.width {
            grid.move(to: CGPoint(x: x, y: -half.height))
            grid.addLine(to: CGPoint(x: x, y: half.height))
            x += step
        }
        var y = -half.height - (-half.height).truncatingRemainder(dividingBy: step)
        while y < half.height {
            grid.move(to: CGPoint(x: -half.width, y: y))
            grid.addLine(to: CGPoint(x: half.width, y: y))
            y += step
        }
        let gridNode = SKShapeNode(path: grid)
        gridNode.strokeColor = SKColor.white.withAlphaComponent(0.035)
        gridNode.lineWidth = 1
        gridNode.zPosition = 1
        addChild(gridNode)

        // Dashed center lane.
        let lane = CGMutablePath()
        var lx = -half.width
        while lx < half.width {
            lane.move(to: CGPoint(x: lx, y: 0))
            lane.addLine(to: CGPoint(x: lx + 28, y: 0))
            lx += 60
        }
        let laneNode = SKShapeNode(path: lane)
        laneNode.strokeColor = Palette.amber.withAlphaComponent(0.12)
        laneNode.lineWidth = 3
        laneNode.zPosition = 1
        addChild(laneNode)

        // Neon light pools + signs.
        let poolCount = 6
        for i in 0..<poolCount {
            let color = Palette.neons[i % Palette.neons.count]
            let pos = CGPoint(x: CGFloat.random(in: -half.width...half.width),
                              y: CGFloat.random(in: -half.height...half.height))
            let d = CGFloat.random(in: 260...460)
            let pool = SKSpriteNode(texture: FX.spark, size: CGSize(width: d, height: d * 0.8))
            pool.color = color
            pool.colorBlendFactor = 1
            pool.blendMode = .add
            pool.alpha = 0.16
            pool.position = pos
            pool.zPosition = 2
            addChild(pool)

            if i < 4 {
                let sign = SKLabelNode(fontNamed: Fonts.display)
                sign.text = Self.signs.randomElement()
                sign.fontSize = CGFloat.random(in: 20...32)
                sign.fontColor = color
                sign.alpha = 0.32
                sign.verticalAlignmentMode = .center
                sign.position = pos
                sign.zRotation = Bool.random() ? 0 : .pi / 2
                sign.zPosition = 3
                addChild(sign)
                let flicker = FX.flicker()
                sign.run(flicker)
                pool.run(flicker)
            }
        }

        // Manhole covers.
        for _ in 0..<3 {
            let hole = SKShapeNode(circleOfRadius: 16)
            hole.strokeColor = SKColor.white.withAlphaComponent(0.08)
            hole.fillColor = SKColor.black.withAlphaComponent(0.25)
            hole.lineWidth = 2
            hole.position = CGPoint(x: CGFloat.random(in: -half.width...half.width),
                                    y: CGFloat.random(in: -half.height...half.height))
            hole.zPosition = 1
            addChild(hole)
        }

        // Ripples from raindrops hitting puddles.
        let ripple = SKAction.run { [weak self] in
            guard let self else { return }
            let ring = SKShapeNode(circleOfRadius: 10)
            ring.strokeColor = Palette.rain.withAlphaComponent(0.22)
            ring.lineWidth = 1
            ring.fillColor = .clear
            ring.position = CGPoint(x: CGFloat.random(in: -half.width...half.width),
                                    y: CGFloat.random(in: -half.height...half.height))
            ring.setScale(0.2)
            ring.zPosition = 4
            self.addChild(ring)
            ring.run(.sequence([
                .group([.scale(to: 1.4, duration: 0.6), .fadeOut(withDuration: 0.6)]),
                .removeFromParent(),
            ]))
        }
        run(.repeatForever(.sequence([ripple, .wait(forDuration: 0.12, withRange: 0.15)])))
    }
}
