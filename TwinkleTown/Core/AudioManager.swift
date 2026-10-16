import AVFoundation
import UIKit

enum Sound: CaseIterable {
    case tap, collect, match, achievement, levelComplete, purchase, reward, flip, gentleOops, place
}

/// Synthesizes all music and sound effects at runtime (soft sine/bell tones), so no audio files are needed.
final class AudioManager {
    static let shared = AudioManager()

    var soundOn = true
    var musicOn = true { didSet { musicOn ? startMusic() : stopMusic() } }
    var hapticsOn = true

    private let engine = AVAudioEngine()
    private let musicNode = AVAudioPlayerNode()
    private var sfxNodes: [AVAudioPlayerNode] = []
    private var nextSfx = 0
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var buffers: [Sound: AVAudioPCMBuffer] = [:]
    private var started = false
    private var musicPlaying = false

    private init() {}

    func apply(_ settings: Settings) {
        soundOn = settings.sound
        hapticsOn = settings.haptics
        if musicOn != settings.music { musicOn = settings.music } else if musicOn { startMusic() }
    }

    private func startEngineIfNeeded() -> Bool {
        if started { return engine.isRunning || (try? engine.start()) != nil }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        engine.attach(musicNode)
        engine.connect(musicNode, to: engine.mainMixerNode, format: format)
        for _ in 0..<4 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            sfxNodes.append(node)
        }
        musicNode.volume = 0.22
        started = true
        do { try engine.start() } catch { return false }
        return true
    }

    func play(_ sound: Sound) {
        guard soundOn, startEngineIfNeeded() else { return }
        let buffer = buffers[sound] ?? makeBuffer(notes(for: sound))
        buffers[sound] = buffer
        let node = sfxNodes[nextSfx]
        nextSfx = (nextSfx + 1) % sfxNodes.count
        node.stop()
        node.scheduleBuffer(buffer, at: nil)
        node.play()
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard hapticsOn else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func startMusic() {
        guard musicOn, !musicPlaying, startEngineIfNeeded() else { return }
        musicNode.scheduleBuffer(makeMusic(), at: nil, options: .loops)
        musicNode.play()
        musicPlaying = true
    }

    func stopMusic() {
        musicNode.stop()
        musicPlaying = false
    }

    // MARK: Synthesis

    /// (MIDI note, start beat, length beat); one beat = 0.1 s for effects.
    private typealias Note = (pitch: Int, start: Double, length: Double)

    private func notes(for sound: Sound) -> [Note] {
        switch sound {
        case .tap: [(84, 0, 0.6)]
        case .flip: [(79, 0, 0.5), (86, 0.3, 0.5)]
        case .place: [(72, 0, 0.8), (79, 0.4, 0.8)]
        case .collect: [(88, 0, 0.8), (93, 0.5, 1.2)]
        case .match: [(76, 0, 0.8), (81, 0.6, 0.8), (88, 1.2, 1.5)]
        case .gentleOops: [(67, 0, 1.2), (64, 1, 1.6)]
        case .purchase: [(72, 0, 1), (76, 0.8, 1), (79, 1.6, 1), (84, 2.4, 2)]
        case .reward: [(79, 0, 1), (84, 0.8, 1), (88, 1.6, 2.5)]
        case .achievement: [(72, 0, 1), (76, 1, 1), (79, 2, 1), (84, 3, 1), (88, 4, 3)]
        case .levelComplete: [(72, 0, 1.5), (76, 1.5, 1.5), (79, 3, 1.5), (84, 4.5, 1.5), (79, 6, 1), (84, 7, 5)]
        }
    }

    private func makeBuffer(_ notes: [Note], beat: Double = 0.1, volume: Float = 0.35) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let total = (notes.map { $0.start + $0.length }.max() ?? 1) * beat + 0.3
        let frames = AVAudioFrameCount(total * rate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let out = buffer.floatChannelData![0]
        for i in 0..<Int(frames) { out[i] = 0 }
        for note in notes {
            let freq = 440 * pow(2, Double(note.pitch - 69) / 12)
            let start = Int(note.start * beat * rate)
            let length = Int((note.length * beat + 0.25) * rate)
            for i in 0..<length where start + i < Int(frames) {
                let t = Double(i) / rate
                // Soft bell: fast attack, exponential decay, gentle overtone.
                let env = min(1, t * 200) * exp(-t * 6)
                let s = sin(2 * .pi * freq * t) + 0.3 * sin(4 * .pi * freq * t)
                out[start + i] += Float(s * env) * volume
            }
        }
        return buffer
    }

    /// A short, calm pentatonic music-box loop.
    private func makeMusic() -> AVAudioPCMBuffer {
        let melody = [72, 76, 79, 81, 79, 76, 74, 76, 72, 74, 76, 79, 76, 74, 72, 67,
                      69, 72, 74, 76, 74, 72, 69, 72, 74, 76, 79, 81, 84, 81, 79, 76]
        let bass = [48, 48, 45, 45, 43, 43, 48, 48]
        var notes: [Note] = melody.enumerated().map { ($1, Double($0) * 4, 6) }
        notes += bass.enumerated().map { ($1, Double($0) * 16, 14) }
        return makeBuffer(notes, beat: 0.12, volume: 0.18)
    }
}
