import XCTest
@testable import Gridbloom

final class ScoringTests: XCTestCase {
    func testPlacementScoreIsOnePerCell() {
        XCTAssertEqual(Scoring.placementScore(cellCount: 3), 3)
        XCTAssertEqual(Scoring.placementScore(cellCount: 5), 5)
        XCTAssertEqual(Scoring.pointsPerCell, 1)
    }

    func testClearScoreUsesComboMultiplier() {
        XCTAssertEqual(Scoring.clearScore(lineCount: 0, combo: 5), 0)
        XCTAssertEqual(Scoring.clearScore(lineCount: 1, combo: 0), 0)
        XCTAssertEqual(Scoring.clearScore(lineCount: 1, combo: 1), 10)
        XCTAssertEqual(Scoring.clearScore(lineCount: 2, combo: 3), 60)
        XCTAssertEqual(Scoring.clearScore(lineCount: 3, combo: 2), 60)
    }

    func testTotalScoreAddsPlacementAndClears() {
        XCTAssertEqual(
            Scoring.totalScore(cellCount: 4, lineCount: 2, comboAfterMove: 2),
            4 + 40
        )
        XCTAssertEqual(
            Scoring.totalScore(cellCount: 5, lineCount: 0, comboAfterMove: 0),
            5
        )
    }
}
