import SpriteKit

/// Everything VEX can pull a trigger on.
enum Weapon: String, CaseIterable, Codable {
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

    /// Beating boss #1…#4 for the first time unlocks these as default weapons.
    static let bossUnlocks: [Weapon] = [.scatter, .buzzsaw, .rail, .boombox]

    /// Roster index of the boss that unlocks this weapon (nil for the SPITTER).
    var unlockingBoss: Int? { Weapon.bossUnlocks.firstIndex(of: self) }

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
        case .scatter: return 0.34
        case .buzzsaw: return 0.04
        case .rail: return 0.42
        case .boombox: return 0.45
        }
    }

    var pellets: Int { self == .scatter ? 10 : 1 }

    /// Scatter: total cone width. Others: random jitter per shot.
    var spread: CGFloat {
        switch self {
        case .spitter: return 0.05
        case .scatter: return 0.55
        case .buzzsaw: return 0.1
        case .rail: return 0
        case .boombox: return 0.02
        }
    }

    var speed: CGFloat {
        switch self {
        case .spitter: return 920
        case .scatter: return 820
        case .buzzsaw: return 1050
        case .rail: return 2000
        case .boombox: return 680
        }
    }

    var damage: Int {
        switch self {
        case .spitter: return 1
        case .scatter, .buzzsaw: return 2
        case .rail: return 10
        case .boombox: return 10
        }
    }

    var pierces: Bool { self == .rail }

    var blastRadius: CGFloat { self == .boombox ? 135 : 0 }

    var life: TimeInterval { self == .scatter ? 0.5 : 1.4 }

    /// Rounds per pickup. 0 = infinite.
    var ammo: Int {
        switch self {
        case .spitter: return 0
        case .scatter: return 45
        case .buzzsaw: return 400
        case .rail: return 35
        case .boombox: return 25
        }
    }

    var knockback: CGFloat {
        switch self {
        case .scatter: return 2.6
        case .rail: return 2.2
        default: return 1
        }
    }

    /// Kept small: recoil that fights your movement stick just feels like lag.
    var recoil: CGFloat {
        switch self {
        case .spitter: return 6
        case .scatter: return 45
        case .buzzsaw: return 4
        case .rail: return 50
        case .boombox: return 30
        }
    }

    var shake: CGFloat {
        switch self {
        case .scatter: return 6
        case .rail: return 8
        case .boombox: return 4
        case .buzzsaw: return 1.5
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
