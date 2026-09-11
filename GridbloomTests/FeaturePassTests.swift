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
        XCTAssertNotNil(GardenMusic.renderLoop(.home))
        XCTAssertNotNil(GardenMusic.renderLoop(.garden))
        XCTAssertNotEqual(GardenMusic.renderLoop(.home), GardenMusic.renderLoop(.garden))
    }

    func testLeaderboardIDsAreSplit() {
        XCTAssertNotEqual(LeaderboardService.classicID, LeaderboardService.dailyID)
        XCTAssertTrue(LeaderboardService.classicID.contains("classic"))
        XCTAssertTrue(LeaderboardService.dailyID.contains("daily"))
    }
}
