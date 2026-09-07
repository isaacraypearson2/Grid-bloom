import Foundation
import Combine
import SwiftUI
import UIKit

/// Player preferences. Sound uses `.ambient` so the hardware silent switch is respected.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var soundEnabled: Bool {
        didSet { persist(soundEnabled, key: Keys.sound) }
    }
    @Published var hapticsEnabled: Bool {
        didSet { persist(hapticsEnabled, key: Keys.haptics) }
    }
    @Published var colorblindPalette: Bool {
        didSet { persist(colorblindPalette, key: Keys.colorblind) }
    }
    @Published var reduceMotion: Bool {
        didSet { persist(reduceMotion, key: Keys.reduceMotion) }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { persist(hasCompletedOnboarding, key: Keys.onboarding) }
    }
    @Published var selectedThemeID: String {
        didSet { persist(selectedThemeID, key: Keys.theme) }
    }

    private let defaults: UserDefaults
    private var isHydrating = true

    private enum Keys {
        static let sound = "gridbloom.settings.sound"
        static let haptics = "gridbloom.settings.haptics"
        static let colorblind = "gridbloom.settings.colorblind"
        static let reduceMotion = "gridbloom.settings.reduceMotion"
        static let onboarding = "gridbloom.settings.onboarding"
        static let theme = "gridbloom.settings.theme"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.sound) == nil {
            soundEnabled = true
        } else {
            soundEnabled = defaults.bool(forKey: Keys.sound)
        }
        if defaults.object(forKey: Keys.haptics) == nil {
            hapticsEnabled = true
        } else {
            hapticsEnabled = defaults.bool(forKey: Keys.haptics)
        }
        colorblindPalette = defaults.bool(forKey: Keys.colorblind)
        reduceMotion = defaults.bool(forKey: Keys.reduceMotion)
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarding)
        selectedThemeID = defaults.string(forKey: Keys.theme) ?? CosmeticPack.garden.rawValue
        isHydrating = false
    }

    private func persist<T>(_ value: T, key: String) {
        guard !isHydrating else { return }
        defaults.set(value, forKey: key)
    }

    /// Combines the in-app toggle with Settings → Accessibility → Motion.
    var prefersReducedMotion: Bool {
        reduceMotion || UIAccessibility.isReduceMotionEnabled
    }
}
