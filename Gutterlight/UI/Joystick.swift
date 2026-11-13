import SpriteKit

/// Floating virtual stick: appears wherever the thumb lands.
final class Joystick: SKNode {
    let radius: CGFloat = 52
    /// Ignore tiny thumb wobble, then rescale so output still spans 0...1.
    let deadZone: CGFloat = 0.12
    private(set) var value = CGVector.zero
    private(set) var isActive = false

    private let base: SKShapeNode
    private let knob: SKShapeNode
    private var origin = CGPoint.zero

    var magnitude: CGFloat { value.length }

    init(color: SKColor) {
        base = SKShapeNode(circleOfRadius: radius)
        base.strokeColor = color.withAlphaComponent(0.45)
        base.fillColor = color.withAlphaComponent(0.05)
        base.lineWidth = 2
        base.zPosition = 0

        knob = SKShapeNode(circleOfRadius: 24)
        knob.strokeColor = color
        knob.fillColor = color.withAlphaComponent(0.3)
        knob.lineWidth = 2
        knob.glowWidth = 3
        knob.zPosition = 1

        super.init()
        addChild(base)
        addChild(knob)
        alpha = 0
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is not supported") }

    func begin(at point: CGPoint) {
        origin = point
        position = point
        knob.position = .zero
        value = .zero
        isActive = true
        removeAllActions()
        alpha = 1
    }

    func move(to point: CGPoint) {
        guard isActive else { return }
        var delta = point - origin
        let len = delta.length
        if len > radius {
            // Drag the base along so reversing direction is instant, not a long thumb trip back.
            let excess = delta.normalized * (len - radius)
            origin += excess
            position = origin
            delta = delta * (radius / len)
        }
        knob.position = CGPoint(x: delta.dx, y: delta.dy)

        let raw = min(1, delta.length / radius)
        if raw < deadZone {
            value = .zero
        } else {
            let scaled = (raw - deadZone) / (1 - deadZone)
            value = delta.normalized * scaled
        }
    }

    func end() {
        guard isActive else { return }
        isActive = false
        value = .zero
        knob.position = .zero
        run(.fadeOut(withDuration: 0.15))
    }
}
