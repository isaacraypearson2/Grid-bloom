import XCTest
@testable import Gridbloom

final class AdConfigTests: XCTestCase {
    func testEmptyProductionIDsResolveToGoogleTestInventory() {
        XCTAssertEqual(AdConfig.testApplicationID, "ca-app-pub-3940256099942544~1458002511")
        XCTAssertEqual(AdConfig.testRewardedUnitID, "ca-app-pub-3940256099942544/1712485313")
        XCTAssertEqual(AdConfig.resolved("", test: AdConfig.testRewardedUnitID), AdConfig.testRewardedUnitID)
        XCTAssertEqual(AdConfig.resolved("   ", test: AdConfig.testRewardedUnitID), AdConfig.testRewardedUnitID)
        XCTAssertEqual(
            AdConfig.resolved(AdConfig.testRewardedUnitID, test: AdConfig.testRewardedUnitID),
            AdConfig.testRewardedUnitID
        )
        XCTAssertTrue(AdConfig.isUsingTestAds)
        XCTAssertEqual(AdConfig.rewardedAdUnitID, AdConfig.testRewardedUnitID)
        XCTAssertEqual(AdConfig.applicationID, AdConfig.testApplicationID)
    }

    func testNonEmptyProductionIDWins() {
        let live = "ca-app-pub-0000000000000000/9999999999"
        XCTAssertEqual(AdConfig.resolved(live, test: AdConfig.testRewardedUnitID), live)
    }

    func testMockRewardedServiceDoesNotGrantWhenToldNotTo() async {
        let mock = MockRewardedAdService()
        mock.grantsReward = false
        mock.delayNanoseconds = 0
        let denied = await mock.showRewarded(placement: .continueGame)
        XCTAssertFalse(denied)
        mock.grantsReward = true
        let granted = await mock.showRewarded(placement: .shuffleTray)
        XCTAssertTrue(granted)
        XCTAssertEqual(mock.showCount, 2)
    }
}
