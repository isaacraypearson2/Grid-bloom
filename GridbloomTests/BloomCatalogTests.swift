import XCTest
@testable import Gridbloom

final class BloomCatalogTests: XCTestCase {
    func testEverySpeciesHasThreeColorsAndFourRarities() {
        for species in FlowerSpecies.allCases {
            let row = BloomCatalog.profile(species)
            XCTAssertEqual(row.colors.count, 3, species.title)
            XCTAssertTrue(row.colors.contains(row.signatureColor), species.title)
            let variants = BloomCatalog.variants(for: species)
            XCTAssertEqual(variants.count, 12, species.title)
            XCTAssertEqual(Set(variants.map(\.storageID)).count, 12, species.title)
        }
        let ids = BloomCatalog.allVariants.map(\.storageID)
        XCTAssertEqual(ids.count, Set(ids).count)
        XCTAssertTrue(ids.allSatisfy { $0 >= BloomCatalog.variantStorageBase })
        XCTAssertTrue(ids.allSatisfy { !CustomBloom.isCustomStorage($0) })
    }

    func testLegacyBoardValuesMapToSignatureVariants() {
        for species in FlowerSpecies.allCases {
            let bloom = BloomCatalog.variant(fromStorage: species.rawValue)
            XCTAssertEqual(bloom, BloomCatalog.signature(species))
        }
        XCTAssertTrue(CustomBloom.isCustomStorage(100))
        XCTAssertFalse(CustomBloom.isCustomStorage(BloomCatalog.signature(.rose).storageID))
    }

    func testPacksDropIntoTheColorRarityMatrix() {
        var rng = SplitMix64(seed: 42)
        let seeds = SeedGardenRules.roll(rarity: .rare, rng: &rng)
        XCTAssertEqual(seeds.count, 2)
        XCTAssertTrue(seeds.allSatisfy { $0.rarity == .rare })
        XCTAssertTrue(seeds.allSatisfy { BloomCatalog.profile($0.species).colors.contains($0.color) })
    }

    func testSpeciesStageUnlocksWhenCollectedAndDealsOnlyThatFamily() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.stages.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let tulipStage = try XCTUnwrap(GardenStageCatalog.stage(id: "tulip"))
        XCTAssertFalse(profile.isStageUnlocked(tulipStage))
        profile.record(lines: 1, combo: 1, blooms: [BloomCatalog.signature(.tulip)], score: 10)
        XCTAssertTrue(profile.isStageUnlocked(tulipStage))
        XCTAssertTrue(profile.isStageUnlocked(GardenStageCatalog.classic))

        let game = GameState(mode: .stage("tulip"), scoreStore: InMemoryScoreStore(), profile: profile)
        let flowers = game.tray.compactMap { $0?.flower }
        XCTAssertFalse(flowers.isEmpty)
        XCTAssertTrue(flowers.allSatisfy { $0 == .tulip })
    }

    func testUltraColorVariantWipesInClassicAndStageButNotDaily() throws {
        let ultraTulip = BloomVariant(species: .tulip, color: .pink, rarity: .ultra)
        func seededBoard() -> Board {
            var board = Board()
            for x in 3..<8 {
                board.fill(GridPoint(x: x, y: 0), value: ultraTulip.storageID)
            }
            board.fill(GridPoint(x: 4, y: 4), value: FlowerSpecies.daisy.rawValue)
            return board
        }

        let piece = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h")).spawned(bloom: ultraTulip)
        let classic = GameState(
            mode: .classic,
            scoreStore: InMemoryScoreStore(),
            rng: SplitMix64(seed: 1),
            board: seededBoard(),
            tray: [piece, nil, nil],
            dealOnStart: false
        )
        let result = try XCTUnwrap(classic.place(trayIndex: 0, at: GridPoint(x: 0, y: 0)))
        XCTAssertTrue(result.didUltraWipe)
        XCTAssertEqual(classic.board.occupiedCount, 0)

        let dailyPiece = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h")).spawned(bloom: ultraTulip)
        let daily = GameState(
            mode: .daily,
            utcDay: "2026-09-10",
            scoreStore: InMemoryScoreStore(),
            rng: SplitMix64(seed: 1),
            board: seededBoard(),
            tray: [dailyPiece, nil, nil],
            dealOnStart: false
        )
        let dailyResult = try XCTUnwrap(daily.place(trayIndex: 0, at: GridPoint(x: 0, y: 0)))
        XCTAssertFalse(dailyResult.didUltraWipe)
        XCTAssertEqual(daily.board[GridPoint(x: 4, y: 4)], FlowerSpecies.daisy.rawValue)
    }

    func testDailyBloomsStaySignatureCommons() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.stages.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        profile.collect(BloomVariant(species: .tulip, color: .white, rarity: .epic))
        let daily = profile.playableBlooms(for: .daily)
        XCTAssertEqual(daily.count, FlowerSpecies.starters.count)
        XCTAssertTrue(daily.allSatisfy { $0.rarity == .common })
        XCTAssertTrue(daily.allSatisfy { $0 == BloomCatalog.signature($0.species) })
        XCTAssertTrue(profile.playableBlooms(for: .classic).contains(where: { $0.color == .white && $0.rarity == .epic }))
    }
}
