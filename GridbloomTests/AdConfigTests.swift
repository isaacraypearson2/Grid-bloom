import XCTest
@testable import Gridbloom

final class AdConfigTests: XCTestCase {
    func testProductionIDsAreWiredAndUsed() {
        XCTAssertEqual(AdConfig.productionApplicationID, "ca-app-pub-9109033018957997~7145749382")
        XCTAssertEqual(AdConfig.productionRewardedUnitID, "ca-app-pub-9109033018957997/6223067453")
        XCTAssertFalse(AdConfig.forceGoogleTestAds)
        XCTAssertFalse(AdConfig.isUsingTestAds)
        XCTAssertEqual(AdConfig.applicationID, AdConfig.productionApplicationID)
        XCTAssertEqual(AdConfig.rewardedAdUnitID, AdConfig.productionRewardedUnitID)
        XCTAssertNotEqual(AdConfig.applicationID, AdConfig.testApplicationID)
        XCTAssertNotEqual(AdConfig.rewardedAdUnitID, AdConfig.testRewardedUnitID)
    }

    func testResolvedFallsBackToTestWhenProductionEmpty() {
        XCTAssertEqual(AdConfig.testApplicationID, "ca-app-pub-3940256099942544~1458002511")
        XCTAssertEqual(AdConfig.testRewardedUnitID, "ca-app-pub-3940256099942544/1712485313")
        XCTAssertEqual(AdConfig.resolved("", test: AdConfig.testRewardedUnitID), AdConfig.testRewardedUnitID)
        XCTAssertEqual(AdConfig.resolved("   ", test: AdConfig.testRewardedUnitID), AdConfig.testRewardedUnitID)
        XCTAssertEqual(
            AdConfig.resolved(AdConfig.testRewardedUnitID, test: AdConfig.testRewardedUnitID),
            AdConfig.testRewardedUnitID
        )
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
