import XCTest
@testable import Gridbloom

final class FairDealerTests: XCTestCase {
    func testOpeningMultiplierFavorsSmallPieces() throws {
        var dealer = FairDealer(rng: SplitMix64(seed: 7))
        dealer.traysDealt = 0
        let tromino = try XCTUnwrap(PieceCatalog.piece(catalogID: "I3_h"))
        let pentomino = try XCTUnwrap(PieceCatalog.piece(catalogID: "I5_h"))
        XCTAssertGreaterThan(dealer.openingMultiplier(for: tromino), dealer.openingMultiplier(for: pentomino))
        XCTAssertGreaterThan(dealer.weight(for: tromino, occupancy: 0), dealer.weight(for: pentomino, occupancy: 0))

        dealer.traysDealt = 20
        XCTAssertEqual(dealer.openingMultiplier(for: tromino), 1.0, accuracy: 0.0001)
        XCTAssertEqual(dealer.openingMultiplier(for: pentomino), 1.0, accuracy: 0.0001)
    }

    func testOpeningTraysAvoidAllPentominoDealsWhenPossible() {
        var dealer = FairDealer(rng: SplitMix64(seed: 3))
        dealer.openingGraceTrays = 5
        let board = Board()
        for _ in 0..<5 {
            let tray = dealer.dealTray(on: board)
            let pentCount = tray.filter { $0.cellCount >= 5 }.count
            XCTAssertLessThan(pentCount, 3, "Opening tray should not be three pentominoes")
            XCTAssertGreaterThanOrEqual(tray.filter { board.canPlaceAnywhere($0) }.count, 2)
        }
    }
}
