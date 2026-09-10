import SwiftUI

struct GardenView: View {
    @ObservedObject var profile: PlayerProfile
    var theme: BoardTheme
    var onClose: () -> Void

    @State private var plantSlot: Int?
    @State private var adMessage: String?
    @State private var toast: String?

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My garden")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Text("Plant seeds, wait (or watch), harvest playable tiles. Classic Garden never waits on this.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(0..<SeedGardenRules.plotCount, id: \.self) { slot in
                            plotCard(slot: slot, now: timeline.date)
                        }
                    }
                }

                packsRow
                shopRow

                Text("\(profile.petals) petals  ·  \(profile.inventorySeeds.reduce(0) { $0 + $1.1 }) seeds")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.inkSoft)

                if let toast {
                    Text(toast)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.accent)
                }

                Spacer(minLength: 0)
            }
            .padding(22)

            if let reveal = profile.lastPackReveal {
                packReveal(reveal)
            }

            if let adMessage {
                Color.black.opacity(0.32).ignoresSafeArea()
                AdInterludeView(theme: theme, title: adMessage)
            }
        }
        .sheet(item: plantSlotBinding) { slot in
            plantPicker(slot: slot.value)
        }
    }

    private var plantSlotBinding: Binding<IdentifiedSlot?> {
        Binding(
            get: { plantSlot.map(IdentifiedSlot.init) },
            set: { plantSlot = $0?.value }
        )
    }

    private var packsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Seed packs")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(theme.ink)
            if profile.seedPacks.isEmpty {
                Text("Win side gardens to earn packs. Common / Rare / Epic / Ultra — a pack only grants that tier.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(theme.inkSoft)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(profile.seedPacks) { pack in
                            Button {
                                if profile.openPack(pack.id) != nil {
                                    Haptics.success()
                                    SoundPlayer.shared.bloom(combo: pack.rarity == .ultra ? 4 : 2)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pack.rarity.title.uppercased())
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                    Text("Open")
                                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(pack.rarity.fill)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var shopRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Buy with petals")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(theme.inkSoft)
            HStack(spacing: 8) {
                ForEach(SeedRarity.allCases) { rarity in
                    Button {
                        if profile.buyPack(rarity) != nil {
                            toast = "\(rarity.packTitle) added"
                            Haptics.success()
                        } else {
                            toast = "Need \(rarity.petalCost) petals"
                            Haptics.error()
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(rarity.title)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Text("\(rarity.petalCost)")
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(rarity.fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func plotCard(slot: Int, now: Date) -> some View {
        let plot = profile.gardenPlots.first { $0.slot == slot }
        return VStack(spacing: 8) {
            if let plot {
                BloomMark(size: 28, petal: plot.species.swiftTint)
                Text(plot.species.title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(plot.species.rarity.title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(plot.species.rarity.ink)
                if plot.isReady(now: now) {
                    Button("Harvest") {
                        if let species = profile.harvestPlot(plot.id, now: now) {
                            toast = "\(species.title) joined Classic Garden"
                            Haptics.success()
                            SoundPlayer.shared.bloom(combo: species.rarity == .ultra ? 3 : 1)
                        }
                    }
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(theme.accent)
                    .clipShape(Capsule())
                } else {
                    ProgressView(value: plot.progress(now: now))
                        .tint(plot.species.rarity.fill)
                    Text(SeedGardenRules.formatRemaining(plot.remaining(now: now)))
                        .font(.system(size: 11, design: .rounded).monospacedDigit())
                        .foregroundColor(theme.inkSoft)
                    Button("Watch to bloom") {
                        boost(plot)
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.accent)
                }
            } else {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .foregroundColor(theme.inkSoft)
                Text("Empty bed")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.inkSoft)
                Button("Plant") {
                    plantSlot = slot
                }
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(theme.accent)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132)
        .padding(10)
        .background(theme.cream.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func plantPicker(slot: Int) -> some View {
        NavigationView {
            List {
                if profile.inventorySeeds.isEmpty {
                    Text("Open a seed pack or win a side garden first.")
                        .foregroundColor(theme.inkSoft)
                }
                ForEach(profile.inventorySeeds, id: \.0) { species, count in
                    Button {
                        if profile.plantSeed(species, slot: slot) != nil {
                            plantSlot = nil
                            Haptics.success()
                        }
                    } label: {
                        HStack {
                            BloomMark(size: 28, petal: species.swiftTint)
                            VStack(alignment: .leading) {
                                Text(species.title)
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(theme.ink)
                                Text("\(species.rarity.title)  ·  \(SeedGardenRules.formatRemaining(species.rarity.growDuration))")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(species.rarity.ink)
                            }
                            Spacer()
                            Text("×\(count)")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundColor(theme.inkSoft)
                        }
                    }
                }
            }
            .navigationTitle("Plant a seed")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { plantSlot = nil }
                }
            }
        }
    }

    private func packReveal(_ reveal: PackReveal) -> some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 14) {
                Text(reveal.rarity.packTitle)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                Text(reveal.rarity.title.uppercased())
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(reveal.rarity.fill)
                    ForEach(Array(reveal.seeds.enumerated()), id: \.offset) { _, species in
                    HStack {
                        BloomMark(size: 28, petal: species.swiftTint)
                        Text(species.title)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Spacer()
                        Text(species.rarity.title)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(species.rarity.ink)
                    }
                    .padding(10)
                    .background(theme.cream.opacity(0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                PrimaryGardenButton(title: "Plant these later", fill: reveal.rarity.fill) {
                    profile.clearPackReveal()
                }
            }
            .padding(22)
            .background(reveal.rarity.fill.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(28)
        }
        .allowsHitTesting(true)
    }

    private func boost(_ plot: GardenPlot) {
        guard adMessage == nil else { return }
        adMessage = "Speeding up a bloom"
        Task {
            let granted = await MonetizationHooks.presentRewarded(.speedGrowth)
            await MainActor.run {
                adMessage = nil
                if granted, profile.boostPlot(plot.id) {
                    toast = "Ready to harvest"
                    Haptics.success()
                } else {
                    Haptics.error()
                }
            }
        }
    }
}

private struct IdentifiedSlot: Identifiable {
    var value: Int
    var id: Int { value }
}
