import XCTest
@testable import Gridbloom

final class GameLayoutTests: XCTestCase {
    func testZeroAndTinySizesStillYieldThreeTraySlots() {
        for size in [CGSize.zero, CGSize(width: 1, height: 1), CGSize(width: 390, height: 844)] {
            let layout = GameBoardLayout(sceneSize: size)
            XCTAssertEqual(layout.traySlots.count, 3, "slots for \(size)")
            XCTAssertGreaterThan(layout.cellSize, 0)
            XCTAssertGreaterThan(layout.boardRect.width, 0)
            XCTAssertLessThan(layout.traySlots[0].x, layout.traySlots[1].x)
            XCTAssertLessThan(layout.traySlots[1].x, layout.traySlots[2].x)
        }
    }
}
