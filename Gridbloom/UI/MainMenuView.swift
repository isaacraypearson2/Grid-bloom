import SwiftUI

struct MainMenuView: View {
    var theme: BoardTheme
    var classicBest: Int
    var dailyBest: Int
    var utcDay: String
    var streak: Int
    var playedToday: Bool
    var gamesPlayed: Int
    var petals: Int
    var rankTitle: String
    var goals: [DailyGoal]
    var goalProgress: DailyGoalProgress
    var onPlayClassic: () -> Void
    var onPlayDaily: () -> Void
    var onPlayStages: () -> Void
    var onMiniGames: () -> Void
    var onAlbum: () -> Void
    var onScanFlower: () -> Void
    var onGarden: () -> Void
    var onShop: () -> Void
    var onSettings: () -> Void

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(spacing: 18) {
                HStack {
                    IconCircleButton(systemName: "bag", label: "Shop", theme: theme, action: onShop)
                    IconCircleButton(systemName: "book.fill", label: "Album", theme: theme, action: onAlbum)
                    IconCircleButton(systemName: "leaf.circle.fill", label: "My garden", theme: theme, action: onGarden)
                    IconCircleButton(systemName: "camera.fill", label: "Scan a flower", theme: theme, action: onScanFlower)
                    Spacer()
                    IconCircleButton(systemName: "slider.horizontal.3", label: "Settings", theme: theme, action: onSettings)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                Spacer(minLength: 4)

                BloomMark(size: 80, petal: theme.accent)
                    .padding(.bottom, 2)

                VStack(spacing: 8) {
                    Text("Gridbloom")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(theme.ink)
                        .tracking(0.4)
                    Text("Plant flowers. Bloom the grid.")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                    Text("\(petals) petals  ·  \(rankTitle)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.accent)
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

                    Button(action: onPlayStages) {
                        menuLabel(title: "Flower maps", subtitle: "Tulip, rose, succulent… unlockable stages", systemImage: "map.fill")
                    }
                    .buttonStyle(GardenButtonStyle(fill: Color(red: 0.72, green: 0.52, blue: 0.62)))

                    Button(action: onGarden) {
                        menuLabel(title: "My garden", subtitle: "Grow seeds · harvest tiles", systemImage: "leaf.circle.fill")
                    }
                    .buttonStyle(GardenButtonStyle(fill: Color(red: 0.46, green: 0.62, blue: 0.42)))

                    Button(action: onMiniGames) {
                        menuLabel(title: "Side gardens", subtitle: "Catch petals · earn seed packs", systemImage: "sparkles")
                    }
                    .buttonStyle(GardenButtonStyle(fill: Color(red: 0.58, green: 0.62, blue: 0.82)))
                }
                .padding(.horizontal, 28)

                HStack(spacing: 12) {
                    scoreChip(title: "Best", value: "\(classicBest)")
                    scoreChip(title: "Today", value: "\(dailyBest)")
                    scoreChip(title: "Streak", value: streak == 0 ? "—" : "\(streak)d")
                }
                .padding(.horizontal, 24)

                dailyGoalsCard
                    .padding(.horizontal, 24)

                Text(gamesPlayed == 0
                     ? "Clear rows & columns · collect flowers"
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

    private var dailyGoalsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today’s goals")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundColor(theme.inkSoft)
            ForEach(goals) { goal in
                let value = goalProgress.value(for: goal)
                HStack {
                    Text(goal.title)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.ink)
                    Spacer()
                    Text(goalProgress.isComplete(goal) ? "+\(goal.rewardPetals)" : "\(value)/\(goal.target)")
                        .font(.system(.caption, design: .rounded).monospacedDigit())
                        .foregroundColor(goalProgress.isComplete(goal) ? theme.accent : theme.inkSoft)
                }
            }
        }
        .padding(12)
        .background(theme.cream.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .padding(.vertical, 14)
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
