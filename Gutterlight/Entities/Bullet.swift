import SpriteKit

final class Bullet: SKNode {
    let friendly: Bool
    let radius: CGFloat
    var velocity: CGVector
    var life: TimeInterval
    var dead = false

    init(friendly: Bool, velocity: CGVector) {
        self.friendly = friendly
        self.velocity = velocity

        let shape: SKShapeNode
        if friendly {
            radius = 5
            life = 1.2
            shape = SKShapeNode(rectOf: CGSize(width: 16, height: 3.5), cornerRadius: 1.75)
            shape.fillColor = .white
            shape.strokeColor = Palette.magenta
            shape.lineWidth = 1.5
            shape.glowWidth = 3
        } else {
            radius = 6
            life = 4
            shape = SKShapeNode(circleOfRadius: 5)
            shape.fillColor = Palette.amber.withAlphaComponent(0.8)
            shape.strokeColor = Palette.amber
            shape.lineWidth = 1.5
            shape.glowWidth = 5
        }

        super.init()
        addChild(shape)
        zRotation = velocity.angle
        zPosition = 4
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// Stolen stim pack. Heals one HP.
final class Pickup: SKNode {
    static let radius: CGFloat = 12
    var life: TimeInterval = 9
    var dead = false

    override init() {
        super.init()
        let cross = CGMutablePath()
        cross.move(to: CGPoint(x: -7, y: 0)); cross.addLine(to: CGPoint(x: 7, y: 0))
        cross.move(to: CGPoint(x: 0, y: -7)); cross.addLine(to: CGPoint(x: 0, y: 7))
        let plus = SKShapeNode(path: cross)
        plus.strokeColor = Palette.acid
        plus.lineWidth = 3
        plus.glowWidth = 4
        plus.zPosition = 1

        let ring = SKShapeNode(circleOfRadius: 12)
        ring.strokeColor = Palette.acid.withAlphaComponent(0.6)
        ring.lineWidth = 1.5
        ring.zPosition = 0

        addChild(ring)
        addChild(plus)
        zPosition = 3
        run(.repeatForever(.sequence([.scale(to: 1.15, duration: 0.4), .scale(to: 1.0, duration: 0.4)])))
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func tick(_ dt: TimeInterval) {
        life -= dt
        if life < 2.5 {
            alpha = Int(life * 10) % 2 == 0 ? 0.25 : 1
        }
    }
}
