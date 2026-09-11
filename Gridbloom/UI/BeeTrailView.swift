import SwiftUI

struct BeeTrailView: View {
    var theme: BoardTheme
    var highlightNext: Bool
    var onExit: () -> Void
    var onFinished: (Bool) -> Void

    @State private var game: BeeTrailGame
    @State private var status = "Watch the bee, then follow"
    @State private var showingPath = true
    @State private var pathIndex = -1
    @State private var deadline: Date?
    @State private var flash: FlowerSpecies?

    init(
        theme: BoardTheme,
        seed: UInt64 = UInt64(Date().timeIntervalSince1970),
        highlightNext: Bool,
        onExit: @escaping () -> Void,
        onFinished: @escaping (Bool) -> Void
    ) {
        self.theme = theme
        self.highlightNext = highlightNext
        self.onExit = onExit
        self.onFinished = onFinished
        _game = State(initialValue: BeeTrailGame(seed: seed))
    }

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(spacing: 16) {
                HStack {
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onExit)
                    Spacer()
                    Text("Flight \(min(game.roundIndex + 1, BeeTrailGame.roundsToWin)) / \(BeeTrailGame.roundsToWin)")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                }
                .padding(.horizontal, 20)

                Text("Bee Trail")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                Text(status)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if let deadline, !showingPath, !game.isFailed, !game.isWon {
                    TimelineView(.periodic(from: .now, by: 0.05)) { timeline in
                        let left = max(0, deadline.timeIntervalSince(timeline.date))
                        ProgressView(value: left, total: game.timeLimit)
                            .tint(theme.accent)
                            .padding(.horizontal, 28)
                            .onChange(of: timeline.date) { now in
                                if now >= deadline { failTimeout() }
                            }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(BeeTrailGame.palette, id: \.self) { species in
                        Button {
                            handleTap(species)
                        } label: {
                            VStack(spacing: 6) {
                                BloomMark(size: 40, petal: species.swiftTint)
                                Text(species.title)
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                            }
                            .foregroundColor(theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 96)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(tileFill(species))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(strokeColor(species), lineWidth: 3)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(showingPath || game.isWon || game.isFailed)
                    }
                }
                .padding(.horizontal, 20)

                if game.isFailed {
                    PrimaryGardenButton(title: "Try this flight again", fill: theme.accent) {
                        var next = game
                        next.retry()
                        game = next
                        status = "Watch the bee"
                        playPath()
                    }
                    .padding(.horizontal, 28)
                }

                Spacer()
            }
            .padding(.top, 8)
        }
        .onAppear { playPath() }
    }

    private func tileFill(_ species: FlowerSpecies) -> Color {
        if flash == species { return theme.cream }
        return theme.cream.opacity(0.78)
    }

    private func strokeColor(_ species: FlowerSpecies) -> Color {
        if flash == species { return theme.accent }
        if highlightNext, !showingPath, game.nextSpecies == species {
            return theme.accent.opacity(0.7)
        }
        return .clear
    }

    private func handleTap(_ species: FlowerSpecies) {
        guard !showingPath else { return }
        let result = withMutation { $0.tap(species) }
        switch result {
        case .correct:
            status = "Keep with the bee"
            Haptics.light()
            SoundPlayer.shared.click()
        case .roundClear:
            status = "The bee found another path"
            Haptics.success()
            SoundPlayer.shared.bloom(combo: 2)
            playPath()
        case .won:
            status = "The hive is buzzing"
            Haptics.success()
            SoundPlayer.shared.bloom(combo: 3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                onFinished(true)
            }
        case .wrong:
            status = "The bee lost you"
            Haptics.error()
            deadline = nil
        case .ignored:
            break
        }
    }

    private func failTimeout() {
        guard !game.isFailed, !game.isWon, !showingPath else { return }
        var next = game
        next.timeout()
        game = next
        status = "The trail wilted — too slow"
        deadline = nil
        Haptics.error()
    }

    private func playPath() {
        showingPath = true
        pathIndex = -1
        deadline = nil
        flash = nil
        status = "Watch the bee"
        let seq = game.sequence
        func step(_ i: Int) {
            guard i < seq.count else {
                showingPath = false
                flash = nil
                status = highlightNext ? "Follow — next bloom is lit" : "Follow the bee"
                deadline = Date().addingTimeInterval(game.timeLimit)
                return
            }
            flash = seq[i]
            SoundPlayer.shared.click()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                flash = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    step(i + 1)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            step(0)
        }
    }

    @discardableResult
    private func withMutation(_ body: (inout BeeTrailGame) -> PatternBloomTapResult) -> PatternBloomTapResult {
        var next = game
        let result = body(&next)
        game = next
        return result
    }
}
