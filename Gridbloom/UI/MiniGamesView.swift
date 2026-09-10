import SwiftUI
import SpriteKit

struct MiniGamesView: View {
    var theme: BoardTheme
    var orchidUnlocked: Bool
    var peonyUnlocked: Bool
    var greenhouseOwned: Bool
    var onPetalCatch: () -> Void
    var onPatternBloom: () -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Side gardens")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Text("Short games that unlock flowers and maps. Classic Garden stays free to play.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                gameCard(
                    title: MiniGameKind.petalCatch.title,
                    blurb: MiniGameKind.petalCatch.blurb,
                    reward: orchidUnlocked ? "Orchid collected" : "Unlocks Orchid",
                    systemImage: "leaf.fill",
                    action: onPetalCatch
                )
                gameCard(
                    title: MiniGameKind.patternBloom.title,
                    blurb: MiniGameKind.patternBloom.blurb,
                    reward: greenhouseOwned && peonyUnlocked ? "Peony & Glasshouse yours" : "Unlocks Peony + Glasshouse",
                    systemImage: "sparkles",
                    action: onPatternBloom
                )

                Spacer()
            }
            .padding(22)
        }
    }

    private func gameCard(title: String, blurb: String, reward: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            SoundPlayer.shared.uiTap()
            Haptics.light()
            action()
        }) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(theme.ink)
                    Text(blurb)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                        .multilineTextAlignment(.leading)
                    Text(reward)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.accent)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.inkSoft)
            }
            .padding(16)
            .background(theme.cream.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct PetalCatchView: View {
    var theme: BoardTheme
    var reducedMotion: Bool
    var onExit: () -> Void
    var onFinished: (Int, Bool) -> Void

    @State private var scene: PetalCatchScene

    init(theme: BoardTheme, reducedMotion: Bool, onExit: @escaping () -> Void, onFinished: @escaping (Int, Bool) -> Void) {
        self.theme = theme
        self.reducedMotion = reducedMotion
        self.onExit = onExit
        self.onFinished = onFinished
        let scene = PetalCatchScene(size: CGSize(width: 390, height: 720))
        scene.scaleMode = .resizeFill
        scene.reducedMotion = reducedMotion
        scene.onFinished = onFinished
        _scene = State(initialValue: scene)
    }

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(spacing: 0) {
                HStack {
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onExit)
                    Spacer()
                    Text("Petal Catch")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(theme.ink)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Text("Tap petals before they wilt. Catch \(PetalCatchRules.winCatches) to invite Orchid.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                    .padding(.bottom, 8)
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            scene.reducedMotion = reducedMotion
            scene.onFinished = { caught, won in
                onFinished(caught, won)
            }
        }
    }
}
