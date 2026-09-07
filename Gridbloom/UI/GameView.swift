import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var game: GameState
    @State private var scene: GameScene
    @State private var showBloomBanner = false
    @State private var bannerCombo = 0
    var onExit: () -> Void

    init(mode: GameMode, onExit: @escaping () -> Void) {
        let state = GameState(mode: mode)
        _game = StateObject(wrappedValue: state)
        let sk = GameScene(game: state, size: CGSize(width: 390, height: 844))
        _scene = State(initialValue: sk)
        self.onExit = onExit
    }

    var body: some View {
        ZStack {
            GardenBackground()
            VStack(spacing: 0) {
                HUDView(
                    score: game.score,
                    best: game.bestScore,
                    combo: game.combo,
                    modeTitle: modeTitle,
                    onBack: onExit,
                    onShuffle: requestShuffle
                )
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
            }

            if showBloomBanner {
                ComboBanner(combo: bannerCombo)
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, 120)
            }

            if game.isGameOver {
                Color.black.opacity(0.28).ignoresSafeArea()
                GameOverView(
                    score: game.score,
                    best: game.bestScore,
                    onRestart: restart,
                    onContinue: requestContinue,
                    onMenu: onExit
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: game.isGameOver)
        .onAppear {
            scene.onNeedsHUD = {}
        }
        .onChange(of: game.bloomPulse) { _ in
            bannerCombo = game.lastBloomCombo
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                showBloomBanner = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
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

    private func restart() {
        game.restart()
        scene.reloadFromState()
    }

    private func requestShuffle() {
        MonetizationHooks.presentRewardedShuffle { granted in
            DispatchQueue.main.async {
                guard granted else { return }
                game.applyRewardedShuffle()
                scene.reloadFromState()
            }
        }
    }

    private func requestContinue() {
        MonetizationHooks.presentRewardedContinue { granted in
            DispatchQueue.main.async {
                guard granted else { return }
                game.applyRewardedContinue()
                scene.reloadFromState()
            }
        }
    }
}
