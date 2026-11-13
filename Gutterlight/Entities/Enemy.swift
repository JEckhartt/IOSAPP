import SpriteKit

final class Enemy: SKNode {
    enum Kind: CaseIterable {
        /// Corporate drone. Walks straight at you.
        case suit
        /// Cyber-dog. Fast, zig-zags.
        case hound
        /// Riot cop with a sidearm. Keeps distance and shoots.
        case enforcer
        /// Armored security unit. Slow, soaks bullets.
        case brute

        var maxHP: Int {
            switch self {
            case .suit: return 2
            case .hound: return 1
            case .enforcer: return 3
            case .brute: return 14
            }
        }

        var speed: CGFloat {
            switch self {
            case .suit: return 95
            case .hound: return 185
            case .enforcer: return 110
            case .brute: return 50
            }
        }

        var radius: CGFloat {
            switch self {
            case .suit: return 13
            case .hound: return 10
            case .enforcer: return 14
            case .brute: return 28
            }
        }

        var color: SKColor {
            switch self {
            case .suit: return Palette.cyan
            case .hound: return Palette.acid
            case .enforcer: return Palette.amber
            case .brute: return Palette.blood
            }
        }

        var points: Int {
            switch self {
            case .suit: return 100
            case .hound: return 150
            case .enforcer: return 300
            case .brute: return 1000
            }
        }

        var sides: Int {
            switch self {
            case .suit: return 4
            case .hound: return 3
            case .enforcer: return 6
            case .brute: return 8
            }
        }

        /// How hard bullets shove it around.
        var knockback: CGFloat {
            self == .brute ? 50 : 230
        }
    }

    let kind: Kind
    let moveSpeed: CGFloat
    var hp: Int
    var knock = CGVector.zero
    var fireTimer: TimeInterval
    let phase = CGFloat.random(in: 0...(.pi * 2))
    var dead = false

    private let shell: SKShapeNode

    init(kind: Kind, wave: Int) {
        self.kind = kind
        self.hp = kind.maxHP + (kind == .brute ? wave / 2 : 0)
        self.moveSpeed = kind.speed * (1 + CGFloat(min(wave, 15)) * 0.03)
        self.fireTimer = TimeInterval.random(in: 1.0...2.5)

        let rotation: CGFloat = kind == .suit ? .pi / 4 : 0
        shell = SKShapeNode(path: Geometry.polygon(sides: kind.sides, radius: kind.radius, rotation: rotation))
        shell.strokeColor = kind.color
        shell.fillColor = kind.color.withAlphaComponent(0.12)
        shell.lineWidth = kind == .brute ? 3 : 2
        shell.glowWidth = 4
        shell.zPosition = 0

        super.init()
        addChild(shell)

        if kind == .brute {
            let core = SKShapeNode(path: Geometry.polygon(sides: 8, radius: 14, rotation: .pi / 8))
            core.strokeColor = kind.color.withAlphaComponent(0.7)
            core.lineWidth = 2
            core.zPosition = 1
            addChild(core)
        }

        // A single white "eye" that tracks the player.
        let eye = SKShapeNode(circleOfRadius: kind == .brute ? 4 : 2.5)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: kind.radius * 0.45, y: 0)
        eye.zPosition = 2
        addChild(eye)

        zPosition = 5
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func flash() {
        let original = kind.color.withAlphaComponent(0.12)
        shell.removeAction(forKey: "flash")
        shell.run(.sequence([
            .run { [weak self] in self?.shell.fillColor = .white },
            .wait(forDuration: 0.05),
            .run { [weak self] in self?.shell.fillColor = original },
        ]), withKey: "flash")
    }
}
