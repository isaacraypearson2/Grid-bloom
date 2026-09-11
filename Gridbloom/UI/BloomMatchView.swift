import SwiftUI

struct BloomMatchView: View {
    var theme: BoardTheme
    var onExit: () -> Void
    var onFinished: (Bool, Int) -> Void

    @State private var game: BloomMatchGame
    @State private var status = "Flip two tiles to match a color variant"

    init(
        theme: BoardTheme,
        seed: UInt64 = UInt64(Date().timeIntervalSince1970),
        onExit: @escaping () -> Void,
        onFinished: @escaping (Bool, Int) -> Void
    ) {
        self.theme = theme
        self.onExit = onExit
        self.onFinished = onFinished
        _game = State(initialValue: BloomMatchGame(seed: seed))
    }

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(spacing: 14) {
                HStack {
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onExit)
                    Spacer()
                    Text("\(game.remainingMismatches) misses left")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                }
                .padding(.horizontal, 20)

                Text("Bloom Match")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                Text(status)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(Array(game.cards.enumerated()), id: \.element.id) { index, card in
                        Button {
                            flip(index)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(faceUp(index) ? Color(card.species.profile.tint(for: card.color)) : theme.cream.opacity(0.9))
                                if faceUp(index) {
                                    VStack(spacing: 4) {
                                        BloomMark(size: 28, petal: Color.white.opacity(0.92))
                                        Text(card.color.title)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(theme.accent.opacity(0.7))
                                }
                            }
                            .frame(height: 88)
                            .opacity(game.matched.contains(index) ? 0.55 : 1)
                        }
                        .buttonStyle(.plain)
                        .disabled(game.isWon || game.isFailed)
                    }
                }
                .padding(.horizontal, 18)

                if game.isFailed {
                    PrimaryGardenButton(title: "Shuffle and try again", fill: theme.accent) {
                        var next = game
                        next.retry()
                        game = next
                        status = "Flip two tiles to match a color variant"
                    }
                    .padding(.horizontal, 28)
                }

                Spacer()
            }
            .padding(.top, 8)
        }
    }

    private func faceUp(_ index: Int) -> Bool {
        game.matched.contains(index) || game.revealed.contains(index)
    }

    private func flip(_ index: Int) {
        var next = game
        let result = next.flip(index)
        game = next
        switch result {
        case .revealed:
            SoundPlayer.shared.click()
        case .matched:
            status = "A pair blooms"
            Haptics.light()
            SoundPlayer.shared.place()
        case .matchedWon:
            status = "The whole bouquet matched"
            Haptics.success()
            SoundPlayer.shared.bloom(combo: 3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onFinished(true, next.mismatches)
            }
        case .mismatch, .mismatchFailed:
            status = result == .mismatchFailed ? "Too many misses" : "Not a pair"
            Haptics.error()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                var hide = game
                hide.hideMismatch()
                game = hide
            }
        case .ignored:
            break
        }
    }
}
