import XCTest
@testable import Gridbloom

final class CosmeticsTests: XCTestCase {
    func testProductIdentifiersMatchStoreKitPlaceholders() {
        XCTAssertEqual(CosmeticPack.sakura.productID, MonetizationHooks.Cosmetics.sakuraPetals)
        XCTAssertEqual(CosmeticPack.moonlight.productID, MonetizationHooks.Cosmetics.moonlightGarden)
        XCTAssertEqual(CosmeticPack.sunflower.productID, MonetizationHooks.Cosmetics.goldenSunflower)
        XCTAssertNil(CosmeticPack.garden.productID)
        XCTAssertTrue(CosmeticPack.garden.isFree)
        XCTAssertEqual(MonetizationHooks.Cosmetics.allIDs.count, 3)
    }

    func testColorblindThemeSwapsPieceFills() {
        let garden = BoardTheme.theme(for: .garden, colorblind: false)
        let colorblind = BoardTheme.theme(for: .garden, colorblind: true)
        XCTAssertNotEqual(
            garden.pieceFill(index: 0).cgColor.components ?? [],
            colorblind.pieceFill(index: 0).cgColor.components ?? []
        )
        XCTAssertEqual(colorblind.pieceFills.count, GardenPalette.colorblindPieceFills.count)
    }
}
