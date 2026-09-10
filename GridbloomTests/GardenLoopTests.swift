import XCTest
@testable import Gridbloom

final class GardenLoopTests: XCTestCase {
    func testPackRollStaysOnItsRarity() {
        for rarity in SeedRarity.allCases {
            var rng = SplitMix64(seed: 11)
            let seeds = SeedGardenRules.roll(rarity: rarity, rng: &rng)
            XCTAssertEqual(seeds.count, rarity.seedCount)
            XCTAssertTrue(seeds.allSatisfy { $0.rarity == rarity }, "\(rarity.title) pack leaked another tier")
        }
    }

    func testStarterSeedsAndPlantGrowHarvest() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        XCTAssertEqual(profile.seedCount(for: .tulip), 1)
        XCTAssertEqual(profile.emptyGardenSlots.count, SeedGardenRules.plotCount)

        let plantedAt = Date(timeIntervalSince1970: 1_000_000)
        let plot = try XCTUnwrap(profile.plantSeed(.tulip, slot: 0, now: plantedAt))
        XCTAssertEqual(profile.seedCount(for: .tulip), 0)
        XCTAssertFalse(plot.isReady(now: plantedAt.addingTimeInterval(10)))
        XCTAssertTrue(plot.isReady(now: plantedAt.addingTimeInterval(SeedRarity.common.growDuration)))

        XCTAssertNil(profile.harvestPlot(plot.id, now: plantedAt.addingTimeInterval(10)))
        let harvested = profile.harvestPlot(plot.id, now: plantedAt.addingTimeInterval(SeedRarity.common.growDuration))
        XCTAssertEqual(harvested, .tulip)
        XCTAssertTrue(profile.collectedFlowers.contains(.tulip))
        XCTAssertTrue(profile.emptyGardenSlots.contains(0))
    }

    func testAdBoostFinishesGrowth() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let now = Date(timeIntervalSince1970: 2_000_000)
        let plot = try XCTUnwrap(profile.plantSeed(.daisy, slot: 1, now: now))
        XCTAssertFalse(plot.isReady(now: now.addingTimeInterval(5)))
        XCTAssertTrue(profile.boostPlot(plot.id, now: now.addingTimeInterval(5)))
        XCTAssertEqual(profile.harvestPlot(plot.id, now: now.addingTimeInterval(5)), .daisy)
    }

    func testOpenPackGrantsInventoryAndBuyCostsPetals() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let pack = profile.grantPack(.rare, source: "test")
        let before = profile.inventorySeeds.reduce(0) { $0 + $1.1 }
        let reveal = try XCTUnwrap(profile.openPack(pack.id))
        XCTAssertEqual(reveal.rarity, .rare)
        XCTAssertEqual(reveal.seeds.count, SeedRarity.rare.seedCount)
        XCTAssertTrue(reveal.seeds.allSatisfy { $0.rarity == .rare })
        XCTAssertEqual(profile.seedPacks.count, 0)
        let after = profile.inventorySeeds.reduce(0) { $0 + $1.1 }
        XCTAssertEqual(after, before + reveal.seeds.count)

        XCTAssertNil(profile.buyPack(.common))
        profile.addPetals(SeedRarity.common.petalCost)
        XCTAssertNotNil(profile.buyPack(.common))
        XCTAssertEqual(profile.petals, 0)
        XCTAssertEqual(profile.seedPacks.count, 1)
    }

    func testHarvestUltraUnlocksPlayableTile() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        profile.addSeed(.starfire)
        let now = Date(timeIntervalSince1970: 3_000_000)
        let plot = try XCTUnwrap(profile.plantSeed(.starfire, slot: 2, now: now))
        XCTAssertTrue(profile.boostPlot(plot.id, now: now))
        XCTAssertEqual(profile.harvestPlot(plot.id, now: now), .starfire)
        XCTAssertTrue(profile.unlockedFlowers.contains(.starfire))
        XCTAssertTrue(profile.playableFlowers(for: .classic).contains(.starfire))
        XCTAssertFalse(profile.playableFlowers(for: .daily).contains(.starfire))
    }

    func testUltraMatchWipesRemainingBoardInClassicOnly() throws {
        var board = Board()
        for x in 3..<8 {
            board.fill(GridPoint(x: x, y: 0), value: FlowerSpecies.starfire.rawValue)
        }
        board.fill(GridPoint(x: 4, y: 4), value: FlowerSpecies.tulip.rawValue)

        let piece = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h")).spawned(flower: .starfire)
        let classic = GameState(
            mode: .classic,
            scoreStore: InMemoryScoreStore(),
            rng: SplitMix64(seed: 1),
            board: board,
            tray: [piece, nil, nil],
            dealOnStart: false
        )
        let result = try XCTUnwrap(classic.place(trayIndex: 0, at: GridPoint(x: 0, y: 0)))
        XCTAssertTrue(result.didUltraWipe)
        XCTAssertEqual(classic.board.occupiedCount, 0)
        XCTAssertGreaterThan(result.scoreDelta, Scoring.totalScore(cellCount: 3, lineCount: 1, comboAfterMove: 1))

        var dailyBoard = Board()
        for x in 3..<8 {
            dailyBoard.fill(GridPoint(x: x, y: 0), value: FlowerSpecies.starfire.rawValue)
        }
        dailyBoard.fill(GridPoint(x: 4, y: 4), value: FlowerSpecies.tulip.rawValue)
        let dailyPiece = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h")).spawned(flower: .starfire)
        let daily = GameState(
            mode: .daily,
            utcDay: "2026-09-10",
            scoreStore: InMemoryScoreStore(),
            rng: SplitMix64(seed: 1),
            board: dailyBoard,
            tray: [dailyPiece, nil, nil],
            dealOnStart: false
        )
        let dailyResult = try XCTUnwrap(daily.place(trayIndex: 0, at: GridPoint(x: 0, y: 0)))
        XCTAssertFalse(dailyResult.didUltraWipe)
        XCTAssertEqual(daily.board[GridPoint(x: 4, y: 4)], FlowerSpecies.tulip.rawValue)
    }

    func testClassicDealerCanStampHarvestedUltra() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        profile.addSeed(.starfire)
        let now = Date(timeIntervalSince1970: 4_000_000)
        let plot = try XCTUnwrap(profile.plantSeed(.starfire, slot: 0, now: now))
        _ = profile.boostPlot(plot.id, now: now)
        _ = profile.harvestPlot(plot.id, now: now)

        var dealer = FairDealer(rng: SplitMix64(seed: 4))
        dealer.flowerRoster = profile.playableFlowers(for: .classic)
        var sawUltra = false
        for _ in 0..<40 {
            let tray = dealer.dealTray(on: Board())
            if tray.contains(where: { $0.flower.rarity == .ultra }) {
                sawUltra = true
                break
            }
        }
        XCTAssertTrue(sawUltra)

        let daily = GameState(mode: .daily, utcDay: "2026-09-10", scoreStore: InMemoryScoreStore(), profile: profile)
        XCTAssertTrue(daily.tray.compactMap { $0?.flower }.allSatisfy { $0.rarity == .common })
    }

    func testStarterSeedsGrantedOnce() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let first = PlayerProfile(defaults: suite)
        XCTAssertEqual(first.seedCount(for: .rose), 1)
        first.addSeed(.rose)
        let second = PlayerProfile(defaults: suite)
        XCTAssertEqual(second.seedCount(for: .rose), 2)
    }

    func testBothMiniGamesGrantOneUltraPack() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        XCTAssertFalse(profile.grantMilestoneUltraIfEligible())
        _ = profile.unlockFlower(.orchid)
        XCTAssertFalse(profile.grantMilestoneUltraIfEligible())
        _ = profile.unlockFlower(.peony)
        XCTAssertTrue(profile.grantMilestoneUltraIfEligible())
        XCTAssertEqual(profile.seedPacks.filter { $0.rarity == .ultra }.count, 1)
        XCTAssertFalse(profile.grantMilestoneUltraIfEligible())
    }

    func testUltraWipeBonusIsPositive() {
        XCTAssertEqual(Scoring.ultraWipeBonus(combo: 2, extraCells: 5), 85)
    }
}
