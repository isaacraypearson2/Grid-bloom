import XCTest
@testable import Gridbloom

final class ContinueAndStreakTests: XCTestCase {
    func testContinueOnlyOncePerRun() {
        let state = GameState(
            mode: .classic,
            scoreStore: InMemoryScoreStore(),
            rng: SplitMix64(seed: 11),
            dealOnStart: true
        )
        XCTAssertTrue(state.canContinue)
        XCTAssertTrue(state.applyRewardedContinue())
        XCTAssertFalse(state.canContinue)
        XCTAssertFalse(state.applyRewardedContinue())

        state.restart()
        XCTAssertTrue(state.canContinue)
    }

    func testStreakIncrementsOnConsecutiveUTCDaysAndResetsOnGap() {
        XCTAssertEqual(PlayerProfile.streakAfterPlay(lastDay: nil, streak: 0, today: "2026-09-07"), 1)
        XCTAssertEqual(PlayerProfile.streakAfterPlay(lastDay: "2026-09-07", streak: 1, today: "2026-09-07"), 1)
        XCTAssertEqual(PlayerProfile.streakAfterPlay(lastDay: "2026-09-07", streak: 1, today: "2026-09-08"), 2)
        XCTAssertEqual(PlayerProfile.streakAfterPlay(lastDay: "2026-09-07", streak: 4, today: "2026-09-09"), 1)
        XCTAssertTrue(PlayerProfile.isNextUTCDay(after: "2026-09-30", today: "2026-10-01"))
    }

    func testProfilePersistsInIsolatedDefaults() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.tests.\(UUID().uuidString)"))
        let profile = PlayerProfile(defaults: suite)
        profile.recordGameStarted()
        profile.record(lines: 3, combo: 4)
        profile.recordDailyPlay(utcDay: "2026-09-07")
        XCTAssertEqual(profile.gamesPlayed, 1)
        XCTAssertEqual(profile.linesCleared, 3)
        XCTAssertEqual(profile.bestCombo, 4)
        XCTAssertEqual(profile.dailyStreak, 1)

        profile.recordDailyPlay(utcDay: "2026-09-08")
        XCTAssertEqual(profile.dailyStreak, 2)
    }
}
