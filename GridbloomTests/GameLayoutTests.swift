import XCTest
import UIKit
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

    func testMatchBloomHeroFillsMostOfTheScreen() {
        let size = CGSize(width: 390, height: 844)
        let span = min(size.width, size.height)
        let hero = BloomOverlay.heroSize(sceneSize: size, combo: 1)
        XCTAssertGreaterThanOrEqual(hero, span * 0.82)
        XCTAssertLessThanOrEqual(hero, span * 0.94)
        let comboHero = BloomOverlay.heroSize(sceneSize: size, combo: 8)
        XCTAssertGreaterThan(comboHero, hero)
        XCTAssertLessThanOrEqual(comboHero, span * 0.94)
    }

    func testFlowerTileShowsAHighContrastGlyph() {
        let tile = Juice.flowerTile(
            size: 48,
            fill: UIColor(red: 0.9, green: 0.4, blue: 0.45, alpha: 1),
            stroke: .black,
            theme: .garden,
            flower: .rose
        )
        XCTAssertNotNil(tile.childNode(withName: "flower-glyph"))
    }

    func testHomeDestinationsSurfaceGardenPacksAndMiniGames() {
        let ids = Set(HomeDestination.allCases.map(\.rawValue))
        for needed in ["classicGarden", "flowerMaps", "myGarden", "seedPacks", "miniGames", "album", "scanFlower", "todaysBloom"] {
            XCTAssertTrue(ids.contains(needed), needed)
        }
        XCTAssertEqual(HomeDestination.myGarden.title, "My Garden")
        XCTAssertEqual(HomeDestination.seedPacks.title, "Seed Packs")
        XCTAssertEqual(HomeDestination.miniGames.title, "Mini-games")
    }
}
