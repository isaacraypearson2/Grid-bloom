import AVFoundation
import Foundation

/// Soft garden clicks played from bundled 16-bit WAV files.
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [AVAudioPlayer] = []
    private let lock = NSLock()

    func click() { play(resource: "click") }
    func place() { play(resource: "place") }
    func bloom() { play(resource: "clear") }

    private func play(resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.45
            player.prepareToPlay()
            player.play()
            lock.lock()
            players.append(player)
            players = players.filter { $0.isPlaying }
            lock.unlock()
        } catch {
            // Audio is optional juice; never crash if a file is missing.
        }
    }
}
