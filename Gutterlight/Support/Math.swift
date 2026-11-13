import CoreGraphics

extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint {
        CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    static func += (lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs + rhs
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGVector {
        CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }

    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

extension CGVector {
    var length: CGFloat { hypot(dx, dy) }

    var angle: CGFloat { atan2(dy, dx) }

    var normalized: CGVector {
        let len = length
        return len > 0.0001 ? CGVector(dx: dx / len, dy: dy / len) : .zero
    }

    /// Rotated 90° counter-clockwise.
    var perpendicular: CGVector { CGVector(dx: -dy, dy: dx) }

    init(angle: CGFloat, length: CGFloat = 1) {
        self.init(dx: cos(angle) * length, dy: sin(angle) * length)
    }

    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }

    static func + (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }

    static func += (lhs: inout CGVector, rhs: CGVector) {
        lhs = lhs + rhs
    }

    static func - (lhs: CGVector, rhs: CGVector) -> CGVector {
        CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }

    /// Linear interpolation toward `target` by fraction `t` (0...1).
    func lerp(to target: CGVector, t: CGFloat) -> CGVector {
        CGVector(dx: dx + (target.dx - dx) * t, dy: dy + (target.dy - dy) * t)
    }
}

extension CGFloat {
    func clamped(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { Swift.min(Swift.max(self, lo), hi) }
}

enum Geometry {
    static func polygon(sides: Int, radius: CGFloat, rotation: CGFloat = 0) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<sides {
            let a = rotation + CGFloat(i) / CGFloat(sides) * .pi * 2
            let pt = CGPoint(x: cos(a) * radius, y: sin(a) * radius)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }
        path.closeSubpath()
        return path
    }
}
