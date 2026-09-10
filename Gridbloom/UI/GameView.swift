import SwiftUI
import SpriteKit
import Combine

/// Owns the match and the SpriteKit scene together so SwiftUI `body` never
/// reconstructs `GameState` / `GameScene` while evaluating `ContentView`.
final class GameSession: ObservableObject {
    let game: GameState
    let scene: GameScene
    private var forwarding: AnyCancellable?

    init(mode: GameMode) {
        let game = GameState(mode: mode)
        self.game = game
        self.scene = GameScene(
            game: game,
            size: CGSize(width: 390, height: 844),
            theme: BoardTheme.theme(for: .garden, colorblind: false)
        )
        forwarding = game.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}

struct GameView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var cosmetics: CosmeticsStore
    @EnvironmentObject private var profile: PlayerProfile
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    @StateObject private var session: GameSession
    @State private var showBloomBanner = false
    @State private var bannerCombo = 0
    @State private var paused = false
    @State private var showSettings = false
    @State private var showOnboarding: Bool
    @State private var adMessage: String?
    var onExit: () -> Void

    private var game: GameState { session.game }
    private var scene: GameScene { session.scene }

    init(mode: GameMode, onExit: @escaping () -> Void) {
        self.onExit = onExit
        // Keep `GameSession(...)` inside `StateObject(wrappedValue:)` so SwiftUI's
        // autoclosure owns it. Never `let session = GameSession(...); _session = ...`
        // — that reconstructs GameState on every parent `body` evaluation.
        _session = StateObject(wrappedValue: GameSession(mode: mode))
        _showOnboarding = State(initialValue: !AppSettings.shared.hasCompletedOnboarding)
    }

    var body: some View {
        let theme = playTheme
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
                    petals: profile.petals,
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

            if showOnboarding == false, game.score == 0, !paused, !game.isGameOver, profile.gamesPlayed <= 1 {
                VStack {
                    Spacer()
                    Text("Drag a flower onto the garden")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(theme.cream.opacity(0.92))
                        .clipShape(Capsule())
                        .padding(.bottom, 28)
                }
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
            // Store the profile pointer without publishing. Increment stats on the
            // next run-loop turn so @Published updates cannot re-enter ContentView.body.
            game.attachProfile(profile)
            scene.settings = settings
            scene.syncProfile(profile)
            scene.apply(theme: playTheme, colorblind: settings.colorblindPalette)
            DispatchQueue.main.async {
                game.recordSessionStartIfNeeded()
            }
        }
        .onChange(of: cosmetics.selectedPack) { _ in
            guard game.mode.usesPlayerMapSkin else { return }
            scene.apply(theme: playTheme, colorblind: settings.colorblindPalette)
        }
        .onChange(of: settings.colorblindPalette) { _ in
            scene.apply(theme: playTheme, colorblind: settings.colorblindPalette)
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
        .onChange(of: profile.lastClaimedGoalIDs) { ids in
            guard !ids.isEmpty else { return }
            Haptics.success()
        }
    }

    private var playTheme: BoardTheme {
        if !game.mode.usesPlayerMapSkin, let pack = game.mode.stage?.themePack {
            return BoardTheme.theme(for: pack, colorblind: settings.colorblindPalette)
        }
        return cosmetics.resolvedTheme
    }

    private var modeTitle: String {
        switch game.mode {
        case .classic: return "Classic"
        case .daily: return "Today’s Bloom"
        case .stage(let id): return GardenStageCatalog.stage(id: id)?.title ?? "Garden"
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
                guard granted else {
                    Haptics.error()
                    return
                }
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
                guard granted else {
                    Haptics.error()
                    return
                }
                _ = game.applyRewardedContinue()
                scene.reloadFromState()
                paused = false
            }
        }
    }
}
