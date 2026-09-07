import XCTest
@testable import Gridbloom

@MainActor
final class CosmeticsTests: XCTestCase {
    func testProductIdentifiersRemainEntitlementKeys() {
        XCTAssertEqual(CosmeticPack.sakura.productID, MonetizationHooks.Cosmetics.sakuraPetals)
        XCTAssertEqual(CosmeticPack.moonlight.productID, MonetizationHooks.Cosmetics.moonlightGarden)
        XCTAssertEqual(CosmeticPack.sunflower.productID, MonetizationHooks.Cosmetics.goldenSunflower)
        XCTAssertNil(CosmeticPack.garden.productID)
        XCTAssertTrue(CosmeticPack.garden.isFree)
        XCTAssertEqual(MonetizationHooks.Cosmetics.allIDs.count, 3)
    }

    func testGardenIsOwnedWithoutAnAd() throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.cosmetics.\(UUID().uuidString)"))
        let settings = AppSettings(defaults: suite)
        let store = CosmeticsStore(settings: settings, defaults: suite)
        XCTAssertTrue(store.isOwned(.garden))
        XCTAssertFalse(store.isOwned(.sakura))
        XCTAssertFalse(store.isOwned(.moonlight))
        XCTAssertFalse(store.isOwned(.sunflower))
    }

    func testWatchingAdUnlocksPackPermanentlyWhenRewardIsEarned() async throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.cosmetics.\(UUID().uuidString)"))
        let settings = AppSettings(defaults: suite)
        let mock = MockRewardedAdService()
        mock.grantsReward = true
        let previous = AdHub.service
        AdHub.service = mock
        defer { AdHub.service = previous }

        let store = CosmeticsStore(settings: settings, defaults: suite)
        XCTAssertFalse(store.isOwned(.sakura))
        await store.unlockByWatchingAd(.sakura)
        XCTAssertEqual(mock.lastPlacement, .unlockCosmetic)
        XCTAssertEqual(mock.showCount, 1)
        XCTAssertTrue(store.isOwned(.sakura))
        XCTAssertEqual(store.selectedPack, .sakura)
        XCTAssertNil(store.lastError)

        let reloaded = CosmeticsStore(settings: settings, defaults: suite)
        XCTAssertTrue(reloaded.isOwned(.sakura))
        await reloaded.unlockByWatchingAd(.sakura)
        XCTAssertEqual(mock.showCount, 1, "already unlocked packs must not request another ad")
    }

    func testFailedRewardDoesNotUnlock() async throws {
        let suite = try XCTUnwrap(UserDefaults(suiteName: "gridbloom.cosmetics.\(UUID().uuidString)"))
        let settings = AppSettings(defaults: suite)
        let mock = MockRewardedAdService()
        mock.grantsReward = false
        let previous = AdHub.service
        AdHub.service = mock
        defer { AdHub.service = previous }

        let store = CosmeticsStore(settings: settings, defaults: suite)
        await store.unlockByWatchingAd(.moonlight)
        XCTAssertFalse(store.isOwned(.moonlight))
        XCTAssertEqual(store.selectedPack, .garden)
        XCTAssertNotNil(store.lastError)
        XCTAssertEqual(mock.showCount, 1)
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
