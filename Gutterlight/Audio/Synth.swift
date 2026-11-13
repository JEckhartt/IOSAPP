import Foundation

/// Tiny offline synthesizer. Everything is rendered once into sample arrays at launch.
enum Synth {
    static let sampleRate = 44_100.0

    static func mtof(_ midi: Int) -> Double {
        440 * pow(2, Double(midi - 69) / 12)
    }

    enum Wave {
        case sine, square, saw, triangle

        func value(_ phase: Double) -> Double {
            switch self {
            case .sine: return sin(phase * 2 * .pi)
            case .square: return phase < 0.5 ? 1 : -1
            case .saw: return 2 * phase - 1
            case .triangle: return 1 - 4 * abs(phase - 0.5)
            }
        }
    }

    /// Oscillator with time-varying pitch and amplitude.
    static func voice(_ duration: Double, _ wave: Wave,
                      freq: (Double) -> Double, amp: (Double) -> Double) -> [Float] {
        let n = Int(duration * sampleRate)
        var out = [Float](repeating: 0, count: n)
        var phase = 0.0
        for i in 0..<n {
            let t = Double(i) / sampleRate
            phase += freq(t) / sampleRate
            phase -= floor(phase)
            out[i] = Float(wave.value(phase) * amp(t))
        }
        return declick(out)
    }

    /// White noise through a one-pole low-pass. `lowpass` is 0...1 (1 = unfiltered).
    static func noise(_ duration: Double, lowpass: Double = 1, amp: (Double) -> Double) -> [Float] {
        let n = Int(duration * sampleRate)
        var out = [Float](repeating: 0, count: n)
        var rng = NoiseGen(seed: UInt32(truncatingIfNeeded: n &* 2_654_435_761))
        var lp = 0.0
        let a = max(0.001, min(1, lowpass))
        let gain = sqrt((2 - a) / a) // keep perceived loudness roughly constant across cutoffs
        for i in 0..<n {
            let t = Double(i) / sampleRate
            lp += a * (rng.next() - lp)
            out[i] = Float(lp * gain * amp(t))
        }
        return declick(out)
    }

    static func mix(_ parts: [[Float]]) -> [Float] {
        let n = parts.map(\.count).max() ?? 0
        var out = [Float](repeating: 0, count: n)
        for part in parts {
            for i in 0..<part.count { out[i] += part[i] }
        }
        return normalize(out)
    }

    static func sequence(_ parts: [[Float]]) -> [Float] {
        parts.flatMap { $0 }
    }

    static func declick(_ samples: [Float], fade: Int = 64) -> [Float] {
        var s = samples
        let n = s.count
        let f = min(fade, n)
        for i in 0..<f {
            s[n - 1 - i] *= Float(i) / Float(f)
        }
        return s
    }

    static func normalize(_ samples: [Float], peak: Float = 0.9) -> [Float] {
        let m = samples.reduce(0) { max($0, abs($1)) }
        guard m > peak else { return samples }
        let g = peak / m
        return samples.map { $0 * g }
    }
}

/// Fast deterministic noise (Float.random is too slow for per-sample use in debug builds).
struct NoiseGen {
    private var state: UInt32

    init(seed: UInt32 = 0x1234_5678) {
        state = seed == 0 ? 0x1234_5678 : seed
    }

    /// Uniform in -1...1.
    mutating func next() -> Double {
        state = state &* 1_664_525 &+ 1_013_904_223
        return Double(state) / Double(UInt32.max) * 2 - 1
    }
}

// MARK: - Sound effects

enum Sfx: CaseIterable {
    case shoot, shotgun, rail, rocket
    case enemyShot, hit, explode, bigExplode
    case hurt, pickup, weapon, wave, gameOver
}

enum SoundBank {
    static func render(_ sfx: Sfx) -> [Float] {
        typealias S = Synth
        switch sfx {
        case .shoot:
            return S.mix([
                S.voice(0.07, .square, freq: { 1400 * exp(-$0 / 0.02) + 260 }, amp: { 0.16 * exp(-$0 / 0.025) }),
                S.noise(0.04, lowpass: 0.5, amp: { 0.1 * exp(-$0 / 0.01) }),
            ])
        case .shotgun:
            return S.mix([
                S.noise(0.4, lowpass: 0.3, amp: { 0.5 * exp(-$0 / 0.08) }),
                S.voice(0.2, .sine, freq: { 170 * exp(-$0 / 0.05) + 50 }, amp: { 0.55 * exp(-$0 / 0.06) }),
            ])
        case .rail:
            return S.mix([
                S.voice(0.4, .saw, freq: { 2400 * exp(-$0 / 0.07) + 160 }, amp: { 0.22 * exp(-$0 / 0.13) }),
                S.voice(0.4, .sine, freq: { _ in 82 }, amp: { 0.35 * exp(-$0 / 0.12) }),
                S.noise(0.1, lowpass: 0.9, amp: { 0.15 * exp(-$0 / 0.02) }),
            ])
        case .rocket:
            return S.mix([
                S.noise(0.35, lowpass: 0.15, amp: { t in 0.4 * min(1, t / 0.02) * exp(-t / 0.13) }),
                S.voice(0.3, .triangle, freq: { 180 + 500 * $0 }, amp: { 0.15 * exp(-$0 / 0.1) }),
            ])
        case .enemyShot:
            return S.voice(0.12, .triangle, freq: { 700 * exp(-$0 / 0.04) + 180 }, amp: { 0.18 * exp(-$0 / 0.04) })
        case .hit:
            return S.mix([
                S.noise(0.05, lowpass: 0.7, amp: { 0.2 * exp(-$0 / 0.012) }),
                S.voice(0.05, .square, freq: { 330 - 2000 * $0 }, amp: { 0.07 * exp(-$0 / 0.015) }),
            ])
        case .explode:
            return S.mix([
                S.noise(0.6, lowpass: 0.12, amp: { 0.6 * exp(-$0 / 0.14) }),
                S.voice(0.4, .sine, freq: { 110 * exp(-$0 / 0.08) + 38 }, amp: { 0.55 * exp(-$0 / 0.12) }),
            ])
        case .bigExplode:
            return S.mix([
                S.noise(1.4, lowpass: 0.07, amp: { 0.8 * exp(-$0 / 0.35) }),
                S.noise(0.3, lowpass: 0.6, amp: { 0.3 * exp(-$0 / 0.05) }),
                S.voice(1.0, .sine, freq: { 80 * exp(-$0 / 0.2) + 26 }, amp: { 0.7 * exp(-$0 / 0.3) }),
            ])
        case .hurt:
            return S.mix([
                S.voice(0.3, .saw, freq: { 420 * exp(-$0 / 0.08) + 70 }, amp: { 0.3 * exp(-$0 / 0.1) }),
                S.noise(0.15, lowpass: 0.4, amp: { 0.25 * exp(-$0 / 0.04) }),
            ])
        case .pickup:
            let notes: [Double] = [523, 659, 784, 1047]
            return S.sequence(notes.map { f in
                S.voice(0.06, .square, freq: { _ in f }, amp: { 0.12 * exp(-$0 / 0.05) })
            })
        case .weapon:
            let notes: [Double] = [392, 523, 659, 784, 1047, 1568]
            return S.sequence(notes.map { f in
                S.voice(0.05, .saw, freq: { _ in f }, amp: { 0.14 * exp(-$0 / 0.06) })
            } + [S.voice(0.3, .square, freq: { _ in 1568 }, amp: { 0.08 * exp(-$0 / 0.1) })])
        case .wave:
            return S.mix([
                S.voice(0.9, .saw, freq: { 110 * pow(4, $0 / 0.9) },
                        amp: { t in 0.13 * min(1, t / 0.7) * (t > 0.82 ? max(0, (0.9 - t) / 0.08) : 1) }),
                S.noise(0.9, lowpass: 0.3, amp: { 0.1 * ($0 / 0.9) }),
            ])
        case .gameOver:
            return S.voice(1.6, .square,
                           freq: { t in 440 * pow(0.125, t / 1.6) * (1 + 0.03 * sin(t * 40)) },
                           amp: { 0.18 * exp(-$0 / 0.9) })
        }
    }
}

// MARK: - Music

/// An 8-bar synthwave loop in A minor (i – VI – III – VII), rendered sample by sample.
enum MusicBox {
    static let bpm = 100.0

    static func render() -> [Float] {
        let sr = Synth.sampleRate
        let beat = 60 / bpm
        let bar = beat * 4
        let bars = 8
        let n = Int(Double(bars) * bar * sr)
        var out = [Float](repeating: 0, count: n)

        let roots = [45, 41, 48, 43]                  // A2 F2 C3 G2
        let chords = [[57, 60, 64], [53, 57, 60],     // Am, F
                      [52, 55, 60], [55, 59, 62]]     // C (1st inv.), G
        let arpPattern = [0, 1, 2, 1, 0, 2, 1, 2]

        var bassPhase = 0.0, bassLP = 0.0
        var padPhases = [Double](repeating: 0, count: 6)
        var padLP = 0.0
        var arpPhase = 0.0

        let eighth = beat / 2
        let sixteenth = beat / 4

        for i in 0..<n {
            let t = Double(i) / sr
            let barIndex = Int(t / bar)
            let chordIndex = (barIndex / 2) % 4
            var s = 0.0

            // Bass: driving 8ths with octave bounce, filter opens on each note.
            let step8 = Int(t / eighth)
            let pos8 = t - Double(step8) * eighth
            let bassMidi = roots[chordIndex] - 12 + (step8 % 2 == 1 ? 12 : 0)
            bassPhase += Synth.mtof(bassMidi) / sr
            bassPhase -= floor(bassPhase)
            let bassEnv = exp(-pos8 / 0.11)
            bassLP += (0.03 + 0.22 * bassEnv) * ((2 * bassPhase - 1) - bassLP)
            s += bassLP * 0.42 * (0.35 + 0.65 * bassEnv)

            // Pad: detuned saws, slow swell per chord.
            let chord = chords[chordIndex]
            var pad = 0.0
            for (k, m) in chord.enumerated() {
                let f = Synth.mtof(m)
                for d in 0..<2 {
                    let idx = k * 2 + d
                    padPhases[idx] += f * (d == 0 ? 1.004 : 0.996) / sr
                    padPhases[idx] -= floor(padPhases[idx])
                    pad += 2 * padPhases[idx] - 1
                }
            }
            padLP += 0.035 * (pad - padLP)
            let posInChord = t.truncatingRemainder(dividingBy: bar * 2)
            let swell = min(1, posInChord / 0.8) * min(1, (bar * 2 - posInChord) / 0.15)
            s += padLP * 0.045 * swell

            // Arp: kicks in for the second half of the loop.
            if barIndex >= 4 {
                let step16 = Int(t / sixteenth)
                let pos16 = t - Double(step16) * sixteenth
                let note = chord[arpPattern[step16 % arpPattern.count]] + 12 + (step16 % 16 >= 8 ? 12 : 0)
                arpPhase += Synth.mtof(note) / sr
                arpPhase -= floor(arpPhase)
                s += (arpPhase < 0.5 ? 1 : -1) * 0.045 * exp(-pos16 / 0.07)
            }

            out[i] = Float(s)
        }

        // Drums.
        var rng = NoiseGen(seed: 0xBEEF)
        let totalBeats = bars * 4
        for b in 0..<totalBeats {
            let start = Int(Double(b) * beat * sr)
            addKick(&out, at: start)
            if b % 2 == 1 { addSnare(&out, at: start, rng: &rng) }
            addHat(&out, at: start, level: 0.04, rng: &rng)
            addHat(&out, at: start + Int(eighth * sr), level: 0.08, rng: &rng)
        }
        // Little snare fill at the end of the loop.
        for k in 0..<4 {
            let start = Int((Double(totalBeats - 1) + Double(k) * 0.25) * beat * sr)
            addSnare(&out, at: start, level: 0.12 + 0.04 * Double(k), rng: &rng)
        }

        // Dotted-eighth echo for that rain-on-chrome space.
        let delay = Int(beat * 0.75 * sr)
        for i in 0..<n {
            out[i] += out[(i - delay + n) % n] * 0.22
        }

        return out.map { Float(tanh(Double($0) * 1.1)) }
    }

    private static func add(_ out: inout [Float], at start: Int, duration: Double, _ f: (Double) -> Double) {
        let n = out.count
        let len = Int(duration * Synth.sampleRate)
        for i in 0..<len {
            let t = Double(i) / Synth.sampleRate
            out[(start + i) % n] += Float(f(t))
        }
    }

    private static func addKick(_ out: inout [Float], at start: Int) {
        var phase = 0.0
        add(&out, at: start, duration: 0.3) { t in
            phase += (110 * exp(-t / 0.035) + 44) / Synth.sampleRate
            return sin(phase * 2 * .pi) * 0.75 * exp(-t / 0.16)
        }
    }

    private static func addSnare(_ out: inout [Float], at start: Int, level: Double = 0.26, rng: inout NoiseGen) {
        var local = rng
        var lp = 0.0
        add(&out, at: start, duration: 0.22) { t in
            lp += 0.5 * (local.next() - lp)
            return lp * level * 1.7 * exp(-t / 0.07) + sin(t * 190 * 2 * .pi) * 0.18 * exp(-t / 0.04)
        }
        rng = local
    }

    private static func addHat(_ out: inout [Float], at start: Int, level: Double, rng: inout NoiseGen) {
        var local = rng
        var lp = 0.0
        add(&out, at: start, duration: 0.06) { t in
            let x = local.next()
            lp += 0.6 * (x - lp)
            return (x - lp) * level * exp(-t / 0.015)
        }
        rng = local
    }
}
