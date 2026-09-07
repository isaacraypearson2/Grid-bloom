import Foundation

enum RewardedPlacement: String, Equatable {
    case continueGame
    case shuffleTray
}

/// Ads are always player-initiated. Swap `MockRewardedAdService` for an AdMob adapter later.
protocol AdServing {
    func isReady(for placement: RewardedPlacement) -> Bool
    func showRewarded(placement: RewardedPlacement) async -> Bool
}

/// Local stub: a short pause, then grant. No SDK, no ad unit IDs, always builds.
final class MockRewardedAdService: AdServing {
    var grantsReward = true
    /// Keep this short so the flow feels like a thank-you, not a fake YouTube ad.
    var delayNanoseconds: UInt64 = 900_000_000

    func isReady(for placement: RewardedPlacement) -> Bool { true }

    func showRewarded(placement: RewardedPlacement) async -> Bool {
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return grantsReward
    }
}

enum AdHub {
    static var service: AdServing = MockRewardedAdService()
}
