import Foundation
import StoreKit

/// Single integration point for future ads and StoreKit 2 cosmetics.
/// No ad network or live IAP flow is wired; game logic for the rewards lives on `GameState`.
enum MonetizationHooks {
    /// Development stub. Flip to `false` when a rewarded-ad SDK is connected.
    static var grantsRewardsWithoutAds = true

    /// Product identifiers to register in App Store Connect later.
    enum Cosmetics {
        static let sakuraPetals = "com.gridbloom.cosmetics.sakura"
        static let moonlightGarden = "com.gridbloom.cosmetics.moonlight"
        static let goldenSunflower = "com.gridbloom.cosmetics.sunflower"

        static var allIDs: Set<String> {
            [sakuraPetals, moonlightGarden, goldenSunflower]
        }
    }

    /// Present a rewarded placement that, on success, should clear a few cells and refill the tray.
    static func presentRewardedContinue(completion: @escaping (Bool) -> Void) {
        completion(grantsRewardsWithoutAds)
    }

    /// Present a rewarded placement that, on success, should shuffle the tray.
    static func presentRewardedShuffle(completion: @escaping (Bool) -> Void) {
        completion(grantsRewardsWithoutAds)
    }

    /// StoreKit 2 fetch for cosmetic product IDs. Safe to call only after products exist in App Store Connect.
    static func loadCosmeticProducts() async -> [Product] {
        do {
            return try await Product.products(for: Cosmetics.allIDs)
        } catch {
            return []
        }
    }
}
