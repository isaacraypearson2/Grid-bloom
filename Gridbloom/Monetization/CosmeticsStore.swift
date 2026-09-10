import Foundation
import StoreKit
import Combine

/// Cosmetic packs. Garden Clay is free; other packs unlock by watching one rewarded ad.
/// Unlocks persist locally. Leftover StoreKit purchases (if any) still count as owned.
@MainActor
final class CosmeticsStore: ObservableObject {
    @Published private(set) var unlockedIDs: Set<String> = []
    @Published var selectedPack: CosmeticPack
    @Published private(set) var isUnlocking = false
    @Published private(set) var unlockingPack: CosmeticPack?
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?
    private let settings: AppSettings
    private let defaults: UserDefaults

    private enum Keys {
        static let unlocked = "gridbloom.cosmetics.unlockedIDs"
    }

    init(settings: AppSettings = .shared, defaults: UserDefaults = .standard) {
        self.settings = settings
        self.defaults = defaults
        selectedPack = CosmeticPack(rawValue: settings.selectedThemeID) ?? .garden
        unlockedIDs = Self.loadLocalIDs(from: defaults)
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    var resolvedTheme: BoardTheme {
        BoardTheme.theme(for: selectedPack, colorblind: settings.colorblindPalette)
    }

    func isOwned(_ pack: CosmeticPack) -> Bool {
        if pack.isFree { return true }
        return unlockedIDs.contains(pack.entitlementKey)
    }

    func load() async {
        lastError = nil
        unlockedIDs = Self.loadLocalIDs(from: defaults)
        await mergeStoreKitEntitlements()
        persist()
        if !isOwned(selectedPack) {
            select(.garden)
        }
    }

    func select(_ pack: CosmeticPack) {
        guard isOwned(pack) else { return }
        selectedPack = pack
        settings.selectedThemeID = pack.rawValue
    }

    /// One rewarded ad = one unlock attempt. Grants only if the reward is earned.
    func unlockByWatchingAd(_ pack: CosmeticPack) async {
        guard !pack.isFree, !isOwned(pack), !isUnlocking else { return }
        guard pack.isAdUnlock else { return }
        isUnlocking = true
        unlockingPack = pack
        lastError = nil
        defer {
            isUnlocking = false
            unlockingPack = nil
        }
        let granted = await MonetizationHooks.presentRewarded(.unlockCosmetic)
        guard granted else {
            lastError = "The bloom didn’t finish. Watch again to unlock."
            return
        }
        grantUnlock(pack)
        select(pack)
    }

    private func grantUnlock(_ pack: CosmeticPack) {
        unlockedIDs.insert(pack.entitlementKey)
        persist()
    }

    /// Imports leftover StoreKit purchases into local unlocks. Ad unlocks already persist on device.
    func restore() async {
        lastError = nil
        do {
            try await AppStore.sync()
        } catch {
            // Sync can fail when there is no IAP; local ad-unlocks are unchanged.
        }
        await mergeStoreKitEntitlements()
        persist()
        if !isOwned(selectedPack) {
            select(.garden)
        }
    }

    /// Mini-game or other progression unlock. No ad.
    func unlockFromProgression(_ pack: CosmeticPack, selectNow: Bool = true) {
        guard !pack.isFree, !isOwned(pack) else {
            if isOwned(pack), selectNow { select(pack) }
            return
        }
        grantUnlock(pack)
        if selectNow {
            select(pack)
        }
    }

    /// Fair petal sink for Desert Bloom. Does not gate Classic Garden.
    @discardableResult
    func unlockWithPetals(_ pack: CosmeticPack, profile: PlayerProfile) -> Bool {
        guard let cost = pack.petalCost, !isOwned(pack) else { return false }
        guard profile.spendPetals(cost) else {
            lastError = "Need \(cost) petals for \(pack.title)."
            return false
        }
        grantUnlock(pack)
        select(pack)
        lastError = nil
        profile.syncMapFlowers(ownedPacks: CosmeticPack.allCases.filter { isOwned($0) })
        return true
    }

    private func persist() {
        defaults.set(Array(unlockedIDs).sorted(), forKey: Keys.unlocked)
    }

    private static func loadLocalIDs(from defaults: UserDefaults) -> Set<String> {
        let stored = defaults.stringArray(forKey: Keys.unlocked) ?? []
        return Set(stored)
    }

    private func mergeStoreKitEntitlements() async {
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(entitlement) {
                unlockedIDs.insert(transaction.productID)
            }
        }
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        guard let transaction = try? checkVerified(verification) else { return }
        unlockedIDs.insert(transaction.productID)
        persist()
        await transaction.finish()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
