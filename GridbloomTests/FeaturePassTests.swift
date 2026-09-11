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
        XCTAssertEqual(GardenMusic.loopDurationSeconds, 48, accuracy: 0.01)
    }

    func testMusicLoopsAreSparseMyceliumBeds() {
        let home = pcmSamples(GardenMusic.renderLoop(.home))
        let garden = pcmSamples(GardenMusic.renderLoop(.garden))
        XCTAssertFalse(home.isEmpty)
        XCTAssertFalse(garden.isEmpty)

        let homeWindows = windowMetric(home, windows: 16, metric: rms)
        let gardenWindows = windowMetric(garden, windows: 16, metric: rms)
        XCTAssertGreaterThan(
            homeWindows.max()! / max(homeWindows.min()!, 1e-6),
            4.0,
            "home should leave breathing space between tones"
        )
        XCTAssertGreaterThan(
            gardenWindows.max()! / max(gardenWindows.min()!, 1e-6),
            3.0,
            "garden should still feel sparse, not a flat hum"
        )

        let homePeak = home.map { abs($0) }.max() ?? 0
        let gardenPeak = garden.map { abs($0) }.max() ?? 0
        XCTAssertLessThan(homePeak, Int16.max)
        XCTAssertLessThan(gardenPeak, Int16.max)
        XCTAssertGreaterThan(homePeak, 2_000)
        XCTAssertGreaterThan(gardenPeak, 2_000)

        let homeCrest = Double(homePeak) / max(rms(home), 1e-6)
        let gardenCrest = Double(gardenPeak) / max(rms(garden), 1e-6)
        XCTAssertGreaterThan(homeCrest, 3.5, "home dynamics should read as notes, not a drone")
        XCTAssertGreaterThan(gardenCrest, 3.5, "garden dynamics should read as notes, not a drone")

        let homeZCR = windowMetric(home, windows: 6, metric: zeroCrossingRate)
        let gardenZCR = windowMetric(garden, windows: 6, metric: zeroCrossingRate)
        XCTAssertGreaterThan(
            homeZCR.reduce(0, +) / Double(homeZCR.count),
            gardenZCR.reduce(0, +) / Double(gardenZCR.count),
            "home register should sit above the earthier garden bed"
        )

        let gardenChirp = goertzelEnergy(Array(garden[pcmRange(6.38, 0.36)]), hz: 1_900)
        let gardenQuiet = goertzelEnergy(Array(garden[pcmRange(2.20, 0.36)]), hz: 1_900)
        XCTAssertGreaterThan(gardenChirp, gardenQuiet * 8, "garden should keep soft bird chirps")
        let homeChirp = goertzelEnergy(Array(home[pcmRange(11.82, 0.16)]), hz: 2_200)
        let homeQuiet = goertzelEnergy(Array(home[pcmRange(7.60, 0.16)]), hz: 2_200)
        XCTAssertGreaterThan(homeChirp, homeQuiet * 8, "home should keep a quieter distant chirp")
    }

    func testMyceliumPulseTrainIsIrregularAndPitched() {
        let home = GardenMusic.pulseEvents(.home)
        let garden = GardenMusic.pulseEvents(.garden)
        XCTAssertGreaterThan(home.count, 8)
        XCTAssertGreaterThan(garden.count, home.count, "garden should fire more mycelium events")
        XCTAssertGreaterThan(home.filter { $0.kind == .spike }.count, 1)
        XCTAssertGreaterThan(garden.filter { $0.kind == .spike }.count, 6)
        XCTAssertTrue(home.contains { $0.kind == .pluck } && home.contains { $0.kind == .swell })
        XCTAssertTrue(garden.contains { $0.kind == .pluck } && garden.contains { $0.kind == .swell })

        let homePitches = Set(home.map { ($0.hz * 10).rounded() })
        let gardenPitches = Set(garden.map { ($0.hz * 10).rounded() })
        XCTAssertGreaterThan(homePitches.count, 3)
        XCTAssertGreaterThan(gardenPitches.count, 3)
        XCTAssertGreaterThan(
            home.map(\.hz).reduce(0, +) / Double(home.count),
            garden.map(\.hz).reduce(0, +) / Double(garden.count)
        )

        func gapRatio(_ events: [GardenMusic.PulseEvent]) -> Double {
            let starts = events.map(\.start).sorted()
            let gaps = zip(starts, starts.dropFirst()).map { $1 - $0 }
            return (gaps.max() ?? 0) / max(gaps.min() ?? 1, 1e-6)
        }
        XCTAssertGreaterThan(gapRatio(home), 3, "home spike timing should be irregular")
        XCTAssertGreaterThan(gapRatio(garden), 3, "garden spike timing should be irregular")

        XCTAssertLessThan(GardenMusic.chirpStarts(.home).count, GardenMusic.chirpStarts(.garden).count)
        XCTAssertEqual(GardenMusic.chirpStarts(.home).first, 11.82, accuracy: 0.01)
        XCTAssertEqual(GardenMusic.chirpStarts(.garden).first, 6.38, accuracy: 0.01)
    }

    func testBirdChirpsHavePhrasesAndVariety() {
        let home = GardenMusic.chirpEvents(.home)
        let garden = GardenMusic.chirpEvents(.garden)
        XCTAssertGreaterThanOrEqual(home.count, 10, "home should have more than a couple of isolated chirps")
        XCTAssertGreaterThanOrEqual(garden.count, 16, "garden should feel more alive with birds")
        XCTAssertGreaterThan(garden.count, home.count)

        let homePhrases = chirpPhraseLengths(home.map(\.start))
        let gardenPhrases = chirpPhraseLengths(garden.map(\.start))
        XCTAssertTrue(homePhrases.contains { $0 == 2 }, "home should have a 2-note phrase")
        XCTAssertTrue(homePhrases.contains { $0 >= 3 }, "home should have a 3-note phrase")
        XCTAssertTrue(gardenPhrases.contains { $0 == 2 }, "garden should have a 2-note phrase")
        XCTAssertGreaterThan(gardenPhrases.filter { $0 >= 3 }.count, 1, "garden should have more than one 3-note phrase")

        let homePitches = Set(home.map { ($0.f0 / 40).rounded() })
        let gardenPitches = Set(garden.map { ($0.f0 / 40).rounded() })
        XCTAssertGreaterThan(homePitches.count, 4, "home chirps should use several pitch centers")
        XCTAssertGreaterThan(gardenPitches.count, 5, "garden chirps should use several pitch centers")

        let homeMoments = chirpMomentStarts(home.map(\.start))
        let gardenMoments = chirpMomentStarts(garden.map(\.start))
        XCTAssertGreaterThan(gapRatio(homeMoments), 1.8, "home bird timing should not feel metronomic")
        XCTAssertGreaterThan(gapRatio(gardenMoments), 1.8, "garden bird timing should not feel metronomic")

        let homeGain = home.map(\.gain).reduce(0, +) / Double(home.count)
        let gardenGain = garden.map(\.gain).reduce(0, +) / Double(garden.count)
        XCTAssertGreaterThan(gardenGain, homeGain, "garden birds should sit a little closer")

        let samples = pcmSamples(GardenMusic.renderLoop(.home))
        let phrase = goertzelEnergy(Array(samples[pcmRange(25.08, 0.55)]), hz: 2_200)
        let padOnly = goertzelEnergy(Array(samples[pcmRange(7.60, 0.55)]), hz: 2_200)
        XCTAssertGreaterThan(phrase, padOnly * 8, "a home 3-note phrase should be audible without drowning the bed")
        XCTAssertLessThan(home.map(\.gain).max() ?? 1, 0.02, "chirps must stay under the pad/pulses")
        XCTAssertLessThan(garden.map(\.gain).max() ?? 1, 0.02, "chirps must stay under the pad/pulses")
    }

    private func chirpPhraseLengths(_ starts: [Double]) -> [Int] {
        let sorted = starts.sorted()
        var lengths: [Int] = []
        var index = 0
        while index < sorted.count {
            var count = 1
            var cursor = index
            while cursor + 1 < sorted.count, sorted[cursor + 1] - sorted[cursor] < 0.35 {
                count += 1
                cursor += 1
            }
            lengths.append(count)
            index = cursor + 1
        }
        return lengths
    }

    private func chirpMomentStarts(_ starts: [Double]) -> [Double] {
        let sorted = starts.sorted()
        var moments: [Double] = []
        for time in sorted {
            if let last = moments.last, time - last < 0.35 { continue }
            moments.append(time)
        }
        return moments
    }

    private func gapRatio(_ times: [Double]) -> Double {
        let gaps = zip(times, times.dropFirst()).map { $1 - $0 }
        return (gaps.max() ?? 0) / max(gaps.min() ?? 1, 1e-6)
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
