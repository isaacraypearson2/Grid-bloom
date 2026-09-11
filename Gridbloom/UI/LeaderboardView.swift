import SwiftUI

struct LeaderboardView: View {
    @ObservedObject var boards: LeaderboardService
    var theme: BoardTheme
    var classicBest: Int
    var dailyBest: Int
    var dailyToday: Int
    var utcDay: String
    var onClose: () -> Void

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Leaderboards")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Text("Classic Garden and Today’s Bloom keep separate high scores.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                boardCard(
                    title: "Classic Garden",
                    subtitle: "Endless mixed meadow",
                    best: max(classicBest, boards.localBest(classic: true)),
                    extra: nil,
                    id: LeaderboardService.classicID
                )
                boardCard(
                    title: "Today’s Bloom",
                    subtitle: "All-time daily best  ·  today \(utcDay)",
                    best: max(dailyBest, boards.localBest(classic: false)),
                    extra: "Today’s run best  \(dailyToday)",
                    id: LeaderboardService.dailyID
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(boards.isAuthenticated ? "Game Center is signed in. Scores submit to \(LeaderboardService.classicID) and \(LeaderboardService.dailyID)." : "Friends — coming soon")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(theme.ink)
                    Text(boards.friendsAvailable
                         ? "Create those two GKLeaderboard IDs in App Store Connect to see friends on-device."
                         : "Your bests save on this iPhone. Sign in to Game Center (Settings) and add the leaderboard IDs in App Store Connect to share with friends.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                    if let authMessage = boards.authMessage, !boards.isAuthenticated {
                        Text(authMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                }
                .padding(14)
                .background(theme.cream.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer()
            }
            .padding(22)
        }
        .onAppear { boards.start() }
    }

    private func boardCard(title: String, subtitle: String, best: Int, extra: String?, id: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(theme.ink)
            Text(subtitle)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(theme.inkSoft)
            HStack(alignment: .lastTextBaseline) {
                Text("\(best)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(theme.ink)
                Text("best")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.inkSoft)
                Spacer()
            }
            if let extra {
                Text(extra)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.accent)
            }
            Text("Board ID  \(id)")
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(theme.inkSoft.opacity(0.8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cream.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
