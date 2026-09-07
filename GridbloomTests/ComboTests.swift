import XCTest
@testable import Gridbloom

final class ComboTests: XCTestCase {
    func testNextComboIncrementsOnClearAndResetsOtherwise() {
        XCTAssertEqual(Scoring.nextCombo(current: 0, didClear: true), 1)
        XCTAssertEqual(Scoring.nextCombo(current: 1, didClear: true), 2)
        XCTAssertEqual(Scoring.nextCombo(current: 7, didClear: true), 8)
        XCTAssertEqual(Scoring.nextCombo(current: 4, didClear: false), 0)
        XCTAssertEqual(Scoring.nextCombo(current: 0, didClear: false), 0)
    }

    func testGameStateChainsBloomComboThenResets() throws {
        var board = Board()
        for x in 3..<8 {
            board.fill(GridPoint(x: x, y: 0), value: 1)
            board.fill(GridPoint(x: x, y: 1), value: 1)
        }

        let first = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h")).spawned()
        let second = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h")).spawned()
        let square = try XCTUnwrap(PieceCatalog.piece(catalogID: "O4")).spawned()

        let state = GameState(
            mode: .classic,
            scoreStore: InMemoryScoreStore(),
            rng: SplitMix64(seed: 42),
            board: board,
            tray: [first, second, square],
            dealOnStart: false
        )

        let clear1 = try XCTUnwrap(state.place(trayIndex: 0, at: GridPoint(x: 0, y: 0)))
        XCTAssertEqual(clear1.combo, 1)
        XCTAssertEqual(clear1.clear.lineCount, 1)
        XCTAssertEqual(clear1.scoreDelta, Scoring.totalScore(cellCount: 3, lineCount: 1, comboAfterMove: 1))
        XCTAssertEqual(state.combo, 1)
        XCTAssertEqual(state.bloomPulse, 0)

        let clear2 = try XCTUnwrap(state.place(trayIndex: 1, at: GridPoint(x: 0, y: 1)))
        XCTAssertEqual(clear2.combo, 2)
        XCTAssertEqual(clear2.clear.lineCount, 1)
        XCTAssertEqual(clear2.scoreDelta, Scoring.totalScore(cellCount: 3, lineCount: 1, comboAfterMove: 2))
        XCTAssertEqual(state.combo, 2)
        XCTAssertEqual(state.lastBloomCombo, 2)
        XCTAssertEqual(state.bloomPulse, 1)

        let miss = try XCTUnwrap(state.place(trayIndex: 2, at: GridPoint(x: 0, y: 2)))
        XCTAssertEqual(miss.clear.lineCount, 0)
        XCTAssertEqual(miss.combo, 0)
        XCTAssertEqual(miss.scoreDelta, 4)
        XCTAssertEqual(state.combo, 0)
    }
}
