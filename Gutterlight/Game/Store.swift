import Foundation
import CoreGraphics

/// Player-facing difficulty: -100% … +100% in steps of 10%.
struct Difficulty: Codable, Equatable {
    /// -10 … 10, one step = 10%.
    var steps: Int = 0

    static let range = -10...10

    var percent: Int { steps * 10 }

    var label: String { percent == 0 ? "NORMAL" : (percent > 0 ? "+\(percent)%" : "\(percent)%") }

    /// Enemy count and hit points. 25% at -100, 200% at +100.
    var amount: Double { max(0.25, 1 + Double(percent) / 100) }

    /// Movement, bullet speed and fire rate. 50% at -100, 150% at +100.
    var tempo: CGFloat { 1 + CGFloat(percent) / 200 }

    func scaledHP(_ hp: Int) -> Int { max(1, Int((Double(hp) * amount).rounded())) }
}

struct Settings: Codable {
    var difficulty = Difficulty()
    var godMode = false
    var extraLivesEnabled = true
    /// Weapon you start every run with (infinite ammo). Must be unlocked.
    var defaultWeapon: Weapon = .spitter

    init() {}

    // Tolerant decoding so settings saved by older builds still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        difficulty = try c.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? Difficulty()
        godMode = try c.decodeIfPresent(Bool.self, forKey: .godMode) ?? false
        extraLivesEnabled = try c.decodeIfPresent(Bool.self, forKey: .extraLivesEnabled) ?? true
        defaultWeapon = try c.decodeIfPresent(Weapon.self, forKey: .defaultWeapon) ?? .spitter
    }
}

struct Progress: Codable {
    /// Unspent upgrade points (1 per wave survived, outside dev runs).
    var points = 0
    /// Lifetime points earned; > 0 means wave 1 has been survived at least once.
    var pointsEarned = 0
    /// Bonus damage bought for the SPITTER.
    var spitterBonus = 0
    /// Roster indices (0…9) of bosses beaten at least once.
    var bossesDefeated: Set<Int> = []

    var spitterUnlocked: Bool { pointsEarned > 0 }
    var extraLives: Int { bossesDefeated.count }

    func isUnlocked(_ weapon: Weapon) -> Bool {
        guard let boss = weapon.unlockingBoss else { return true }
        return bossesDefeated.contains(boss)
    }
}

struct ScoreEntry: Codable {
    var score: Int
    var wave: Int
    var difficulty: Int
    var date: Date
}

/// Everything persisted between launches. Lives in UserDefaults as JSON.
enum Store {
    private static let defaults = UserDefaults.standard
    private static let settingsKey = "gutterlight.settings"
    private static let progressKey = "gutterlight.progress"
    private static let scoresKey = "gutterlight.scores"
    private static let legacyBestKey = "gutterlight.bestScore"
    static let maxScores = 10

    static var settings: Settings {
        get { load(settingsKey) ?? Settings() }
        set { save(newValue, settingsKey) }
    }

    static var progress: Progress {
        get { load(progressKey) ?? Progress() }
        set { save(newValue, progressKey) }
    }

    static var scores: [ScoreEntry] {
        get {
            if let s: [ScoreEntry] = load(scoresKey) { return s }
            // Carry over the single best score from before the leaderboard existed.
            let legacy = defaults.integer(forKey: legacyBestKey)
            return legacy > 0 ? [ScoreEntry(score: legacy, wave: 0, difficulty: 0, date: Date())] : []
        }
        set { save(newValue, scoresKey) }
    }

    static var best: Int { scores.first?.score ?? 0 }

    /// Inserts a score; returns its rank (0-based) if it made the top 10.
    @discardableResult
    static func submit(score: Int, wave: Int, difficulty: Difficulty) -> Int? {
        guard score > 0 else { return nil }
        var list = scores
        list.append(ScoreEntry(score: score, wave: wave, difficulty: difficulty.percent, date: Date()))
        list.sort { $0.score > $1.score }
        let trimmed = Array(list.prefix(maxScores))
        scores = trimmed
        return trimmed.firstIndex { $0.score == score && abs($0.date.timeIntervalSinceNow) < 2 }
    }

    private static func load<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func save<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}
