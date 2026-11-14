import SpriteKit
import UIKit

final class GameScene: SKScene {
    private enum State { case title, playing, paused, dead }

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
    private var boss: Boss?

    private var lastTime: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var fireCooldown: TimeInterval = 0
    private var weapon: Weapon = .spitter
    private var ammo = 0
    /// The run's start weapon: infinite ammo, what you fall back to when a pickup runs dry.
    private var baseWeapon: Weapon = .spitter
    private var infiniteAmmo: Bool { weapon == baseWeapon }
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

    // Run configuration (snapshotted from Store when a run starts).
    private let menu = MainMenu()
    private var difficulty = Difficulty()
    /// Bought damage bonus, applied to the start weapon.
    private var startWeaponBonus = 0
    private var godMode = false
    /// God mode or boss skip: nothing gets saved.
    private var isDevRun = false
    private var lastRun: (startWave: Int, dev: Bool) = (1, false)

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

        menu.zPosition = 150
        menu.onPlay = { [weak self] in
            self?.startGame(atWave: 1, dev: Store.settings.godMode)
        }
        menu.onSkipToWave = { [weak self] wave in
            self?.startGame(atWave: wave, dev: true)
        }
        cam.addChild(menu)

        layoutForSize()
        showMenu()

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
        menu.layout(for: size, insets: view?.safeAreaInsets ?? .zero)

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

    private func showMenu() {
        state = .title
        world.isPaused = false
        hud.hidePause()
        releaseAllSticks()
        clearWorld()
        player.isHidden = true
        hud.showMenuMode()
        menu.show()
        Audio.shared.setMusicLevel(.title)
    }

    private func clearWorld() {
        enemies.forEach { $0.removeFromParent() }
        bullets.forEach { $0.removeFromParent() }
        pickups.forEach { $0.removeFromParent() }
        enemies.removeAll()
        bullets.removeAll()
        pickups.removeAll()
        boss?.removeFromParent()
        boss = nil
        hud.hideBossBar()
    }

    private func startGame(atWave startWave: Int, dev: Bool) {
        let settings = Store.settings
        let progress = Store.progress
        difficulty = settings.difficulty
        godMode = settings.godMode
        isDevRun = dev || godMode
        startWeaponBonus = progress.spitterUnlocked ? progress.spitterBonus : 0
        baseWeapon = progress.isUnlocked(settings.defaultWeapon) ? settings.defaultWeapon : .spitter
        lastRun = (startWave, dev)
        let maxHP = Player.baseMaxHP + (settings.extraLivesEnabled ? progress.extraLives : 0)
        menu.hide()

        enemies.forEach { $0.removeFromParent() }
        bullets.forEach { $0.removeFromParent() }
        pickups.forEach { $0.removeFromParent() }
        enemies.removeAll()
        bullets.removeAll()
        pickups.removeAll()
        boss?.removeFromParent()
        boss = nil
        hud.hideBossBar()

        player.reset(maxHP: maxHP)
        player.isHidden = false

        score = 0
        comboKills = 0
        comboTimer = 0
        wave = max(0, startWave - 1)
        spawnQueue = []
        nextWaveIn = 0.8
        fireCooldown = 0
        elapsed = 0

        hud.showGameplay()
        hud.setScore(0)
        hud.setCombo(1)
        hud.setWave(0)
        hud.setHP(player.hp, max: player.maxHP)
        hud.setDevTag(godMode ? "GOD MODE" : (isDevRun ? "DEV RUN" : nil))
        weapon = baseWeapon
        equip(baseWeapon, announce: false)
        Audio.shared.setMusicLevel(.playing)
        state = .playing
    }

    private func startWave() {
        wave += 1
        if let encounter = BossSpec.forWave(wave) {
            startBossWave(encounter.spec, lap: encounter.lap)
            return
        }
        let count = max(3, Int((Double(5 + wave * 3) * difficulty.amount).rounded()))
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

    private func startBossWave(_ spec: BossSpec, lap: Int) {
        spawnQueue = []
        let b = Boss(spec: spec, lap: lap, difficulty: difficulty)
        b.position = CGPoint(x: 0, y: arena.maxY + spec.radius + 40)
        world.addChild(b)
        boss = b

        hud.setWave(wave)
        hud.banner(spec.name, sub: "\"" + spec.quip + "\"")
        hud.showBossBar(name: lap > 0 ? "\(spec.name)  \(String(repeating: "+", count: lap))" : spec.name, color: spec.color)
        hud.setBossHP(1)
        Audio.shared.play(.wave)
        Audio.shared.play(.bigExplode, volume: 0.5)
        shake = max(shake, 10)
        Haptics.heavy()
    }

    private func gameOver() {
        state = .dead
        hud.hideBossBar()
        deadDelay = 1.2
        releaseAllSticks()

        FX.burst(at: player.position, color: Palette.magenta, count: 80, speed: 420, in: world)
        FX.shockwave(at: player.position, color: Palette.magenta, radius: 60, in: world)
        player.isHidden = true
        shake = 22
        Haptics.death()
        Audio.shared.play(.gameOver)
        Audio.shared.setMusicLevel(.dead)

        var newBest = false
        if !isDevRun {
            newBest = Store.submit(score: score, wave: wave, difficulty: difficulty) == 0
        }
        hud.showGameOver(score: score, best: Store.best, wave: wave, newBest: newBest, devRun: isDevRun)
    }

    // MARK: Touch input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch state {
        case .title:
            menu.touchesBegan(touches)
            return
        case .dead:
            guard deadDelay <= 0, let touch = touches.first else { return }
            switch hud.gameOverChoice(for: touch) {
            case .retry?: startGame(atWave: lastRun.startWave, dev: lastRun.dev)
            case .menu?: showMenu()
            case nil: break
            }
            return
        case .paused:
            guard let touch = touches.first else { return }
            switch hud.pauseChoice(for: touch) {
            case .resume?: resume()
            case .menu?: showMenu()
            case nil: break
            }
            return
        case .playing:
            if touches.contains(where: { hud.pauseButtonHit($0) }) {
                pause()
                return
            }
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
        if state == .title { menu.touchesMoved(touches) }
        for touch in touches {
            touchSticks[ObjectIdentifier(touch)]?.move(to: touch.location(in: cam))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if state == .title { menu.touchesEnded(touches) }
        for touch in touches {
            touchSticks.removeValue(forKey: ObjectIdentifier(touch))?.end()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func pause() {
        guard state == .playing else { return }
        state = .paused
        releaseAllSticks()
        world.isPaused = true
        hud.showPause()
        Audio.shared.setMusicLevel(.dead)
        Audio.shared.play(.hit, volume: 0.5)
    }

    private func resume() {
        state = .playing
        world.isPaused = false
        hud.hidePause()
        Audio.shared.setMusicLevel(.playing)
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
        case .title, .paused:
            return
        case .dead:
            if deadDelay > 0 {
                deadDelay -= dt
                if deadDelay <= 0 { hud.enableGameOverButtons() }
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
        updateBoss(dt)
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

        // Slight curve: fine control near center, full speed quickly.
        let m = moveStick.magnitude
        let target = moveStick.value.normalized * (Player.moveSpeed * min(1, m * 1.25))
        let response: TimeInterval = m > 0 ? 24 : 18
        player.velocity = player.velocity.lerp(to: target, t: CGFloat(min(1, dt * response)))
        player.position += player.velocity * CGFloat(dt)

        let bounds = arena.insetBy(dx: Player.radius + 6, dy: Player.radius + 6)
        player.position.x = player.position.x.clamped(bounds.minX, bounds.maxX)
        player.position.y = player.position.y.clamped(bounds.minY, bounds.maxY)

        if aimStick.magnitude > 0 {
            player.zRotation = assistedAim(aimStick.value.angle)
        } else if moveStick.magnitude > 0 {
            player.zRotation = moveStick.value.angle
        }
    }

    private func updateShooting(_ dt: TimeInterval) {
        fireCooldown -= dt
        guard aimStick.magnitude > 0, fireCooldown <= 0 else { return }
        fireCooldown = weapon.cooldown

        let aim = assistedAim(aimStick.value.angle)
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
            let bullet = Bullet(weapon: weapon, velocity: dir * speed,
                                damageBonus: weapon == baseWeapon ? startWeaponBonus : 0)
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
        if weapon.shake >= 4 { Haptics.light() }

        if !infiniteAmmo {
            ammo -= 1
            if ammo <= 0 {
                FX.popup("DRY", at: player.position + CGVector(dx: 0, dy: 26), color: .white, in: world)
                equip(baseWeapon, announce: false)
            } else {
                hud.setWeapon(weapon, ammo: ammo)
            }
        }
    }

    /// Gentle aim magnetism: bends the shot toward the best target inside a narrow cone.
    private func assistedAim(_ raw: CGFloat) -> CGFloat {
        let cone: CGFloat = 0.22
        var best: (diff: CGFloat, score: CGFloat)?
        for e in enemies where !e.dead && arena.contains(e.position) {
            let to = e.position - player.position
            let dist = to.length
            guard dist < 650, dist > 1 else { continue }
            let diff = atan2(sin(to.angle - raw), cos(to.angle - raw))
            guard abs(diff) < cone else { continue }
            let score = abs(diff) * 300 + dist  // prefer on-line, then close
            if best == nil || score < best!.score { best = (diff, score) }
        }
        guard let best else { return raw }
        return raw + best.diff * 0.75
    }

    private func equip(_ newWeapon: Weapon, announce: Bool) {
        if newWeapon == weapon && !infiniteAmmo {
            ammo = min(newWeapon.ammo * 2, ammo + newWeapon.ammo)
        } else {
            ammo = newWeapon.ammo
        }
        weapon = newWeapon
        fireCooldown = min(fireCooldown, 0.1)
        hud.setWeapon(newWeapon, ammo: infiniteAmmo ? nil : ammo)
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
        } else if enemies.isEmpty && boss == nil {
            nextWaveIn = 2.2
            if wave % 3 == 0 {
                let spot = arena.insetBy(dx: 90, dy: 90)
                dropWeapon(at: CGPoint(x: CGFloat.random(in: spot.minX...spot.maxX),
                                       y: CGFloat.random(in: spot.minY...spot.maxY)))
            }
            score += wave * 250
            hud.setScore(score)
            FX.popup("WAVE CLEAR  +\(wave * 250)", at: player.position + CGVector(dx: 0, dy: 30), color: Palette.acid, in: world)
            if !isDevRun {
                var progress = Store.progress
                progress.points += 1
                progress.pointsEarned += 1
                Store.progress = progress
                FX.popup("+1 UPGRADE POINT", at: player.position + CGVector(dx: 0, dy: 52), color: .white, in: world)
            }
        }
    }

    private func spawnEnemy(_ kind: Enemy.Kind) {
        let enemy = Enemy(kind: kind, wave: wave, difficulty: difficulty)
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
                desired = dir * e.moveSpeed
            case .hound:
                let wobble = CGFloat(sin(elapsed * 7 + Double(e.phase)))
                desired = (dir + dir.perpendicular * (wobble * 0.9)).normalized * e.moveSpeed
            case .enforcer:
                if dist > 280 {
                    desired = dir * e.moveSpeed
                } else if dist < 170 {
                    desired = dir * -e.moveSpeed
                } else {
                    let side: CGFloat = sin(e.phase) > 0 ? 1 : -1
                    desired = dir.perpendicular * (e.moveSpeed * 0.6 * side)
                }
                e.fireTimer -= dt
                if e.fireTimer <= 0 && dist < 520 && arena.contains(e.position) {
                    e.fireTimer = max(0.9, 2.0 - Double(wave) * 0.06) / Double(difficulty.tempo)
                    let shot = Bullet(enemyVelocity: dir * ((230 + CGFloat(min(wave, 12)) * 8) * difficulty.tempo))
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
                if !b.dead, let boss, !boss.dead, !boss.entering {
                    let id = ObjectIdentifier(boss)
                    if !b.hits.contains(id) && b.position.distance(to: boss.position) < b.radius + boss.radius {
                        if b.blastRadius > 0 {
                            b.dead = true
                            explode(at: b.position, radius: b.blastRadius, damage: b.damage)
                        } else {
                            hitBoss(damage: b.damage, at: b.position)
                            if b.pierces { b.hits.insert(id) } else { b.dead = true }
                        }
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

        if let boss, !boss.dead, boss.position.distance(to: player.position) < boss.radius * 0.85 + Player.radius {
            damagePlayer()
            player.velocity = (player.position - boss.position).normalized * 520
        }

        for p in pickups where !p.dead {
            guard p.position.distance(to: player.position) < Pickup.radius + Player.radius else { continue }
            p.dead = true
            switch p.kind {
            case .health:
                player.hp = min(player.maxHP, player.hp + 1)
                hud.setHP(player.hp, max: player.maxHP)
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
                hit(e, direction: away.normalized, damage: damage, knockScale: 3.5)
            }
        }
        if let boss, !boss.dead, !boss.entering, boss.position.distance(to: point) < radius + boss.radius {
            hitBoss(damage: damage, at: point)
        }
    }

    // MARK: Boss

    private func updateBoss(_ dt: TimeInterval) {
        guard let boss, !boss.dead else { return }
        let out = boss.update(dt, player: player.position, arena: arena)

        let bulletColor = boss.spec.color == .white ? Palette.blood : boss.spec.color
        for shot in out.shots {
            let b = Bullet(enemyVelocity: shot.velocity, color: bulletColor, big: boss.phase == 2)
            b.position = shot.position
            world.addChild(b)
            bullets.append(b)
        }
        if !out.shots.isEmpty { Audio.shared.play(.enemyShot, volume: 0.7) }

        for (i, kind) in out.summons.enumerated() {
            let enemy = Enemy(kind: kind, wave: wave, difficulty: difficulty)
            let a = CGFloat(i) / CGFloat(max(1, out.summons.count)) * .pi * 2
            enemy.position = boss.position + CGVector(angle: a, length: boss.radius + 30)
            world.addChild(enemy)
            enemies.append(enemy)
            FX.shockwave(at: enemy.position, color: kind.color, radius: 20, in: world)
        }

        if let phase = out.newPhase {
            FX.shockwave(at: boss.position, color: boss.spec.color, radius: boss.radius * 2, in: world)
            FX.popup(phase == 2 ? "ENRAGED" : "PHASE \(phase + 1)", at: boss.position + CGVector(dx: 0, dy: boss.radius + 20),
                     color: Palette.blood, in: world)
            Audio.shared.play(.wave, volume: 0.8)
            shake = max(shake, 12)
            Haptics.heavy()
        }
        if out.charged {
            Audio.shared.play(.rail)
            shake = max(shake, 6)
        }
        if out.blinked {
            FX.burst(at: boss.position, color: boss.spec.accent, count: 30, speed: 300, in: world)
            Audio.shared.play(.rocket)
        }
        if out.arrived {
            FX.shockwave(at: boss.position, color: boss.spec.color, radius: boss.radius * 1.8, in: world)
        }

        // Grunts don't get to stand inside their boss.
        for e in enemies where !e.dead {
            let delta = e.position - boss.position
            let minDist = boss.radius + e.kind.radius
            let d = delta.length
            if d > 0.01 && d < minDist {
                e.position += delta.normalized * (minDist - d)
            }
        }
    }

    private func hitBoss(damage: Int, at point: CGPoint) {
        guard let boss, !boss.dead else { return }
        boss.hp -= damage
        boss.flash()
        hud.setBossHP(CGFloat(boss.hp) / CGFloat(boss.maxHP))
        FX.burst(at: point, color: boss.spec.color, count: 3, speed: 150, in: world)
        Audio.shared.play(.hit, volume: 0.6)
        if boss.hp <= 0 { killBoss(boss) }
    }

    private func killBoss(_ b: Boss) {
        b.dead = true
        b.shutdown()
        boss = nil
        hud.setBossHP(0)

        // Loot: first kill of each boss permanently adds one max HP.
        if !isDevRun {
            let index = (wave / BossSpec.interval - 1) % BossSpec.roster.count
            var progress = Store.progress
            if !progress.bossesDefeated.contains(index) {
                progress.bossesDefeated.insert(index)
                Store.progress = progress
                if Store.settings.extraLivesEnabled {
                    player.maxHP += 1
                    player.hp += 1
                    hud.setHP(player.hp, max: player.maxHP)
                }
                FX.popup("MAX HP +1 UNLOCKED", at: player.position + CGVector(dx: 0, dy: 40), color: Palette.magenta, in: world)
                if index < Weapon.bossUnlocks.count {
                    let w = Weapon.bossUnlocks[index]
                    FX.popup("START WEAPON UNLOCKED: \(w.name)", at: player.position + CGVector(dx: 0, dy: 64), color: w.color, in: world)
                }
            }
        }

        // Their bullets fizzle with them.
        for bullet in bullets where !bullet.friendly && !bullet.dead {
            bullet.dead = true
            FX.burst(at: bullet.position, color: b.spec.color, count: 2, speed: 60, in: world)
        }

        let points = 2500 * (wave / BossSpec.interval)
        score += points
        hud.setScore(score)
        FX.popup("\(b.spec.name) DOWN  +\(points)", at: b.position + CGVector(dx: 0, dy: b.radius + 24),
                 color: Palette.acid, in: world)

        // Chain of explosions, then the big one.
        hitStop = 0.18
        shake = 30
        Haptics.death()
        Audio.shared.play(.bigExplode)
        var chain: [SKAction] = []
        for i in 0..<8 {
            chain.append(.run { [weak self, weak b] in
                guard let self, let b else { return }
                let offset = CGVector(angle: CGFloat.random(in: 0...(.pi * 2)), length: CGFloat.random(in: 0...b.radius))
                let colors = [b.spec.color, b.spec.accent, Palette.amber, .white]
                FX.burst(at: b.position + offset, color: colors[i % colors.count], count: 40, speed: 320, in: self.world)
                FX.shockwave(at: b.position + offset, color: b.spec.accent, radius: b.radius * 0.7, in: self.world)
                self.shake = max(self.shake, 12)
                Audio.shared.play(.explode, volume: 0.8)
                Haptics.heavy()
            })
            chain.append(.wait(forDuration: 0.12))
        }
        chain.append(.run { [weak self, weak b] in
            guard let self, let b else { return }
            FX.burst(at: b.position, color: .white, count: 160, speed: 620, in: self.world)
            FX.burst(at: b.position, color: b.spec.color, count: 120, speed: 420, in: self.world)
            FX.shockwave(at: b.position, color: b.spec.color, radius: b.radius * 3, in: self.world)
            FX.shockwave(at: b.position, color: .white, radius: b.radius * 5, in: self.world)
            self.shake = 34
            self.damageFlash?.removeAllActions()
            self.damageFlash?.color = .white
            self.damageFlash?.alpha = 0.45
            self.damageFlash?.run(.sequence([.fadeOut(withDuration: 0.5), .run { [weak self] in self?.damageFlash?.color = Palette.blood }]))
            Audio.shared.play(.bigExplode)
            Haptics.death()
            self.hud.hideBossBar()
        })
        chain.append(.removeFromParent())
        b.run(.group([
            .sequence(chain),
            .sequence([.wait(forDuration: 0.9), .fadeOut(withDuration: 0.1)]),
            .repeat(.sequence([.moveBy(x: 6, y: 0, duration: 0.03), .moveBy(x: -6, y: 0, duration: 0.03)]), count: 16),
        ]))
    }

    private func dropWeapon(at point: CGPoint) {
        let options = Weapon.drops.filter { $0 != weapon && $0 != baseWeapon }
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
        guard state == .playing, player.invulnerable <= 0, !godMode else { return }
        player.hp -= 1
        player.invulnerable = 1.2
        hud.setHP(player.hp, max: player.maxHP)

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
