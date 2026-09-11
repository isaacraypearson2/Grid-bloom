import AVFoundation
import Foundation

/// Procedural zen loops. No bundled stems — in-memory WAVs, category `.ambient`.
///
/// Artistic map (not a science simulation): mycelium networks fire sparse,
/// irregular bioelectric spikes. Those voltage-like events become soft pitched
/// tones — plucks, short overshoot “spikes,” and slower pad swells — with
/// organic timing jitter and quiet space between them. The *mood* is calm
/// video-game ambient (warm, sparse, slightly melancholic) without copying
/// any third-party melody or stem.
final class GardenMusic {
    static let shared = GardenMusic()

    enum Bed: Equatable {
        case home
        case garden
    }

    /// Long enough that the irregular spike train does not feel like a short phrase.
    static let loopDurationSeconds = 48.0
    static let sampleRate = 22_050.0

    enum PulseKind: String, Equatable {
        case pluck
        case spike
        case swell
    }

    struct PulseEvent: Equatable {
        let start: Double
        let hz: Double
        let duration: Double
        let gain: Double
        let kind: PulseKind
    }

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
            // Sparse beds need a little more playback gain than the old continuous hum.
            next.volume = bed == .garden ? 0.34 : 0.30
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

    /// Authored mycelium events only (no delay tails). Home is softer / higher;
    /// garden is denser and earthier.
    static func pulseEvents(_ bed: Bed) -> [PulseEvent] {
        BedSpec(bed).pulses
    }

    static func chirpStarts(_ bed: Bed) -> [Double] {
        BedSpec(bed).chirps.map(\.start)
    }

    /// 48-second 22050 Hz mono 16-bit WAV: quiet warm pad + spike-train tones + birds.
    static func renderLoop(_ bed: Bed) -> Data? {
        let spec = BedSpec(bed)
        let pulses = spec.pulses + echoTails(spec.pulses)
        let n = Int(sampleRate * loopDurationSeconds)
        var samples = [Int16](repeating: 0, count: n)
        let twoPi = 2.0 * Double.pi
        var padPhases = [Double](repeating: 0, count: spec.pads.count)
        var detunePhases = [Double](repeating: 0, count: spec.pads.count)
        var pulsePhases = [Double](repeating: 0, count: pulses.count)
        let detuneRatio = pow(2.0, spec.detuneCents / 1_200.0)
        var brown = 0.0
        var rng: UInt64 = spec.soilSeed
        let fadeSamples = 1_800.0

        for i in 0..<n {
            let t = Double(i) / sampleRate
            var localBreath = t.truncatingRemainder(dividingBy: spec.breathSeconds)
            if localBreath < 0 { localBreath += spec.breathSeconds }
            let breathX = localBreath / spec.breathSeconds
            let breath = spec.breathFloor + (1 - spec.breathFloor) * (0.5 - 0.5 * cos(twoPi * breathX))
            let wander = 0.5 + 0.5 * sin(twoPi * t / 24.0)

            var pad = 0.0
            for k in spec.pads.indices {
                let partial = spec.pads[k]
                let osc = sin(padPhases[k])
                    + spec.padH2 * wander * sin(2 * padPhases[k])
                    + spec.padH3 * sin(3 * padPhases[k])
                    + 0.35 * sin(detunePhases[k])
                pad += osc * partial.gain
                padPhases[k] = wrapPhase(padPhases[k] + twoPi * partial.hz / sampleRate)
                detunePhases[k] = wrapPhase(detunePhases[k] + twoPi * partial.hz * detuneRatio / sampleRate)
            }

            var voice = 0.0
            for k in pulses.indices {
                let pulse = pulses[k]
                let u = t - pulse.start
                guard u >= 0, u <= pulse.duration else { continue }
                let env: Double
                let bright: Double
                let freq: Double
                switch pulse.kind {
                case .pluck:
                    env = pluckEnvelope(u, duration: pulse.duration)
                    bright = 0.20
                    freq = pulse.hz
                case .spike:
                    env = spikeEnvelope(u, duration: pulse.duration)
                    bright = 0.38
                    freq = pulse.hz * (1 + 0.016 * exp(-u / 0.045))
                case .swell:
                    env = swellEnvelope(u, duration: pulse.duration)
                    bright = 0.16
                    freq = pulse.hz
                }
                var osc = sin(pulsePhases[k]) + bright * sin(2 * pulsePhases[k])
                if pulse.kind == .spike {
                    osc += 0.10 * sin(3 * pulsePhases[k])
                }
                voice += osc * env * pulse.gain
                pulsePhases[k] = wrapPhase(pulsePhases[k] + twoPi * freq / sampleRate)
            }

            let birds = chirpMix(t, chirps: spec.chirps)
            var dirt = 0.0
            if spec.soilGain > 0 {
                rng = rng &* 6_364_136_223_846_793_005 &+ 1
                let white = Double(rng >> 11) / 9_007_199_254_740_992.0 * 2 - 1
                brown = brown * 0.995 + white * 0.05
                dirt = brown * spec.soilGain * (0.7 + 0.3 * breath)
            }

            let mix = pad * (0.62 + 0.38 * breath) + voice + birds + dirt
            let fade = min(1, Double(i) / fadeSamples, Double(n - 1 - i) / fadeSamples)
            let clamped = max(-1, min(1, mix * fade))
            samples[i] = Int16(clamped * Double(Int16.max - 1))
        }
        return wav(samples: samples, sampleRate: UInt32(sampleRate))
    }

    private struct Chirp {
        let start: Double
        let duration: Double
        let f0: Double
        let f1: Double
        let gain: Double
    }

    private struct PadPartial {
        let hz: Double
        let gain: Double
    }

    private struct BedSpec {
        let pads: [PadPartial]
        let breathSeconds: Double
        let breathFloor: Double
        let padH2: Double
        let padH3: Double
        let detuneCents: Double
        let soilGain: Double
        let soilSeed: UInt64
        let pulses: [PulseEvent]
        let chirps: [Chirp]

        init(_ bed: Bed) {
            switch bed {
            case .home:
                // Softer indoor bed: Bb-major pentatonic float, fewer spikes, distant birds.
                pads = [PadPartial(hz: 233.08, gain: 0.016), PadPartial(hz: 349.23, gain: 0.008)]
                breathSeconds = 12
                breathFloor = 0.22
                padH2 = 0.28
                padH3 = 0.10
                detuneCents = 6.5
                soilGain = 0
                soilSeed = 0xC0FFEE
                pulses = [
                    PulseEvent(start: 0.92, hz: 233.08, duration: 2.70, gain: 0.155, kind: .pluck),
                    PulseEvent(start: 4.85, hz: 293.66, duration: 2.40, gain: 0.138, kind: .pluck),
                    PulseEvent(start: 9.40, hz: 174.61, duration: 5.60, gain: 0.088, kind: .swell),
                    PulseEvent(start: 14.35, hz: 349.23, duration: 2.20, gain: 0.128, kind: .pluck),
                    PulseEvent(start: 18.10, hz: 261.63, duration: 0.78, gain: 0.102, kind: .spike),
                    PulseEvent(start: 18.56, hz: 293.66, duration: 0.60, gain: 0.074, kind: .spike),
                    PulseEvent(start: 22.55, hz: 233.08, duration: 4.30, gain: 0.092, kind: .swell),
                    PulseEvent(start: 27.20, hz: 392.00, duration: 2.20, gain: 0.100, kind: .pluck),
                    PulseEvent(start: 31.15, hz: 261.63, duration: 2.50, gain: 0.118, kind: .pluck),
                    PulseEvent(start: 36.40, hz: 293.66, duration: 4.80, gain: 0.080, kind: .swell),
                    PulseEvent(start: 41.25, hz: 233.08, duration: 2.40, gain: 0.112, kind: .pluck),
                    PulseEvent(start: 44.80, hz: 174.61, duration: 2.20, gain: 0.090, kind: .pluck)
                ]
                chirps = [
                    Chirp(start: 11.82, duration: 0.11, f0: 2_080, f1: 2_560, gain: 0.008),
                    Chirp(start: 28.62, duration: 0.10, f0: 2_360, f1: 1_880, gain: 0.007),
                    Chirp(start: 39.55, duration: 0.09, f0: 1_980, f1: 2_420, gain: 0.0065)
                ]
            case .garden:
                // More nature / mycelium: G-minor earth tones, bursty spike trains, closer birds.
                pads = [
                    PadPartial(hz: 98.00, gain: 0.022),
                    PadPartial(hz: 146.83, gain: 0.012),
                    PadPartial(hz: 116.54, gain: 0.007)
                ]
                breathSeconds = 16
                breathFloor = 0.28
                padH2 = 0.22
                padH3 = 0.07
                detuneCents = 5
                soilGain = 0.006
                soilSeed = 0xA11CE
                pulses = [
                    PulseEvent(start: 0.48, hz: 146.83, duration: 0.70, gain: 0.148, kind: .spike),
                    PulseEvent(start: 0.98, hz: 174.61, duration: 0.58, gain: 0.118, kind: .spike),
                    PulseEvent(start: 3.70, hz: 196.00, duration: 2.50, gain: 0.150, kind: .pluck),
                    PulseEvent(start: 7.45, hz: 98.00, duration: 5.40, gain: 0.092, kind: .swell),
                    PulseEvent(start: 11.60, hz: 233.08, duration: 2.25, gain: 0.136, kind: .pluck),
                    PulseEvent(start: 14.35, hz: 146.83, duration: 0.72, gain: 0.152, kind: .spike),
                    PulseEvent(start: 14.74, hz: 174.61, duration: 0.64, gain: 0.122, kind: .spike),
                    PulseEvent(start: 15.18, hz: 196.00, duration: 0.72, gain: 0.100, kind: .spike),
                    PulseEvent(start: 18.80, hz: 261.63, duration: 3.80, gain: 0.100, kind: .swell),
                    PulseEvent(start: 22.70, hz: 174.61, duration: 2.30, gain: 0.138, kind: .pluck),
                    PulseEvent(start: 26.15, hz: 146.83, duration: 0.68, gain: 0.140, kind: .spike),
                    PulseEvent(start: 26.58, hz: 220.00, duration: 0.60, gain: 0.108, kind: .spike),
                    PulseEvent(start: 29.40, hz: 196.00, duration: 2.50, gain: 0.126, kind: .pluck),
                    PulseEvent(start: 33.10, hz: 116.54, duration: 2.80, gain: 0.110, kind: .pluck),
                    PulseEvent(start: 37.05, hz: 146.83, duration: 0.66, gain: 0.136, kind: .spike),
                    PulseEvent(start: 37.48, hz: 174.61, duration: 0.55, gain: 0.108, kind: .spike),
                    PulseEvent(start: 37.95, hz: 233.08, duration: 0.62, gain: 0.090, kind: .spike),
                    PulseEvent(start: 40.80, hz: 98.00, duration: 4.60, gain: 0.086, kind: .swell),
                    PulseEvent(start: 45.20, hz: 196.00, duration: 2.20, gain: 0.120, kind: .pluck)
                ]
                chirps = [
                    Chirp(start: 6.38, duration: 0.13, f0: 1_680, f1: 2_280, gain: 0.014),
                    Chirp(start: 6.60, duration: 0.11, f0: 2_160, f1: 1_720, gain: 0.011),
                    Chirp(start: 12.28, duration: 0.15, f0: 1_460, f1: 1_940, gain: 0.012),
                    Chirp(start: 19.52, duration: 0.11, f0: 2_480, f1: 1_980, gain: 0.010),
                    Chirp(start: 19.72, duration: 0.10, f0: 2_040, f1: 1_640, gain: 0.008),
                    Chirp(start: 31.18, duration: 0.12, f0: 1_880, f1: 2_320, gain: 0.011),
                    Chirp(start: 43.35, duration: 0.13, f0: 1_720, f1: 2_140, gain: 0.012),
                    Chirp(start: 43.58, duration: 0.10, f0: 2_100, f1: 1_680, gain: 0.009)
                ]
            }
        }
    }

    /// Quiet delay tails so notes have a little air without a convolution reverb.
    private static func echoTails(_ pulses: [PulseEvent]) -> [PulseEvent] {
        var tails: [PulseEvent] = []
        tails.reserveCapacity(pulses.count * 2)
        for pulse in pulses where pulse.kind != .swell {
            tails.append(
                PulseEvent(
                    start: pulse.start + 0.38,
                    hz: pulse.hz * pow(2.0, -12.0 / 1_200.0),
                    duration: min(pulse.duration * 0.85, 2.1),
                    gain: pulse.gain * 0.20,
                    kind: pulse.kind
                )
            )
            tails.append(
                PulseEvent(
                    start: pulse.start + 0.78,
                    hz: pulse.hz * pow(2.0, -24.0 / 1_200.0),
                    duration: min(pulse.duration * 0.70, 1.7),
                    gain: pulse.gain * 0.08,
                    kind: pulse.kind
                )
            )
        }
        return tails
    }

    private static func pluckEnvelope(_ u: Double, duration: Double) -> Double {
        let attack = 0.028
        guard u >= 0, u <= duration, duration > 0 else { return 0 }
        if u < attack {
            let x = u / attack
            return x * x * (3 - 2 * x)
        }
        let x = (u - attack) / max(1e-9, duration - attack)
        return exp(-2.6 * x) * (1 - 0.12 * x)
    }

    private static func spikeEnvelope(_ u: Double, duration: Double) -> Double {
        let attack = 0.011
        guard u >= 0, u <= duration, duration > 0 else { return 0 }
        if u < attack {
            return pow(u / attack, 0.7)
        }
        let x = (u - attack) / max(1e-9, duration - attack)
        return exp(-4.8 * x)
    }

    private static func swellEnvelope(_ u: Double, duration: Double) -> Double {
        guard u >= 0, u <= duration, duration > 0 else { return 0 }
        return pow(sin(Double.pi * u / duration), 1.15)
    }

    private static func chirpMix(_ t: Double, chirps: [Chirp]) -> Double {
        var mix = 0.0
        for chirp in chirps {
            let u = t - chirp.start
            guard u >= 0, u <= chirp.duration, chirp.duration > 0, chirp.f0 > 0 else { continue }
            let x = u / chirp.duration
            let env = sin(Double.pi * x) * exp(-2.8 * x)
            let ratio = chirp.f1 / chirp.f0
            let phase: Double
            if abs(ratio - 1) < 1e-4 {
                phase = 2 * Double.pi * chirp.f0 * u
            } else {
                phase = 2 * Double.pi * chirp.f0 * chirp.duration / log(ratio) * (pow(ratio, x) - 1)
            }
            mix += (sin(phase) + 0.16 * sin(2 * phase)) * env * chirp.gain
        }
        return mix
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
