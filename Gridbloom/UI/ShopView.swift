import SwiftUI
import StoreKit

struct ShopView: View {
    @ObservedObject var store: CosmeticsStore
    @ObservedObject var settings: AppSettings
    var theme: BoardTheme
    var onClose: () -> Void

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Greenhouse")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Text("Board themes, tile glaze, petal FX.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                if store.isLoading && store.products.isEmpty {
                    ProgressView("Checking the greenhouse…")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                }

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(CosmeticPack.allCases) { pack in
                            packRow(pack)
                        }
                    }
                    .padding(.bottom, 12)
                }

                if let error = store.lastError, !store.isLoading {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                        Button("Try again") {
                            Task { await store.load() }
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.accent)
                    }
                }

                Button("Restore purchases") {
                    Task { await store.restore() }
                }
                .font(.system(.headline, design: .rounded))
                .foregroundColor(theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
                .disabled(store.isLoading || store.isPurchasing)
            }
            .padding(22)
        }
        .task { await store.load() }
    }

    private func packRow(_ pack: CosmeticPack) -> some View {
        let owned = store.isOwned(pack)
        let selected = store.selectedPack == pack
        let product = store.product(for: pack)
        return HStack(alignment: .center, spacing: 14) {
            BloomMark(size: 44, petal: BoardTheme.theme(for: pack, colorblind: settings.colorblindPalette).accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(pack.title)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                Text(pack.blurb)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(theme.inkSoft)
            }
            Spacer()
            if selected {
                Text("On")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(theme.accent)
            } else if owned {
                Button("Use") { store.select(pack) }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(theme.accent)
                    .clipShape(Capsule())
            } else {
                buyButton(pack: pack, product: product)
            }
        }
        .padding(14)
        .background(theme.cream.opacity(selected ? 0.95 : 0.72))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(selected ? theme.accent.opacity(0.55) : Color.clear, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func buyButton(pack: CosmeticPack, product: Product?) -> some View {
        if store.isLoading, product == nil {
            ProgressView()
                .tint(theme.accent)
                .frame(width: 44, height: 32)
        } else if let price = product?.displayPrice {
            Button(price) {
                Task { await store.purchase(pack) }
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(GardenPalette.dailyFill)
            .clipShape(Capsule())
            .disabled(store.isPurchasing)
            .accessibilityLabel("Buy \(pack.title) for \(price)")
        } else {
            Button("Unavailable") {
                Task { await store.load() }
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundColor(theme.inkSoft)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(theme.cream)
            .clipShape(Capsule())
        }
    }
}
