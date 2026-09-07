import AVFoundation
import Foundation
import UIKit

/// Garden SFX. Category `.ambient` ducks to the hardware silent switch and other audio.
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [AVAudioPlayer] = []
    private let lock = NSLock()
    private var sessionReady = false

    func prepareSession() {
        guard !sessionReady else { return }
        sessionReady = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Still play if the session fails; the silent switch may not apply.
        }
    }

    func uiTap() { play(resource: "ui", volume: 0.28) }
    func click() { play(resource: "click", volume: 0.36) }
    func place() { play(resource: "place", volume: 0.42) }
    func bloom(combo: Int = 1) {
        if combo >= 2 {
            play(resource: "combo", volume: min(0.55, 0.34 + Float(combo) * 0.04))
        } else {
            play(resource: "clear", volume: 0.44)
        }
    }

    private func play(resource: String, volume: Float) {
        guard AppSettings.shared.soundEnabled else { return }
        prepareSession()
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            lock.lock()
            players.append(player)
            players = players.filter { $0.isPlaying }
            lock.unlock()
        } catch {}
    }
}

enum Haptics {
    static func light() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func error() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func success() {
        guard AppSettings.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
