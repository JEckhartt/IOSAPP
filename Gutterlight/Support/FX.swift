import SpriteKit
import UIKit

/// Procedurally generated textures and particle effects. No asset files needed.
@MainActor
enum FX {
    // MARK: Textures

    static let spark: SKTexture = FX.texture(size: CGSize(width: 32, height: 32)) { ctx, size in
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        ctx.drawRadialGradient(gradient, startCenter: c, startRadius: 0, endCenter: c, endRadius: size.width / 2, options: [])
    }

    static let streak: SKTexture = FX.texture(size: CGSize(width: 2, height: 22)) { ctx, size in
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
    }

    static func texture(size: CGSize, draw: (CGContext, CGSize) -> Void) -> SKTexture {
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            draw(ctx.cgContext, size)
        }
        return SKTexture(image: image)
    }

    // MARK: Screen-space overlays

    static func rain(for size: CGSize) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = streak
        e.particleBirthRate = 260
        e.particleLifetime = 0.32
        e.particleLifetimeRange = 0.15
        e.particlePositionRange = CGVector(dx: size.width * 1.3, dy: size.height * 1.3)
        e.emissionAngle = -.pi / 2 - 0.38
        e.particleSpeed = 950
        e.particleSpeedRange = 250
        e.particleRotation = e.emissionAngle - .pi / 2
        e.particleAlpha = 0.16
        e.particleAlphaRange = 0.1
        e.particleScale = 1
        e.particleScaleRange = 0.5
        e.particleColor = Palette.rain
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .add
        e.advanceSimulationTime(1)
        return e
    }

    static func vignette(for size: CGSize) -> SKSpriteNode {
        let tex = texture(size: CGSize(width: 256, height: 256)) { ctx, s in
            let c = CGPoint(x: s.width / 2, y: s.height / 2)
            let colors = [
                UIColor.black.withAlphaComponent(0).cgColor,
                UIColor.black.withAlphaComponent(0.15).cgColor,
                UIColor.black.withAlphaComponent(0.8).cgColor,
            ] as CFArray
            let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1])!
            ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: s.width * 0.72,
                                   options: [.drawsAfterEndLocation])
        }
        let node = SKSpriteNode(texture: tex, size: size)
        return node
    }

    static func scanlines(for size: CGSize) -> SKSpriteNode {
        let tex = texture(size: size) { ctx, s in
            ctx.setFillColor(UIColor.black.withAlphaComponent(0.22).cgColor)
            var y: CGFloat = 0
            while y < s.height {
                ctx.fill(CGRect(x: 0, y: y, width: s.width, height: 1))
                y += 3
            }
        }
        let node = SKSpriteNode(texture: tex, size: size)
        node.alpha = 0.6
        return node
    }

    // MARK: World effects

    static func burst(at point: CGPoint, color: SKColor, count: Int, speed: CGFloat = 280, in parent: SKNode) {
        let e = SKEmitterNode()
        e.particleTexture = spark
        e.particleBirthRate = 4000
        e.numParticlesToEmit = count
        e.particleLifetime = 0.45
        e.particleLifetimeRange = 0.3
        e.particleSpeed = speed
        e.particleSpeedRange = speed * 0.8
        e.emissionAngleRange = .pi * 2
        e.particleAlphaSpeed = -2.2
        e.particleScale = 0.5
        e.particleScaleRange = 0.3
        e.particleScaleSpeed = -0.9
        e.particleColor = color
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .add
        e.position = point
        e.zPosition = 15
        parent.addChild(e)
        e.run(.sequence([.wait(forDuration: 1.0), .removeFromParent()]))
    }

    static func rocketTrail() -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleTexture = spark
        e.particleBirthRate = 90
        e.particleLifetime = 0.35
        e.particleLifetimeRange = 0.15
        e.particleSpeed = 30
        e.emissionAngle = .pi
        e.emissionAngleRange = 0.6
        e.particleAlpha = 0.7
        e.particleAlphaSpeed = -2
        e.particleScale = 0.45
        e.particleScaleSpeed = 0.8
        e.particleColor = Palette.amber
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .add
        return e
    }

    static func shockwave(at point: CGPoint, color: SKColor, radius: CGFloat, in parent: SKNode) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.strokeColor = color
        ring.lineWidth = 3
        ring.glowWidth = 4
        ring.fillColor = .clear
        ring.position = point
        ring.zPosition = 14
        ring.setScale(0.3)
        parent.addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 1.6, duration: 0.28), .fadeOut(withDuration: 0.28)]),
            .removeFromParent(),
        ]))
    }

    static func muzzleFlash(at point: CGPoint, in parent: SKNode) {
        let flash = SKSpriteNode(texture: spark, size: CGSize(width: 34, height: 34))
        flash.color = Palette.magenta
        flash.colorBlendFactor = 0.6
        flash.blendMode = .add
        flash.position = point
        flash.zPosition = 7
        parent.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.06), .removeFromParent()]))
    }

    static func popup(_ text: String, at point: CGPoint, color: SKColor, in parent: SKNode) {
        let label = SKLabelNode(fontNamed: Fonts.mono)
        label.text = text
        label.fontSize = 15
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.position = point
        label.zPosition = 20
        parent.addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 42, duration: 0.7), .sequence([.wait(forDuration: 0.35), .fadeOut(withDuration: 0.35)])]),
            .removeFromParent(),
        ]))
    }

    /// Random neon-tube stutter.
    static func flicker() -> SKAction {
        .repeatForever(.sequence([
            .wait(forDuration: 2.5, withRange: 4),
            .fadeAlpha(by: -0.7, duration: 0.03),
            .fadeAlpha(by: 0.7, duration: 0.03),
            .wait(forDuration: 0.08),
            .fadeAlpha(by: -0.5, duration: 0.04),
            .fadeAlpha(by: 0.5, duration: 0.06),
        ]))
    }
}
