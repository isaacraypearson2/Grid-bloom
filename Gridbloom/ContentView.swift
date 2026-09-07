import SwiftUI

enum AppRoute: Equatable {
    case menu
    case play(GameMode)
    case settings
    case shop
}

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var cosmetics: CosmeticsStore
    @EnvironmentObject private var profile: PlayerProfile
    @State private var route: AppRoute = .menu
    private let scoreStore = UserDefaultsScoreStore()

    var body: some View {
        let theme = cosmetics.resolvedTheme
        return ZStack {
            switch route {
            case .menu:
                MainMenuView(
                    theme: theme,
                    classicBest: scoreStore.best(for: .classic, utcDay: nil),
                    dailyBest: scoreStore.best(for: .daily, utcDay: DailySeed.utcDayString()),
                    utcDay: DailySeed.utcDayString(),
                    streak: profile.dailyStreak,
                    playedToday: profile.playedDailyToday,
                    gamesPlayed: profile.gamesPlayed,
                    onPlayClassic: { route = .play(.classic) },
                    onPlayDaily: { route = .play(.daily) },
                    onShop: { route = .shop },
                    onSettings: { route = .settings }
                )
            case .play(let mode):
                GameView(mode: mode, onExit: { route = .menu })
            case .settings:
                SettingsView(settings: settings, theme: theme, onClose: { route = .menu })
            case .shop:
                ShopView(store: cosmetics, settings: settings, theme: theme, onClose: { route = .menu })
            }
        }
        .animation(.easeInOut(duration: settings.prefersReducedMotion ? 0.12 : 0.25), value: route)
        .preferredColorScheme(.light)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppSettings.shared)
            .environmentObject(CosmeticsStore())
            .environmentObject(PlayerProfile.shared)
    }
}
