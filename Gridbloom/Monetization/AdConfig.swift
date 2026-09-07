import Foundation

/// AdMob inventory for Bloom revive and New tray.
///
/// Live IDs are set below and used by default. `GADApplicationIdentifier` in
/// `Gridbloom/Info.plist` **must** match `productionApplicationID` (the Mobile Ads
/// SDK reads the App ID from Info.plist at launch). Unit IDs come from here.
enum AdConfig {
    /// Google sample App ID — only used if `forceGoogleTestAds` is on (DEBUG).
    static let testApplicationID = "ca-app-pub-3940256099942544~1458002511"
    /// Google sample rewarded unit — only used if `forceGoogleTestAds` is on (DEBUG).
    static let testRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    static let productionApplicationID = "ca-app-pub-9109033018957997~7145749382"
    /// Rewarded unit for Bloom revive and New tray. No interstitials.
    static let productionRewardedUnitID = "ca-app-pub-9109033018957997/6223067453"

    /// DEBUG-only escape hatch. Leave `false` for production inventory.
    /// Set `true` if the AdMob account is still under review / no-fill and you
    /// need Google’s sample rewarded unit in Simulator. Release builds ignore this.
    /// The Info.plist App ID stays the production App ID (SDK requirement).
    #if DEBUG
    static let forceGoogleTestAds = false
    #else
    static var forceGoogleTestAds: Bool { false }
    #endif

    static var applicationID: String {
        if forceGoogleTestAds { return testApplicationID }
        return resolved(productionApplicationID, test: testApplicationID)
    }

    static var rewardedAdUnitID: String {
        if forceGoogleTestAds { return testRewardedUnitID }
        return resolved(productionRewardedUnitID, test: testRewardedUnitID)
    }

    /// True when serving Google’s sample units (DEBUG hatch or unset production IDs).
    static var isUsingTestAds: Bool {
        forceGoogleTestAds
            || rewardedAdUnitID == testRewardedUnitID
            || applicationID == testApplicationID
    }

    static func resolved(_ production: String, test: String) -> String {
        let trimmed = production.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == test { return test }
        return trimmed
    }
}
