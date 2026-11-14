import SpriteKit
import UIKit

/// Start screen: PLAY, HIGH SCORES, UNLOCKS, DEVELOPER, difficulty slider and the ? help overlay.
final class MainMenu: SKNode {
    enum Page { case main, scores, unlocks, dev, help }

    /// Start a normal run from wave 1.
    var onPlay: () -> Void = {}
    /// Developer skip: start a (dev) run directly at this wave.
    var onSkipToWave: (Int) -> Void = { _ in }

    private static let design = CGSize(width: 760, height: 380)

    private var page: Page = .main
    private let canvas = SKNode()
    private let mainPage = SKNode()
    private let scoresPage = SKNode()
    private let unlocksPage = SKNode()
    private let devPage = SKNode()
    private let help = HelpPanel()
    private let helpButton = SKNode()
    private static let helpRadius: CGFloat = 20
    private var buttons: [Page: [MenuButton]] = [:]

    // Main
    private let slider = DifficultySlider()
    private let unlocksButton = MenuButton("UNLOCKS", color: Palette.acid)
    private let godTag = HUD.label("GOD MODE ON", size: 12, color: Palette.blood, font: Fonts.display)

    // Scores
    private let scoreRows = SKNode()

    // Unlocks
    private let pointsLabel = HUD.label("", size: 20, color: Palette.acid, font: Fonts.display)
    private let spitterValue = HUD.label("", size: 14, color: .white)
    private let spitterMinus = MenuButton("−", width: 46, height: 34, color: Palette.cyan, fontSize: 22)
    private let spitterPlus = MenuButton("+", width: 46, height: 34, color: Palette.acid, fontSize: 22)
    private let livesValue = HUD.label("", size: 14, color: .white)
    private let livesToggle = MenuButton("ON", width: 100, height: 34, color: Palette.acid, fontSize: 16)
    private let bossIcons = SKNode()

    // Dev
    private let godToggle = MenuButton("GOD MODE: OFF", width: 280, height: 40, color: Palette.blood)

    override init() {
        super.init()
        canvas.zPosition = 1
        addChild(canvas)
        for p in [mainPage, scoresPage, unlocksPage, devPage] {
            p.zPosition = 1
            canvas.addChild(p)
        }
        buildMain()
        buildScores()
        buildUnlocks()
        buildDev()
        buildHelpButton()

        help.zPosition = 50
        addChild(help)
        go(.main)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: Layout

    func layout(for size: CGSize, insets: UIEdgeInsets) {
        canvas.setScale(min(1, size.width / MainMenu.design.width, size.height / MainMenu.design.height))
        let right = size.width / 2 - max(insets.right, 24)
        let top = size.height / 2 - max(insets.top, 18) - 16
        helpButton.position = CGPoint(x: right - MainMenu.helpRadius, y: top - 4)
        help.build(for: size)
        if page == .help { help.isHidden = false }
    }

    func show() {
        isHidden = false
        go(.main)
    }

    func hide() {
        isHidden = true
    }

    private func go(_ p: Page) {
        page = p
        mainPage.isHidden = p != .main
        scoresPage.isHidden = p != .scores
        unlocksPage.isHidden = p != .unlocks
        devPage.isHidden = p != .dev
        help.isHidden = p != .help
        helpButton.isHidden = p != .main
        canvas.isHidden = p == .help

        switch p {
        case .main: refreshMain()
        case .scores: refreshScores()
        case .unlocks: refreshUnlocks()
        case .dev: refreshDev()
        case .help:
            help.alpha = 0
            help.run(.fadeIn(withDuration: 0.15))
        }
    }

    // MARK: Touches

    func touchesBegan(_ touches: Set<UITouch>) {
        guard let touch = touches.first else { return }
        if page == .help {
            go(.main)
            return
        }
        if page == .main, !helpButton.isHidden,
           touch.location(in: self).distance(to: helpButton.position) < MainMenu.helpRadius + 22 {
            Audio.shared.play(.pickup, volume: 0.6)
            go(.help)
            return
        }
        for b in buttons[page] ?? [] where b.hitTest(touch) {
            b.press()
            return
        }
        if page == .main { _ = slider.touchBegan(touch) }
    }

    func touchesMoved(_ touches: Set<UITouch>) {
        touches.forEach { slider.touchMoved($0) }
    }

    func touchesEnded(_ touches: Set<UITouch>) {
        touches.forEach { slider.touchEnded($0) }
    }

    // MARK: Helpers

    private func add(_ button: MenuButton, to page: Page, at point: CGPoint, in parent: SKNode) {
        button.position = point
        button.zPosition = 2
        parent.addChild(button)
        buttons[page, default: []].append(button)
    }

    private func text(_ s: String, size: CGFloat, color: SKColor, at point: CGPoint, in parent: SKNode,
                      font: String = Fonts.mono, align: SKLabelHorizontalAlignmentMode = .center) -> SKLabelNode {
        let l = HUD.label(s, size: size, color: color, font: font)
        l.horizontalAlignmentMode = align
        l.position = point
        l.zPosition = 2
        parent.addChild(l)
        return l
    }

    private func panel(in parent: SKNode) {
        let bg = SKShapeNode(rectOf: CGSize(width: 740, height: 370), cornerRadius: 14)
        bg.fillColor = SKColor.black.withAlphaComponent(0.78)
        bg.strokeColor = SKColor.white.withAlphaComponent(0.12)
        bg.lineWidth = 1.5
        bg.zPosition = 0
        parent.addChild(bg)
    }

    private func title(_ s: String, color: SKColor, in parent: SKNode) {
        let t = HUD.neonText(s, size: 38, color: color)
        t.position = CGPoint(x: 0, y: 145)
        t.zPosition = 2
        parent.addChild(t)
    }

    private func backButton(for page: Page, in parent: SKNode) {
        add(MenuButton("BACK", width: 160, height: 36, color: .white, fontSize: 16) { [weak self] in self?.go(.main) },
            to: page, at: CGPoint(x: 0, y: -158), in: parent)
    }

    // MARK: Main page

    private func buildMain() {
        let t = HUD.neonText("GUTTERLIGHT", size: 64, color: Palette.magenta)
        t.position = CGPoint(x: 0, y: 128)
        t.zPosition = 2
        t.run(FX.flicker())
        mainPage.addChild(t)
        _ = text("A NEO-NOIR PUNK RIOT", size: 14, color: Palette.cyan, at: CGPoint(x: 0, y: 86), in: mainPage)

        godTag.position = CGPoint(x: 0, y: 66)
        godTag.zPosition = 2
        mainPage.addChild(godTag)

        add(MenuButton("PLAY", width: 260, height: 46, color: Palette.magenta, fontSize: 24) { [weak self] in self?.onPlay() },
            to: .main, at: CGPoint(x: 0, y: 34), in: mainPage)
        add(MenuButton("HIGH SCORES", color: Palette.cyan) { [weak self] in self?.go(.scores) },
            to: .main, at: CGPoint(x: 0, y: -16), in: mainPage)
        unlocksButton.action = { [weak self] in self?.go(.unlocks) }
        add(unlocksButton, to: .main, at: CGPoint(x: 0, y: -62), in: mainPage)
        add(MenuButton("DEVELOPER", width: 180, height: 30, color: SKColor.white.withAlphaComponent(0.6), fontSize: 13) { [weak self] in self?.go(.dev) },
            to: .main, at: CGPoint(x: 0, y: -103), in: mainPage)

        slider.position = CGPoint(x: 0, y: -160)
        slider.zPosition = 2
        slider.onChange = { d in
            var s = Store.settings
            s.difficulty = d
            Store.settings = s
        }
        mainPage.addChild(slider)
        buttons[.main, default: []] += [slider.minus, slider.plus]
    }

    private func refreshMain() {
        let settings = Store.settings
        slider.set(settings.difficulty)
        godTag.isHidden = !settings.godMode
        let pts = Store.progress.points
        unlocksButton.setTitle(pts > 0 ? "UNLOCKS  ·  \(pts) PTS" : "UNLOCKS")
    }

    private func buildHelpButton() {
        let ring = SKShapeNode(circleOfRadius: MainMenu.helpRadius)
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
        helpButton.run(FX.flicker())
        addChild(helpButton)
    }

    // MARK: High scores

    private func buildScores() {
        panel(in: scoresPage)
        title("HIGH SCORES", color: Palette.cyan, in: scoresPage)
        scoreRows.zPosition = 2
        scoresPage.addChild(scoreRows)
        backButton(for: .scores, in: scoresPage)
    }

    private func refreshScores() {
        scoreRows.removeAllChildren()
        let scores = Store.scores
        guard !scores.isEmpty else {
            _ = text("NO SCORES YET. GO MAKE SOME NOISE.", size: 15, color: SKColor.white.withAlphaComponent(0.6),
                     at: .zero, in: scoreRows)
            return
        }
        let dim = SKColor.white.withAlphaComponent(0.45)
        let headerY: CGFloat = 104
        _ = text("#", size: 11, color: dim, at: CGPoint(x: -250, y: headerY), in: scoreRows, align: .left)
        _ = text("SCORE", size: 11, color: dim, at: CGPoint(x: -20, y: headerY), in: scoreRows, align: .right)
        _ = text("WAVE", size: 11, color: dim, at: CGPoint(x: 30, y: headerY), in: scoreRows, align: .left)
        _ = text("DIFFICULTY", size: 11, color: dim, at: CGPoint(x: 110, y: headerY), in: scoreRows, align: .left)
        _ = text("DATE", size: 11, color: dim, at: CGPoint(x: 240, y: headerY), in: scoreRows, align: .left)

        let df = DateFormatter()
        df.dateFormat = "d MMM yy"
        df.locale = Locale(identifier: "en_US")
        for (i, s) in scores.enumerated() {
            let y = 82 - CGFloat(i) * 22
            let c: SKColor = i == 0 ? Palette.acid : .white
            _ = text("\(i + 1).", size: 14, color: c, at: CGPoint(x: -250, y: y), in: scoreRows, align: .left)
            _ = text(s.score.formatted(), size: 14, color: c, at: CGPoint(x: -20, y: y), in: scoreRows, align: .right)
            _ = text(s.wave > 0 ? "\(s.wave)" : "–", size: 14, color: c, at: CGPoint(x: 30, y: y), in: scoreRows, align: .left)
            let d = Difficulty(steps: s.difficulty / 10)
            let dc: SKColor = s.difficulty == 0 ? c : (s.difficulty > 0 ? Palette.blood : Palette.cyan)
            _ = text(d.label, size: 14, color: dc, at: CGPoint(x: 110, y: y), in: scoreRows, align: .left)
            _ = text(df.string(from: s.date).uppercased(), size: 14, color: dim, at: CGPoint(x: 240, y: y), in: scoreRows, align: .left)
        }
    }

    // MARK: Unlocks

    private func buildUnlocks() {
        panel(in: unlocksPage)
        title("UNLOCKS", color: Palette.acid, in: unlocksPage)

        pointsLabel.position = CGPoint(x: 0, y: 96)
        pointsLabel.zPosition = 2
        unlocksPage.addChild(pointsLabel)
        _ = text("+1 POINT FOR EVERY WAVE YOU SURVIVE", size: 11, color: SKColor.white.withAlphaComponent(0.55),
                 at: CGPoint(x: 0, y: 74), in: unlocksPage)

        // SPITTER damage
        _ = text("SPITTER DAMAGE", size: 18, color: Palette.magenta, at: CGPoint(x: -320, y: 30), in: unlocksPage,
                 font: Fonts.display, align: .left)
        spitterValue.horizontalAlignmentMode = .left
        spitterValue.position = CGPoint(x: -80, y: 30)
        spitterValue.zPosition = 2
        unlocksPage.addChild(spitterValue)
        spitterMinus.action = { [weak self] in self?.changeSpitter(-1) }
        spitterPlus.action = { [weak self] in self?.changeSpitter(1) }
        add(spitterMinus, to: .unlocks, at: CGPoint(x: 220, y: 30), in: unlocksPage)
        add(spitterPlus, to: .unlocks, at: CGPoint(x: 280, y: 30), in: unlocksPage)

        // Extra lives
        _ = text("EXTRA LIVES", size: 18, color: Palette.blood, at: CGPoint(x: -320, y: -24), in: unlocksPage,
                 font: Fonts.display, align: .left)
        livesValue.horizontalAlignmentMode = .left
        livesValue.position = CGPoint(x: -80, y: -24)
        livesValue.zPosition = 2
        unlocksPage.addChild(livesValue)
        livesToggle.action = { [weak self] in
            var s = Store.settings
            s.extraLivesEnabled.toggle()
            Store.settings = s
            self?.refreshUnlocks()
        }
        add(livesToggle, to: .unlocks, at: CGPoint(x: 250, y: -24), in: unlocksPage)

        bossIcons.zPosition = 2
        unlocksPage.addChild(bossIcons)
        _ = text("EACH BOSS BEATEN = +1 MAX HP", size: 11, color: SKColor.white.withAlphaComponent(0.55),
                 at: CGPoint(x: 0, y: -112), in: unlocksPage)

        backButton(for: .unlocks, in: unlocksPage)
    }

    private func changeSpitter(_ delta: Int) {
        var p = Store.progress
        if delta > 0 {
            guard p.points > 0 else { return }
            p.points -= 1
            p.spitterBonus += 1
        } else {
            guard p.spitterBonus > 0 else { return }
            p.points += 1
            p.spitterBonus -= 1
        }
        Store.progress = p
        refreshUnlocks()
    }

    private func refreshUnlocks() {
        let p = Store.progress
        let s = Store.settings
        pointsLabel.text = "UPGRADE POINTS  \(p.points)"

        if p.spitterUnlocked {
            let dmg = Weapon.spitter.damage + p.spitterBonus
            spitterValue.text = "DMG \(dmg)" + (p.spitterBonus > 0 ? "   (+\(p.spitterBonus))" : "")
            spitterValue.fontColor = .white
            spitterMinus.isEnabled = p.spitterBonus > 0
            spitterPlus.isEnabled = p.points > 0
        } else {
            spitterValue.text = "SURVIVE WAVE 1 TO UNLOCK"
            spitterValue.fontColor = SKColor.white.withAlphaComponent(0.4)
            spitterMinus.isEnabled = false
            spitterPlus.isEnabled = false
        }

        let lives = p.extraLives
        if lives > 0 {
            livesValue.text = "+\(lives) MAX HP   (\(Player.baseMaxHP) → \(Player.baseMaxHP + lives))"
            livesValue.fontColor = s.extraLivesEnabled ? .white : SKColor.white.withAlphaComponent(0.4)
            livesToggle.isEnabled = true
        } else {
            livesValue.text = "BEAT A BOSS TO UNLOCK"
            livesValue.fontColor = SKColor.white.withAlphaComponent(0.4)
            livesToggle.isEnabled = false
        }
        livesToggle.setTitle(s.extraLivesEnabled ? "ON" : "OFF")
        livesToggle.setColor(s.extraLivesEnabled ? Palette.acid : SKColor.white.withAlphaComponent(0.6))

        bossIcons.removeAllChildren()
        for (i, spec) in BossSpec.roster.enumerated() {
            let beaten = p.bossesDefeated.contains(i)
            let x = -252 + CGFloat(i) * 56
            let icon = SKShapeNode(path: Geometry.polygon(sides: spec.sides, radius: 14, rotation: spec.sides == 3 ? .pi / 2 : 0))
            icon.strokeColor = beaten ? spec.color : SKColor.white.withAlphaComponent(0.2)
            icon.fillColor = beaten ? spec.color.withAlphaComponent(0.2) : .clear
            icon.lineWidth = 2
            icon.glowWidth = beaten ? 2 : 0
            icon.position = CGPoint(x: x, y: -72)
            bossIcons.addChild(icon)
            let mark = HUD.label(beaten ? "\(i + 1)" : "?", size: 11, color: beaten ? .white : SKColor.white.withAlphaComponent(0.3),
                                 font: Fonts.display)
            mark.position = icon.position
            mark.zPosition = 1
            bossIcons.addChild(mark)
        }
    }

    // MARK: Developer

    private func buildDev() {
        panel(in: devPage)
        title("DEVELOPER MODE", color: Palette.blood, in: devPage)

        godToggle.action = { [weak self] in
            var s = Store.settings
            s.godMode.toggle()
            Store.settings = s
            self?.refreshDev()
        }
        add(godToggle, to: .dev, at: CGPoint(x: 0, y: 92), in: devPage)

        _ = text("SKIP TO BOSS", size: 13, color: SKColor.white.withAlphaComponent(0.6), at: CGPoint(x: 0, y: 56), in: devPage,
                 font: Fonts.display)
        for (i, spec) in BossSpec.roster.enumerated() {
            let col = i % 5, row = i / 5
            let x = -260 + CGFloat(col) * 130
            let y: CGFloat = row == 0 ? 20 : -48
            let wave = (i + 1) * 10
            add(MenuButton("WAVE \(wave)", width: 118, height: 34, color: spec.color == .white ? Palette.blood : spec.color, fontSize: 15) { [weak self] in
                self?.onSkipToWave(wave)
            }, to: .dev, at: CGPoint(x: x, y: y), in: devPage)
            let name = spec.name.replacingOccurrences(of: "THE ", with: "")
            _ = text(name, size: 9, color: SKColor.white.withAlphaComponent(0.55), at: CGPoint(x: x, y: y - 25), in: devPage)
        }
        _ = text("DEV RUNS DON'T COUNT FOR HIGH SCORES OR UNLOCKS.", size: 11, color: SKColor.white.withAlphaComponent(0.5),
                 at: CGPoint(x: 0, y: -112), in: devPage)
        backButton(for: .dev, in: devPage)
    }

    private func refreshDev() {
        let on = Store.settings.godMode
        godToggle.setTitle(on ? "GOD MODE: ON" : "GOD MODE: OFF")
        godToggle.setColor(on ? Palette.blood : SKColor.white.withAlphaComponent(0.6))
    }
}
