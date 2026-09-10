import SwiftUI

struct ShopView: View {
    @ObservedObject var store: CosmeticsStore
    @ObservedObject var settings: AppSettings
    @ObservedObject var profile: PlayerProfile
    var theme: BoardTheme
    var onPlayPatternBloom: () -> Void
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
                        Text("Maps and glazes. Classic Garden is never paywalled. You have \(profile.petals) petals.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(CosmeticPack.allCases) { pack in
                            packRow(pack)
                        }
                    }
                    .padding(.bottom, 12)
                }

                if let error = store.lastError, !store.isUnlocking {
                    Text(error)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                }

                Button("Restore previous unlocks") {
                    Task { await store.restore() }
                }
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(theme.inkSoft)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
                .disabled(store.isUnlocking)
                .accessibilityHint("Imports leftover App Store purchases, if any")
            }
            .padding(22)
        }
        .task { await store.load() }
    }

    private func packRow(_ pack: CosmeticPack) -> some View {
        let owned = store.isOwned(pack)
        let selected = store.selectedPack == pack
        let unlockingThis = store.unlockingPack == pack
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
                    .disabled(store.isUnlocking)
            } else if unlockingThis {
                ProgressView()
                    .tint(theme.accent)
                    .frame(width: 44, height: 32)
            } else if pack.isAdUnlock {
                Button("Watch to unlock") {
                    Task {
                        await store.unlockByWatchingAd(pack)
                        profile.syncMapFlowers(ownedPacks: CosmeticPack.allCases.filter { store.isOwned($0) })
                    }
                }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(GardenPalette.dailyFill)
                .clipShape(Capsule())
                .disabled(store.isUnlocking)
                .accessibilityLabel("Watch an ad to unlock \(pack.title)")
            } else if pack.miniGameUnlock != nil {
                Button("Play to unlock") {
                    onPlayPatternBloom()
                }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(theme.accent)
                .clipShape(Capsule())
            } else if let cost = pack.petalCost {
                Button("\(cost) petals") {
                    if store.unlockWithPetals(pack, profile: profile) {
                        Haptics.success()
                    } else {
                        Haptics.error()
                    }
                }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(GardenPalette.dailyFill)
                .clipShape(Capsule())
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
