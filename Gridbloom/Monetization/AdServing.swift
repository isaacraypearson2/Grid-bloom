import Foundation

enum RewardedPlacement: String, Equatable {
    case continueGame
    case shuffleTray
}

/// Ads are always player-initiated. The app target uses `AdMobRewardedAdService`.
/// Tests assign `MockRewardedAdService` onto `AdHub.service`.
protocol AdServing {
    func isReady(for placement: RewardedPlacement) -> Bool
    func showRewarded(placement: RewardedPlacement) async -> Bool
}

/// Local stub for unit tests. Never used as the app’s default `AdHub.service`.
final class MockRewardedAdService: AdServing {
    var grantsReward = true
    var delayNanoseconds: UInt64 = 0
    var showCount = 0

    func isReady(for placement: RewardedPlacement) -> Bool { true }

    func showRewarded(placement: RewardedPlacement) async -> Bool {
        showCount += 1
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return grantsReward
    }
}

enum AdHub {
    /// Live path: AdMob rewarded ads (Google test units until production IDs are set).
    static var service: AdServing = AdMobRewardedAdService()
}
