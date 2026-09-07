import SwiftUI

struct MainMenuView: View {
    var theme: BoardTheme
    var classicBest: Int
    var dailyBest: Int
    var utcDay: String
    var streak: Int
    var playedToday: Bool
    var gamesPlayed: Int
    var onPlayClassic: () -> Void
    var onPlayDaily: () -> Void
    var onShop: () -> Void
    var onSettings: () -> Void

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(spacing: 22) {
                HStack {
                    IconCircleButton(systemName: "bag", label: "Shop", theme: theme, action: onShop)
                    Spacer()
                    IconCircleButton(systemName: "slider.horizontal.3", label: "Settings", theme: theme, action: onSettings)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                Spacer(minLength: 8)

                BloomMark(size: 88, petal: theme.accent)
                    .padding(.bottom, 4)

                VStack(spacing: 8) {
                    Text("Gridbloom")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(theme.ink)
                        .tracking(0.4)
                    Text("Plant pieces. Bloom the grid.")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                }

                VStack(spacing: 12) {
                    Button(action: onPlayClassic) {
                        menuLabel(title: "Play", subtitle: "Classic garden", systemImage: "leaf.fill")
                    }
                    .buttonStyle(GardenButtonStyle(fill: theme.accent))

                    Button(action: onPlayDaily) {
                        menuLabel(
                            title: "Today’s Bloom",
                            subtitle: dailySubtitle,
                            systemImage: "sun.max.fill"
                        )
                    }
                    .buttonStyle(GardenButtonStyle(fill: GardenPalette.dailyFill))
                }
                .padding(.horizontal, 28)

                HStack(spacing: 12) {
                    scoreChip(title: "Best", value: "\(classicBest)")
                    scoreChip(title: "Today", value: "\(dailyBest)")
                    scoreChip(title: "Streak", value: streak == 0 ? "—" : "\(streak)d")
                }
                .padding(.horizontal, 24)

                Text(gamesPlayed == 0
                     ? "Clear rows & columns · chain Bloom combos"
                     : "\(gamesPlayed) gardens planted")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(theme.inkSoft.opacity(0.9))

                Spacer()
            }
        }
    }

    private var dailySubtitle: String {
        if playedToday {
            return utcDay + " · played today"
        }
        return utcDay + " · UTC seed"
    }

    private func menuLabel(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .opacity(0.88)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .opacity(0.7)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func scoreChip(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(theme.inkSoft)
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(theme.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.cream.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
