import SwiftUI

struct GameOverView: View {
    var theme: BoardTheme
    var modeTitle: String
    var score: Int
    var best: Int
    var lifetimeBest: Int?
    var packs: [SeedRarity]
    var organic: Bool
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

                Text(modeTitle)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(theme.accent)

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

                if let lifetimeBest, lifetimeBest != best {
                    Text("All-time \(modeTitle)  \(lifetimeBest)")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.inkSoft)
                }

                if !packs.isEmpty || organic {
                    VStack(spacing: 6) {
                        Text("Run gifts")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(theme.inkSoft)
                        Text(rewardLine)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(theme.accent)
                            .multilineTextAlignment(.center)
                    }
                }

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

    private var rewardLine: String {
        var parts = packs.map { "\($0.title) pack" }
        if organic { parts.append("Organic fertilizer") }
        return parts.joined(separator: " · ")
    }
}
