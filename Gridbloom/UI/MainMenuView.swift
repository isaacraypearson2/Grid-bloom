import SwiftUI

enum HomeDestination: String, CaseIterable, Identifiable {
    case classicGarden
    case flowerMaps
    case myGarden
    case seedPacks
    case miniGames
    case album
    case scanFlower
    case todaysBloom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicGarden: return "Classic Garden"
        case .flowerMaps: return "Flower Maps"
        case .myGarden: return "My Garden"
        case .seedPacks: return "Seed Packs"
        case .miniGames: return "Mini-games"
        case .album: return "Album"
        case .scanFlower: return "Scan Flower"
        case .todaysBloom: return "Today’s Bloom"
        }
    }
}

struct MainMenuView: View {
    var theme: BoardTheme
    var classicBest: Int
    var dailyBest: Int
    var dailyToday: Int
    var utcDay: String
    var streak: Int
    var playedToday: Bool
    var gamesPlayed: Int
    var petals: Int
    var rankTitle: String
    var seedPackCount: Int
    var fertilizerCharges: Int
    var goals: [DailyGoal]
    var goalProgress: DailyGoalProgress
    var onPlayClassic: () -> Void
    var onPlayDaily: () -> Void
    var onPlayStages: () -> Void
    var onMiniGames: () -> Void
    var onAlbum: () -> Void
    var onScanFlower: () -> Void
    var onGarden: () -> Void
    var onSeedPacks: () -> Void
    var onShop: () -> Void
    var onSettings: () -> Void
    var onLeaderboard: () -> Void
    var albumBlooms: [BloomVariant] = HomeBloomSlideshow.defaultBlooms
    var reducedMotion: Bool = false

    var body: some View {
        ZStack {
            GardenBackground(theme: theme, decorativeMarks: false)
            HomeBloomBackdrop(blooms: albumBlooms, reduced: reducedMotion)
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        IconCircleButton(systemName: "bag", label: "Shop", theme: theme, action: onShop)
                        Spacer()
                        IconCircleButton(systemName: "trophy.fill", label: "Leaderboards", theme: theme, action: onLeaderboard)
                        IconCircleButton(systemName: "slider.horizontal.3", label: "Settings", theme: theme, action: onSettings)
                    }

                    VStack(spacing: 6) {
                        Text("Gridbloom")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(theme.ink)
                        Text("\(petals) petals  ·  \(rankTitle)")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(theme.accent)
                    }

                    Button(action: onPlayClassic) {
                        menuLabel(title: "Classic Garden", subtitle: "Play the mixed flower board", systemImage: "leaf.fill")
                    }
                    .buttonStyle(GardenButtonStyle(fill: theme.accent))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        destButton("Flower Maps", "Tulip, rose, succulent…", "map.fill", Color(red: 0.72, green: 0.52, blue: 0.62), onPlayStages)
                        destButton("My Garden", "Water · care · fertilizer", "leaf.circle.fill", Color(red: 0.46, green: 0.62, blue: 0.42), onGarden)
                        destButton(
                            "Seed Packs",
                            seedPackCount == 0 ? "Open packs · fertilizer" : "\(seedPackCount) pack\(seedPackCount == 1 ? "" : "s") · \(fertilizerCharges) fertilizer",
                            "gift.fill",
                            Color(red: 0.86, green: 0.62, blue: 0.32),
                            onSeedPacks
                        )
                        destButton("Mini-games", "Earn seed packs", "sparkles", Color(red: 0.58, green: 0.62, blue: 0.82), onMiniGames)
                        destButton("Album", "XP · collector tiers", "book.fill", Color(red: 0.62, green: 0.48, blue: 0.72), onAlbum)
                        destButton("Scan Flower", "Camera scan only", "camera.fill", Color(red: 0.42, green: 0.58, blue: 0.72), onScanFlower)
                    }

                    Button(action: onPlayDaily) {
                        menuLabel(
                            title: "Today’s Bloom",
                            subtitle: playedToday ? "\(utcDay) · played today" : "\(utcDay) · UTC seed",
                            systemImage: "sun.max.fill"
                        )
                    }
                    .buttonStyle(GardenButtonStyle(fill: GardenPalette.dailyFill))

                    HStack(spacing: 12) {
                        scoreChip(title: "Classic", value: "\(classicBest)")
                        scoreChip(title: "Daily", value: "\(dailyBest)")
                        scoreChip(title: "Streak", value: streak == 0 ? "—" : "\(streak)d")
                    }
                    Text("Today’s Bloom run  \(dailyToday)   ·   UTC \(utcDay)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(theme.inkSoft)

                    dailyGoalsCard

                    Text(gamesPlayed == 0
                         ? "Clear rows & columns · collect flowers"
                         : "\(gamesPlayed) gardens planted")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(theme.inkSoft.opacity(0.9))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
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

    private func destButton(_ title: String, _ subtitle: String, _ icon: String, _ fill: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .opacity(0.9)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            .padding(14)
        }
        .buttonStyle(GardenButtonStyle(fill: fill))
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
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
