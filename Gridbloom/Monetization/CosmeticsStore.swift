import Foundation
import StoreKit
import Combine

/// StoreKit 2 cosmetics. Products come from App Store Connect, or from
/// `Products.storekit` when that file is attached to the Gridbloom scheme.
@MainActor
final class CosmeticsStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedIDs: Set<String> = []
    @Published var selectedPack: CosmeticPack
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
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

    /// StoreKit localized price, or nil when the product has not loaded yet.
    func displayPrice(for pack: CosmeticPack) -> String? {
        product(for: pack)?.displayPrice
    }

    var paidProductCount: Int {
        products.filter { MonetizationHooks.Cosmetics.allIDs.contains($0.id) }.count
    }

    func load() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: MonetizationHooks.Cosmetics.allIDs)
            products = CosmeticPack.allCases.compactMap { pack in
                guard let id = pack.productID else { return nil }
                return loaded.first { $0.id == id }
            }
            await refreshEntitlements()
            if products.isEmpty {
                lastError = Self.missingProductsMessage
            } else if paidProductCount < MonetizationHooks.Cosmetics.allIDs.count {
                lastError = "Some Greenhouse packs did not load. \(Self.missingProductsMessage)"
            }
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
        guard !isPurchasing else { return }
        guard let product = product(for: pack) else {
            lastError = Self.missingProductsMessage
            await load()
            return
        }
        isPurchasing = true
        lastError = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedIDs.insert(transaction.productID)
                select(pack)
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                lastError = "Purchase is pending approval (Ask to Buy). It will unlock after it’s approved."
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
        await refreshEntitlements()
    }

    func restore() async {
        lastError = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            lastError = error.localizedDescription
        }
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

    static let missingProductsMessage =
        "No live prices yet. In Xcode: Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration → Products.storekit. For TestFlight or the App Store, create matching non-consumable IAPs in App Store Connect."
}
