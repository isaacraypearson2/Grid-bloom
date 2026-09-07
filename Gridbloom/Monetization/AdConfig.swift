import Foundation

/// Single place to switch Google test ads vs live AdMob inventory.
///
/// Default IDs are Google’s official **test** App ID and rewarded unit so Simulator
/// and Debug builds work with no AdMob account.
///
/// **To go live (human + consoles):**
/// 1. Create an iOS app and a Rewarded ad unit in https://apps.admob.com
/// 2. Paste those IDs into `productionApplicationID` and `productionRewardedUnitID` below.
/// 3. Set `GADApplicationIdentifier` in `Gridbloom/Info.plist` to the **same** production App ID.
///    The Mobile Ads SDK reads the App ID from Info.plist at launch; unit IDs come from here.
enum AdConfig {
    /// Google sample App ID — `ca-app-pub-3940256099942544~1458002511`
    static let testApplicationID = "ca-app-pub-3940256099942544~1458002511"
    /// Google sample rewarded unit — `ca-app-pub-3940256099942544/1712485313`
    static let testRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// TODO: Paste your AdMob iOS App ID (`ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx`).
    /// Also replace `GADApplicationIdentifier` in `Info.plist` with this same value.
    static let productionApplicationID = ""

    /// TODO: Paste your AdMob Rewarded ad unit ID (`ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx`).
    /// Used for Bloom revive and New tray. No interstitials.
    static let productionRewardedUnitID = ""

    static var applicationID: String {
        resolved(productionApplicationID, test: testApplicationID)
    }

    static var rewardedAdUnitID: String {
        resolved(productionRewardedUnitID, test: testRewardedUnitID)
    }

    /// True when we are still on Google’s sample inventory (safe for Simulator).
    static var isUsingTestAds: Bool {
        rewardedAdUnitID == testRewardedUnitID || applicationID == testApplicationID
    }

    static func resolved(_ production: String, test: String) -> String {
        let trimmed = production.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == test { return test }
        return trimmed
    }
}
