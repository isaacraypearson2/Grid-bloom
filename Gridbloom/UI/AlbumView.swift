import SwiftUI

struct AlbumView: View {
    @ObservedObject var profile: PlayerProfile
    @ObservedObject var cosmetics: CosmeticsStore
    var theme: BoardTheme
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
                        Text("\(profile.collectedFlowers.count)/\(FlowerSpecies.allCases.count) collected  ·  \(profile.gardenRank.title)")
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
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(FlowerSpecies.allCases) { species in
                            flowerCard(species)
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

    private func flowerCard(_ species: FlowerSpecies) -> some View {
        let status = profile.albumStatus(for: species)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                BloomMark(size: 36, petal: status == .locked ? theme.inkSoft.opacity(0.35) : species.swiftTint)
                    .opacity(status == .locked ? 0.45 : 1)
                Spacer()
                Text(statusLabel(status))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.inkSoft)
            }
            Text(status == .locked ? "???" : species.title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(theme.ink)
            Text(status == .locked ? species.unlockHint : species.blurb)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(theme.cream.opacity(status == .collected ? 0.95 : 0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(status == .collected ? theme.accent.opacity(0.5) : Color.clear, lineWidth: 1.4)
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
        }
    }
}
