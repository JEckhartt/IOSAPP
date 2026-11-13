import SpriteKit
import UIKit

final class GameScene: SKScene {
    private enum State { case title, playing, dead }

    // MARK: Nodes

    private let cam = SKCameraNode()
    private let world = SKNode()
    private let backdrop = CityBackdrop()
    private let hud = HUD()
    private let moveStick = Joystick(color: Palette.magenta)
    private let aimStick = Joystick(color: Palette.cyan)
    private let player = Player()

    private var rain: SKEmitterNode?
    private var vignette: SKSpriteNode?
    private var scanlines: SKSpriteNode?
    private var damageFlash: SKSpriteNode?

    // MARK: State

    private var state: State = .title
    private var built = false
    private var touchSticks: [ObjectIdentifier: Joystick] = [:]

    private var enemies: [Enemy] = []
    private var bullets: [Bullet] = []
    private var pickups: [Pickup] = []

    private var lastTime: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var fireCooldown: TimeInterval = 0
    private var weapon: Weapon = .spitter
    private var ammo = 0
    private var hitStop: TimeInterval = 0
    private var shake: CGFloat = 0
    private var deadDelay: TimeInterval = 0

    private var score = 0
    private var comboKills = 0
    private var comboTimer: TimeInterval = 0
    private var multiplier: Int { min(8, 1 + comboKills / 4) }

    private var wave = 0
    private var spawnQueue: [Enemy.Kind] = []
    private var spawnTimer: TimeInterval = 0
    private var nextWaveIn: TimeInterval?

    private static let bestKey = "gutterlight.bestScore"
    private var best: Int {
        get { UserDefaults.standard.integer(forKey: Self.bestKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.bestKey) }
    }

    private static let waveQuips = [
        "THE SUITS WANT THEIR STREETS BACK",
        "NO GODS. NO MANAGERS.",
        "THE RAIN NEVER STOPS",
        "THEY CUT THE POWER AGAIN",
        "SMASH THE SIGNAL",
        "CURFEW IS A SUGGESTION",
        "EVERY STREETLIGHT IS A WITNESS",
        "THE TOWER IS WATCHING",
    ]

    private var arena: CGRect {
        CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
    }

    // MARK: Setup

    override func didMove(to view: SKView) {
        backgroundColor = Palette.night
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.isMultipleTouchEnabled = true
        guard !built else { return }
        built = true

        addChild(cam)
        camera = cam

        world.zPosition = 0
        addChild(world)
        world.addChild(backdrop)

        player.zPosition = 6
        player.isHidden = true
        world.addChild(player)

        hud.zPosition = 100
        cam.addChild(hud)
        moveStick.zPosition = 200
        aimStick.zPosition = 200
        cam.addChild(moveStick)
        cam.addChild(aimStick)

        layoutForSize()
        hud.showTitle(best: best)

        Audio.shared.start()
        Audio.shared.playMusic()
        Audio.shared.setMusicLevel(.title)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard built else { return }
        layoutForSize()
    }

    private func layoutForSize() {
        guard size.width > 0, size.height > 0 else { return }
        backdrop.build(for: size)
        hud.layout(for: size, insets: view?.safeAreaInsets ?? .zero)

        rain?.removeFromParent()
        vignette?.removeFromParent()
        scanlines?.removeFromParent()
        damageFlash?.removeFromParent()

        let rain = FX.rain(for: size)
        rain.zPosition = 50
        cam.addChild(rain)
        self.rain = rain

        let vignette = FX.vignette(for: size)
        vignette.zPosition = 80
        cam.addChild(vignette)
        self.vignette = vignette

        let scanlines = FX.scanlines(for: size)
        scanlines.zPosition = 81
        cam.addChild(scanlines)
        self.scanlines = scanlines

        let flash = SKSpriteNode(color: Palette.blood, size: size)
        flash.alpha = 0
        flash.blendMode = .add
        flash.zPosition = 82
        cam.addChild(flash)
        damageFlash = flash
    }

    // MARK: Game flow

    private func startGame() {
        enemies.forEach { $0.removeFromParent() }
        bullets.forEach { $0.removeFromParent() }
        pickups.forEach { $0.removeFromParent() }
        enemies.removeAll()
        bullets.removeAll()
        pickups.removeAll()

        player.reset()
        player.isHidden = false

        score = 0
        comboKills = 0
        comboTimer = 0
        wave = 0
        spawnQueue = []
        nextWaveIn = 0.8
        fireCooldown = 0
        elapsed = 0

        hud.showGameplay()
        hud.setScore(0)
        hud.setCombo(1)
        hud.setWave(0)
        hud.setHP(player.hp, max: Player.maxHP)
        equip(.spitter, announce: false)
        Audio.shared.setMusicLevel(.playing)
        state = .playing
    }

    private func startWave() {
        wave += 1
        let count = 5 + wave * 3
        var queue: [Enemy.Kind] = []
        for _ in 0..<count {
            let roll = Double.random(in: 0..<1)
            if wave >= 4 && roll < 0.06 + Double(min(wave, 12)) * 0.008 {
                queue.append(.brute)
            } else if wave >= 3 && roll < 0.3 {
                queue.append(.enforcer)
            } else if wave >= 2 && roll < 0.55 {
                queue.append(.hound)
            } else {
                queue.append(.suit)
            }
        }
        if wave % 5 == 0 { queue.append(.brute) }
        spawnQueue = queue.shuffled()
        spawnTimer = 0.4
        hud.setWave(wave)
        hud.banner("WAVE \(wave)", sub: Self.waveQuips[(wave - 1) % Self.waveQuips.count])
        Audio.shared.play(.wave)
    }

    private func gameOver() {
        state = .dead
        deadDelay = 1.2
        releaseAllSticks()

        FX.burst(at: player.position, color: Palette.magenta, count: 80, speed: 420, in: world)
        FX.shockwave(at: player.position, color: Palette.magenta, radius: 60, in: world)
        player.isHidden = true
        shake = 22
        Haptics.death()
        Audio.shared.play(.gameOver)
        Audio.shared.setMusicLevel(.dead)

        let newBest = score > best
        if newBest { best = score }
        hud.showGameOver(score: score, best: best, wave: wave, newBest: newBest)
    }

    // MARK: Touch input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch state {
        case .title:
            startGame()
            return
        case .dead:
            if deadDelay <= 0 { startGame() }
            return
        case .playing:
            break
        }

        for touch in touches {
            let p = touch.location(in: cam)
            let stick = p.x < 0 ? moveStick : aimStick
            guard !stick.isActive else { continue }
            stick.begin(at: p)
            touchSticks[ObjectIdentifier(touch)] = stick
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchSticks[ObjectIdentifier(touch)]?.move(to: touch.location(in: cam))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchSticks.removeValue(forKey: ObjectIdentifier(touch))?.end()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func releaseAllSticks() {
        touchSticks.removeAll()
        moveStick.end()
        aimStick.end()
    }

    // MARK: Main loop

    override func update(_ currentTime: TimeInterval) {
        let rawDt = lastTime == 0 ? 0 : currentTime - lastTime
        lastTime = currentTime
        let dt = min(rawDt, 1.0 / 30.0)

        updateShake(dt)

        switch state {
        case .title:
            return
        case .dead:
            if deadDelay > 0 {
                deadDelay -= dt
                if deadDelay <= 0 { hud.enableGameOverPrompt() }
            }
            updateBullets(dt)
            cleanup()
            return
        case .playing:
            break
        }

        if hitStop > 0 {
            hitStop -= dt
            return
        }

        elapsed += dt
        updatePlayer(dt)
        updateShooting(dt)
        updateWaves(dt)
        updateEnemies(dt)
        updateBullets(dt)
        updatePickups(dt)
        resolveCollisions()
        updateCombo(dt)
        cleanup()
    }

    private func updateShake(_ dt: TimeInterval) {
        if shake > 0.1 {
            cam.position = CGPoint(x: CGFloat.random(in: -shake...shake), y: CGFloat.random(in: -shake...shake))
            shake *= CGFloat(pow(0.002, dt))
        } else {
            shake = 0
            cam.position = .zero
        }
    }

    private func updatePlayer(_ dt: TimeInterval) {
        player.tick(dt)

        let target = moveStick.value * Player.moveSpeed
        player.velocity = player.velocity.lerp(to: target, t: CGFloat(min(1, dt * 14)))
        player.position += player.velocity * CGFloat(dt)

        let bounds = arena.insetBy(dx: Player.radius + 6, dy: Player.radius + 6)
        player.position.x = player.position.x.clamped(bounds.minX, bounds.maxX)
        player.position.y = player.position.y.clamped(bounds.minY, bounds.maxY)

        if aimStick.magnitude > 0.2 {
            player.zRotation = aimStick.value.angle
        } else if moveStick.magnitude > 0.2 {
            player.zRotation = moveStick.value.angle
        }
    }

    private func updateShooting(_ dt: TimeInterval) {
        fireCooldown -= dt
        guard aimStick.magnitude > 0.25, fireCooldown <= 0 else { return }
        fireCooldown = weapon.cooldown

        let aim = aimStick.value.angle
        let pellets = weapon.pellets
        for i in 0..<pellets {
            let angle: CGFloat
            if pellets > 1 {
                let step = weapon.spread / CGFloat(pellets - 1)
                angle = aim - weapon.spread / 2 + step * CGFloat(i) + CGFloat.random(in: -0.04...0.04)
            } else {
                angle = aim + CGFloat.random(in: -weapon.spread...max(weapon.spread, 0.0001))
            }
            let dir = CGVector(angle: angle)
            let speed = weapon.speed * (pellets > 1 ? CGFloat.random(in: 0.85...1.1) : 1)
            let bullet = Bullet(weapon: weapon, velocity: dir * speed)
            bullet.position = player.position + dir * 20
            world.addChild(bullet)
            bullet.trail?.targetNode = world
            bullets.append(bullet)
        }

        let dir = CGVector(angle: aim)
        FX.muzzleFlash(at: player.position + dir * 20, in: world)
        player.velocity += dir * -weapon.recoil
        shake = max(shake, weapon.shake)
        Audio.shared.play(weapon.sfx, volume: weapon.sfxVolume)
        if weapon.shake > 0 { Haptics.light() }

        if weapon.ammo > 0 {
            ammo -= 1
            if ammo <= 0 {
                FX.popup("DRY", at: player.position + CGVector(dx: 0, dy: 26), color: .white, in: world)
                equip(.spitter, announce: false)
            } else {
                hud.setWeapon(weapon, ammo: ammo)
            }
        }
    }

    private func equip(_ newWeapon: Weapon, announce: Bool) {
        weapon = newWeapon
        ammo = newWeapon.ammo
        fireCooldown = min(fireCooldown, 0.1)
        hud.setWeapon(newWeapon, ammo: ammo)
        hud.flashWeapon()
        if announce {
            FX.popup(newWeapon.name, at: player.position + CGVector(dx: 0, dy: 30), color: newWeapon.color, in: world)
            FX.shockwave(at: player.position, color: newWeapon.color, radius: 30, in: world)
            Audio.shared.play(.weapon)
            Haptics.heavy()
        }
    }

    private func updateWaves(_ dt: TimeInterval) {
        if var countdown = nextWaveIn {
            countdown -= dt
            if countdown <= 0 {
                nextWaveIn = nil
                startWave()
            } else {
                nextWaveIn = countdown
            }
            return
        }

        if !spawnQueue.isEmpty {
            spawnTimer -= dt
            if spawnTimer <= 0 {
                spawnEnemy(spawnQueue.removeLast())
                spawnTimer = max(0.22, 0.95 - Double(wave) * 0.06)
            }
        } else if enemies.isEmpty {
            nextWaveIn = 2.2
            if wave % 3 == 0 {
                let spot = arena.insetBy(dx: 90, dy: 90)
                dropWeapon(at: CGPoint(x: CGFloat.random(in: spot.minX...spot.maxX),
                                       y: CGFloat.random(in: spot.minY...spot.maxY)))
            }
            score += wave * 250
            hud.setScore(score)
            FX.popup("WAVE CLEAR  +\(wave * 250)", at: player.position + CGVector(dx: 0, dy: 30), color: Palette.acid, in: world)
        }
    }

    private func spawnEnemy(_ kind: Enemy.Kind) {
        let enemy = Enemy(kind: kind, wave: wave)
        let margin = kind.radius + 30
        let a = arena
        let pos: CGPoint
        switch Int.random(in: 0..<4) {
        case 0: pos = CGPoint(x: CGFloat.random(in: a.minX...a.maxX), y: a.maxY + margin)
        case 1: pos = CGPoint(x: CGFloat.random(in: a.minX...a.maxX), y: a.minY - margin)
        case 2: pos = CGPoint(x: a.minX - margin, y: CGFloat.random(in: a.minY...a.maxY))
        default: pos = CGPoint(x: a.maxX + margin, y: CGFloat.random(in: a.minY...a.maxY))
        }
        enemy.position = pos
        world.addChild(enemy)
        enemies.append(enemy)
    }

    private func updateEnemies(_ dt: TimeInterval) {
        let fdt = CGFloat(dt)

        for e in enemies where !e.dead {
            let toPlayer = player.position - e.position
            let dist = toPlayer.length
            let dir = toPlayer.normalized
            var desired: CGVector

            switch e.kind {
            case .suit, .brute:
                desired = dir * e.speed
            case .hound:
                let wobble = CGFloat(sin(elapsed * 7 + Double(e.phase)))
                desired = (dir + dir.perpendicular * (wobble * 0.9)).normalized * e.speed
            case .enforcer:
                if dist > 280 {
                    desired = dir * e.speed
                } else if dist < 170 {
                    desired = dir * -e.speed
                } else {
                    let side: CGFloat = sin(e.phase) > 0 ? 1 : -1
                    desired = dir.perpendicular * (e.speed * 0.6 * side)
                }
                e.fireTimer -= dt
                if e.fireTimer <= 0 && dist < 520 && arena.contains(e.position) {
                    e.fireTimer = max(0.9, 2.0 - Double(wave) * 0.06)
                    let shot = Bullet(enemyVelocity: dir * (230 + CGFloat(min(wave, 12)) * 8))
                    shot.position = e.position + dir * (e.kind.radius + 4)
                    world.addChild(shot)
                    bullets.append(shot)
                    Audio.shared.play(.enemyShot, volume: 0.6)
                }
            }

            e.position += (desired + e.knock) * fdt
            e.knock = e.knock * CGFloat(pow(0.001, dt))
            e.zRotation = dir.angle
        }

        // Cheap separation so they don't stack into a single blob.
        let count = enemies.count
        for i in 0..<count {
            let a = enemies[i]
            for j in (i + 1)..<count {
                let b = enemies[j]
                let delta = a.position - b.position
                let minDist = a.kind.radius + b.kind.radius
                let d = delta.length
                if d > 0.01 && d < minDist {
                    let push = delta.normalized * ((minDist - d) * 0.5)
                    // Brutes barely budge; everyone else gets shoved.
                    let aWeight: CGFloat = a.kind == .brute ? 0.2 : 1
                    let bWeight: CGFloat = b.kind == .brute ? 0.2 : 1
                    a.position += push * aWeight
                    b.position += push * -bWeight
                }
            }
        }
    }

    private func updateBullets(_ dt: TimeInterval) {
        let killZone = arena.insetBy(dx: -60, dy: -60)
        for b in bullets where !b.dead {
            b.position += b.velocity * CGFloat(dt)
            b.life -= dt
            if b.life <= 0 || !killZone.contains(b.position) {
                b.dead = true
                if b.life <= 0 && b.blastRadius > 0 && state == .playing {
                    explode(at: b.position, radius: b.blastRadius, damage: b.damage)
                }
            }
        }
    }

    private func updatePickups(_ dt: TimeInterval) {
        for p in pickups where !p.dead {
            p.tick(dt)
            if p.life <= 0 { p.dead = true }
        }
    }

    private func updateCombo(_ dt: TimeInterval) {
        guard comboKills > 0 else { return }
        comboTimer -= dt
        if comboTimer <= 0 {
            comboKills = 0
            hud.setCombo(1)
        }
    }

    // MARK: Collisions

    private func resolveCollisions() {
        for b in bullets where !b.dead {
            if b.friendly {
                for e in enemies where !e.dead {
                    let id = ObjectIdentifier(e)
                    guard !b.hits.contains(id),
                          b.position.distance(to: e.position) < b.radius + e.kind.radius else { continue }
                    if b.blastRadius > 0 {
                        b.dead = true
                        explode(at: b.position, radius: b.blastRadius, damage: b.damage)
                        break
                    }
                    hit(e, direction: b.velocity.normalized, damage: b.damage, knockScale: b.knockback)
                    if b.pierces {
                        b.hits.insert(id)
                    } else {
                        b.dead = true
                        break
                    }
                }
            } else if b.position.distance(to: player.position) < b.radius + Player.radius * 0.6 {
                b.dead = true
                damagePlayer()
            }
        }

        guard state == .playing else { return }

        for e in enemies where !e.dead {
            if e.position.distance(to: player.position) < e.kind.radius + Player.radius * 0.8 {
                damagePlayer()
                e.knock = (e.position - player.position).normalized * 420
            }
        }

        for p in pickups where !p.dead {
            guard p.position.distance(to: player.position) < Pickup.radius + Player.radius else { continue }
            p.dead = true
            switch p.kind {
            case .health:
                player.hp = min(Player.maxHP, player.hp + 1)
                hud.setHP(player.hp, max: Player.maxHP)
                FX.burst(at: p.position, color: Palette.acid, count: 18, in: world)
                FX.popup("+1 HP", at: p.position, color: Palette.acid, in: world)
                Audio.shared.play(.pickup)
                Haptics.light()
            case .weapon(let w):
                FX.burst(at: p.position, color: w.color, count: 26, in: world)
                equip(w, announce: true)
            }
        }
    }

    private func hit(_ enemy: Enemy, direction: CGVector, damage: Int, knockScale: CGFloat = 1) {
        guard !enemy.dead else { return }
        enemy.hp -= damage
        enemy.knock += direction * (enemy.kind.knockback * knockScale)
        enemy.flash()
        FX.burst(at: enemy.position, color: enemy.kind.color, count: 4, speed: 160, in: world)
        if enemy.hp <= 0 {
            kill(enemy)
        } else {
            Audio.shared.play(.hit, volume: 0.7)
        }
    }

    private func explode(at point: CGPoint, radius: CGFloat, damage: Int) {
        FX.burst(at: point, color: Palette.amber, count: 50, speed: 340, in: world)
        FX.burst(at: point, color: Palette.blood, count: 20, speed: 200, in: world)
        FX.shockwave(at: point, color: Palette.amber, radius: radius * 0.7, in: world)
        shake = max(shake, 11)
        Audio.shared.play(.explode)
        Haptics.heavy()

        for e in enemies where !e.dead {
            let away = e.position - point
            if away.length < radius + e.kind.radius {
                hit(e, direction: away.normalized, damage: damage, knockScale: 2)
            }
        }
    }

    private func dropWeapon(at point: CGPoint) {
        let options = Weapon.drops.filter { $0 != weapon }
        guard let pick = options.randomElement() else { return }
        let crate = Pickup(kind: .weapon(pick))
        crate.position = point
        world.addChild(crate)
        pickups.append(crate)
        FX.shockwave(at: point, color: pick.color, radius: 24, in: world)
    }

    private func kill(_ enemy: Enemy) {
        enemy.dead = true

        comboKills += 1
        comboTimer = 2.5
        let gained = enemy.kind.points * multiplier
        score += gained
        hud.setScore(score)
        hud.setCombo(multiplier)

        let big = enemy.kind == .brute
        FX.burst(at: enemy.position, color: enemy.kind.color, count: big ? 70 : 26, speed: big ? 380 : 260, in: world)
        FX.shockwave(at: enemy.position, color: enemy.kind.color, radius: enemy.kind.radius * 1.4, in: world)
        FX.popup("+\(gained)", at: enemy.position, color: enemy.kind.color, in: world)

        shake = max(shake, big ? 14 : 4)
        if big {
            hitStop = 0.06
            Haptics.heavy()
            Audio.shared.play(.bigExplode)
        } else {
            Haptics.light()
            Audio.shared.play(.explode, volume: 0.55)
        }

        guard arena.contains(enemy.position) else { return }
        let roll = Double.random(in: 0..<1)
        switch enemy.kind {
        case .brute:
            dropWeapon(at: enemy.position + CGVector(dx: -18, dy: 0))
            if roll < 0.5 { dropHealth(at: enemy.position + CGVector(dx: 18, dy: 0)) }
        case .enforcer:
            if roll < 0.1 { dropWeapon(at: enemy.position) } else if roll < 0.14 { dropHealth(at: enemy.position) }
        case .suit, .hound:
            if roll < 0.015 { dropWeapon(at: enemy.position) } else if roll < 0.045 { dropHealth(at: enemy.position) }
        }
    }

    private func dropHealth(at point: CGPoint) {
        let pickup = Pickup(kind: .health)
        pickup.position = point
        world.addChild(pickup)
        pickups.append(pickup)
    }

    private func damagePlayer() {
        guard state == .playing, player.invulnerable <= 0 else { return }
        player.hp -= 1
        player.invulnerable = 1.2
        hud.setHP(player.hp, max: Player.maxHP)

        comboKills = 0
        hud.setCombo(1)

        shake = max(shake, 14)
        hitStop = 0.08
        Haptics.heavy()
        Audio.shared.play(.hurt)
        damageFlash?.removeAllActions()
        damageFlash?.alpha = 0.35
        damageFlash?.run(.fadeOut(withDuration: 0.3))
        FX.burst(at: player.position, color: Palette.magenta, count: 20, in: world)

        if player.hp <= 0 { gameOver() }
    }

    private func cleanup() {
        bullets.removeAll { b in
            if b.dead { b.removeFromParent() }
            return b.dead
        }
        enemies.removeAll { e in
            if e.dead { e.removeFromParent() }
            return e.dead
        }
        pickups.removeAll { p in
            if p.dead { p.removeFromParent() }
            return p.dead
        }
    }
}
