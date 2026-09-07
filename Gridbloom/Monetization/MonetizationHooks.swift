import Foundation
import StoreKit

/// Tasteful monetization surface. Ads are player-initiated; cosmetics use StoreKit 2.
enum MonetizationHooks {
    enum Cosmetics {
        static let sakuraPetals = "com.gridbloom.cosmetics.sakura"
        static let moonlightGarden = "com.gridbloom.cosmetics.moonlight"
        static let goldenSunflower = "com.gridbloom.cosmetics.sunflower"

        static var allIDs: Set<String> {
            [sakuraPetals, moonlightGarden, goldenSunflower]
        }
    }

    static func presentRewarded(_ placement: RewardedPlacement) async -> Bool {
        await AdHub.service.showRewarded(placement: placement)
    }
}
