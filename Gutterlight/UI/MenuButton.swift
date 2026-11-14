import SpriteKit
import UIKit

extension SKNode {
    /// True when neither this node nor any ancestor is hidden or fully transparent.
    var isVisibleInTree: Bool {
        var node: SKNode? = self
        while let n = node {
            if n.isHidden || n.alpha < 0.01 { return false }
            node = n.parent
        }
        return true
    }
}

/// Neon-outlined tappable button.
final class MenuButton: SKNode {
    let size: CGSize
    var action: () -> Void
    var isEnabled = true { didSet { refresh() } }

    private let frameShape: SKShapeNode
    private let label: SKLabelNode
    private var color: SKColor

    init(_ title: String, width: CGFloat = 240, height: CGFloat = 40, color: SKColor = .white,
         fontSize: CGFloat = 18, action: @escaping () -> Void = {}) {
        self.size = CGSize(width: width, height: height)
        self.color = color
        self.action = action

        frameShape = SKShapeNode(rectOf: size, cornerRadius: 6)
        frameShape.lineWidth = 2
        frameShape.zPosition = 0

        label = HUD.label(title, size: fontSize, color: color, font: Fonts.display)
        label.zPosition = 1

        super.init()
        addChild(frameShape)
        addChild(label)
        refresh()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func setTitle(_ title: String) { label.text = title }

    func setColor(_ c: SKColor) {
        color = c
        refresh()
    }

    private func refresh() {
        let c = isEnabled ? color : SKColor.white.withAlphaComponent(0.25)
        frameShape.strokeColor = c
        frameShape.fillColor = c.withAlphaComponent(0.08)
        frameShape.glowWidth = isEnabled ? 2 : 0
        label.fontColor = c
    }

    func hitTest(_ touch: UITouch) -> Bool {
        guard isVisibleInTree else { return false }
        let p = touch.location(in: self)
        return abs(p.x) <= size.width / 2 + 8 && abs(p.y) <= size.height / 2 + 8
    }

    func press() {
        guard isEnabled else {
            run(.sequence([.moveBy(x: 5, y: 0, duration: 0.04), .moveBy(x: -10, y: 0, duration: 0.08), .moveBy(x: 5, y: 0, duration: 0.04)]))
            return
        }
        removeAction(forKey: "press")
        setScale(0.92)
        run(.scale(to: 1, duration: 0.12), withKey: "press")
        Audio.shared.play(.hit, volume: 0.5)
        Haptics.light()
        action()
    }
}

/// Difficulty slider: -100% … +100% in 10% notches. Drag the knob or tap the arrows.
final class DifficultySlider: SKNode {
    static let width: CGFloat = 300
    var onChange: (Difficulty) -> Void = { _ in }
    private(set) var value = Difficulty()

    private let fill = SKShapeNode()
    private let knob = SKShapeNode(circleOfRadius: 11)
    private let valueLabel = HUD.label("", size: 15, color: .white, font: Fonts.display)
    private var dragging: ObjectIdentifier?
    let minus: MenuButton
    let plus: MenuButton

    override init() {
        minus = MenuButton("◀", width: 40, height: 32, color: Palette.cyan, fontSize: 16)
        plus = MenuButton("▶", width: 40, height: 32, color: Palette.blood, fontSize: 16)
        super.init()

        let w = DifficultySlider.width
        let track = SKShapeNode(rectOf: CGSize(width: w, height: 4), cornerRadius: 2)
        track.fillColor = SKColor.white.withAlphaComponent(0.2)
        track.strokeColor = .clear
        track.zPosition = 0
        addChild(track)

        for i in DifficultySlider.notches {
            let tick = SKShapeNode(rectOf: CGSize(width: 2, height: i == 0 ? 16 : (i % 5 == 0 ? 12 : 7)))
            tick.fillColor = SKColor.white.withAlphaComponent(i == 0 ? 0.7 : 0.3)
            tick.strokeColor = .clear
            tick.position = CGPoint(x: DifficultySlider.x(for: i), y: 0)
            tick.zPosition = 1
            addChild(tick)
        }

        fill.lineWidth = 4
        fill.lineCap = .round
        fill.zPosition = 2
        addChild(fill)

        knob.fillColor = .white
        knob.strokeColor = Palette.magenta
        knob.lineWidth = 3
        knob.glowWidth = 3
        knob.zPosition = 3
        addChild(knob)

        valueLabel.position = CGPoint(x: 0, y: 24)
        valueLabel.zPosition = 1
        addChild(valueLabel)

        minus.position = CGPoint(x: -w / 2 - 38, y: 0)
        plus.position = CGPoint(x: w / 2 + 38, y: 0)
        minus.action = { [weak self] in self?.nudge(-1) }
        plus.action = { [weak self] in self?.nudge(1) }
        addChild(minus)
        addChild(plus)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    private static var notches: ClosedRange<Int> { Difficulty.range }

    private static func x(for step: Int) -> CGFloat {
        CGFloat(step) / CGFloat(Difficulty.range.upperBound) * width / 2
    }

    func set(_ d: Difficulty, notify: Bool = false) {
        value = Difficulty(steps: min(max(d.steps, Difficulty.range.lowerBound), Difficulty.range.upperBound))
        let x = DifficultySlider.x(for: value.steps)
        knob.position = CGPoint(x: x, y: 0)

        let color: SKColor = value.steps == 0 ? .white : (value.steps > 0 ? Palette.blood : Palette.cyan)
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: x, y: 0))
        fill.path = path
        fill.strokeColor = color
        knob.strokeColor = color
        valueLabel.text = "DIFFICULTY  " + value.label
        valueLabel.fontColor = color
        if notify { onChange(value) }
    }

    private func nudge(_ delta: Int) {
        set(Difficulty(steps: value.steps + delta), notify: true)
    }

    // Touch handling: returns true if the slider consumed the touch.
    func touchBegan(_ touch: UITouch) -> Bool {
        guard isVisibleInTree else { return false }
        let p = touch.location(in: self)
        guard abs(p.x) <= DifficultySlider.width / 2 + 14, abs(p.y) <= 22 else { return false }
        dragging = ObjectIdentifier(touch)
        drag(to: p.x)
        return true
    }

    func touchMoved(_ touch: UITouch) {
        guard dragging == ObjectIdentifier(touch) else { return }
        drag(to: touch.location(in: self).x)
    }

    func touchEnded(_ touch: UITouch) {
        if dragging == ObjectIdentifier(touch) { dragging = nil }
    }

    private func drag(to x: CGFloat) {
        let step = Int((x / (DifficultySlider.width / 2) * CGFloat(Difficulty.range.upperBound)).rounded())
        if step != value.steps {
            set(Difficulty(steps: step), notify: true)
            Haptics.light()
        }
    }
}
