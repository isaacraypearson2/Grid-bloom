import XCTest
@testable import Gridbloom

final class FlowerMetaTests: XCTestCase {
    func testStartersArePlayableAndExtrasRemapUntilUnlocked() {
        let starters = Set(FlowerSpecies.starters)
        XCTAssertEqual(starters.count, 6)
        let locked = FlowerSpecies.playable(at: 6, unlocked: starters)
        XCTAssertTrue(starters.contains(locked))
        XCTAssertNotEqual(locked, .orchid)

        let withOrchid = starters.union([.orchid])
        XCTAssertEqual(FlowerSpecies.playable(at: 6, unlocked: withOrchid), .orchid)
    }

    func testDailyRosterIgnoresAlbumUnlocks() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.flowers.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        XCTAssertTrue(profile.unlockFlower(.orchid))
        XCTAssertEqual(profile.playableFlowers(for: .daily), Set(FlowerSpecies.starters))
        XCTAssertTrue(profile.playableFlowers(for: .classic).contains(.orchid))
    }

    func testPetalsAndLotusSink() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.flowers.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        XCTAssertEqual(Scoring.petals(lineCount: 2, combo: 3), 4)
        XCTAssertEqual(Scoring.petals(lineCount: 0, combo: 5), 0)
        profile.record(lines: 2, combo: 3, flowers: [.tulip], score: 40)
        XCTAssertGreaterThanOrEqual(profile.petals, 4)
        XCTAssertTrue(profile.collectedFlowers.contains(.tulip))
        XCTAssertEqual(profile.albumStatus(for: .lotus), .locked)
        XCTAssertFalse(profile.buyLotus())
        profile.addPetals(30)
        XCTAssertTrue(profile.buyLotus())
        XCTAssertEqual(profile.albumStatus(for: .lotus), .collected)
        XCTAssertFalse(profile.buyLotus())
    }

    func testDailyGoalsAreStableForADay() throws {
        let a = DailyGoalCatalog.goals(utcDay: "2026-09-10")
        let b = DailyGoalCatalog.goals(utcDay: "2026-09-10")
        XCTAssertEqual(a.map(\.id), b.map(\.id))
        XCTAssertEqual(a.count, 3)
        XCTAssertNotEqual(
            DailyGoalCatalog.goals(utcDay: "2026-09-10").map(\.id),
            DailyGoalCatalog.goals(utcDay: "2026-09-11").map(\.id)
        )
    }

    func testLineGoalClaimsOnceAndPaysPetals() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.goals.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        var chosenDay = "2026-01-01"
        var lineGoal: DailyGoal?
        for day in 1...28 {
            let utc = String(format: "2026-01-%02d", day)
            if let goal = DailyGoalCatalog.goals(utcDay: utc).first(where: { $0.kind == .lines }) {
                chosenDay = utc
                lineGoal = goal
                break
            }
        }
        let goal = try XCTUnwrap(lineGoal)
        profile.refreshGoalsIfNeeded(utcDay: chosenDay)
        XCTAssertEqual(profile.todayGoals.contains(where: { $0.id == goal.id }), true)

        let before = profile.petals
        profile.record(lines: goal.target, combo: 1, score: 10)
        XCTAssertTrue(profile.goalState.isClaimed(goal))
        XCTAssertGreaterThan(profile.petals, before)

        let afterClaim = profile.petals
        profile.record(lines: 0, combo: 0, score: 10)
        XCTAssertEqual(profile.petals, afterClaim, "goal reward must not pay twice")
    }

    func testMapSyncUnlocksCherryAndCactus() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.flowers.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        XCTAssertEqual(profile.albumStatus(for: .cherryBlossom), .locked)
        profile.syncMapFlowers(ownedPacks: [.sakura, .desertBloom])
        XCTAssertEqual(profile.albumStatus(for: .cherryBlossom), .collected)
        XCTAssertEqual(profile.albumStatus(for: .cactusBloom), .collected)
        XCTAssertEqual(profile.albumStatus(for: .moonflower), .locked)
    }

    func testClassicDealStampsUnlockedFlowerWithoutChangingShapeCount() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.flowers.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        _ = profile.unlockFlower(.orchid)
        var dealer = FairDealer(rng: SplitMix64(seed: 9))
        dealer.flowerRoster = profile.playableFlowers(for: .classic)
        let tray = dealer.dealTray(on: Board())
        XCTAssertEqual(tray.count, 3)
        XCTAssertTrue(tray.allSatisfy { dealer.flowerRoster.contains($0.flower) })
    }

    func testBoardStoresFlowerRawValue() throws {
        var board = Board()
        let piece = try XCTUnwrap(PieceCatalog.piece(catalogID: "O4")).spawned(flower: .rose)
        board.place(piece, at: GridPoint(x: 0, y: 0))
        XCTAssertEqual(board[GridPoint(x: 0, y: 0)], FlowerSpecies.rose.rawValue)
    }

    func testDailyDealStampsOnlyStarterFlowers() {
        let state = GameState(mode: .daily, utcDay: "2026-09-07", scoreStore: InMemoryScoreStore())
        let flowers = state.tray.compactMap { $0?.flower }
        XCTAssertEqual(flowers.count, 3)
        XCTAssertTrue(flowers.allSatisfy { FlowerSpecies.starters.contains($0) })
    }
}

final class MiniGameUnlockTests: XCTestCase {
    func testPatternBloomWrongTapFailsAndRetryKeepsSequence() {
        var game = PatternBloomGame(seed: 7)
        let original = game.sequence
        let wrong = PatternBloomGame.palette.first { $0 != original[0] } ?? .lily
        XCTAssertEqual(game.tap(wrong), .wrong)
        XCTAssertTrue(game.isFailed)
        game.retry()
        XCTAssertFalse(game.isFailed)
        XCTAssertEqual(game.sequence, original)
        XCTAssertEqual(game.tap(original[0]), .correct)
    }

    func testPatternBloomFullWin() {
        var game = PatternBloomGame(seed: 99)
        var taps = 0
        while !game.isWon && taps < 80 {
            taps += 1
            XCTAssertFalse(game.sequence.isEmpty)
            let next = game.sequence[game.input.count]
            _ = game.tap(next)
        }
        XCTAssertTrue(game.isWon)
        XCTAssertEqual(game.roundIndex, PatternBloomGame.roundsToWin - 1)
    }

    func testPetalCatchRulesAreBeatable() {
        XCTAssertGreaterThan(PetalCatchRules.duration, 5)
        XCTAssertLessThanOrEqual(PetalCatchRules.winCatches, 12)
        XCTAssertGreaterThan(PetalCatchRules.spawnEvery, 0)
        let spawns = PetalCatchRules.duration / PetalCatchRules.spawnEvery
        XCTAssertGreaterThan(spawns, Double(PetalCatchRules.winCatches))
    }
}

@MainActor
final class MapUnlockTests: XCTestCase {
    func testGreenhouseStartsLockedAndProgressionUnlocksWithoutAd() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.maps.\(UUID().uuidString)"))
        let settings = AppSettings(defaults: suite)
        let store = CosmeticsStore(settings: settings, defaults: suite)
        XCTAssertTrue(store.isOwned(.garden))
        XCTAssertFalse(store.isOwned(.greenhouse))
        XCTAssertFalse(store.isOwned(.desertBloom))
        XCTAssertNil(CosmeticPack.greenhouse.productID)
        XCTAssertEqual(CosmeticPack.greenhouse.entitlementKey, "com.gridbloom.map.greenhouse")

        store.unlockFromProgression(.greenhouse)
        XCTAssertTrue(store.isOwned(.greenhouse))
        XCTAssertEqual(store.selectedPack, .greenhouse)

        let reloaded = CosmeticsStore(settings: settings, defaults: suite)
        XCTAssertTrue(reloaded.isOwned(.greenhouse))
    }

    func testDesertBloomCostsPetalsAndDoesNotSpendOnFailure() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.maps.\(UUID().uuidString)"))
        let settings = AppSettings(defaults: suite)
        let store = CosmeticsStore(settings: settings, defaults: suite)
        let profile = PlayerProfile(defaults: suite)
        XCTAssertFalse(store.unlockWithPetals(.desertBloom, profile: profile))
        XCTAssertFalse(store.isOwned(.desertBloom))
        profile.addPetals(40)
        XCTAssertTrue(store.unlockWithPetals(.desertBloom, profile: profile))
        XCTAssertTrue(store.isOwned(.desertBloom))
        XCTAssertEqual(profile.petals, 0)
        XCTAssertEqual(store.selectedPack, .desertBloom)
        XCTAssertEqual(profile.albumStatus(for: .cactusBloom), .collected)
    }
}
