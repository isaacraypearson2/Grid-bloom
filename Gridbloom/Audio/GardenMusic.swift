import AVFoundation
import Foundation

/// Procedural zen loops. No bundled stems — short in-memory WAVs, category `.ambient`.
/// Home: light pentatonic pad. My Garden: slower, lower drone.
final class GardenMusic {
    static let shared = GardenMusic()

    enum Bed: Equatable {
        case home
        case garden
    }

    private var player: AVAudioPlayer?
    private var current: Bed?
    private var requested: Bed?
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
        guard let data = Self.renderLoop(bed) else { return }
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

    /// 8-second 22050 Hz mono 16-bit WAV of stacked sines with a slow amplitude envelope.
    static func renderLoop(_ bed: Bed) -> Data? {
        let sampleRate = 22_050.0
        let seconds = 8.0
        let n = Int(sampleRate * seconds)
        let freqs: [Double]
        let tremolo: Double
        switch bed {
        case .home:
            freqs = [261.63, 329.63, 392.00, 523.25]
            tremolo = 0.18
        case .garden:
            freqs = [130.81, 196.00, 246.94, 329.63]
            tremolo = 0.12
        }
        var samples = [Int16](repeating: 0, count: n)
        let twoPi = 2.0 * Double.pi
        for i in 0..<n {
            let t = Double(i) / sampleRate
            var mix = 0.0
            for (index, f) in freqs.enumerated() {
                let amp = 0.09 / Double(index + 1)
                mix += sin(twoPi * f * t) * amp
            }
            let env = 0.72 + tremolo * sin(twoPi * (bed == .garden ? 0.07 : 0.11) * t)
            // Fade the loop seam.
            let fade = min(1, Double(i) / 1400, Double(n - 1 - i) / 1400)
            let clamped = max(-1, min(1, mix * env * fade))
            samples[i] = Int16(clamped * Double(Int16.max - 1))
        }
        return wav(samples: samples, sampleRate: UInt32(sampleRate))
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
