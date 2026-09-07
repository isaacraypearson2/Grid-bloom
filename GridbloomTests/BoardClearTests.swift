import XCTest
@testable import Gridbloom

final class BoardClearTests: XCTestCase {
    func testEmptyBoardClearsNothing() {
        var board = Board()
        let result = board.clearCompletedLines()
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(result.cellsCleared, 0)
        XCTAssertEqual(board.occupiedCount, 0)
    }

    func testFullRowClearsEightCells() {
        var board = Board()
        board.fillRow(3, value: 2)
        let result = board.clearCompletedLines()
        XCTAssertEqual(result.rows, [3])
        XCTAssertEqual(result.columns, [])
        XCTAssertEqual(result.lineCount, 1)
        XCTAssertEqual(result.cellsCleared, 8)
        XCTAssertEqual(board.occupiedCount, 0)
        XCTAssertEqual(board[GridPoint(x: 0, y: 3)], 0)
    }

    func testFullColumnClearsEightCells() {
        var board = Board()
        board.fillColumn(5, value: 3)
        let result = board.clearCompletedLines()
        XCTAssertEqual(result.columns, [5])
        XCTAssertEqual(result.rows, [])
        XCTAssertEqual(result.cellsCleared, 8)
        XCTAssertEqual(board.occupiedCount, 0)
    }

    func testRowAndColumnClearTogetherCountingIntersectionOnce() {
        var board = Board()
        board.fillRow(0, value: 1)
        board.fillColumn(0, value: 1)
        let result = board.clearCompletedLines()
        XCTAssertEqual(result.rows, [0])
        XCTAssertEqual(result.columns, [0])
        XCTAssertEqual(result.lineCount, 2)
        XCTAssertEqual(result.cellsCleared, 15)
        XCTAssertEqual(board.occupiedCount, 0)
    }

    func testIncompleteRowDoesNotClear() {
        var board = Board()
        for x in 0..<7 {
            board.fill(GridPoint(x: x, y: 1), value: 1)
        }
        let result = board.clearCompletedLines()
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(board.occupiedCount, 7)
    }

    func testPlaceThenClearCompletedRow() throws {
        var board = Board()
        for x in 3..<8 {
            board.fill(GridPoint(x: x, y: 0), value: 1)
        }
        let piece = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h"))
        XCTAssertTrue(board.canPlace(piece, at: GridPoint(x: 0, y: 0)))
        board.place(piece, at: GridPoint(x: 0, y: 0))
        let result = board.clearCompletedLines()
        XCTAssertEqual(result.rows, [0])
        XCTAssertEqual(result.cellsCleared, 8)
    }

    func testCannotPlaceOutOfBoundsOrOnOccupied() throws {
        var board = Board()
        let square = try XCTUnwrap(PieceCatalog.piece(catalogID: "O4"))
        XCTAssertTrue(board.canPlace(square, at: GridPoint(x: 6, y: 6)))
        XCTAssertFalse(board.canPlace(square, at: GridPoint(x: 7, y: 7)))
        board.place(square, at: GridPoint(x: 0, y: 0))
        XCTAssertFalse(board.canPlace(square, at: GridPoint(x: 0, y: 0)))
        XCTAssertFalse(board.canPlace(square, at: GridPoint(x: 1, y: 1)))
        XCTAssertTrue(board.canPlace(square, at: GridPoint(x: 2, y: 0)))
    }

    func testMultipleRowsAndColumns() {
        var board = Board()
        board.fillRow(1)
        board.fillRow(6)
        board.fillColumn(2)
        board.fillColumn(3)
        let result = board.clearCompletedLines()
        XCTAssertEqual(result.rows, [1, 6])
        XCTAssertEqual(result.columns, [2, 3])
        XCTAssertEqual(result.lineCount, 4)
        // 8+8+8+8 minus 2 row-col intersections per column = 32 - 4 = 28
        XCTAssertEqual(result.cellsCleared, 28)
    }
}
