import SpriteKit

/// "HOW TO RIOT" overlay shown from the title screen's ? button.
final class HelpPanel: SKNode {
    /// Design canvas; the panel is scaled down to fit smaller screens.
    private static let designSize = CGSize(width: 780, height: 400)

    private let content = SKNode()

    override init() {
        super.init()
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func build(for size: CGSize) {
        removeAllChildren()
        content.removeAllChildren()

        let dim = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.88), size: CGSize(width: size.width * 1.2, height: size.height * 1.2))
        dim.zPosition = 0
        addChild(dim)

        content.zPosition = 1
        content.setScale(min(1, size.width / Self.designSize.width, size.height / Self.designSize.height))
        addChild(content)

        let title = HUD.neonText("HOW TO RIOT", size: 40, color: Palette.magenta)
        title.position = CGPoint(x: 0, y: 165)
        title.zPosition = 1
        content.addChild(title)

        // Columns span roughly x-362 ... x+365 (the longest weapon line), so the block sits centered.
        buildControls(x: -362)
        buildEnemies(x: -112)
        buildWeapons(x: 138)
        buildTips()

        let close = HUD.label("TAP ANYWHERE TO CLOSE", size: 13, color: SKColor.white.withAlphaComponent(0.55))
        close.position = CGPoint(x: 0, y: -190)
        close.zPosition = 1
        close.run(.repeatForever(.sequence([.fadeAlpha(to: 0.2, duration: 0.7), .fadeAlpha(to: 0.55, duration: 0.7)])))
        content.addChild(close)
    }

    // MARK: Columns

    private static let headerY: CGFloat = 115
    private static let firstRowY: CGFloat = 80
    private static let rowStep: CGFloat = 38

    private func header(_ text: String, x: CGFloat, color: SKColor) {
        let l = HUD.label(text, size: 16, color: color, font: Fonts.display)
        l.horizontalAlignmentMode = .left
        l.position = CGPoint(x: x, y: Self.headerY)
        l.zPosition = 1
        content.addChild(l)

        let rule = SKShapeNode(rectOf: CGSize(width: 220, height: 1))
        rule.fillColor = color.withAlphaComponent(0.4)
        rule.strokeColor = .clear
        rule.position = CGPoint(x: x + 110, y: Self.headerY - 13)
        rule.zPosition = 1
        content.addChild(rule)
    }

    private func row(icon: SKNode?, name: String, nameColor: SKColor, desc: String, x: CGFloat, index: Int) {
        let y = Self.firstRowY - CGFloat(index) * Self.rowStep
        let textX = x + 30

        if let icon {
            icon.position = CGPoint(x: x + 11, y: y - 7)
            icon.zPosition = 1
            content.addChild(icon)
        }

        let n = HUD.label(name, size: 13, color: nameColor)
        n.horizontalAlignmentMode = .left
        n.position = CGPoint(x: textX, y: y)
        n.zPosition = 1
        content.addChild(n)

        let d = HUD.label(desc, size: 11, color: SKColor.white.withAlphaComponent(0.7))
        d.horizontalAlignmentMode = .left
        d.position = CGPoint(x: textX, y: y - 15)
        d.zPosition = 1
        content.addChild(d)
    }

    private func buildControls(x: CGFloat) {
        header("CONTROLS", x: x, color: Palette.magenta)
        row(icon: stickIcon(Palette.magenta), name: "LEFT THUMB", nameColor: Palette.magenta,
            desc: "Move.", x: x, index: 0)
        row(icon: stickIcon(Palette.cyan), name: "RIGHT THUMB", nameColor: Palette.cyan,
            desc: "Aim. Fires automatically.", x: x, index: 1)
        row(icon: nil, name: "FLOATING STICKS", nameColor: .white,
            desc: "Appear under your thumb.", x: x, index: 2)
        row(icon: nil, name: "AIM ASSIST", nameColor: .white,
            desc: "Shots bend toward targets.", x: x, index: 3)
        row(icon: nil, name: "STAY MOVING", nameColor: .white,
            desc: "Standing still gets you shot.", x: x, index: 4)
    }

    private func buildEnemies(x: CGFloat) {
        header("THE OPPOSITION", x: x, color: Palette.cyan)
        let enemies: [(Enemy.Kind, String, String)] = [
            (.suit, "SUIT", "Walks straight at you."),
            (.hound, "HOUND", "Fast. Zig-zags."),
            (.enforcer, "ENFORCER", "Keeps distance, shoots back."),
            (.brute, "BRUTE", "Slow tank. Drops a weapon."),
        ]
        for (i, e) in enemies.enumerated() {
            row(icon: enemyIcon(e.0), name: e.1, nameColor: e.0.color, desc: e.2, x: x, index: i)
        }
    }

    private func buildWeapons(x: CGFloat) {
        header("WEAPON CRATES", x: x, color: Palette.amber)
        let weapons: [(Weapon, String)] = [
            (.spitter, "Default. Infinite ammo."),
            (.scatter, "Shotgun. 10 pellets."),
            (.buzzsaw, "SMG. Absurd fire rate."),
            (.rail, "Pierces everything in a line."),
            (.boombox, "Rockets. Splash damage."),
        ]
        for (i, w) in weapons.enumerated() {
            row(icon: weaponIcon(w.0), name: w.0.name, nameColor: w.0.color, desc: w.1, x: x, index: i)
        }
    }

    private func buildTips() {
        let lines = [
            "CHAIN KILLS FOR UP TO x8 COMBO. GETTING HIT RESETS IT.",
            "+ HEALS 1 HP  ·  SAME WEAPON AGAIN STACKS AMMO  ·  EVERY 3RD WAVE LEAVES A CRATE",
            "EVERY 5TH WAVE A NEW BOSS SHOWS UP. TEN OF THEM. GOOD LUCK.",
        ]
        for (i, text) in lines.enumerated() {
            let color: SKColor = i == 0 ? Palette.acid : (i == 2 ? Palette.blood : SKColor.white.withAlphaComponent(0.75))
            let l = HUD.label(text, size: 12, color: color)
            l.position = CGPoint(x: 0, y: -118 - CGFloat(i) * 18)
            l.zPosition = 1
            content.addChild(l)
        }
    }

    // MARK: Icons

    private func stickIcon(_ color: SKColor) -> SKNode {
        let node = SKNode()
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = color.withAlphaComponent(0.6)
        ring.lineWidth = 1.5
        ring.zPosition = 0
        let knob = SKShapeNode(circleOfRadius: 4.5)
        knob.fillColor = color
        knob.strokeColor = .clear
        knob.position = CGPoint(x: 3, y: 2)
        knob.zPosition = 1
        node.addChild(ring)
        node.addChild(knob)
        return node
    }

    private func enemyIcon(_ kind: Enemy.Kind) -> SKNode {
        let r: CGFloat = kind == .brute ? 11 : 9
        let shape = SKShapeNode(path: Geometry.polygon(sides: kind.sides, radius: r, rotation: kind == .suit ? .pi / 4 : 0))
        shape.strokeColor = kind.color
        shape.fillColor = kind.color.withAlphaComponent(0.15)
        shape.lineWidth = 2
        shape.glowWidth = 2
        return shape
    }

    private func weaponIcon(_ weapon: Weapon) -> SKNode {
        let node = SKNode()
        let crate = SKShapeNode(path: Geometry.polygon(sides: 4, radius: 11))
        crate.strokeColor = weapon.color
        crate.fillColor = weapon.color.withAlphaComponent(0.15)
        crate.lineWidth = 2
        crate.glowWidth = 2
        crate.zPosition = 0
        node.addChild(crate)

        let glyph = HUD.label(weapon.glyph, size: 11, color: .white, font: Fonts.display)
        glyph.zPosition = 1
        node.addChild(glyph)
        return node
    }
}
