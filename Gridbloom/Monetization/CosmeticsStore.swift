import Foundation
import StoreKit
import Combine

/// StoreKit 2 cosmetics. Load products from App Store Connect or the local `.storekit` file.
@MainActor
final class CosmeticsStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedIDs: Set<String> = []
    @Published var selectedPack: CosmeticPack
    @Published private(set) var isLoading = false
    @Published var lastError: String?

    private var updatesTask: Task<Void, Never>?
    private let settings: AppSettings

    init(settings: AppSettings = .shared) {
        self.settings = settings
        selectedPack = CosmeticPack(rawValue: settings.selectedThemeID) ?? .garden
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
        guard let id = pack.productID else { return false }
        return purchasedIDs.contains(id)
    }

    func product(for pack: CosmeticPack) -> Product? {
        guard let id = pack.productID else { return nil }
        return products.first { $0.id == id }
    }

    func load() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: MonetizationHooks.Cosmetics.allIDs)
            products = loaded.sorted { $0.displayName < $1.displayName }
            await refreshEntitlements()
        } catch {
            lastError = error.localizedDescription
            products = []
        }
    }

    func select(_ pack: CosmeticPack) {
        guard isOwned(pack) else { return }
        selectedPack = pack
        settings.selectedThemeID = pack.rawValue
    }

    func purchase(_ pack: CosmeticPack) async {
        guard let product = product(for: pack) else {
            lastError = "Product isn’t available. Enable Products.storekit on the Gridbloom scheme, or create the IAP in App Store Connect."
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedIDs.insert(transaction.productID)
                select(pack)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var owned = Set<String>()
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(entitlement) {
                owned.insert(transaction.productID)
            }
        }
        purchasedIDs = owned
        if !isOwned(selectedPack) {
            select(.garden)
        }
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        guard let transaction = try? checkVerified(verification) else { return }
        purchasedIDs.insert(transaction.productID)
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
