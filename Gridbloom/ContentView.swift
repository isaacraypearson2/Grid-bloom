import SwiftUI

enum AppRoute: Equatable {
    case menu
    case play(GameMode)
    case settings
    case shop
    case album
    case miniGames
    case petalCatch
    case patternBloom
    case scanFlower
}

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var cosmetics: CosmeticsStore
    @EnvironmentObject private var profile: PlayerProfile
    @State private var route: AppRoute = .menu
    @State private var miniGameToast: String?
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
                    petals: profile.petals,
                    rankTitle: profile.gardenRank.title,
                    goals: profile.todayGoals,
                    goalProgress: profile.goalState,
                    onPlayClassic: { route = .play(.classic) },
                    onPlayDaily: { route = .play(.daily) },
                    onMiniGames: { route = .miniGames },
                    onAlbum: { route = .album },
                    onScanFlower: { route = .scanFlower },
                    onShop: { route = .shop },
                    onSettings: { route = .settings }
                )
            case .play(let mode):
                GameView(mode: mode, onExit: { route = .menu })
                    .id(mode)
            case .settings:
                SettingsView(settings: settings, theme: theme, onClose: { route = .menu })
            case .shop:
                ShopView(
                    store: cosmetics,
                    settings: settings,
                    profile: profile,
                    theme: theme,
                    onPlayPatternBloom: { route = .patternBloom },
                    onClose: { route = .menu }
                )
            case .album:
                AlbumView(
                    profile: profile,
                    cosmetics: cosmetics,
                    theme: theme,
                    onScanFlower: { route = .scanFlower },
                    onClose: { route = .menu }
                )
            case .scanFlower:
                FlowerScanView(profile: profile, theme: theme, onClose: { route = .album })
            case .miniGames:
                MiniGamesView(
                    theme: theme,
                    orchidUnlocked: profile.unlockedFlowers.contains(.orchid),
                    peonyUnlocked: profile.unlockedFlowers.contains(.peony),
                    greenhouseOwned: cosmetics.isOwned(.greenhouse),
                    onPetalCatch: { route = .petalCatch },
                    onPatternBloom: { route = .patternBloom },
                    onClose: { route = .menu }
                )
            case .petalCatch:
                PetalCatchView(
                    theme: theme,
                    reducedMotion: settings.prefersReducedMotion,
                    onExit: { route = .miniGames },
                    onFinished: finishPetalCatch
                )
            case .patternBloom:
                PatternBloomView(
                    theme: theme,
                    onExit: { route = .miniGames },
                    onWin: finishPatternBloom
                )
            }

            if let miniGameToast {
                VStack {
                    Spacer()
                    Text(miniGameToast)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(theme.accent.opacity(0.95))
                        .clipShape(Capsule())
                        .padding(.bottom, 36)
                }
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: settings.prefersReducedMotion ? 0.12 : 0.25), value: route)
        .preferredColorScheme(.light)
        .onAppear {
            profile.refreshGoalsIfNeeded()
            profile.syncMapFlowers(ownedPacks: CosmeticPack.allCases.filter { cosmetics.isOwned($0) })
        }
    }

    private func finishPetalCatch(caught: Int, won: Bool) {
        profile.recordPetalCatches(caught)
        if won {
            let first = profile.unlockFlower(.orchid)
            profile.addPetals(first ? MiniGameKind.petalCatch.winPetals : MiniGameKind.petalCatch.repeatPetals)
            showToast(first ? "Orchid joined the album" : "+\(MiniGameKind.petalCatch.repeatPetals) petals")
        }
        route = .miniGames
    }

    private func finishPatternBloom() {
        let first = profile.unlockFlower(.peony)
        cosmetics.unlockFromProgression(.greenhouse)
        profile.syncMapFlowers(ownedPacks: CosmeticPack.allCases.filter { cosmetics.isOwned($0) })
        profile.addPetals(first ? MiniGameKind.patternBloom.winPetals : MiniGameKind.patternBloom.repeatPetals)
        showToast(first ? "Peony & Glasshouse unlocked" : "+\(MiniGameKind.patternBloom.repeatPetals) petals")
        route = .miniGames
    }

    private func showToast(_ text: String) {
        miniGameToast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            if miniGameToast == text { miniGameToast = nil }
        }
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
