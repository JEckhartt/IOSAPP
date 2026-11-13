import AVFoundation
import QuartzCore

/// Plays the synthesized SFX and music loop through a single AVAudioEngine.
/// Call from the main thread.
final class Audio {
    static let shared = Audio()

    enum MusicLevel { case title, playing, dead }

    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: Synth.sampleRate, channels: 1)!
    private let sfxBus = AVAudioMixerNode()
    private let musicPlayer = AVAudioPlayerNode()
    /// Dedicated voice for rapid-fire weapons so they never starve the pool.
    private let gunVoice = AVAudioPlayerNode()
    private var voices: [AVAudioPlayerNode] = []
    private var nextVoice = 0

    private var buffers: [Sfx: AVAudioPCMBuffer] = [:]
    private var musicBuffer: AVAudioPCMBuffer?
    private var lastPlayed: [Sfx: CFTimeInterval] = [:]
    private var wantsMusic = false
    private var started = false

    /// Minimum gap between repeats, so a buzzsaw doesn't turn hits into white noise.
    private let throttle: [Sfx: CFTimeInterval] = [.hit: 0.035, .enemyShot: 0.05, .explode: 0.04]

    private init() {}

    func start() {
        guard !started else { return }
        started = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default)
        try? session.setActive(true)

        engine.attach(sfxBus)
        engine.connect(sfxBus, to: engine.mainMixerNode, format: nil)
        sfxBus.outputVolume = 0.85

        for _ in 0..<12 {
            let v = AVAudioPlayerNode()
            engine.attach(v)
            engine.connect(v, to: sfxBus, format: format)
            voices.append(v)
        }
        engine.attach(gunVoice)
        engine.connect(gunVoice, to: sfxBus, format: format)

        engine.attach(musicPlayer)
        engine.connect(musicPlayer, to: engine.mainMixerNode, format: format)
        musicPlayer.volume = 0.4

        startEngine()

        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self?.restart()
        }
        nc.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            self?.restart()
        }

        // Rendering takes a moment, so do it off the main thread.
        let format = self.format
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var sfx: [Sfx: AVAudioPCMBuffer] = [:]
            for s in Sfx.allCases {
                sfx[s] = Audio.makeBuffer(SoundBank.render(s), format: format)
            }
            DispatchQueue.main.async { self?.buffers = sfx }

            let music = Audio.makeBuffer(MusicBox.render(), format: format)
            DispatchQueue.main.async {
                guard let self else { return }
                self.musicBuffer = music
                if self.wantsMusic { self.startMusic() }
            }
        }
    }

    // MARK: Playback

    func play(_ sfx: Sfx, volume: Float = 1) {
        guard engine.isRunning, let buffer = buffers[sfx] else { return }

        let now = CACurrentMediaTime()
        if let gap = throttle[sfx], let last = lastPlayed[sfx], now - last < gap { return }
        lastPlayed[sfx] = now

        if sfx == .shoot {
            gunVoice.volume = volume
            gunVoice.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
            if !gunVoice.isPlaying { gunVoice.play() }
            return
        }

        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        voice.stop()
        voice.volume = volume
        voice.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        voice.play()
    }

    func playMusic() {
        wantsMusic = true
        startMusic()
    }

    func setMusicLevel(_ level: MusicLevel) {
        switch level {
        case .title: musicPlayer.volume = 0.4
        case .playing: musicPlayer.volume = 0.6
        case .dead: musicPlayer.volume = 0.18
        }
    }

    // MARK: Internals

    private func startMusic() {
        guard engine.isRunning, let buffer = musicBuffer, !musicPlayer.isPlaying else { return }
        musicPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        musicPlayer.play()
    }

    private func startEngine() {
        guard !engine.isRunning else { return }
        engine.prepare()
        try? engine.start()
    }

    private func restart() {
        try? AVAudioSession.sharedInstance().setActive(true)
        startEngine()
        if wantsMusic {
            musicPlayer.stop()
            startMusic()
        }
    }

    private static func makeBuffer(_ samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { src in
            channel.update(from: src.baseAddress!, count: samples.count)
        }
        return buffer
    }
}
