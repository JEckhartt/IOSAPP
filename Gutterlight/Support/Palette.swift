import SpriteKit
import UIKit

/// Wet asphalt, sodium lamps, and neon that won't stop buzzing.
enum Palette {
    static let night   = SKColor(red: 0.025, green: 0.02, blue: 0.05, alpha: 1)
    static let asphalt = SKColor(red: 0.07, green: 0.06, blue: 0.11, alpha: 1)
    static let magenta = SKColor(red: 1.00, green: 0.12, blue: 0.56, alpha: 1)
    static let cyan    = SKColor(red: 0.15, green: 0.95, blue: 1.00, alpha: 1)
    static let acid    = SKColor(red: 0.78, green: 1.00, blue: 0.12, alpha: 1)
    static let amber   = SKColor(red: 1.00, green: 0.66, blue: 0.10, alpha: 1)
    static let blood   = SKColor(red: 1.00, green: 0.16, blue: 0.18, alpha: 1)
    static let violet  = SKColor(red: 0.55, green: 0.30, blue: 1.00, alpha: 1)
    static let rain    = SKColor(red: 0.60, green: 0.75, blue: 1.00, alpha: 1)

    static let neons: [SKColor] = [magenta, cyan, acid, amber, violet]
}

enum Fonts {
    static let display = "Futura-CondensedExtraBold"
    static let mono = "Menlo-Bold"
}

@MainActor
enum Haptics {
    private static let lightGen = UIImpactFeedbackGenerator(style: .light)
    private static let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    private static let notifyGen = UINotificationFeedbackGenerator()

    static func light() { lightGen.impactOccurred(intensity: 0.6) }
    static func heavy() { heavyGen.impactOccurred() }
    static func death() { notifyGen.notificationOccurred(.error) }
}
