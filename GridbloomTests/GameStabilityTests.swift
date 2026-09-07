import XCTest
@testable import Gridbloom

final class GameStabilityTests: XCTestCase {
    func testGameStateInitDoesNotMutateProfilePublisher() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.tests.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        XCTAssertEqual(profile.gamesPlayed, 0)

        let state = GameState(
            mode: .classic,
            scoreStore: InMemoryScoreStore(),
            profile: profile,
            rng: SplitMix64(seed: 42)
        )

        XCTAssertEqual(profile.gamesPlayed, 0, "init must not call recordGameStarted")
        XCTAssertEqual(state.tray.count, 3)
        XCTAssertTrue(state.tray.contains { $0 != nil })

        state.recordSessionStartIfNeeded()
        XCTAssertEqual(profile.gamesPlayed, 1)
        state.recordSessionStartIfNeeded()
        XCTAssertEqual(profile.gamesPlayed, 1, "session start is recorded once")
    }

    func testSessionStartCanWaitUntilProfileIsAttached() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.tests.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let state = GameState(
            mode: .classic,
            scoreStore: InMemoryScoreStore(),
            rng: SplitMix64(seed: 3)
        )

        state.recordSessionStartIfNeeded()
        XCTAssertEqual(profile.gamesPlayed, 0)

        state.attachProfile(profile)
        state.recordSessionStartIfNeeded()
        XCTAssertEqual(profile.gamesPlayed, 1)
    }

    func testDailySessionStartRecordsStreakOnlyAfterExplicitCall() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.tests.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        let state = GameState(
            mode: .daily,
            utcDay: "2026-09-07",
            scoreStore: InMemoryScoreStore(),
            profile: profile,
            rng: SplitMix64(seed: 9)
        )

        XCTAssertEqual(profile.gamesPlayed, 0)
        XCTAssertEqual(profile.dailyStreak, 0)
        XCTAssertNil(profile.lastDailyPlayDay)

        state.recordSessionStartIfNeeded()
        XCTAssertEqual(profile.gamesPlayed, 1)
        XCTAssertEqual(profile.dailyStreak, 1)
        XCTAssertEqual(profile.lastDailyPlayDay, "2026-09-07")
    }

    func testIrregularBoardInputIsNormalizedInsteadOfCrashing() {
        var board = Board(filled: [[1, 1], [0]])
        XCTAssertEqual(board[GridPoint(x: 0, y: 0)], 1)
        XCTAssertEqual(board[GridPoint(x: 7, y: 7)], 0)
        board.fill(GridPoint(x: 20, y: 20), value: 3)
        XCTAssertEqual(board[GridPoint(x: 20, y: 20)], 0)
        board.fillRow(99)
        board.fillColumn(-1)
        XCTAssertEqual(board.occupiedCount, 2)
    }

    func testEmptyCatalogDealStillReturnsThreePieces() {
        var dealer = FairDealer(rng: SplitMix64(seed: 1), catalog: [])
        dealer.maxRegenerateAttempts = 4
        let tray = dealer.dealTray(on: Board())
        XCTAssertEqual(tray.count, 3)
    }

    func testReplaceTrayAlwaysHasThreeSlots() {
        let state = GameState(
            mode: .classic,
            scoreStore: InMemoryScoreStore(),
            rng: SplitMix64(seed: 2),
            dealOnStart: false
        )
        state.replaceTray([])
        XCTAssertEqual(state.tray.count, 3)
        state.replaceTray([nil, nil, nil, nil])
        XCTAssertEqual(state.tray.count, 3)
    }
}
