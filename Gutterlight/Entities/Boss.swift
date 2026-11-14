import SpriteKit

// MARK: - Spec

enum BossAttack {
    /// Ring of bullets in every direction.
    case radial(count: Int, speed: CGFloat)
    /// Aimed spread, optionally repeated in quick volleys.
    case fan(count: Int, spread: CGFloat, speed: CGFloat, volleys: Int)
    /// Rotating multi-arm stream.
    case spiral(arms: Int, duration: TimeInterval, rate: TimeInterval, turn: CGFloat, speed: CGFloat)
    /// Machine-gun stream that tracks the player.
    case stream(duration: TimeInterval, rate: TimeInterval, speed: CGFloat)
    /// Telegraphed dash at the player.
    case charge(speed: CGFloat)
    /// Fade out, reappear elsewhere with a burst.
    case blink
    /// Call in grunts.
    case summon([Enemy.Kind])
}

enum BossMovement {
    case chase(CGFloat)
    case hover(distance: CGFloat, speed: CGFloat)
    case wander(CGFloat)
    /// Sways along the top of the arena.
    case anchor
}

enum BossOrnament { case spikes, orbiters, halo, eye }

struct BossSpec {
    let name: String
    let quip: String
    let hp: Int
    let radius: CGFloat
    let sides: Int
    let color: SKColor
    let accent: SKColor
    let ornament: BossOrnament
    let movement: BossMovement
    let cooldown: TimeInterval
    /// Attack rotation for each of the three phases (>66%, >33%, rest).
    let phases: [[BossAttack]]

    static let interval = 5

    /// Boss for a given wave (5, 10 … 50). Past that the roster loops, tougher each lap.
    static func forWave(_ wave: Int) -> (spec: BossSpec, lap: Int)? {
        guard wave > 0, wave % interval == 0 else { return nil }
        let index = wave / interval - 1
        return (roster[index % roster.count], index / roster.count)
    }

    static let roster: [BossSpec] = [
        BossSpec(name: "THE MIDDLE MANAGER", quip: "LET'S CIRCLE BACK ON THAT.",
                 hp: 160, radius: 40, sides: 4, color: Palette.cyan, accent: .white,
                 ornament: .halo, movement: .chase(70), cooldown: 2.0,
                 phases: [
                    [.radial(count: 14, speed: 210), .fan(count: 5, spread: 0.6, speed: 280, volleys: 1)],
                    [.radial(count: 18, speed: 220), .fan(count: 5, spread: 0.6, speed: 290, volleys: 2),
                     .summon([.suit, .suit, .suit])],
                    [.radial(count: 22, speed: 240), .fan(count: 7, spread: 0.8, speed: 300, volleys: 2),
                     .summon([.suit, .suit, .hound, .hound])],
                 ]),
        BossSpec(name: "KENNEL MASTER", quip: "RELEASE THE HOUNDS.",
                 hp: 220, radius: 40, sides: 3, color: Palette.acid, accent: Palette.amber,
                 ornament: .spikes, movement: .hover(distance: 260, speed: 140), cooldown: 1.8,
                 phases: [
                    [.charge(speed: 620), .summon([.hound, .hound, .hound])],
                    [.charge(speed: 700), .fan(count: 7, spread: 0.9, speed: 300, volleys: 1),
                     .summon([.hound, .hound, .hound, .hound])],
                    [.charge(speed: 780), .charge(speed: 780), .fan(count: 9, spread: 1.0, speed: 320, volleys: 2),
                     .summon([.hound, .hound, .hound, .hound, .hound])],
                 ]),
        BossSpec(name: "RIOT CAPTAIN", quip: "THIS IS AN UNLAWFUL ASSEMBLY.",
                 hp: 300, radius: 44, sides: 6, color: Palette.amber, accent: Palette.cyan,
                 ornament: .orbiters, movement: .hover(distance: 300, speed: 100), cooldown: 1.7,
                 phases: [
                    [.fan(count: 3, spread: 0.25, speed: 340, volleys: 3), .summon([.enforcer, .enforcer])],
                    [.fan(count: 3, spread: 0.25, speed: 360, volleys: 4), .radial(count: 16, speed: 230),
                     .summon([.enforcer, .enforcer, .suit, .suit])],
                    [.stream(duration: 2.0, rate: 0.08, speed: 380), .fan(count: 5, spread: 0.4, speed: 360, volleys: 4),
                     .summon([.enforcer, .enforcer, .enforcer])],
                 ]),
        BossSpec(name: "THE BULLDOZER", quip: "URBAN RENEWAL STARTS NOW.",
                 hp: 420, radius: 58, sides: 8, color: Palette.blood, accent: Palette.amber,
                 ornament: .spikes, movement: .chase(55), cooldown: 2.0,
                 phases: [
                    [.charge(speed: 560), .radial(count: 20, speed: 200)],
                    [.charge(speed: 640), .radial(count: 26, speed: 210), .radial(count: 26, speed: 240)],
                    [.charge(speed: 720), .radial(count: 32, speed: 230), .charge(speed: 720), .summon([.brute])],
                 ]),
        BossSpec(name: "SPIN DOCTOR", quip: "THAT'S NOT WHAT HAPPENED.",
                 hp: 480, radius: 44, sides: 5, color: Palette.violet, accent: Palette.magenta,
                 ornament: .halo, movement: .anchor, cooldown: 1.6,
                 phases: [
                    [.spiral(arms: 3, duration: 3.0, rate: 0.09, turn: 0.23, speed: 210)],
                    [.spiral(arms: 4, duration: 3.2, rate: 0.08, turn: 0.21, speed: 220),
                     .fan(count: 5, spread: 0.6, speed: 300, volleys: 1)],
                    [.spiral(arms: 5, duration: 3.5, rate: 0.07, turn: -0.19, speed: 230),
                     .spiral(arms: 5, duration: 3.5, rate: 0.07, turn: 0.19, speed: 230),
                     .radial(count: 24, speed: 240)],
                 ]),
        BossSpec(name: "THE AUDITOR", quip: "EVERY BULLET IS ACCOUNTED FOR.",
                 hp: 560, radius: 40, sides: 4, color: .white, accent: Palette.cyan,
                 ornament: .orbiters, movement: .wander(120), cooldown: 1.5,
                 phases: [
                    [.blink, .radial(count: 16, speed: 230), .fan(count: 5, spread: 0.5, speed: 320, volleys: 1)],
                    [.blink, .radial(count: 20, speed: 240), .blink, .stream(duration: 1.5, rate: 0.1, speed: 340)],
                    [.blink, .radial(count: 24, speed: 260), .blink, .fan(count: 7, spread: 0.7, speed: 340, volleys: 2),
                     .summon([.hound, .hound, .enforcer])],
                 ]),
        BossSpec(name: "BIG BROTHER", quip: "WE SEE YOU, VEX.",
                 hp: 640, radius: 54, sides: 24, color: Palette.magenta, accent: Palette.cyan,
                 ornament: .eye, movement: .anchor, cooldown: 1.5,
                 phases: [
                    [.stream(duration: 2.5, rate: 0.07, speed: 360), .radial(count: 18, speed: 220)],
                    [.stream(duration: 3.0, rate: 0.06, speed: 380),
                     .spiral(arms: 2, duration: 2.5, rate: 0.06, turn: 0.3, speed: 240), .summon([.enforcer, .enforcer])],
                    [.stream(duration: 3.5, rate: 0.05, speed: 400),
                     .spiral(arms: 3, duration: 3.0, rate: 0.05, turn: 0.28, speed: 260), .radial(count: 28, speed: 250)],
                 ]),
        BossSpec(name: "THE LOBBYIST", quip: "EVERYONE HAS A PRICE.",
                 hp: 720, radius: 48, sides: 7, color: Palette.amber, accent: Palette.acid,
                 ornament: .orbiters, movement: .hover(distance: 320, speed: 90), cooldown: 1.6,
                 phases: [
                    [.summon([.suit, .suit, .enforcer, .enforcer]), .fan(count: 9, spread: 1.2, speed: 260, volleys: 2)],
                    [.summon([.suit, .suit, .hound, .hound, .enforcer]), .fan(count: 11, spread: 1.4, speed: 270, volleys: 3),
                     .radial(count: 20, speed: 240)],
                    [.summon([.brute, .enforcer, .enforcer]), .fan(count: 13, spread: 1.6, speed: 280, volleys: 3),
                     .spiral(arms: 4, duration: 2.5, rate: 0.07, turn: 0.25, speed: 240)],
                 ]),
        BossSpec(name: "THE BOARD", quip: "THE MOTION CARRIES. YOU DIE.",
                 hp: 860, radius: 52, sides: 6, color: Palette.violet, accent: Palette.blood,
                 ornament: .orbiters, movement: .anchor, cooldown: 1.4,
                 phases: [
                    [.spiral(arms: 6, duration: 2.5, rate: 0.12, turn: 0.15, speed: 200),
                     .fan(count: 7, spread: 0.8, speed: 320, volleys: 2)],
                    [.spiral(arms: 6, duration: 3.0, rate: 0.1, turn: -0.17, speed: 220),
                     .stream(duration: 2.0, rate: 0.06, speed: 380), .radial(count: 30, speed: 230)],
                    [.spiral(arms: 8, duration: 3.5, rate: 0.09, turn: 0.18, speed: 240), .charge(speed: 700),
                     .stream(duration: 2.0, rate: 0.05, speed: 400), .summon([.enforcer, .enforcer, .hound, .hound])],
                 ]),
        BossSpec(name: "THE CHAIRMAN", quip: "THIS CITY IS MY PROPERTY.",
                 hp: 1200, radius: 62, sides: 8, color: .white, accent: Palette.blood,
                 ornament: .spikes, movement: .hover(distance: 280, speed: 90), cooldown: 1.3,
                 phases: [
                    [.radial(count: 24, speed: 230), .fan(count: 7, spread: 0.8, speed: 320, volleys: 2),
                     .spiral(arms: 4, duration: 2.5, rate: 0.08, turn: 0.22, speed: 230), .summon([.suit, .suit, .enforcer])],
                    [.charge(speed: 720), .stream(duration: 2.5, rate: 0.05, speed: 400),
                     .spiral(arms: 6, duration: 3.0, rate: 0.07, turn: -0.2, speed: 240), .blink, .radial(count: 30, speed: 250)],
                    [.charge(speed: 820), .spiral(arms: 8, duration: 3.0, rate: 0.06, turn: 0.2, speed: 260), .blink,
                     .stream(duration: 2.5, rate: 0.04, speed: 420), .radial(count: 36, speed: 270),
                     .summon([.brute, .hound, .hound])],
                 ]),
    ]
}

// MARK: - Runtime

final class Boss: SKNode {
    struct Output {
        var shots: [(position: CGPoint, velocity: CGVector)] = []
        var summons: [Enemy.Kind] = []
        var newPhase: Int?
        var charged = false
        var blinked = false
        var arrived = false
    }

    private enum Active {
        case fan(left: Int, timer: TimeInterval, count: Int, spread: CGFloat, speed: CGFloat)
        case spiral(left: TimeInterval, timer: TimeInterval, angle: CGFloat, arms: Int, rate: TimeInterval, turn: CGFloat, speed: CGFloat)
        case stream(left: TimeInterval, timer: TimeInterval, rate: TimeInterval, speed: CGFloat)
        case windup(left: TimeInterval, dir: CGVector, speed: CGFloat)
        case charging(left: TimeInterval, dir: CGVector, speed: CGFloat)
        case blink(left: TimeInterval, target: CGPoint)
    }

    let spec: BossSpec
    let maxHP: Int
    var hp: Int
    var dead = false
    var radius: CGFloat { spec.radius }
    private(set) var phase = 0
    private(set) var entering = true

    private let lapScale: CGFloat
    private var attackTimer: TimeInterval = 1.0
    private var attackIndex = 0
    private var active: Active?
    private var wanderTarget: CGPoint?
    private var strafeSign: CGFloat = 1
    private var strafeTimer: TimeInterval = 3
    private var clock: TimeInterval = 0

    private let hull: SKShapeNode
    private let inner: SKShapeNode
    private let eye: SKShapeNode
    private let telegraph: SKShapeNode
    private var blinkMarker: SKShapeNode?

    init(spec: BossSpec, lap: Int, difficulty: Difficulty) {
        self.spec = spec
        self.lapScale = (1 + CGFloat(lap) * 0.15) * difficulty.tempo
        self.maxHP = difficulty.scaledHP(spec.hp * (1 + lap))
        self.hp = maxHP

        let rotation: CGFloat = spec.sides == 4 && spec.color != .white ? .pi / 4 : (spec.sides == 3 ? .pi / 2 : 0)
        hull = SKShapeNode(path: Geometry.polygon(sides: spec.sides, radius: spec.radius, rotation: rotation))
        hull.strokeColor = spec.color
        hull.fillColor = spec.color.withAlphaComponent(0.14)
        hull.lineWidth = 3.5
        hull.glowWidth = 7
        hull.zPosition = 1

        inner = SKShapeNode(path: Geometry.polygon(sides: spec.sides, radius: spec.radius * 0.6, rotation: rotation + .pi / CGFloat(spec.sides)))
        inner.strokeColor = spec.accent.withAlphaComponent(0.8)
        inner.lineWidth = 2
        inner.zPosition = 2

        eye = SKShapeNode(circleOfRadius: max(6, spec.radius * 0.16))
        eye.fillColor = .white
        eye.strokeColor = spec.accent
        eye.lineWidth = 2
        eye.glowWidth = 4
        eye.zPosition = 4

        let line = CGMutablePath()
        line.move(to: .zero)
        line.addLine(to: CGPoint(x: 1600, y: 0))
        telegraph = SKShapeNode(path: line)
        telegraph.strokeColor = spec.color.withAlphaComponent(0.5)
        telegraph.lineWidth = spec.radius * 0.9
        telegraph.zPosition = -1
        telegraph.isHidden = true

        super.init()
        addChild(telegraph)
        addChild(hull)
        addChild(inner)
        addChild(eye)
        buildOrnament()
        inner.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 7)))
        zPosition = 5
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    private func buildOrnament() {
        let r = spec.radius
        switch spec.ornament {
        case .spikes:
            let path = CGMutablePath()
            let n = 14
            for i in 0..<n {
                let a = CGFloat(i) / CGFloat(n) * .pi * 2
                let w: CGFloat = .pi / CGFloat(n) * 0.5
                path.move(to: CGPoint(x: cos(a - w) * (r + 6), y: sin(a - w) * (r + 6)))
                path.addLine(to: CGPoint(x: cos(a) * (r + 22), y: sin(a) * (r + 22)))
                path.addLine(to: CGPoint(x: cos(a + w) * (r + 6), y: sin(a + w) * (r + 6)))
            }
            let spikes = SKShapeNode(path: path)
            spikes.strokeColor = spec.accent
            spikes.lineWidth = 2.5
            spikes.glowWidth = 3
            spikes.zPosition = 0
            spikes.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 6)))
            addChild(spikes)
        case .orbiters:
            let ring = SKNode()
            ring.zPosition = 3
            for i in 0..<4 {
                let a = CGFloat(i) * .pi / 2
                let dot = SKShapeNode(circleOfRadius: 8)
                dot.fillColor = spec.accent
                dot.strokeColor = .white
                dot.lineWidth = 1.5
                dot.glowWidth = 4
                dot.position = CGPoint(x: cos(a) * (r + 24), y: sin(a) * (r + 24))
                ring.addChild(dot)
            }
            ring.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 3)))
            addChild(ring)
        case .halo:
            let halo = SKShapeNode(circleOfRadius: r + 16)
            halo.strokeColor = spec.accent.withAlphaComponent(0.6)
            halo.lineWidth = 3
            halo.glowWidth = 5
            halo.fillColor = .clear
            halo.zPosition = 0
            halo.run(.repeatForever(.sequence([.scale(to: 1.08, duration: 0.5), .scale(to: 0.96, duration: 0.5)])))
            addChild(halo)
        case .eye:
            let iris = SKShapeNode(circleOfRadius: r * 0.5)
            iris.strokeColor = spec.accent
            iris.fillColor = spec.accent.withAlphaComponent(0.2)
            iris.lineWidth = 3
            iris.glowWidth = 5
            iris.zPosition = 3
            addChild(iris)
            eye.setScale(1.6)
        }
    }

    // MARK: Update

    func update(_ dt: TimeInterval, player: CGPoint, arena: CGRect) -> Output {
        var out = Output()
        clock += dt

        let toPlayer = player - position
        eye.position = CGPoint(x: toPlayer.normalized.dx * radius * 0.28, y: toPlayer.normalized.dy * radius * 0.28)

        if entering {
            let target = CGPoint(x: 0, y: arena.maxY - radius - 80)
            let to = target - position
            if to.length < 4 {
                entering = false
                out.arrived = true
            } else {
                position += to.normalized * min(to.length, 150 * CGFloat(dt))
            }
            return out
        }

        let fraction = CGFloat(hp) / CGFloat(maxHP)
        let newPhase = fraction > 0.66 ? 0 : (fraction > 0.33 ? 1 : 2)
        if newPhase > phase {
            phase = newPhase
            out.newPhase = phase
            attackTimer = 0.9
            hull.glowWidth = 7 + CGFloat(phase) * 4
            if phase == 2 { hull.strokeColor = spec.color == Palette.blood ? .white : Palette.blood }
            run(.sequence([.scale(to: 1.25, duration: 0.12), .scale(to: 1, duration: 0.25)]))
        }

        let speed = lapScale * [1.0, 1.1, 1.22][phase]

        if let current = active {
            active = step(current, dt: dt, player: player, arena: arena, speed: speed, out: &out)
            if case .spiral = current { move(dt, player: player, arena: arena, scale: 0.4) }
            if case .stream = current { move(dt, player: player, arena: arena, scale: 0.7) }
            if case .fan = current { move(dt, player: player, arena: arena, scale: 0.7) }
        } else {
            move(dt, player: player, arena: arena, scale: 1)
            attackTimer -= dt
            if attackTimer <= 0 {
                let list = spec.phases[phase]
                start(list[attackIndex % list.count], player: player, arena: arena, speed: speed, out: &out)
                attackIndex += 1
                attackTimer = spec.cooldown * [1.0, 0.8, 0.62][phase] / Double(lapScale)
            }
        }

        let bounds = arena.insetBy(dx: radius * 0.6, dy: radius * 0.6)
        position.x = position.x.clamped(bounds.minX, bounds.maxX)
        position.y = position.y.clamped(bounds.minY, bounds.maxY)
        return out
    }

    private func move(_ dt: TimeInterval, player: CGPoint, arena: CGRect, scale: CGFloat) {
        let fdt = CGFloat(dt) * scale * lapScale
        let to = player - position
        switch spec.movement {
        case .chase(let s):
            position += to.normalized * (s * fdt)
        case .hover(let d, let s):
            strafeTimer -= dt
            if strafeTimer <= 0 { strafeSign *= -1; strafeTimer = Double.random(in: 2...4) }
            let dist = to.length
            let dir: CGVector
            if dist > d + 40 { dir = to.normalized }
            else if dist < d - 40 { dir = to.normalized * -1 }
            else { dir = to.normalized.perpendicular * strafeSign }
            position += dir * (s * fdt)
        case .wander(let s):
            let inner = arena.insetBy(dx: radius + 40, dy: radius + 40)
            if wanderTarget == nil || position.distance(to: wanderTarget!) < 12 {
                wanderTarget = CGPoint(x: CGFloat.random(in: inner.minX...inner.maxX),
                                       y: CGFloat.random(in: inner.minY...inner.maxY))
            }
            position += (wanderTarget! - position).normalized * (s * fdt)
        case .anchor:
            let target = CGPoint(x: CGFloat(sin(clock * 0.6)) * arena.width * 0.28, y: arena.maxY - radius - 80)
            let delta = target - position
            position += delta.normalized * min(delta.length, 120 * fdt)
        }
    }

    // MARK: Attacks

    private func fire(_ angle: CGFloat, speed: CGFloat, out: inout Output) {
        let dir = CGVector(angle: angle)
        out.shots.append((position + dir * (radius * 0.8), dir * speed))
    }

    private func fan(count: Int, spread: CGFloat, speed: CGFloat, player: CGPoint, out: inout Output) {
        let aim = (player - position).angle
        for i in 0..<count {
            let t = count == 1 ? 0.5 : CGFloat(i) / CGFloat(count - 1)
            fire(aim - spread / 2 + spread * t, speed: speed, out: &out)
        }
    }

    private func radial(count: Int, speed: CGFloat, out: inout Output) {
        let offset = CGFloat.random(in: 0...(.pi * 2))
        for i in 0..<count {
            fire(offset + CGFloat(i) / CGFloat(count) * .pi * 2, speed: speed, out: &out)
        }
    }

    private func start(_ attack: BossAttack, player: CGPoint, arena: CGRect, speed: CGFloat, out: inout Output) {
        switch attack {
        case let .radial(count, s):
            radial(count: count, speed: s * speed, out: &out)
        case let .fan(count, spread, s, volleys):
            fan(count: count, spread: spread, speed: s * speed, player: player, out: &out)
            if volleys > 1 { active = .fan(left: volleys - 1, timer: 0.22, count: count, spread: spread, speed: s * speed) }
        case let .spiral(arms, duration, rate, turn, s):
            active = .spiral(left: duration, timer: 0, angle: CGFloat.random(in: 0...(.pi * 2)),
                             arms: arms, rate: rate, turn: turn, speed: s * speed)
        case let .stream(duration, rate, s):
            active = .stream(left: duration, timer: 0, rate: rate, speed: s * speed)
        case let .charge(s):
            let dir = (player - position).normalized
            telegraph.zRotation = dir.angle
            telegraph.isHidden = false
            telegraph.alpha = 0.2
            telegraph.run(.repeatForever(.sequence([.fadeAlpha(to: 0.7, duration: 0.1), .fadeAlpha(to: 0.2, duration: 0.1)])), withKey: "warn")
            active = .windup(left: 0.75, dir: dir, speed: s * speed)
        case .blink:
            let inner = arena.insetBy(dx: radius + 60, dy: radius + 60)
            var target = CGPoint(x: CGFloat.random(in: inner.minX...inner.maxX), y: CGFloat.random(in: inner.minY...inner.maxY))
            for _ in 0..<8 where target.distance(to: player) < 240 {
                target = CGPoint(x: CGFloat.random(in: inner.minX...inner.maxX), y: CGFloat.random(in: inner.minY...inner.maxY))
            }
            let marker = SKShapeNode(circleOfRadius: radius)
            marker.strokeColor = spec.color.withAlphaComponent(0.7)
            marker.lineWidth = 2
            marker.glowWidth = 3
            marker.position = target
            marker.zPosition = 2
            marker.setScale(1.6)
            marker.run(.scale(to: 1, duration: 0.6))
            parent?.addChild(marker)
            blinkMarker = marker
            run(.fadeAlpha(to: 0.15, duration: 0.3))
            active = .blink(left: 0.65, target: target)
        case let .summon(kinds):
            out.summons += kinds
        }
    }

    private func step(_ current: Active, dt: TimeInterval, player: CGPoint, arena: CGRect, speed: CGFloat, out: inout Output) -> Active? {
        switch current {
        case var .fan(left, timer, count, spread, s):
            timer -= dt
            if timer <= 0 {
                fan(count: count, spread: spread, speed: s, player: player, out: &out)
                left -= 1
                timer = 0.22
            }
            return left > 0 ? .fan(left: left, timer: timer, count: count, spread: spread, speed: s) : nil

        case var .spiral(left, timer, angle, arms, rate, turn, s):
            timer -= dt
            while timer <= 0 {
                for arm in 0..<arms {
                    fire(angle + CGFloat(arm) / CGFloat(arms) * .pi * 2, speed: s, out: &out)
                }
                angle += turn
                timer += rate
            }
            left -= dt
            return left > 0 ? .spiral(left: left, timer: timer, angle: angle, arms: arms, rate: rate, turn: turn, speed: s) : nil

        case var .stream(left, timer, rate, s):
            timer -= dt
            while timer <= 0 {
                fire((player - position).angle + CGFloat.random(in: -0.08...0.08), speed: s, out: &out)
                timer += rate
            }
            left -= dt
            return left > 0 ? .stream(left: left, timer: timer, rate: rate, speed: s) : nil

        case var .windup(left, dir, s):
            left -= dt
            if left <= 0 {
                telegraph.removeAction(forKey: "warn")
                telegraph.isHidden = true
                out.charged = true
                return .charging(left: 0.6, dir: dir, speed: s)
            }
            return .windup(left: left, dir: dir, speed: s)

        case var .charging(left, dir, s):
            position += dir * (s * CGFloat(dt))
            left -= dt
            let bounds = arena.insetBy(dx: radius * 0.6, dy: radius * 0.6)
            if left <= 0 || !bounds.contains(position) {
                if phase >= 1 { radial(count: 10 + phase * 4, speed: 220 * speed, out: &out) }
                return nil
            }
            return .charging(left: left, dir: dir, speed: s)

        case var .blink(left, target):
            left -= dt
            if left <= 0 {
                position = target
                removeAction(forKey: "fade")
                alpha = 1
                blinkMarker?.removeFromParent()
                blinkMarker = nil
                out.blinked = true
                radial(count: 12 + phase * 4, speed: 230 * speed, out: &out)
                return nil
            }
            return .blink(left: left, target: target)
        }
    }

    // MARK: Damage

    func flash() {
        let original = spec.color.withAlphaComponent(0.14)
        hull.removeAction(forKey: "flash")
        hull.run(.sequence([
            .run { [weak self] in self?.hull.fillColor = .white },
            .wait(forDuration: 0.04),
            .run { [weak self] in self?.hull.fillColor = original },
        ]), withKey: "flash")
    }

    /// Stop any in-progress attack visuals (used on death).
    func shutdown() {
        active = nil
        telegraph.removeAllActions()
        telegraph.isHidden = true
        blinkMarker?.removeFromParent()
        blinkMarker = nil
    }
}
