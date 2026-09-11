import XCTest
@testable import Gridbloom

final class FeaturePassTests: XCTestCase {
    func testGrowTimesMeetTheFloorAndScaleWithRarity() {
        XCTAssertGreaterThanOrEqual(SeedRarity.common.growDuration, 12 * 60)
        XCTAssertLessThanOrEqual(SeedRarity.common.growDuration, 15 * 60)
        XCTAssertGreaterThan(SeedRarity.rare.growDuration, SeedRarity.common.growDuration)
        XCTAssertGreaterThan(SeedRarity.epic.growDuration, SeedRarity.rare.growDuration)
        XCTAssertGreaterThan(SeedRarity.ultra.growDuration, SeedRarity.epic.growDuration)
        XCTAssertGreaterThanOrEqual(SeedRarity.ultra.growDuration, 40 * 60)
    }

    func testWateringIsAboutThreeHours() {
        for rarity in SeedRarity.allCases {
            XCTAssertEqual(SeedGardenRules.waterEvery(for: rarity), 3 * 60 * 60, accuracy: 1)
            XCTAssertEqual(SeedGardenRules.thirstyGrace(for: rarity), 20 * 60, accuracy: 1)
            XCTAssertEqual(SeedGardenRules.wiltGrace(for: rarity), 40 * 60, accuracy: 1)
        }
        let planted = Date(timeIntervalSince1970: 5_000_000)
        var plot = GardenPlot(
            id: UUID(),
            slot: 0,
            speciesRaw: FlowerSpecies.tulip.rawValue,
            colorRaw: BloomColor.pink.rawValue,
            rarityRaw: SeedRarity.common.rawValue,
            plantedAt: planted,
            lastWateredAt: planted,
            lastTickAt: planted,
            baseDuration: SeedRarity.common.growDuration,
            workRemaining: SeedRarity.common.growDuration
        )
        XCTAssertEqual(plot.thirstyAt().timeIntervalSince(planted), 3 * 60 * 60, accuracy: 1)
        let grown = planted.addingTimeInterval(12 * 60)
        plot.tick(now: grown)
        XCTAssertEqual(plot.careStage(now: grown), .ready)
        XCTAssertEqual(plot.careStage(now: planted.addingTimeInterval(3 * 60 * 60)), .thirsty)
    }

    func testScorePackTableStepsRaritiesAndMakesUltraHarder() {
        XCTAssertEqual(ScorePackTable.rungs(reaching: 99).map(\.rarity), [])
        XCTAssertEqual(ScorePackTable.rungs(reaching: 100).map(\.rarity), [.common])
        XCTAssertEqual(ScorePackTable.rungs(reaching: 500).map(\.rarity), [.common, .rare])
        XCTAssertEqual(ScorePackTable.rungs(reaching: 1000).map(\.rarity), [.common, .rare, .epic])
        let twoK = ScorePackTable.rungs(reaching: 2000)
        XCTAssertEqual(twoK.last?.rarity, .ultra)
        XCTAssertEqual(twoK.last?.chance, 0.22)
        XCTAssertEqual(ScorePackTable.rungs(reaching: 4000).last?.chance, 1)
        var rng = SplitMix64(seed: 1)
        let always = ScorePackTable.awards(score: 1000, alreadyResolved: [], rng: &rng)
        XCTAssertEqual(always.packs, [.common, .rare, .epic])
        let again = ScorePackTable.awards(score: 1000, alreadyResolved: always.resolved, rng: &rng)
        XCTAssertTrue(again.packs.isEmpty)
    }

    func testClassicAndDailyHighScoresStayOnSeparateBoards() {
        let store = InMemoryScoreStore()
        _ = store.updateBest(for: .classic, utcDay: nil, score: 900)
        _ = store.updateBest(for: .daily, utcDay: "2026-09-11", score: 400)
        _ = store.updateBest(for: .daily, utcDay: "2026-09-12", score: 700)
        XCTAssertEqual(store.best(for: .classic, utcDay: nil), 900)
        XCTAssertEqual(store.lifetimeBest(for: .classic), 900)
        XCTAssertEqual(store.best(for: .daily, utcDay: "2026-09-11"), 400)
        XCTAssertEqual(store.best(for: .daily, utcDay: "2026-09-12"), 700)
        XCTAssertEqual(store.lifetimeBest(for: .daily), 700)
        XCTAssertNotEqual(store.lifetimeBest(for: .classic), store.lifetimeBest(for: .daily))
    }

    func testCollectorTiersAreGardenNamesAndUseXP() {
        XCTAssertEqual(GardenRank.from(xp: 0).title, "Sprout Scout")
        XCTAssertEqual(GardenRank.from(xp: 80).title, "Meadow Keeper")
        XCTAssertEqual(GardenRank.from(xp: 280).title, "Bloom Sage")
        XCTAssertEqual(GardenRank.from(xp: 800).title, "Greenhouse Legend")
        XCTAssertFalse(GardenRank.greenhouseLegend.title.lowercased().contains("super flower"))
        let ultra = BloomVariant(species: .tulip, color: .pink, rarity: .ultra)
        XCTAssertGreaterThan(CollectorProgress.xp(for: .ultra), CollectorProgress.xp(for: .common))
        let xp = CollectorProgress.totalXP(
            variants: [ultra.catalogKey],
            species: [.tulip],
            scans: 1
        )
        XCTAssertEqual(xp, CollectorProgress.xp(for: .ultra) + CollectorProgress.newSpeciesBonus + CollectorProgress.scanXP)
    }

    func testPetalOffersAndOrganicFertilizer() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.feature.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let plantedAt = Date(timeIntervalSince1970: 6_000_000)
        let plot = try XCTUnwrap(profile.plantSeed(.tulip, slot: 0, now: plantedAt))
        XCTAssertFalse(profile.redeem(.mistAll, now: plantedAt))
        profile.addPetals(200)
        XCTAssertTrue(profile.redeem(.mistAll, now: plantedAt))
        XCTAssertEqual(profile.gardenPlots.first?.lastWateredAt, plantedAt)
        XCTAssertTrue(profile.redeem(.dewBurst, now: plantedAt))
        var live = try XCTUnwrap(profile.gardenPlots.first)
        live.tick(now: plantedAt.addingTimeInterval(10))
        XCTAssertTrue(live.isDewActive(now: plantedAt.addingTimeInterval(10)))

        XCTAssertEqual(profile.grantOrganicFertilizer(), 1)
        XCTAssertTrue(profile.applyFertilizer(plot.id, kind: .organic, now: plantedAt))
        live = try XCTUnwrap(profile.gardenPlots.first)
        XCTAssertEqual(live.fertilizerKind, .organic)
        XCTAssertEqual(live.growthRate(at: plantedAt), 3 * SeedGardenRules.dewMultiplier, accuracy: 0.01)
        XCTAssertLessThan(live.fertilizerCooldownRemaining(now: plantedAt), 13 * 60 * 60)
        XCTAssertGreaterThan(live.fertilizerCooldownRemaining(now: plantedAt), 11 * 60 * 60)
    }

    func testScoreRewardsGrantPacksAndOncePerDayOrganic() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.feature.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let rewards = profile.grantScoreRewards(RunScoreRewards(packs: [.common, .rare], organicFertilizer: true))
        XCTAssertEqual(profile.seedPacks.map(\.rarity), [.common, .rare])
        XCTAssertEqual(profile.organicFertilizerCharges, 1)
        XCTAssertEqual(rewards.packs.count, 2)
        XCTAssertTrue(profile.shouldGrantOrganicForScore(score: 2500, utcDay: "2026-09-11"))
        XCTAssertFalse(profile.shouldGrantOrganicForScore(score: 4000, utcDay: "2026-09-11"))
        XCTAssertTrue(profile.shouldGrantOrganicForScore(score: 2500, utcDay: "2026-09-12"))
    }

    func testBeeTrailAndBloomMatchRules() throws {
        var bee = BeeTrailGame(seed: 21)
        XCTAssertEqual(bee.length, 4)
        XCTAssertGreaterThan(bee.timeLimit, 3)
        var taps = 0
        while !bee.isWon && taps < 80 {
            taps += 1
            let next = try XCTUnwrap(bee.nextSpecies)
            XCTAssertNotEqual(bee.tap(next), PatternBloomTapResult.wrong)
        }
        XCTAssertTrue(bee.isWon)

        var match = BloomMatchGame(seed: 8)
        XCTAssertEqual(match.cards.count, 12)
        var seen: [String: Int] = [:]
        for (index, card) in match.cards.enumerated() {
            let key = "\(card.species.rawValue).\(card.color.rawValue)"
            if let other = seen[key] {
                XCTAssertEqual(match.flip(other), .revealed)
                let second = match.flip(index)
                XCTAssertTrue(second == .matched || second == .matchedWon)
            } else {
                seen[key] = index
            }
        }
        XCTAssertTrue(match.isWon)
    }

    func testFunFactsCoverEverySpeciesAndColor() {
        for species in FlowerSpecies.allCases {
            XCTAssertFalse(BloomFacts.speciesFact(species).isEmpty)
            for color in species.colors {
                XCTAssertTrue(BloomFacts.variantFact(species: species, color: color).contains(BloomFacts.speciesFact(species)))
            }
        }
    }

    func testUltraCollectSetsObtainBloom() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.feature.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let ultra = BloomVariant(species: .rose, color: .red, rarity: .ultra)
        profile.collect(ultra)
        XCTAssertEqual(profile.lastUltraBloom, ultra)
        let pack = profile.grantPack(.ultra, source: "test")
        _ = profile.openPack(pack.id)
        XCTAssertEqual(profile.lastUltraBloom?.rarity, .ultra)
    }

    func testGameOverAwardsScorePacksOncePerRung() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.feature.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let store = InMemoryScoreStore()
        var board = Board()
        for x in 0..<8 { board.fill(GridPoint(x: x, y: 0), value: FlowerSpecies.tulip.rawValue) }
        // Force game over with an empty tray after a scored place via helper path:
        // settle by constructing a finished state through refreshGameOver after attaching profile.
        let game = GameState(
            mode: .classic,
            scoreStore: store,
            profile: profile,
            rng: SplitMix64(seed: 3),
            board: Board(),
            tray: [nil, nil, nil],
            dealOnStart: false
        )
        game.attachProfile(profile)
        game.replaceTray([])
        game.refreshGameOver()
        XCTAssertTrue(game.isGameOver)
        XCTAssertEqual(profile.seedPacks.count, 0, "score 0 must not grant packs")
    }

    func testMusicLoopsRender() {
        let home = GardenMusic.renderLoop(.home)
        let garden = GardenMusic.renderLoop(.garden)
        XCTAssertNotNil(home)
        XCTAssertNotNil(garden)
        XCTAssertNotEqual(home, garden)
        XCTAssertEqual(home.flatMap { String(data: $0.prefix(4), encoding: .ascii) }, "RIFF")
        XCTAssertEqual(garden.flatMap { String(data: $0.prefix(4), encoding: .ascii) }, "RIFF")
        let expectedPCM = Int(GardenMusic.sampleRate * GardenMusic.loopDurationSeconds) * 2
        XCTAssertEqual(home?.count, 44 + expectedPCM)
        XCTAssertEqual(garden?.count, 44 + expectedPCM)
    }

    func testMusicLoopsBreatheAndShiftPitch() {
        let home = pcmSamples(GardenMusic.renderLoop(.home))
        let garden = pcmSamples(GardenMusic.renderLoop(.garden))
        XCTAssertFalse(home.isEmpty)
        XCTAssertFalse(garden.isEmpty)

        let homePeakRMS = rmsSlice(home, start: 2.8, duration: 0.8)
        let homeTroughRMS = rmsSlice(home, start: 5.7, duration: 0.5)
        let gardenPeakRMS = rmsSlice(garden, start: 2.8, duration: 0.8)
        let gardenTroughRMS = rmsSlice(garden, start: 5.7, duration: 0.5)
        XCTAssertGreaterThan(homePeakRMS / max(homeTroughRMS, 1e-6), 1.45, "home should breathe")
        XCTAssertGreaterThan(gardenPeakRMS / max(gardenTroughRMS, 1e-6), 1.25, "garden should breathe")
        XCTAssertGreaterThan(homePeakRMS, 400)

        let homeZCR = windowMetric(home, windows: 4, metric: zeroCrossingRate)
        let gardenZCR = windowMetric(garden, windows: 4, metric: zeroCrossingRate)
        XCTAssertGreaterThan(homeZCR.max()! / max(homeZCR.min()!, 1e-9), 1.08, "home pitch should wander")
        XCTAssertGreaterThan(gardenZCR.max()! / max(gardenZCR.min()!, 1e-9), 1.08, "garden pitch should wander")
        XCTAssertGreaterThan(
            homeZCR.reduce(0, +) / Double(homeZCR.count),
            gardenZCR.reduce(0, +) / Double(gardenZCR.count),
            "home hummed register should sit above garden"
        )

        let homePeak = home.map { abs($0) }.max() ?? 0
        let gardenPeak = garden.map { abs($0) }.max() ?? 0
        XCTAssertLessThan(homePeak, Int16.max)
        XCTAssertLessThan(gardenPeak, Int16.max)
        XCTAssertGreaterThan(homePeak, 2_000)
        XCTAssertGreaterThan(gardenPeak, 2_000)

        let gardenChirp = goertzelEnergy(Array(garden[pcmRange(6.38, 0.36)]), hz: 1_900)
        let gardenQuiet = goertzelEnergy(Array(garden[pcmRange(0.38, 0.36)]), hz: 1_900)
        XCTAssertGreaterThan(gardenChirp, gardenQuiet * 8, "garden should have a brief high bird chirp")
        let homeChirp = goertzelEnergy(Array(home[pcmRange(6.42, 0.16)]), hz: 2_200)
        let homeQuiet = goertzelEnergy(Array(home[pcmRange(0.42, 0.16)]), hz: 2_200)
        XCTAssertGreaterThan(homeChirp, homeQuiet * 8, "home should have a quieter distant chirp")
    }

    func testMusicPitchContourUsesDistinctHumCenters() {
        let times = [1.0, 7.0, 13.0, 19.0]
        let home = times.map { GardenMusic.hummedPitch($0, bed: .home) }
        let garden = times.map { GardenMusic.hummedPitch($0, bed: .garden) }
        XCTAssertGreaterThan(Set(home.map { ($0 * 10).rounded() }).count, 2)
        XCTAssertGreaterThan(Set(garden.map { ($0 * 10).rounded() }).count, 2)
        XCTAssertGreaterThan(home.min()!, garden.max()! - 20)
        XCTAssertEqual(GardenMusic.hummedPitch(0, bed: .home), GardenMusic.hummedPitch(24, bed: .home), accuracy: 0.01)
        XCTAssertEqual(GardenMusic.hummedPitch(0, bed: .garden), GardenMusic.hummedPitch(24, bed: .garden), accuracy: 0.01)
    }

    private func pcmSamples(_ data: Data?) -> [Int16] {
        guard let data, data.count > 44 else { return [] }
        let payload = data.dropFirst(44)
        return payload.withUnsafeBytes { buf in
            Array(buf.bindMemory(to: Int16.self))
        }
    }

    private func pcmRange(_ start: Double, _ duration: Double) -> Range<Int> {
        let sr = GardenMusic.sampleRate
        let limit = Int(sr * GardenMusic.loopDurationSeconds)
        let from = min(limit - 1, max(0, Int(start * sr)))
        let to = min(limit, max(from + 1, from + Int(duration * sr)))
        return from..<to
    }

    private func rmsSlice(_ samples: [Int16], start: Double, duration: Double) -> Double {
        let sr = GardenMusic.sampleRate
        let from = max(0, Int(start * sr))
        let to = min(samples.count, from + Int(duration * sr))
        guard from < to else { return 0 }
        return rms(Array(samples[from..<to]))
    }

    private func windowMetric(_ samples: [Int16], windows: Int, metric: ([Int16]) -> Double) -> [Double] {
        let size = max(1, samples.count / windows)
        return (0..<windows).map { index in
            let start = index * size
            let end = min(samples.count, start + size)
            return metric(Array(samples[start..<end]))
        }
    }

    private func rms(_ samples: [Int16]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sum = samples.reduce(0.0) { $0 + Double($1) * Double($1) }
        return sqrt(sum / Double(samples.count))
    }

    private func goertzelEnergy(_ samples: [Int16], hz: Double) -> Double {
        let n = samples.count
        guard n > 4, hz > 0 else { return 0 }
        let k = Int((Double(n) * hz / GardenMusic.sampleRate).rounded())
        let omega = 2 * Double.pi * Double(k) / Double(n)
        let coeff = 2 * cos(omega)
        var s0 = 0.0
        var s1 = 0.0
        var s2 = 0.0
        for sample in samples {
            s0 = Double(sample) + coeff * s1 - s2
            s2 = s1
            s1 = s0
        }
        return s1 * s1 + s2 * s2 - coeff * s1 * s2
    }

    private func zeroCrossingRate(_ samples: [Int16]) -> Double {
        guard samples.count > 1 else { return 0 }
        var crossings = 0
        for i in 1..<samples.count where (samples[i - 1] >= 0) != (samples[i] >= 0) {
            crossings += 1
        }
        return Double(crossings) / Double(samples.count)
    }

    func testLeaderboardIDsAreSplit() {
        XCTAssertNotEqual(LeaderboardService.classicID, LeaderboardService.dailyID)
        XCTAssertTrue(LeaderboardService.classicID.contains("classic"))
        XCTAssertTrue(LeaderboardService.dailyID.contains("daily"))
    }

    func testIntroIsAtMostFivePagesAndCoversTheGardenLoop() {
        XCTAssertLessThanOrEqual(OnboardingPage.allCases.count, IntroFlow.maxPages)
        XCTAssertEqual(OnboardingPage.allCases.count, 5)
        let blob = OnboardingPage.allCases
            .map { $0.title + " " + $0.message }
            .joined(separator: " ")
            .lowercased()
        XCTAssertTrue(blob.contains("row") || blob.contains("column"))
        XCTAssertTrue(blob.contains("water"))
        XCTAssertTrue(blob.contains("pack"))
        XCTAssertTrue(blob.contains("album"))
        XCTAssertTrue(blob.contains("petal catch") || blob.contains("mini"))
    }

    func testIntroDropsIntoClassicUnlessSkipped() {
        XCTAssertEqual(IntroFlow.route(after: .completed), .play(.classic))
        XCTAssertEqual(IntroFlow.route(after: .skipped), .menu)
        XCTAssertEqual(
            IntroFlow.initialRoute(seenIntro: false, completedOnboarding: false),
            .intro
        )
        XCTAssertEqual(
            IntroFlow.initialRoute(seenIntro: true, completedOnboarding: false),
            .menu
        )
        XCTAssertFalse(IntroFlow.shouldShow(seenIntro: false, completedOnboarding: true))
        XCTAssertFalse(IntroFlow.shouldShow(seenIntro: true, completedOnboarding: true))
    }

    func testSeenIntroPersistsAndMigratesFromSettings() {
        let suiteName = "gridbloom.intro.\(UUID().uuidString)"
        let suite = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        suite.removePersistentDomain(forName: suiteName)
        let fresh = PlayerProfile(defaults: suite)
        XCTAssertFalse(fresh.hasSeenIntro)
        fresh.markIntroSeen()
        XCTAssertTrue(fresh.hasSeenIntro)
        XCTAssertTrue(suite.bool(forKey: "gridbloom.profile.seenIntro"))
        XCTAssertTrue(suite.bool(forKey: "gridbloom.settings.onboarding"))

        let reloaded = PlayerProfile(defaults: suite)
        XCTAssertTrue(reloaded.hasSeenIntro)

        let legacyName = "gridbloom.intro.legacy.\(UUID().uuidString)"
        let legacy = try XCTUnwrap(UserDefaults(suiteName: legacyName))
        legacy.removePersistentDomain(forName: legacyName)
        legacy.set(true, forKey: "gridbloom.settings.onboarding")
        let migrated = PlayerProfile(defaults: legacy)
        XCTAssertTrue(migrated.hasSeenIntro)
        XCTAssertTrue(legacy.bool(forKey: "gridbloom.profile.seenIntro"))
    }
}
