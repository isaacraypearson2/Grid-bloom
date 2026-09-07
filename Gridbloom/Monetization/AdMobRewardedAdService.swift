import Foundation
import UIKit
import GoogleMobileAds

/// Starts the Mobile Ads SDK once, as early as app launch.
enum MobileAdsBootstrap {
    private static var didStart = false
    private static let lock = NSLock()

    static func startIfNeeded() {
        lock.lock()
        defer { lock.unlock() }
        guard !didStart else { return }
        didStart = true
        let start = {
            MobileAds.shared.start()
        }
        if Thread.isMainThread {
            start()
        } else {
            DispatchQueue.main.async(execute: start)
        }
    }
}

/// Real AdMob rewarded ads for player-initiated revive and tray shuffle.
/// Never grants a reward unless Google’s earn-reward callback fires.
final class AdMobRewardedAdService: NSObject, AdServing, FullScreenContentDelegate {
    private var rewardedAd: RewardedAd?
    private var continuation: CheckedContinuation<Bool, Never>?
    private var earnedReward = false
    private var isPresenting = false

    func isReady(for placement: RewardedPlacement) -> Bool {
        rewardedAd != nil && !isPresenting
    }

    func showRewarded(placement: RewardedPlacement) async -> Bool {
        MobileAdsBootstrap.startIfNeeded()
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.beginShow(continuation: continuation)
            }
        }
    }

    func preload() {
        DispatchQueue.main.async {
            Task { await self.preloadQuietly() }
        }
    }

    private func beginShow(continuation: CheckedContinuation<Bool, Never>) {
        guard self.continuation == nil, !isPresenting else {
            continuation.resume(returning: false)
            return
        }
        self.continuation = continuation
        self.earnedReward = false
        Task { @MainActor in
            let ad: RewardedAd
            if let cached = self.rewardedAd {
                self.rewardedAd = nil
                ad = cached
            } else {
                do {
                    ad = try await self.loadRewardedAd()
                } catch {
                    self.finish(granted: false)
                    return
                }
            }
            self.isPresenting = true
            ad.fullScreenContentDelegate = self
            ad.present(from: Self.topViewController) { [weak self] in
                self?.earnedReward = true
            }
        }
    }

    private func loadRewardedAd() async throws -> RewardedAd {
        try await withThrowingTaskGroup(of: RewardedAd.self) { group in
            group.addTask {
                try await RewardedAd.load(with: AdConfig.rewardedAdUnitID, request: GoogleMobileAds.Request())
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 20_000_000_000)
                throw AdLoadFailure.timedOut
            }
            guard let ad = try await group.next() else {
                throw AdLoadFailure.timedOut
            }
            group.cancelAll()
            return ad
        }
    }

    private func finish(granted: Bool) {
        isPresenting = false
        rewardedAd = nil
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: granted)
        Task { await preloadQuietly() }
    }

    private func preloadQuietly() async {
        guard rewardedAd == nil, !isPresenting else { return }
        rewardedAd = try? await loadRewardedAd()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finish(granted: earnedReward)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finish(granted: false)
    }

    private static var topViewController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.flatMap(\.windows)
        let key = windows.first(where: \.isKeyWindow) ?? windows.first
        var top = key?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

private enum AdLoadFailure: Error {
    case timedOut
}
