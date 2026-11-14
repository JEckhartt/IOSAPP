import SpriteKit

final class Bullet: SKNode {
    let friendly: Bool
    let radius: CGFloat
    let damage: Int
    let pierces: Bool
    let blastRadius: CGFloat
    let knockback: CGFloat
    var velocity: CGVector
    var life: TimeInterval
    var dead = false
    /// Enemies a piercing round has already gone through.
    var hits = Set<ObjectIdentifier>()
    /// Smoke trail for rockets; its targetNode must be set once in the scene.
    private(set) var trail: SKEmitterNode?

    /// Player round.
    init(weapon: Weapon, velocity: CGVector) {
        friendly = true
        damage = weapon.damage
        pierces = weapon.pierces
        blastRadius = weapon.blastRadius
        knockback = weapon.knockback
        life = weapon.life
        self.velocity = velocity

        let shape: SKShapeNode
        switch weapon {
        case .spitter:
            radius = 5
            shape = SKShapeNode(rectOf: CGSize(width: 16, height: 3.5), cornerRadius: 1.75)
            shape.strokeColor = Palette.magenta
            shape.glowWidth = 3
        case .scatter:
            radius = 6
            shape = SKShapeNode(rectOf: CGSize(width: 10, height: 3.5), cornerRadius: 1.75)
            shape.strokeColor = Palette.acid
            shape.glowWidth = 2
        case .buzzsaw:
            radius = 4
            shape = SKShapeNode(rectOf: CGSize(width: 12, height: 2.5), cornerRadius: 1.25)
            shape.strokeColor = Palette.violet
            shape.glowWidth = 2
        case .rail:
            radius = 11
            shape = SKShapeNode(rectOf: CGSize(width: 46, height: 5), cornerRadius: 2.5)
            shape.strokeColor = Palette.cyan
            shape.glowWidth = 7
        case .boombox:
            radius = 8
            shape = SKShapeNode(rectOf: CGSize(width: 16, height: 8), cornerRadius: 3)
            shape.strokeColor = Palette.amber
            shape.glowWidth = 4
            trail = FX.rocketTrail()
        }
        shape.fillColor = .white
        shape.lineWidth = 1.5

        super.init()
        addChild(shape)
        if let trail {
            trail.position = CGPoint(x: -8, y: 0)
            trail.zPosition = -1
            addChild(trail)
        }
        zRotation = velocity.angle
        zPosition = 4
    }

    /// Enemy round. Sprite-based (no SKShapeNode glow) so boss bullet-hell stays smooth.
    init(enemyVelocity velocity: CGVector, color: SKColor = Palette.amber, big: Bool = false) {
        friendly = false
        damage = 1
        pierces = false
        blastRadius = 0
        knockback = 0
        radius = big ? 8 : 6
        life = 6
        self.velocity = velocity

        super.init()
        let glow = SKSpriteNode(texture: FX.spark, size: CGSize(width: radius * 4.4, height: radius * 4.4))
        glow.color = color
        glow.colorBlendFactor = 1
        glow.blendMode = .add
        glow.zPosition = 0
        addChild(glow)

        let core = SKSpriteNode(texture: FX.spark, size: CGSize(width: radius * 2, height: radius * 2))
        core.color = .white
        core.colorBlendFactor = 1
        core.zPosition = 1
        addChild(core)
        zPosition = 4
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }
}

/// Something lying in the gutter worth picking up.
final class Pickup: SKNode {
    enum Kind {
        /// Stolen stim pack. Heals one HP.
        case health
        case weapon(Weapon)
    }

    static let radius: CGFloat = 14
    let kind: Kind
    var life: TimeInterval
    var dead = false

    init(kind: Kind) {
        self.kind = kind
        switch kind {
        case .health: life = 9
        case .weapon: life = 12
        }
        super.init()

        switch kind {
        case .health:
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

        case .weapon(let weapon):
            let crate = SKShapeNode(path: Geometry.polygon(sides: 4, radius: 17))
            crate.strokeColor = weapon.color
            crate.fillColor = weapon.color.withAlphaComponent(0.15)
            crate.lineWidth = 2.5
            crate.glowWidth = 5
            crate.zPosition = 0
            crate.run(.repeatForever(.rotate(byAngle: .pi, duration: 2)))
            addChild(crate)

            let glyph = SKLabelNode(fontNamed: Fonts.display)
            glyph.text = weapon.glyph
            glyph.fontSize = 18
            glyph.fontColor = .white
            glyph.verticalAlignmentMode = .center
            glyph.horizontalAlignmentMode = .center
            glyph.zPosition = 1
            addChild(glyph)
        }

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
