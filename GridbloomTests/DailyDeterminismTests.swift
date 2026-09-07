import XCTest
@testable import Gridbloom

final class DailyDeterminismTests: XCTestCase {
    func testUTCDayFormattingIsZeroPadded() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 9, day: 7))!
        XCTAssertEqual(DailySeed.utcDayString(from: date), "2026-09-07")
    }

    func testSameDayProducesTheSameSeed() {
        let a = DailySeed.seed(fromUTCDay: "2026-09-07")
        let b = DailySeed.seed(fromUTCDay: "2026-09-07")
        let c = DailySeed.seed(fromUTCDay: "2026-09-08")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testSameUTCDayDealsIdenticalTrays() {
        let day = "2026-09-07"
        let a = GameState(mode: .daily, utcDay: day, scoreStore: InMemoryScoreStore())
        let b = GameState(mode: .daily, utcDay: day, scoreStore: InMemoryScoreStore())
        XCTAssertEqual(a.traySignatures, b.traySignatures)
        XCTAssertEqual(a.tray.compactMap { $0?.cells }, b.tray.compactMap { $0?.cells })

        a.dealTray()
        b.dealTray()
        XCTAssertEqual(a.traySignatures, b.traySignatures)

        a.dealTray()
        b.dealTray()
        XCTAssertEqual(a.traySignatures, b.traySignatures)
    }

    func testDifferentUTCDaysDiverge() {
        let a = GameState(mode: .daily, utcDay: "2026-01-01", scoreStore: InMemoryScoreStore())
        let b = GameState(mode: .daily, utcDay: "2026-01-02", scoreStore: InMemoryScoreStore())
        XCTAssertNotEqual(a.traySignatures, b.traySignatures)
    }

    func testOccupancyDownWeightsBulkyPieces() throws {
        let dealer = FairDealer(rng: SplitMix64(seed: 1))
        let tromino = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h"))
        let pentomino = try XCTUnwrap(PieceCatalog.piece(catalogID: "I5_h"))
        XCTAssertEqual(dealer.weight(for: tromino, occupancy: 0.85), 1.0, accuracy: 0.0001)
        XCTAssertLessThan(dealer.weight(for: pentomino, occupancy: 0.85), dealer.weight(for: tromino, occupancy: 0.85))
        XCTAssertEqual(dealer.weight(for: pentomino, occupancy: 0), dealer.weight(for: tromino, occupancy: 0), accuracy: 0.0001)
    }

    func testDealerRegeneratesUntilAPieceFitsWhenPossible() {
        var board = Board()
        for y in 0..<Board.size {
            for x in 0..<Board.size {
                if !(y == 7 && x < 3) {
                    board.fill(GridPoint(x: x, y: y), value: 1)
                }
            }
        }
        XCTAssertTrue(board.canPlaceAny(from: PieceCatalog.trominoes))

        var dealer = FairDealer(rng: SplitMix64(seed: 99))
        let tray = dealer.dealTray(on: board)
        XCTAssertTrue(tray.contains { board.canPlaceAnywhere($0) })
    }
}
