import AVFoundation
import Foundation

/// Procedural zen loops. No bundled stems — in-memory WAVs, category `.ambient`.
/// One hummed voice slowly changes pitch (hmmmmm → hummmmm → hmmmmm) with a
/// breathing swell and shifting partials — not a static sine wash or noise bed.
final class GardenMusic {
    static let shared = GardenMusic()

    enum Bed: Equatable {
        case home
        case garden
    }

    /// Four 6-second hummed phrases. Modulation rates divide this so the loop seams.
    static let loopDurationSeconds = 24.0
    static let sampleRate = 22_050.0

    private var player: AVAudioPlayer?
    private var current: Bed?
    private var requested: Bed?
    private var cache: [Bed: Data] = [:]
    private let lock = NSLock()

    func refresh() {
        if let requested {
            current = nil
            play(requested)
        }
    }

    func play(_ bed: Bed) {
        requested = bed
        guard AppSettings.shared.soundEnabled, AppSettings.shared.musicEnabled else {
            haltPlayback()
            return
        }
        lock.lock()
        let already = current == bed && player?.isPlaying == true
        lock.unlock()
        if already { return }

        SoundPlayer.shared.prepareSession()
        guard let data = loopData(bed) else { return }
        do {
            let next = try AVAudioPlayer(data: data)
            next.numberOfLoops = -1
            next.volume = bed == .garden ? 0.20 : 0.14
            next.prepareToPlay()
            next.play()
            lock.lock()
            player?.stop()
            player = next
            current = bed
            lock.unlock()
        } catch {
            haltPlayback()
        }
    }

    func stop() {
        requested = nil
        haltPlayback()
    }

    private func haltPlayback() {
        lock.lock()
        player?.stop()
        player = nil
        current = nil
        lock.unlock()
    }

    private func loopData(_ bed: Bed) -> Data? {
        lock.lock()
        if let cached = cache[bed] {
            lock.unlock()
            return cached
        }
        lock.unlock()
        let data = Self.renderLoop(bed)
        lock.lock()
        cache[bed] = data
        lock.unlock()
        return data
    }

    /// 24-second 22050 Hz mono 16-bit WAV of a hummed pitch contour plus a quiet pedal.
    static func renderLoop(_ bed: Bed) -> Data? {
        let n = Int(sampleRate * loopDurationSeconds)
        var samples = [Int16](repeating: 0, count: n)
        let twoPi = 2.0 * Double.pi
        let spec = VoiceSpec(bed)
        var voicePhase = 0.0
        var detunePhase = 0.0
        var pedalPhase = 0.0
        let fadeSamples = 1_200.0

        for i in 0..<n {
            let t = Double(i) / sampleRate
            let hz = hummedPitch(t, spec: spec)
            let vibrato = pow(2.0, spec.vibratoCents * sin(twoPi * spec.vibratoHz * t) / 1_200.0)
            let freq = hz * vibrato

            let voice = hummedPartialMix(phase: voicePhase, spec: spec, t: t)
            voicePhase = wrapPhase(voicePhase + twoPi * freq / sampleRate)

            let detune = sin(detunePhase) * spec.detuneMix
            detunePhase = wrapPhase(detunePhase + twoPi * freq * spec.detuneRatio / sampleRate)

            let pedal = (sin(pedalPhase) + 0.28 * sin(2 * pedalPhase)) * spec.pedalGain
            pedalPhase = wrapPhase(pedalPhase + twoPi * spec.pedalHz / sampleRate)

            let breath = phraseBreath(t, spec: spec)
            let pulse = 0.93 + spec.pulseDepth * sin(twoPi * spec.pulseHz * t)
            let fade = min(1, Double(i) / fadeSamples, Double(n - 1 - i) / fadeSamples)

            let mix = (voice + detune) * spec.voiceGain * breath * pulse + pedal * (0.72 + 0.28 * breath)
            let clamped = max(-1, min(1, mix * fade))
            samples[i] = Int16(clamped * Double(Int16.max - 1))
        }
        return wav(samples: samples, sampleRate: UInt32(sampleRate))
    }

    /// Sequential hummed centers (not a stacked chord). Last phrase glides back to the first.
    static func hummedPitch(_ t: Double, bed: Bed) -> Double {
        hummedPitch(t, spec: VoiceSpec(bed))
    }

    private struct VoiceSpec {
        let pitches: [Double]
        let phraseSeconds: Double
        let glideSeconds: Double
        let pedalHz: Double
        let pedalGain: Double
        let voiceGain: Double
        let vibratoHz: Double
        let vibratoCents: Double
        let pulseHz: Double
        let pulseDepth: Double
        let detuneRatio: Double
        let detuneMix: Double
        let breathFloor: Double
        let h2Center: Double
        let h2Wander: Double
        let h3Center: Double
        let h3Wander: Double
        let h4Center: Double
        let h4Wander: Double
        let partialWanderHz: Double

        init(_ bed: Bed) {
            phraseSeconds = 6
            glideSeconds = 1.35
            detuneRatio = pow(2.0, 3.5 / 1_200.0)
            switch bed {
            case .home:
                // C4 → D4 → E4 → D4 — close neighbor tones, pentatonic, not a held triad.
                pitches = [261.63, 293.66, 329.63, 293.66]
                pedalHz = 196.00
                pedalGain = 0.022
                voiceGain = 0.16
                vibratoHz = 2.0 / 3.0
                vibratoCents = 7
                pulseHz = 1.0 / GardenMusic.loopDurationSeconds
                pulseDepth = 0.05
                detuneMix = 0.22
                breathFloor = 0.34
                h2Center = 0.40
                h2Wander = 0.08
                h3Center = 0.18
                h3Wander = 0.07
                h4Center = 0.07
                h4Wander = 0.03
                partialWanderHz = 1.0 / 12.0
            case .garden:
                // D3 → C3 → G2 → C3 — lower, wider, more drone-like.
                pitches = [146.83, 130.81, 98.00, 130.81]
                pedalHz = 73.42
                pedalGain = 0.036
                voiceGain = 0.18
                vibratoHz = 0.5
                vibratoCents = 5
                pulseHz = 1.0 / GardenMusic.loopDurationSeconds
                pulseDepth = 0.04
                detuneMix = 0.16
                breathFloor = 0.46
                h2Center = 0.30
                h2Wander = 0.06
                h3Center = 0.11
                h3Wander = 0.04
                h4Center = 0.035
                h4Wander = 0.015
                partialWanderHz = 1.0 / 24.0
            }
        }
    }

    private static func hummedPitch(_ t: Double, spec: VoiceSpec) -> Double {
        let pitches = spec.pitches
        let phrase = spec.phraseSeconds
        let loop = loopDurationSeconds
        var wrapped = t.truncatingRemainder(dividingBy: loop)
        if wrapped < 0 { wrapped += loop }
        var index = Int(wrapped / phrase)
        if index >= pitches.count { index = pitches.count - 1 }
        let local = wrapped - Double(index) * phrase
        let current = pitches[index]
        let next = pitches[(index + 1) % pitches.count]
        let glideStart = phrase - spec.glideSeconds
        guard local > glideStart, spec.glideSeconds > 0, current > 0, next > 0 else {
            return current
        }
        let u = min(1, max(0, (local - glideStart) / spec.glideSeconds))
        let s = u * u * (3 - 2 * u)
        return current * pow(next / current, s)
    }

    private static func phraseBreath(_ t: Double, spec: VoiceSpec) -> Double {
        var local = t.truncatingRemainder(dividingBy: spec.phraseSeconds)
        if local < 0 { local += spec.phraseSeconds }
        let x = local / spec.phraseSeconds
        let swell = 0.5 - 0.5 * cos(2 * Double.pi * x)
        return spec.breathFloor + (1 - spec.breathFloor) * swell
    }

    private static func hummedPartialMix(phase: Double, spec: VoiceSpec, t: Double) -> Double {
        let wander = 2 * Double.pi * spec.partialWanderHz * t
        let h2 = spec.h2Center + spec.h2Wander * sin(wander)
        let h3 = spec.h3Center + spec.h3Wander * sin(wander + 1.7)
        let h4 = spec.h4Center + spec.h4Wander * sin(wander * 0.5 + 0.6)
        return sin(phase) + h2 * sin(2 * phase) + h3 * sin(3 * phase) + h4 * sin(4 * phase)
    }

    private static func wrapPhase(_ phase: Double) -> Double {
        let twoPi = 2.0 * Double.pi
        var wrapped = phase.truncatingRemainder(dividingBy: twoPi)
        if wrapped < 0 { wrapped += twoPi }
        return wrapped
    }

    private static func wav(samples: [Int16], sampleRate: UInt32) -> Data {
        let dataSize = UInt32(samples.count * 2)
        var data = Data()
        func ascii(_ s: String) { data.append(contentsOf: s.utf8) }
        func u16(_ v: UInt16) {
            var le = v.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }
        func u32(_ v: UInt32) {
            var le = v.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }
        ascii("RIFF")
        u32(36 + dataSize)
        ascii("WAVE")
        ascii("fmt ")
        u32(16)
        u16(1)
        u16(1)
        u32(sampleRate)
        u32(sampleRate * 2)
        u16(2)
        u16(16)
        ascii("data")
        u32(dataSize)
        samples.withUnsafeBytes { data.append(contentsOf: $0) }
        return data
    }
}
