import SpriteKit

/// Everything VEX can pull a trigger on.
enum Weapon: CaseIterable {
    /// Default sidearm. Infinite ammo.
    case spitter
    /// Shotgun. Seven pellets, short range, huge knockback.
    case scatter
    /// SMG. Absurd fire rate, wide spray.
    case buzzsaw
    /// Railgun. Slow, pierces everything in a line.
    case rail
    /// Rocket launcher. Splash damage.
    case boombox

    /// Weapons that can drop as pickups.
    static let drops: [Weapon] = [.scatter, .buzzsaw, .rail, .boombox]

    var name: String {
        switch self {
        case .spitter: return "SPITTER"
        case .scatter: return "SCATTER"
        case .buzzsaw: return "BUZZSAW"
        case .rail: return "RAILGUN"
        case .boombox: return "BOOMBOX"
        }
    }

    /// One-letter glyph on the pickup.
    var glyph: String {
        switch self {
        case .spitter: return "P"
        case .scatter: return "S"
        case .buzzsaw: return "Z"
        case .rail: return "R"
        case .boombox: return "X"
        }
    }

    var color: SKColor {
        switch self {
        case .spitter: return Palette.magenta
        case .scatter: return Palette.acid
        case .buzzsaw: return Palette.violet
        case .rail: return Palette.cyan
        case .boombox: return Palette.amber
        }
    }

    var cooldown: TimeInterval {
        switch self {
        case .spitter: return 0.1
        case .scatter: return 0.42
        case .buzzsaw: return 0.045
        case .rail: return 0.55
        case .boombox: return 0.6
        }
    }

    var pellets: Int { self == .scatter ? 7 : 1 }

    /// Scatter: total cone width. Others: random jitter per shot.
    var spread: CGFloat {
        switch self {
        case .spitter: return 0.05
        case .scatter: return 0.5
        case .buzzsaw: return 0.16
        case .rail: return 0
        case .boombox: return 0.02
        }
    }

    var speed: CGFloat {
        switch self {
        case .spitter: return 920
        case .scatter: return 780
        case .buzzsaw: return 1000
        case .rail: return 1800
        case .boombox: return 520
        }
    }

    var damage: Int {
        switch self {
        case .spitter, .scatter, .buzzsaw: return 1
        case .rail: return 4
        case .boombox: return 5
        }
    }

    var pierces: Bool { self == .rail }

    var blastRadius: CGFloat { self == .boombox ? 95 : 0 }

    var life: TimeInterval { self == .scatter ? 0.42 : 1.4 }

    /// Rounds per pickup. 0 = infinite.
    var ammo: Int {
        switch self {
        case .spitter: return 0
        case .scatter: return 30
        case .buzzsaw: return 260
        case .rail: return 22
        case .boombox: return 16
        }
    }

    var knockback: CGFloat {
        switch self {
        case .scatter: return 2.2
        case .rail: return 1.6
        default: return 1
        }
    }

    var recoil: CGFloat {
        switch self {
        case .spitter: return 18
        case .scatter: return 140
        case .buzzsaw: return 10
        case .rail: return 160
        case .boombox: return 90
        }
    }

    var shake: CGFloat {
        switch self {
        case .scatter: return 5
        case .rail: return 7
        case .boombox: return 3
        default: return 0
        }
    }

    var sfx: Sfx {
        switch self {
        case .spitter, .buzzsaw: return .shoot
        case .scatter: return .shotgun
        case .rail: return .rail
        case .boombox: return .rocket
        }
    }

    var sfxVolume: Float { self == .buzzsaw ? 0.55 : 1 }
}
