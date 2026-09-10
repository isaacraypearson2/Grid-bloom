import SwiftUI

struct PatternBloomView: View {
    var theme: BoardTheme
    var onExit: () -> Void
    var onWin: () -> Void

    @State private var game: PatternBloomGame
    @State private var playbackIndex = -1
    @State private var isPlayingBack = true
    @State private var flash: FlowerSpecies?
    @State private var status = "Watch the bloom"

    init(theme: BoardTheme, seed: UInt64 = UInt64(Date().timeIntervalSince1970), onExit: @escaping () -> Void, onWin: @escaping () -> Void) {
        self.theme = theme
        self.onExit = onExit
        self.onWin = onWin
        _game = State(initialValue: PatternBloomGame(seed: seed))
    }

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(spacing: 18) {
                HStack {
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onExit)
                    Spacer()
                    Text("Round \(min(game.roundIndex + 1, PatternBloomGame.roundsToWin)) / \(PatternBloomGame.roundsToWin)")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                }
                .padding(.horizontal, 20)

                Text("Pattern Bloom")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                Text(status)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(PatternBloomGame.palette, id: \.self) { species in
                        Button {
                            handleTap(species)
                        } label: {
                            VStack(spacing: 8) {
                                BloomMark(size: 52, petal: species.swiftTint)
                                Text(species.title)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            }
                            .foregroundColor(theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(theme.cream.opacity(flash == species ? 1 : 0.78))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(flash == species ? theme.accent : Color.clear, lineWidth: 3)
                            )
                            .scaleEffect(flash == species ? 1.04 : 1)
                        }
                        .buttonStyle(.plain)
                        .disabled(isPlayingBack || game.isWon || game.isFailed)
                    }
                }
                .padding(.horizontal, 24)

                if game.isFailed {
                    PrimaryGardenButton(title: "Try this round again", fill: theme.accent) {
                        var next = game
                        next.retry()
                        game = next
                        status = "Watch the bloom"
                        playSequence()
                    }
                    .padding(.horizontal, 28)
                }

                Spacer()
            }
            .padding(.top, 12)
        }
        .onAppear { playSequence() }
    }

    private func handleTap(_ species: FlowerSpecies) {
        Haptics.medium()
        SoundPlayer.shared.click()
        flash = species
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            if flash == species { flash = nil }
        }
        var next = game
        let result = next.tap(species)
        game = next
        switch result {
        case .correct:
            status = "Keep going"
        case .roundClear:
            Haptics.success()
            SoundPlayer.shared.bloom(combo: 2)
            status = "Lovely. Next pattern…"
            playSequence()
        case .won:
            Haptics.success()
            SoundPlayer.shared.bloom(combo: 3)
            status = "The glasshouse opens."
            onWin()
        case .wrong:
            Haptics.error()
            status = "Not that bloom. Try the round again."
        case .ignored:
            break
        }
    }

    private func playSequence() {
        isPlayingBack = true
        playbackIndex = -1
        let sequence = game.sequence
        func step(_ index: Int) {
            if index >= sequence.count {
                isPlayingBack = false
                status = "Repeat the bloom"
                flash = nil
                return
            }
            flash = sequence[index]
            SoundPlayer.shared.uiTap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                flash = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    step(index + 1)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            step(0)
        }
    }
}
