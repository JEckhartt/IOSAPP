import SpriteKit

/// VEX — one punk, one gun, zero permits.
final class Player: SKNode {
    static let radius: CGFloat = 14
    static let baseMaxHP = 5
    static let moveSpeed: CGFloat = 270

    /// Base 5, plus one per boss ever beaten (when EXTRA LIVES is on).
    var maxHP = Player.baseMaxHP
    var hp = Player.baseMaxHP
    var velocity = CGVector.zero
    var invulnerable: TimeInterval = 0

    private let hull: SKShapeNode
    private let crest: SKShapeNode

    override init() {
        let body = CGMutablePath()
        body.move(to: CGPoint(x: 18, y: 0))
        body.addLine(to: CGPoint(x: -12, y: 12))
        body.addLine(to: CGPoint(x: -5, y: 0))
        body.addLine(to: CGPoint(x: -12, y: -12))
        body.closeSubpath()
        hull = SKShapeNode(path: body)
        hull.strokeColor = Palette.magenta
        hull.fillColor = Palette.magenta.withAlphaComponent(0.18)
        hull.lineWidth = 2.5
        hull.glowWidth = 6
        hull.lineJoin = .miter

        // The mohawk: a jagged acid-green spine down the back.
        let spikes = CGMutablePath()
        spikes.move(to: CGPoint(x: 8, y: 0))
        spikes.addLine(to: CGPoint(x: 4, y: 5))
        spikes.addLine(to: CGPoint(x: 1, y: 0))
        spikes.addLine(to: CGPoint(x: -3, y: 5))
        spikes.addLine(to: CGPoint(x: -6, y: 0))
        crest = SKShapeNode(path: spikes)
        crest.strokeColor = Palette.acid
        crest.lineWidth = 2
        crest.glowWidth = 2

        super.init()
        hull.zPosition = 0
        crest.zPosition = 1
        addChild(hull)
        addChild(crest)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func reset(maxHP: Int) {
        self.maxHP = maxHP
        hp = maxHP
        velocity = .zero
        invulnerable = 1.0
        position = .zero
        zRotation = 0
        alpha = 1
        setScale(1)
    }

    func tick(_ dt: TimeInterval) {
        if invulnerable > 0 {
            invulnerable -= dt
            alpha = Int(invulnerable * 20) % 2 == 0 ? 0.35 : 1
        } else {
            alpha = 1
        }
    }
}
