import SwiftUI

struct GameOverView: View {
    var theme: BoardTheme
    var score: Int
    var best: Int
    var canContinue: Bool
    var onRestart: () -> Void
    var onContinue: () -> Void
    var onMenu: () -> Void

    var body: some View {
        GardenCard(theme: theme) {
            VStack(spacing: 16) {
                BloomMark(size: 58, petal: theme.accent)
                Text("Garden’s full")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                Text("No remaining piece fits. Restart, or bloom-revive once this run.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                    .multilineTextAlignment(.center)

                HStack(spacing: 28) {
                    VStack {
                        Text("Score").font(.caption).foregroundColor(theme.inkSoft)
                        Text("\(score)").font(.title.bold())
                    }
                    VStack {
                        Text("Best").font(.caption).foregroundColor(theme.inkSoft)
                        Text("\(best)").font(.title.bold())
                    }
                }
                .foregroundColor(theme.ink)

                PrimaryGardenButton(title: "Restart", fill: theme.accent, action: onRestart)

                if canContinue {
                    PrimaryGardenButton(
                        title: "Bloom revive  ·  once",
                        fill: GardenPalette.dailyFill,
                        action: onContinue
                    )
                    Text("Clears a few tiles and refills the tray. You choose when.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Revive already used this run.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                }

                Button("Menu", action: onMenu)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 24)
    }
}
