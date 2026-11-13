import SpriteKit
import CoreImage
import UIKit
import QuartzCore

/// Screen-space overlay: score, combo, wave, health, and the title / game-over cards.
final class HUD: SKNode {
    private let scoreLabel = HUD.label("0", size: 26, color: .white)
    private let comboLabel = HUD.label("", size: 18, color: Palette.acid)
    private let waveLabel = HUD.label("", size: 18, color: Palette.cyan)
    private let weaponLabel = HUD.label("", size: 16, color: Palette.magenta)
    private let hpNode = SKNode()

    private let bannerNode = SKNode()
    private let bannerTitle = HUD.label("", size: 44, color: Palette.magenta, font: Fonts.display)
    private let bannerSub = HUD.label("", size: 15, color: Palette.cyan)

    private let titleCard = SKNode()
    private let titleBest = HUD.label("", size: 14, color: SKColor.white.withAlphaComponent(0.6))
    private let helpButton = SKNode()
    private let helpPanel = HelpPanel()
    private static let helpButtonRadius: CGFloat = 20

    var isHelpVisible: Bool { !helpPanel.isHidden }

    private let gameOverCard = SKNode()
    private let goScore = HUD.label("", size: 30, color: .white)
    private let goDetail = HUD.label("", size: 15, color: Palette.cyan)
    private let goPrompt = HUD.label("TAP TO GO AGAIN", size: 17, color: .white)

    private var gameplayNodes: [SKNode] { [scoreLabel, comboLabel, waveLabel, weaponLabel, hpNode] }

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

        buildTitleCard()
        buildGameOverCard()
        buildHelpButton()

        helpPanel.zPosition = 30
        addChild(helpPanel)
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

    private func buildTitleCard() {
        let title = HUD.neonText("GUTTERLIGHT", size: 72, color: Palette.magenta)
        title.position = CGPoint(x: 0, y: 60)
        title.run(FX.flicker())

        let sub = HUD.label("A NEO-NOIR PUNK RIOT", size: 16, color: Palette.cyan)
        sub.position = CGPoint(x: 0, y: 6)

        let prompt = HUD.label("TAP TO RIOT", size: 20, color: .white)
        prompt.position = CGPoint(x: 0, y: -52)
        prompt.run(.repeatForever(.sequence([.fadeAlpha(to: 0.25, duration: 0.6), .fadeAlpha(to: 1, duration: 0.6)])))

        let controls = HUD.label("LEFT THUMB: MOVE   ·   RIGHT THUMB: AIM + FIRE", size: 12,
                                 color: SKColor.white.withAlphaComponent(0.5))
        controls.position = CGPoint(x: 0, y: -92)

        titleBest.position = CGPoint(x: 0, y: -118)

        for (i, n) in ([title, sub, prompt, controls, titleBest] as [SKNode]).enumerated() {
            n.zPosition = CGFloat(i)
            titleCard.addChild(n)
        }
        titleCard.zPosition = 10
        titleCard.isHidden = true
        addChild(titleCard)
    }

    private func buildHelpButton() {
        let ring = SKShapeNode(circleOfRadius: HUD.helpButtonRadius)
        ring.strokeColor = Palette.cyan
        ring.fillColor = Palette.cyan.withAlphaComponent(0.1)
        ring.lineWidth = 2
        ring.glowWidth = 3
        ring.zPosition = 0
        helpButton.addChild(ring)

        let mark = HUD.label("?", size: 24, color: .white, font: Fonts.display)
        mark.zPosition = 1
        helpButton.addChild(mark)

        helpButton.zPosition = 20
        helpButton.isHidden = true
        helpButton.run(FX.flicker())
        addChild(helpButton)
    }

    private func buildGameOverCard() {
        let title = HUD.neonText("FLATLINED", size: 64, color: Palette.blood)
        title.position = CGPoint(x: 0, y: 70)

        let quip = HUD.label("THE CITY WINS. FOR NOW.", size: 14, color: SKColor.white.withAlphaComponent(0.55))
        quip.position = CGPoint(x: 0, y: 22)

        goScore.position = CGPoint(x: 0, y: -16)
        goDetail.position = CGPoint(x: 0, y: -50)
        goPrompt.position = CGPoint(x: 0, y: -96)
        goPrompt.run(.repeatForever(.sequence([.fadeAlpha(to: 0.25, duration: 0.6), .fadeAlpha(to: 1, duration: 0.6)])))

        for (i, n) in ([title, quip, goScore, goDetail, goPrompt] as [SKNode]).enumerated() {
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
        waveLabel.position = CGPoint(x: right, y: top)
        weaponLabel.position = CGPoint(x: right, y: top - 28)
        hpNode.position = CGPoint(x: 0, y: top)

        helpButton.position = CGPoint(x: right - HUD.helpButtonRadius, y: top - 4)
        helpPanel.build(for: size)

        let cardScale = min(1, size.width / 760, size.height / 380)
        titleCard.setScale(cardScale)
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

    func setWeapon(_ weapon: Weapon, ammo: Int) {
        weaponLabel.text = weapon.ammo > 0 ? "\(weapon.name)  \(ammo)" : weapon.name
        weaponLabel.fontColor = weapon.color
        let low = weapon.ammo > 0 && ammo <= max(3, weapon.ammo / 6)
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

    func showTitle(best: Int) {
        titleBest.text = best > 0 ? "BEST  \(best.formatted())" : ""
        titleCard.isHidden = false
        helpButton.isHidden = false
        helpPanel.isHidden = true
        gameOverCard.isHidden = true
        gameplayNodes.forEach { $0.isHidden = true }
    }

    func showGameOver(score: Int, best: Int, wave: Int, newBest: Bool) {
        goScore.text = score.formatted()
        goDetail.text = newBest ? "NEW BEST  ·  WAVE \(wave)" : "BEST \(best.formatted())  ·  WAVE \(wave)"
        goDetail.fontColor = newBest ? Palette.acid : Palette.cyan
        goPrompt.isHidden = true
        gameOverCard.isHidden = false
        gameOverCard.alpha = 0
        gameOverCard.run(.fadeIn(withDuration: 0.5))
        bannerNode.removeAllActions()
        bannerNode.alpha = 0
    }

    // MARK: Help

    /// `point` is in HUD (camera) space. Generous hit area for thumbs.
    func helpButtonContains(_ point: CGPoint) -> Bool {
        !helpButton.isHidden && point.distance(to: helpButton.position) < HUD.helpButtonRadius + 22
    }

    func showHelp() {
        helpPanel.isHidden = false
        helpPanel.alpha = 0
        helpPanel.run(.fadeIn(withDuration: 0.15))
        helpButton.isHidden = true
        titleCard.isHidden = true
    }

    func hideHelp() {
        helpPanel.isHidden = true
        helpButton.isHidden = false
        titleCard.isHidden = false
    }

    func enableGameOverPrompt() {
        goPrompt.isHidden = false
    }

    func showGameplay() {
        titleCard.isHidden = true
        helpButton.isHidden = true
        helpPanel.isHidden = true
        gameOverCard.isHidden = true
        gameplayNodes.forEach { $0.isHidden = false }
    }
}
