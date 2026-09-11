import SwiftUI

enum AppRoute: Equatable {
    case intro
    case menu
    case play(GameMode)
    case stages
    case settings
    case shop
    case album
    case miniGames
    case petalCatch
    case patternBloom
    case beeTrail
    case bloomMatch
    case scanFlower
    case garden
    case leaderboard
}

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var cosmetics: CosmeticsStore
    @EnvironmentObject private var profile: PlayerProfile
    @State private var route: AppRoute = IntroFlow.initialRoute(
        seenIntro: PlayerProfile.shared.hasSeenIntro,
        completedOnboarding: AppSettings.shared.hasCompletedOnboarding
    )
    @State private var miniGameToast: String?
    @ObservedObject private var boards = LeaderboardService.shared
    private let scoreStore = UserDefaultsScoreStore()

    var body: some View {
        let theme = cosmetics.resolvedTheme
        return ZStack {
            switch route {
            case .intro:
                OnboardingView(theme: theme) { outcome in
                    finishIntro(outcome)
                }
            case .menu:
                MainMenuView(
                    theme: theme,
                    classicBest: scoreStore.lifetimeBest(for: .classic),
                    dailyBest: scoreStore.lifetimeBest(for: .daily),
                    dailyToday: scoreStore.best(for: .daily, utcDay: DailySeed.utcDayString()),
                    utcDay: DailySeed.utcDayString(),
                    streak: profile.dailyStreak,
                    playedToday: profile.playedDailyToday,
                    gamesPlayed: profile.gamesPlayed,
                    petals: profile.petals,
                    rankTitle: profile.gardenRank.title,
                    seedPackCount: profile.seedPacks.count,
                    fertilizerCharges: profile.fertilizerCharges,
                    goals: profile.todayGoals,
                    goalProgress: profile.goalState,
                    onPlayClassic: { route = .play(.classic) },
                    onPlayDaily: { route = .play(.daily) },
                    onPlayStages: { route = .stages },
                    onMiniGames: { route = .miniGames },
                    onAlbum: { route = .album },
                    onScanFlower: { route = .scanFlower },
                    onGarden: { route = .garden },
                    onSeedPacks: { route = .garden },
                    onShop: { route = .shop },
                    onSettings: { route = .settings },
                    onLeaderboard: { route = .leaderboard },
                    albumBlooms: HomeBloomSlideshow.blooms(collectedVariantIDs: profile.collectedVariantIDs),
                    reducedMotion: settings.prefersReducedMotion
                )
            case .play(let mode):
                GameView(mode: mode, onExit: { route = .menu })
                    .id(mode)
            case .stages:
                StagesView(
                    profile: profile,
                    theme: theme,
                    classicBest: scoreStore.best(for: .classic, utcDay: nil),
                    bestForStage: { scoreStore.best(for: .stage($0), utcDay: nil) },
                    onPlayClassic: { route = .play(.classic) },
                    onPlayStage: { route = .play(.stage($0.id)) },
                    onClose: { route = .menu }
                )
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
                FlowerScanView(profile: profile, theme: theme, onClose: { route = .menu })
            case .garden:
                GardenView(profile: profile, theme: theme, onClose: { route = .menu })
            case .miniGames:
                MiniGamesView(
                    theme: theme,
                    orchidUnlocked: profile.unlockedFlowers.contains(.orchid),
                    peonyUnlocked: profile.unlockedFlowers.contains(.peony),
                    greenhouseOwned: cosmetics.isOwned(.greenhouse),
                    beeTrailWins: profile.miniGameWins(.beeTrail),
                    bloomMatchWins: profile.miniGameWins(.bloomMatch),
                    organicCharges: profile.organicFertilizerCharges,
                    onPetalCatch: { route = .petalCatch },
                    onPatternBloom: { route = .patternBloom },
                    onBeeTrail: {
                        route = .beeTrail
                    },
                    onBloomMatch: { route = .bloomMatch },
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
            case .beeTrail:
                BeeTrailView(
                    theme: theme,
                    highlightNext: false,
                    onExit: { route = .miniGames },
                    onFinished: finishBeeTrail
                )
            case .bloomMatch:
                BloomMatchView(
                    theme: theme,
                    onExit: { route = .miniGames },
                    onFinished: finishBloomMatch
                )
            case .leaderboard:
                LeaderboardView(
                    boards: boards,
                    theme: theme,
                    classicBest: scoreStore.lifetimeBest(for: .classic),
                    dailyBest: scoreStore.lifetimeBest(for: .daily),
                    dailyToday: scoreStore.best(for: .daily, utcDay: DailySeed.utcDayString()),
                    utcDay: DailySeed.utcDayString(),
                    onClose: { route = .menu }
                )
            }

            if let ultra = profile.lastUltraBloom {
                FullScreenMatchBloom(
                    flash: MatchBloomFlash(
                        species: ultra.species,
                        title: "Ultra  \(ultra.fullTitle)",
                        tint: ultra.swiftTint,
                        stamp: nil,
                        combo: 5
                    ),
                    reduced: settings.prefersReducedMotion
                )
                .transition(.opacity)
                .zIndex(50)
                .allowsHitTesting(false)
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
            _ = profile.grantMilestoneUltraIfEligible()
            profile.tickGarden()
            boards.start()
            applyMusic(for: route)
        }
        .onChange(of: route) { next in
            applyMusic(for: next)
        }
        .onChange(of: profile.lastUltraBloom) { bloom in
            guard bloom != nil else { return }
            SoundPlayer.shared.bloom(combo: 5)
            Haptics.success()
            let hold = settings.prefersReducedMotion ? 0.45 : 1.15
            DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
                profile.clearUltraBloom()
            }
        }
    }

    private func finishPetalCatch(caught: Int, won: Bool) {
        profile.recordPetalCatches(caught)
        if won {
            let first = profile.unlockFlower(.orchid)
            profile.addPetals(first ? MiniGameKind.petalCatch.winPetals : MiniGameKind.petalCatch.repeatPetals)
            let pack = first ? MiniGameKind.petalCatch.winPack : MiniGameKind.petalCatch.repeatPack
            _ = profile.grantPack(pack, source: MiniGameKind.petalCatch.rawValue)
            if profile.grantMilestoneUltraIfEligible() {
                showToast("Rare pack + Orchid · Ultra pack!")
            } else {
                showToast(first ? "Rare pack + Orchid" : "\(pack.title) seed pack")
            }
        }
        route = .miniGames
    }

    private func finishPatternBloom() {
        let first = profile.unlockFlower(.peony)
        cosmetics.unlockFromProgression(.greenhouse)
        profile.syncMapFlowers(ownedPacks: CosmeticPack.allCases.filter { cosmetics.isOwned($0) })
        profile.addPetals(first ? MiniGameKind.patternBloom.winPetals : MiniGameKind.patternBloom.repeatPetals)
        let pack = first ? MiniGameKind.patternBloom.winPack : MiniGameKind.patternBloom.repeatPack
        _ = profile.grantPack(pack, source: MiniGameKind.patternBloom.rawValue)
        if profile.grantMilestoneUltraIfEligible() {
            showToast("Epic pack + Peony · Ultra pack!")
        } else {
            showToast(first ? "Epic pack + Peony & Glasshouse" : "\(pack.title) seed pack")
        }
        route = .miniGames
    }

    private func finishBeeTrail(won: Bool) {
        guard won else {
            route = .miniGames
            return
        }
        let first = profile.recordMiniGameWin(.beeTrail)
        profile.addPetals(first ? MiniGameKind.beeTrail.winPetals : MiniGameKind.beeTrail.repeatPetals)
        let pack = first ? MiniGameKind.beeTrail.winPack : MiniGameKind.beeTrail.repeatPack
        _ = profile.grantPack(pack, source: MiniGameKind.beeTrail.rawValue)
        if first || (profile.miniGameWins(.beeTrail) % 3 == 0) {
            _ = profile.grantOrganicFertilizer()
            showToast(first ? "Rare pack + Organic fertilizer" : "\(pack.title) pack + Organic")
        } else {
            showToast("\(pack.title) seed pack")
        }
        route = .miniGames
    }

    private func finishBloomMatch(won: Bool, mismatches: Int) {
        guard won else {
            route = .miniGames
            return
        }
        let first = profile.recordMiniGameWin(.bloomMatch)
        profile.addPetals(first ? MiniGameKind.bloomMatch.winPetals : MiniGameKind.bloomMatch.repeatPetals)
        let perfect = mismatches <= 2
        let pack: SeedRarity = perfect && !first ? .rare : (first ? MiniGameKind.bloomMatch.winPack : MiniGameKind.bloomMatch.repeatPack)
        _ = profile.grantPack(pack, source: MiniGameKind.bloomMatch.rawValue)
        showToast(perfect && !first ? "Clean match · Rare pack" : "\(pack.title) seed pack")
        route = .miniGames
    }

    private func finishIntro(_ outcome: OnboardingOutcome) {
        profile.markIntroSeen()
        settings.hasCompletedOnboarding = true
        route = IntroFlow.route(after: outcome)
    }

    private func applyMusic(for route: AppRoute) {
        switch route {
        case .intro, .menu, .album, .miniGames, .settings, .shop, .stages, .leaderboard:
            GardenMusic.shared.play(.home)
        case .garden:
            GardenMusic.shared.play(.garden)
        case .play, .petalCatch, .patternBloom, .beeTrail, .bloomMatch, .scanFlower:
            GardenMusic.shared.stop()
        }
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
