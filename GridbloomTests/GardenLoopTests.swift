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

        let readyAt = tendUntilReady(profile, plotID: plot.id, from: plantedAt)
        let harvested = profile.harvestPlot(plot.id, now: readyAt)
        XCTAssertEqual(harvested, .tulip)
        XCTAssertTrue(profile.collectedFlowers.contains(.tulip))
        XCTAssertTrue(profile.emptyGardenSlots.contains(0))
    }

    func testNeglectWiltsThenDiesWithWarningWindows() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let plantedAt = Date(timeIntervalSince1970: 2_000_000)
        let plot = try XCTUnwrap(profile.plantSeed(.tulip, slot: 0, now: plantedAt))
        let thirsty = plot.thirstyAt()
        profile.tickGarden(now: thirsty)
        var live = try XCTUnwrap(profile.gardenPlots.first)
        live.tick(now: thirsty)
        XCTAssertEqual(live.careStage(now: thirsty), .thirsty)
        XCTAssertTrue(live.warningCopy(now: thirsty)?.contains("Needs water") == true)

        let wilt = plot.wiltAt()
        profile.tickGarden(now: wilt)
        live = try XCTUnwrap(profile.gardenPlots.first)
        live.tick(now: wilt)
        XCTAssertEqual(live.careStage(now: wilt), .wilted)
        XCTAssertTrue(live.warningCopy(now: wilt)?.contains("Wilting") == true)
        XCTAssertTrue(profile.waterPlot(plot.id, now: wilt))
        live = try XCTUnwrap(profile.gardenPlots.first)
        live.tick(now: wilt)
        XCTAssertEqual(live.careStage(now: wilt), .growing)

        let neglected = try XCTUnwrap(profile.plantSeed(.daisy, slot: 1, now: plantedAt))
        profile.tickGarden(now: neglected.deathAt())
        XCTAssertNil(profile.gardenPlots.first { $0.id == neglected.id })
        XCTAssertNotNil(profile.lastGardenEvent)
    }

    func testFertilizerDoublesRateAndRespectsDailyCooldown() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let plantedAt = Date(timeIntervalSince1970: 3_000_000)
        let plot = try XCTUnwrap(profile.plantSeed(.tulip, slot: 0, now: plantedAt))
        XCTAssertFalse(profile.applyFertilizer(plot.id, now: plantedAt), "needs a charge from an ad")
        XCTAssertEqual(profile.grantFertilizerCharge(), 1)
        XCTAssertTrue(profile.applyFertilizer(plot.id, now: plantedAt))
        XCTAssertEqual(profile.fertilizerCharges, 0)

        let later = plantedAt.addingTimeInterval(10)
        profile.tickGarden(now: later)
        var live = try XCTUnwrap(profile.gardenPlots.first)
        live.tick(now: later)
        XCTAssertEqual(live.workRemaining, SeedRarity.common.growDuration - 20, accuracy: 0.25)
        XCTAssertTrue(live.isFertilizerActive(now: later))
        XCTAssertFalse(live.canAcceptFertilizer(now: later))
        XCTAssertGreaterThan(live.fertilizerCooldownRemaining(now: later), 23 * 60 * 60)

        _ = profile.grantFertilizerCharge()
        XCTAssertFalse(profile.applyFertilizer(plot.id, now: later), "24h cooldown per plant")
        let afterCooldown = plantedAt.addingTimeInterval(SeedGardenRules.fertilizerCooldown)
        // Plant will already be finished; cooldown itself must have elapsed.
        live.tick(now: afterCooldown)
        XCTAssertEqual(live.fertilizerCooldownRemaining(now: afterCooldown), 0, accuracy: 0.1)
    }

    func testFertilizerCooldownPersistsOnProfileReload() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.garden.\(UUID().uuidString)"))
        let now = Date()
        let first = PlayerProfile(defaults: suite)
        let plot = try XCTUnwrap(first.plantSeed(.tulip, slot: 0, now: now))
        _ = first.grantFertilizerCharge()
        XCTAssertTrue(first.applyFertilizer(plot.id, now: now))
        let until = try XCTUnwrap(first.gardenPlots.first?.fertilizerUntil)
        let available = try XCTUnwrap(first.gardenPlots.first?.fertilizerAvailableAt)

        let second = PlayerProfile(defaults: suite)
        XCTAssertEqual(second.fertilizerCharges, 0)
        let live = try XCTUnwrap(second.gardenPlots.first)
        XCTAssertEqual(live.fertilizerUntil?.timeIntervalSince1970 ?? 0, until.timeIntervalSince1970, accuracy: 0.5)
        XCTAssertEqual(live.fertilizerAvailableAt?.timeIntervalSince1970 ?? 0, available.timeIntervalSince1970, accuracy: 0.5)
        XCTAssertTrue(live.isFertilizerActive(now: now.addingTimeInterval(10)))
        XCTAssertFalse(live.canAcceptFertilizer(now: now.addingTimeInterval(10)))
    }

    func testLegacyPlotMigrationKeepsRemainingWorkAndResetsCare() throws {
        struct LegacyPlot: Encodable {
            var id: UUID
            var slot: Int
            var speciesRaw: Int
            var plantedAt: Date
            var finishesAt: Date
            var boosted: Bool
        }
        let plantedAt = Date().addingTimeInterval(-20)
        let finishesAt = Date().addingTimeInterval(40)
        let data = try JSONEncoder().encode(
            LegacyPlot(
                id: UUID(),
                slot: 0,
                speciesRaw: FlowerSpecies.tulip.rawValue,
                plantedAt: plantedAt,
                finishesAt: finishesAt,
                boosted: false
            )
        )
        let plot = try JSONDecoder().decode(GardenPlot.self, from: data)
        XCTAssertEqual(plot.workRemaining, 40, accuracy: 1.5)
        XCTAssertEqual(plot.careStage(now: Date()), .growing)
        XCTAssertGreaterThan(plot.thirstyAt().timeIntervalSinceNow, 30)
    }

    func testSalvageChanceIsDeterministicPerPlot() {
        let yes = (0..<400).contains { _ in
            SeedGardenRules.salvagesSeed(plotID: UUID())
        }
        XCTAssertTrue(yes)
        XCTAssertEqual(
            SeedGardenRules.salvagesSeed(plotID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!),
            SeedGardenRules.salvagesSeed(plotID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!)
        )
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
        let readyAt = tendUntilReady(profile, plotID: plot.id, from: now)
        XCTAssertEqual(profile.harvestPlot(plot.id, now: readyAt), .starfire)
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
        let readyAt = tendUntilReady(profile, plotID: plot.id, from: now)
        _ = profile.harvestPlot(plot.id, now: readyAt)

        var dealer = FairDealer(rng: SplitMix64(seed: 4))
        dealer.flowerRoster = profile.playableFlowers(for: .classic)
        var sawUltra = false
        for _ in 0..<40 {
            let tray = dealer.dealTray(on: Board())
            if tray.contains(where: { $0.bloom.rarity == .ultra }) {
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

    /// Keep the plot watered so growth runs at full rate until harvest.
    @discardableResult
    private func tendUntilReady(_ profile: PlayerProfile, plotID: UUID, from plantedAt: Date) -> Date {
        var now = plantedAt
        for _ in 0..<240 {
            now = now.addingTimeInterval(8)
            _ = profile.waterPlot(plotID, now: now)
            if let plot = profile.gardenPlots.first(where: { $0.id == plotID }), plot.isReady(now: now) {
                return now
            }
        }
        XCTFail("plot never became ready while watered")
        return now
    }
}
