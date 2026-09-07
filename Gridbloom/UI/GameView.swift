import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var cosmetics: CosmeticsStore
    @EnvironmentObject private var profile: PlayerProfile
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @StateObject private var game: GameState
    @State private var scene: GameScene
    @State private var showBloomBanner = false
    @State private var bannerCombo = 0
    @State private var paused = false
    @State private var showSettings = false
    @State private var showOnboarding: Bool
    @State private var adMessage: String?
    var onExit: () -> Void

    init(mode: GameMode, onExit: @escaping () -> Void) {
        let state = GameState(mode: mode, profile: PlayerProfile.shared)
        _game = StateObject(wrappedValue: state)
        let theme = BoardTheme.theme(for: .garden, colorblind: false)
        let sk = GameScene(game: state, size: CGSize(width: 390, height: 844), theme: theme)
        _scene = State(initialValue: sk)
        self.onExit = onExit
        _showOnboarding = State(initialValue: !AppSettings.shared.hasCompletedOnboarding)
    }

    var body: some View {
        let theme = cosmetics.resolvedTheme
        let reduce = settings.prefersReducedMotion || systemReduceMotion
        return ZStack {
            GardenBackground(theme: theme)
            VStack(spacing: 0) {
                HUDView(
                    theme: theme,
                    score: game.score,
                    best: game.bestScore,
                    combo: game.combo,
                    modeTitle: modeTitle,
                    onPause: pause
                )
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(!paused && !game.isGameOver && adMessage == nil && !showOnboarding)
            }

            if showBloomBanner {
                ComboBanner(combo: bannerCombo, theme: theme)
                    .transition(reduce ? .opacity : .scale.combined(with: .opacity))
                    .padding(.bottom, 80)
                    .allowsHitTesting(false)
            }

            if paused, !game.isGameOver, adMessage == nil {
                Color.black.opacity(0.28).ignoresSafeArea()
                PauseView(
                    theme: theme,
                    onResume: resume,
                    onShuffle: requestShuffle,
                    onSettings: { showSettings = true },
                    onMenu: onExit
                )
                .transition(reduce ? .opacity : .scale.combined(with: .opacity))
            }

            if game.isGameOver, adMessage == nil, !showOnboarding {
                Color.black.opacity(0.28).ignoresSafeArea()
                GameOverView(
                    theme: theme,
                    score: game.score,
                    best: game.bestScore,
                    canContinue: game.canContinue,
                    onRestart: restart,
                    onContinue: requestContinue,
                    onMenu: onExit
                )
                .transition(reduce ? .opacity : .scale.combined(with: .opacity))
            }

            if let adMessage {
                Color.black.opacity(0.32).ignoresSafeArea()
                AdInterludeView(theme: theme, title: adMessage)
            }

            if showOnboarding {
                OnboardingView(theme: theme) {
                    settings.hasCompletedOnboarding = true
                    showOnboarding = false
                }
            }
        }
        .animation(reduce ? .easeOut(duration: 0.15) : .spring(response: 0.38, dampingFraction: 0.78), value: game.isGameOver)
        .animation(reduce ? .easeOut(duration: 0.15) : .spring(response: 0.38, dampingFraction: 0.78), value: paused)
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings, theme: theme, onClose: { showSettings = false })
        }
        .onAppear {
            scene.settings = settings
            scene.apply(theme: theme)
        }
        .onChange(of: cosmetics.selectedPack) { _ in
            scene.apply(theme: cosmetics.resolvedTheme)
        }
        .onChange(of: settings.colorblindPalette) { _ in
            scene.apply(theme: cosmetics.resolvedTheme)
        }
        .onChange(of: game.bloomPulse) { _ in
            bannerCombo = game.lastBloomCombo
            withAnimation(reduce ? .easeOut(duration: 0.12) : .spring(response: 0.32, dampingFraction: 0.7)) {
                showBloomBanner = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduce ? 0.45 : 0.95)) {
                withAnimation { showBloomBanner = false }
            }
        }
    }

    private var modeTitle: String {
        switch game.mode {
        case .classic: return "Classic"
        case .daily: return "Today’s Bloom"
        }
    }

    private func pause() {
        paused = true
        scene.isPausedOverlay = true
    }

    private func resume() {
        paused = false
        scene.isPausedOverlay = false
    }

    private func restart() {
        game.restart()
        scene.reloadFromState()
        paused = false
    }

    private func requestShuffle() {
        guard adMessage == nil else { return }
        adMessage = "Refreshing the tray"
        Task {
            let granted = await MonetizationHooks.presentRewarded(.shuffleTray)
            await MainActor.run {
                adMessage = nil
                guard granted else { return }
                game.applyRewardedShuffle()
                scene.reloadFromState()
                paused = false
            }
        }
    }

    private func requestContinue() {
        guard game.canContinue, adMessage == nil else { return }
        adMessage = "Bloom revive"
        Task {
            let granted = await MonetizationHooks.presentRewarded(.continueGame)
            await MainActor.run {
                adMessage = nil
                guard granted else { return }
                _ = game.applyRewardedContinue()
                scene.reloadFromState()
                paused = false
            }
        }
    }
}
