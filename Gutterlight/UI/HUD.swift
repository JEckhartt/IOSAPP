import SpriteKit
import CoreImage
import UIKit
import QuartzCore

/// Screen-space overlay: score, combo, wave, health, boss bar, banners and the game-over card.
final class HUD: SKNode {
    private let scoreLabel = HUD.label("0", size: 26, color: .white)
    private let comboLabel = HUD.label("", size: 18, color: Palette.acid)
    private let waveLabel = HUD.label("", size: 18, color: Palette.cyan)
    private let weaponLabel = HUD.label("", size: 16, color: Palette.magenta)
    private let hpNode = SKNode()

    private let bannerNode = SKNode()
    private let bannerTitle = HUD.label("", size: 44, color: Palette.magenta, font: Fonts.display)
    private let bannerSub = HUD.label("", size: 15, color: Palette.cyan)

    private let bossBar = SKNode()
    private let bossFill = SKSpriteNode(color: Palette.blood, size: CGSize(width: 1, height: 8))
    private let bossName = HUD.label("", size: 14, color: .white, font: Fonts.display)
    private static let bossBarWidth: CGFloat = 320
    private let devTag = HUD.label("", size: 11, color: Palette.blood, font: Fonts.display)

    private let gameOverCard = SKNode()
    private let goScore = HUD.label("", size: 30, color: .white)
    private let goDetail = HUD.label("", size: 15, color: Palette.cyan)
    private let retryButton = MenuButton("RETRY", width: 170, height: 42, color: Palette.magenta, fontSize: 20)
    private let menuButton = MenuButton("MENU", width: 170, height: 42, color: Palette.cyan, fontSize: 20)

    enum GameOverChoice { case retry, menu }
    enum PauseChoice { case resume, menu }

    private let pauseButton = SKNode()
    private static let pauseRadius: CGFloat = 17
    private let pauseCard = SKNode()
    private let resumeButton = MenuButton("RESUME", width: 220, height: 44, color: Palette.magenta, fontSize: 20)
    private let quitButton = MenuButton("MAIN MENU", width: 220, height: 44, color: Palette.cyan, fontSize: 20)

    private var gameplayNodes: [SKNode] { [scoreLabel, comboLabel, waveLabel, weaponLabel, hpNode, devTag, pauseButton] }

    override init() {
        super.init()

        scoreLabel.horizontalAlignmentMode = .left
        comboLabel.horizontalAlignmentMode = .left
        waveLabel.horizontalAlignmentMode = .right
        weaponLabel.horizontalAlignmentMode = .right
        for node in gameplayNodes {
            node.zPosition = 1
            addChild(node)
        }

        bannerTitle.position = CGPoint(x: 0, y: 30)
        bannerSub.position = CGPoint(x: 0, y: -8)
        bannerNode.addChild(bannerTitle)
        bannerNode.addChild(bannerSub)
        bannerNode.alpha = 0
        bannerNode.zPosition = 2
        addChild(bannerNode)

        buildGameOverCard()
        buildBossBar()
        buildPause()
    }

    private func buildPause() {
        let ring = SKShapeNode(circleOfRadius: HUD.pauseRadius)
        ring.strokeColor = SKColor.white.withAlphaComponent(0.7)
        ring.fillColor = SKColor.black.withAlphaComponent(0.3)
        ring.lineWidth = 2
        ring.zPosition = 0
        pauseButton.addChild(ring)
        for x in [-4.5, 4.5] as [CGFloat] {
            let bar = SKShapeNode(rectOf: CGSize(width: 4, height: 14), cornerRadius: 1)
            bar.fillColor = .white
            bar.strokeColor = .clear
            bar.position = CGPoint(x: x, y: 0)
            bar.zPosition = 1
            pauseButton.addChild(bar)
        }
        pauseButton.zPosition = 5

        let dim = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.7), size: CGSize(width: 4000, height: 4000))
        dim.zPosition = 0
        pauseCard.addChild(dim)
        let title = HUD.neonText("PAUSED", size: 56, color: Palette.magenta)
        title.position = CGPoint(x: 0, y: 80)
        title.zPosition = 1
        pauseCard.addChild(title)
        resumeButton.position = CGPoint(x: 0, y: 6)
        resumeButton.zPosition = 1
        pauseCard.addChild(resumeButton)
        quitButton.position = CGPoint(x: 0, y: -52)
        quitButton.zPosition = 1
        pauseCard.addChild(quitButton)
        let note = HUD.label("QUITTING ENDS THIS RUN. POINTS ALREADY EARNED ARE KEPT.", size: 11,
                             color: SKColor.white.withAlphaComponent(0.5))
        note.position = CGPoint(x: 0, y: -96)
        note.zPosition = 1
        pauseCard.addChild(note)
        pauseCard.zPosition = 40
        pauseCard.isHidden = true
        addChild(pauseCard)
    }

    // MARK: Pause

    func pauseButtonHit(_ touch: UITouch) -> Bool {
        guard pauseButton.isVisibleInTree else { return false }
        return touch.location(in: self).distance(to: pauseButton.position) < HUD.pauseRadius + 20
    }

    func showPause() {
        pauseCard.isHidden = false
        pauseCard.alpha = 0
        pauseCard.run(.fadeIn(withDuration: 0.12))
    }

    func hidePause() {
        pauseCard.isHidden = true
    }

    func pauseChoice(for touch: UITouch) -> PauseChoice? {
        if resumeButton.hitTest(touch) { resumeButton.press(); return .resume }
        if quitButton.hitTest(touch) { quitButton.press(); return .menu }
        return nil
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: Building

    static func label(_ text: String, size: CGFloat, color: SKColor, font: String = Fonts.mono) -> SKLabelNode {
        let l = SKLabelNode(fontNamed: font)
        l.text = text
        l.fontSize = size
        l.fontColor = color
        l.verticalAlignmentMode = .center
        l.horizontalAlignmentMode = .center
        return l
    }

    /// Text with a blurred halo behind it.
    static func neonText(_ text: String, size: CGFloat, color: SKColor) -> SKNode {
        let node = SKNode()

        let glow = SKEffectNode()
        glow.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 12])
        glow.shouldRasterize = true
        glow.zPosition = 0
        glow.addChild(label(text, size: size, color: color, font: Fonts.display))
        node.addChild(glow)

        let main = label(text, size: size, color: color, font: Fonts.display)
        main.zPosition = 1
        node.addChild(main)

        let core = label(text, size: size, color: SKColor.white.withAlphaComponent(0.35), font: Fonts.display)
        core.zPosition = 2
        node.addChild(core)
        return node
    }

    private func buildBossBar() {
        let w = HUD.bossBarWidth
        let frame = SKShapeNode(rectOf: CGSize(width: w + 6, height: 14), cornerRadius: 3)
        frame.strokeColor = SKColor.white.withAlphaComponent(0.6)
        frame.fillColor = SKColor.black.withAlphaComponent(0.5)
        frame.lineWidth = 1.5
        frame.zPosition = 0
        bossBar.addChild(frame)

        bossFill.anchorPoint = CGPoint(x: 0, y: 0.5)
        bossFill.position = CGPoint(x: -w / 2, y: 0)
        bossFill.zPosition = 1
        bossBar.addChild(bossFill)

        bossName.position = CGPoint(x: 0, y: 18)
        bossName.zPosition = 1
        bossBar.addChild(bossName)

        bossBar.zPosition = 3
        bossBar.isHidden = true
        addChild(bossBar)
    }

    private func buildGameOverCard() {
        let title = HUD.neonText("FLATLINED", size: 64, color: Palette.blood)
        title.position = CGPoint(x: 0, y: 70)

        let quip = HUD.label("THE CITY WINS. FOR NOW.", size: 14, color: SKColor.white.withAlphaComponent(0.55))
        quip.position = CGPoint(x: 0, y: 22)

        goScore.position = CGPoint(x: 0, y: -16)
        goDetail.position = CGPoint(x: 0, y: -50)
        retryButton.position = CGPoint(x: -100, y: -104)
        menuButton.position = CGPoint(x: 100, y: -104)

        for (i, n) in ([title, quip, goScore, goDetail, retryButton, menuButton] as [SKNode]).enumerated() {
            n.zPosition = CGFloat(i)
            gameOverCard.addChild(n)
        }
        gameOverCard.zPosition = 10
        gameOverCard.isHidden = true
        addChild(gameOverCard)
    }

    // MARK: Layout

    func layout(for size: CGSize, insets: UIEdgeInsets) {
        let left = -size.width / 2 + max(insets.left, 24)
        let right = size.width / 2 - max(insets.right, 24)
        let top = size.height / 2 - max(insets.top, 18) - 16

        scoreLabel.position = CGPoint(x: left, y: top)
        comboLabel.position = CGPoint(x: left, y: top - 28)
        pauseButton.position = CGPoint(x: right - HUD.pauseRadius, y: top - 4)
        waveLabel.position = CGPoint(x: right - HUD.pauseRadius * 2 - 14, y: top)
        weaponLabel.position = CGPoint(x: right - HUD.pauseRadius * 2 - 14, y: top - 28)
        hpNode.position = CGPoint(x: 0, y: top)
        devTag.position = CGPoint(x: 0, y: top - 20)

        bossBar.position = CGPoint(x: 0, y: top - 52)
        bossBar.setScale(max(0.45, min(1, (right - left - 360) / HUD.bossBarWidth)))
        let cardScale = min(1, size.width / 760, size.height / 380)
        pauseCard.setScale(cardScale)
        gameOverCard.setScale(cardScale)
        bannerNode.setScale(cardScale)
    }

    // MARK: Gameplay readouts

    func setScore(_ score: Int) {
        scoreLabel.text = score.formatted()
    }

    func setCombo(_ multiplier: Int) {
        comboLabel.text = multiplier > 1 ? "x\(multiplier) COMBO" : ""
        if multiplier > 1 {
            comboLabel.removeAction(forKey: "pop")
            comboLabel.setScale(1.3)
            comboLabel.run(.scale(to: 1, duration: 0.12), withKey: "pop")
        }
    }

    func setWave(_ wave: Int) {
        waveLabel.text = wave > 0 ? "WAVE \(wave)" : ""
    }

    /// `ammo == nil` means infinite (the run's start weapon).
    func setWeapon(_ weapon: Weapon, ammo: Int?) {
        weaponLabel.text = ammo.map { "\(weapon.name)  \($0)" } ?? "\(weapon.name)  ∞"
        weaponLabel.fontColor = weapon.color
        let low = ammo.map { $0 <= max(3, weapon.ammo / 6) } ?? false
        weaponLabel.alpha = low && Int(CACurrentMediaTime() * 8) % 2 == 0 ? 0.35 : 1
    }

    func flashWeapon() {
        weaponLabel.removeAction(forKey: "pop")
        weaponLabel.setScale(1.5)
        weaponLabel.run(.scale(to: 1, duration: 0.2), withKey: "pop")
    }

    func setHP(_ hp: Int, max maxHP: Int) {
        hpNode.removeAllChildren()
        let spacing: CGFloat = 24
        let startX = -CGFloat(maxHP - 1) * spacing / 2
        for i in 0..<maxHP {
            let pip = SKShapeNode(rectOf: CGSize(width: 18, height: 8), cornerRadius: 2)
            pip.strokeColor = Palette.magenta
            pip.lineWidth = 1.5
            pip.fillColor = i < hp ? Palette.magenta : .clear
            pip.glowWidth = i < hp ? 2 : 0
            pip.position = CGPoint(x: startX + CGFloat(i) * spacing, y: 0)
            hpNode.addChild(pip)
        }
    }

    func banner(_ title: String, sub: String) {
        bannerTitle.text = title
        bannerSub.text = sub
        bannerNode.removeAllActions()
        bannerNode.alpha = 0
        bannerNode.run(.sequence([
            .fadeIn(withDuration: 0.15),
            .wait(forDuration: 1.5),
            .fadeOut(withDuration: 0.4),
        ]))
    }

    // MARK: Cards

    /// Hide everything gameplay-related (the main menu takes over the screen).
    func showMenuMode() {
        gameOverCard.isHidden = true
        pauseCard.isHidden = true
        bannerNode.removeAllActions()
        bannerNode.alpha = 0
        hideBossBar()
        gameplayNodes.forEach { $0.isHidden = true }
    }

    func showGameOver(score: Int, best: Int, wave: Int, newBest: Bool, devRun: Bool) {
        goScore.text = score.formatted()
        if devRun {
            goDetail.text = "DEV RUN  ·  WAVE \(wave)  ·  NOT SAVED"
            goDetail.fontColor = Palette.blood
        } else {
            goDetail.text = newBest ? "NEW BEST  ·  WAVE \(wave)" : "BEST \(best.formatted())  ·  WAVE \(wave)"
            goDetail.fontColor = newBest ? Palette.acid : Palette.cyan
        }
        retryButton.isHidden = true
        menuButton.isHidden = true
        gameOverCard.isHidden = false
        gameOverCard.alpha = 0
        gameOverCard.run(.fadeIn(withDuration: 0.5))
        bannerNode.removeAllActions()
        bannerNode.alpha = 0
    }

    func enableGameOverButtons() {
        retryButton.isHidden = false
        menuButton.isHidden = false
    }

    func gameOverChoice(for touch: UITouch) -> GameOverChoice? {
        if retryButton.hitTest(touch) { retryButton.press(); return .retry }
        if menuButton.hitTest(touch) { menuButton.press(); return .menu }
        return nil
    }

    func setDevTag(_ text: String?) {
        devTag.text = text ?? ""
    }

    // MARK: Boss bar

    func showBossBar(name: String, color: SKColor) {
        bossName.text = name
        bossName.fontColor = color
        bossFill.color = color == .white ? Palette.blood : color
        bossFill.size = CGSize(width: HUD.bossBarWidth, height: 8)
        bossBar.isHidden = false
        bossBar.alpha = 0
        bossBar.run(.fadeIn(withDuration: 0.4))
    }

    func setBossHP(_ fraction: CGFloat) {
        bossFill.size = CGSize(width: max(0, fraction) * HUD.bossBarWidth, height: 8)
    }

    func hideBossBar() {
        bossBar.removeAllActions()
        bossBar.isHidden = true
    }

    func showGameplay() {
        gameOverCard.isHidden = true
        gameplayNodes.forEach { $0.isHidden = false }
    }
}
