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

                if store.isLoading {
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

                if store.products.isEmpty && !store.isLoading {
                    Text("No live prices yet. In Xcode choose the Gridbloom scheme → Run → Options → StoreKit Configuration → Products.storekit.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                }

                Button("Restore purchases") {
                    Task { await store.restore() }
                }
                .font(.system(.headline, design: .rounded))
                .foregroundColor(theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
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
                Button(product?.displayPrice ?? "…") {
                    Task { await store.purchase(pack) }
                }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(GardenPalette.dailyFill)
                .clipShape(Capsule())
                .disabled(product == nil && !pack.isFree)
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
}
