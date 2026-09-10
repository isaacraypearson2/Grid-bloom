import SwiftUI

struct AlbumView: View {
    @ObservedObject var profile: PlayerProfile
    @ObservedObject var cosmetics: CosmeticsStore
    var theme: BoardTheme
    var onScanFlower: () -> Void
    var onClose: () -> Void
    @State private var toast: String?

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Flower album")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Text("\(profile.collectedVariantIDs.count)/\(BloomCatalog.allVariants.count) variants  ·  \(profile.collectedFlowers.count) species  ·  \(profile.customBlooms.count) scanned  ·  \(profile.gardenRank.title)")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                HStack {
                    Text("\(profile.petals) petals")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(theme.ink)
                    Spacer()
                    if profile.albumStatus(for: .lotus) == .locked {
                        Button("Invite Lotus · 30") {
                            if profile.buyLotus() {
                                toast = "Lotus joined the album"
                                Haptics.success()
                            } else {
                                toast = "Need 30 petals"
                                Haptics.error()
                            }
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(theme.accent)
                        .clipShape(Capsule())
                    }
                    Button("Scan") {
                        onScanFlower()
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(GardenPalette.dailyFill)
                    .clipShape(Capsule())
                }
                .padding(12)
                .background(theme.cream.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if let toast {
                    Text(toast)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.accent)
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                        ForEach(profile.customBlooms) { bloom in
                            customCard(bloom)
                        }
                        ForEach(FlowerSpecies.allCases) { species in
                            speciesCard(species)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .padding(22)
        }
        .onAppear {
            profile.syncMapFlowers(ownedPacks: CosmeticPack.allCases.filter { cosmetics.isOwned($0) })
        }
    }

    private func speciesCard(_ species: FlowerSpecies) -> some View {
        let status = profile.albumStatus(for: species)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                BloomMark(size: 36, petal: status == .locked ? theme.inkSoft.opacity(0.35) : species.swiftTint)
                    .opacity(status == .locked ? 0.45 : 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status == .locked ? "???" : species.title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(theme.ink)
                    Text(status == .locked ? species.unlockHint : species.blurb)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Text(statusLabel(status))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.inkSoft)
            }
            if status != .locked {
                ForEach(species.colors, id: \.self) { color in
                    colorRow(species: species, color: color)
                }
            }
        }
        .padding(14)
        .background(theme.cream.opacity(status == .collected ? 0.95 : 0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(status == .collected ? theme.accent.opacity(0.5) : Color.clear, lineWidth: 1.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func colorRow(species: FlowerSpecies, color: BloomColor) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(species.profile.tint(for: color)))
                .frame(width: 14, height: 14)
            Text(color.title)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundColor(theme.ink)
                .frame(width: 72, alignment: .leading)
            ForEach(SeedRarity.allCases) { rarity in
                let bloom = BloomVariant(species: species, color: color, rarity: rarity)
                let status = profile.albumStatus(for: bloom)
                Text(rarity.title.prefix(1))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(status == .collected ? .white : rarity.ink.opacity(status == .unlocked ? 0.9 : 0.35))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        (status == .collected ? rarity.fill : rarity.fill.opacity(status == .unlocked ? 0.28 : 0.12))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityLabel("\(rarity.title) \(color.title) \(species.title), \(statusLabel(status))")
            }
        }
    }

    private func customCard(_ bloom: CustomBloom) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let stamp = CustomBloomDisk.stamp(id: bloom.id) {
                    Image(uiImage: stamp)
                        .resizable()
                        .frame(width: 36, height: 36)
                } else {
                    BloomMark(size: 36, petal: Color(bloom.fillColor))
                }
                Spacer()
                Text("Scanned")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.inkSoft)
            }
            Text(bloom.name)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(theme.ink)
            Text(bloom.identifiedOnDevice ? "Spotted on-device. Plays in Classic Garden." : "Custom bloom from your photo. Plays in Classic Garden.")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button("Remove") {
                profile.removeCustomBloom(bloom.id)
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundColor(theme.inkSoft)
        }
        .padding(14)
        .background(theme.cream.opacity(0.95))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.accent.opacity(0.5), lineWidth: 1.4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func statusLabel(_ status: AlbumStatus) -> String {
        switch status {
        case .locked: return "Locked"
        case .unlocked: return "Seen"
        case .collected: return "Collected"
        }
    }
}

extension FlowerSpecies {
    var unlockHint: String {
        switch unlock {
        case .starter:
            return "Play Classic Garden."
        case .miniGame(let kind):
            return kind.blurb
        case .petals(let cost):
            return "Spend \(cost) petals in the album."
        case .mapSkin(let pack):
            return "Unlock the \(pack.title) map."
        case .seedPack(let rarity):
            return "Grow a \(rarity.title) seed and harvest it in My garden."
        }
    }
}
