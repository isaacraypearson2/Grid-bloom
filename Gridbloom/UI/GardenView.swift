import SwiftUI
import Combine

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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My garden")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Text("Water so they don’t wilt. Ads grant fertilizer (2× for 2 hours), not an instant skip. Classic Garden never waits on this.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                fertilizerBar

                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(0..<SeedGardenRules.plotCount, id: \.self) { slot in
                            plotCard(slot: slot, now: timeline.date)
                        }
                    }
                }
                .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
                    profile.tickGarden(now: date)
                    presentGardenEvent()
                }

                packsRow
                shopRow

                Text("\(profile.petals) petals  ·  \(profile.inventorySeeds.reduce(0) { $0 + $1.1 }) seeds  ·  \(profile.fertilizerCharges) fertilizer")
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
        .onAppear {
            profile.tickGarden()
            presentGardenEvent()
        }
    }

    private var plantSlotBinding: Binding<IdentifiedSlot?> {
        Binding(
            get: { plantSlot.map(IdentifiedSlot.init) },
            set: { plantSlot = $0?.value }
        )
    }

    private var fertilizerBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Fertilizer")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.inkSoft)
                Text("\(profile.fertilizerCharges) charge\(profile.fertilizerCharges == 1 ? "" : "s")")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
            }
            Spacer()
            Button {
                watchForFertilizer()
            } label: {
                Text(profile.fertilizerCharges >= SeedGardenRules.fertilizerChargeCap ? "Full" : "Watch for fertilizer")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(profile.fertilizerCharges >= SeedGardenRules.fertilizerChargeCap ? theme.inkSoft : theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(profile.fertilizerCharges >= SeedGardenRules.fertilizerChargeCap || adMessage != nil)
        }
        .padding(12)
        .background(theme.cream.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    private func resolvedPlot(slot: Int, now: Date) -> GardenPlot? {
        guard var plot = profile.gardenPlots.first(where: { $0.slot == slot }) else { return nil }
        plot.tick(now: now)
        return plot
    }

    private func plotCard(slot: Int, now: Date) -> some View {
        let plot = resolvedPlot(slot: slot, now: now)
        return VStack(spacing: 6) {
            if let plot {
                BloomMark(size: 26, petal: plot.careStage(now: now) == .wilted ? theme.inkSoft : plot.bloom.swiftTint)
                    .opacity(plot.careStage(now: now) == .wilted ? 0.55 : 1)
                Text(plot.bloom.title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let warning = plot.warningCopy(now: now) {
                    Text(warning)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(plot.careStage(now: now) == .wilted ? Color(red: 0.72, green: 0.38, blue: 0.18) : Color(red: 0.78, green: 0.55, blue: 0.12))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else if plot.isFertilizerActive(now: now) {
                    Text("2× fertilizer")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.46, green: 0.62, blue: 0.28))
                } else {
                    Text(plot.bloom.rarity.title)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(plot.bloom.rarity.ink)
                }
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
                } else if plot.careStage(now: now) == .wilted {
                    ProgressView(value: plot.progress(now: now))
                        .tint(theme.inkSoft)
                    Text("Growth paused")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                } else {
                    ProgressView(value: plot.progress(now: now))
                        .tint(plot.bloom.rarity.fill)
                    Text(SeedGardenRules.formatRemaining(plot.remaining(now: now)))
                        .font(.system(size: 11, design: .rounded).monospacedDigit())
                        .foregroundColor(theme.inkSoft)
                }
                HStack(spacing: 6) {
                    Button("Water") {
                        if profile.waterPlot(plot.id, now: now) {
                            toast = "Watered"
                            Haptics.light()
                        }
                    }
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accent)
                    .clipShape(Capsule())
                    Button("Fertilize") {
                        applyFertilizer(plot, now: now)
                    }
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(canFertilize(plot, now: now) ? theme.accent : theme.inkSoft)
                }
                if plot.fertilizerCooldownRemaining(now: now) > 0, !plot.isReady(now: now) {
                    Text("Fertilizer again in \(SeedGardenRules.formatRemaining(plot.fertilizerCooldownRemaining(now: now)))")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                        .multilineTextAlignment(.center)
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
        .frame(maxWidth: .infinity, minHeight: 168)
        .padding(10)
        .background(plotBackground(live: plot, now: now))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func plotBackground(live: GardenPlot?, now: Date) -> Color {
        guard let plot = live else { return theme.cream.opacity(0.82) }
        switch plot.careStage(now: now) {
        case .wilted:
            return Color(red: 0.93, green: 0.84, blue: 0.72).opacity(0.95)
        case .thirsty:
            return Color(red: 0.96, green: 0.92, blue: 0.72).opacity(0.95)
        default:
            return theme.cream.opacity(0.82)
        }
    }

    private func canFertilize(_ plot: GardenPlot, now: Date) -> Bool {
        profile.fertilizerCharges > 0 && plot.canAcceptFertilizer(now: now)
    }

    private func applyFertilizer(_ plot: GardenPlot, now: Date) {
        if plot.careStage(now: now) == .wilted {
            toast = "Water first — growth is paused"
            Haptics.error()
            return
        }
        if plot.fertilizerCooldownRemaining(now: now) > 0 {
            toast = "This plant can take fertilizer again in \(SeedGardenRules.formatRemaining(plot.fertilizerCooldownRemaining(now: now)))"
            Haptics.error()
            return
        }
        if profile.fertilizerCharges <= 0 {
            toast = "Watch an ad for a fertilizer charge"
            Haptics.error()
            return
        }
        if profile.applyFertilizer(plot.id, now: now) {
            toast = "2× growth for 2 hours"
            Haptics.success()
        } else {
            Haptics.error()
        }
    }

    private func plantPicker(slot: Int) -> some View {
        NavigationView {
            List {
                if profile.inventorySeeds.isEmpty {
                    Text("Open a seed pack or win a side garden first.")
                        .foregroundColor(theme.inkSoft)
                }
                ForEach(profile.inventorySeeds, id: \.0.catalogKey) { bloom, count in
                    Button {
                        if profile.plantSeed(bloom, slot: slot) != nil {
                            plantSlot = nil
                            Haptics.success()
                        }
                    } label: {
                        HStack {
                            BloomMark(size: 28, petal: bloom.swiftTint)
                            VStack(alignment: .leading) {
                                Text(bloom.title)
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundColor(theme.ink)
                                Text("\(bloom.rarity.title)  ·  \(SeedGardenRules.formatRemaining(bloom.rarity.growDuration))  ·  water often")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(bloom.rarity.ink)
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
                ForEach(Array(reveal.seeds.enumerated()), id: \.offset) { _, bloom in
                    HStack {
                        BloomMark(size: 28, petal: bloom.swiftTint)
                        Text(bloom.title)
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Spacer()
                        Text(bloom.rarity.title)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(bloom.rarity.ink)
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

    private func watchForFertilizer() {
        guard adMessage == nil, profile.fertilizerCharges < SeedGardenRules.fertilizerChargeCap else { return }
        adMessage = "Gathering fertilizer"
        Task {
            let granted = await MonetizationHooks.presentRewarded(.fertilizer)
            await MainActor.run {
                adMessage = nil
                if granted {
                    _ = profile.grantFertilizerCharge()
                    toast = "Fertilizer charge ready — apply it to a plant"
                    Haptics.success()
                } else {
                    Haptics.error()
                }
            }
        }
    }

    private func presentGardenEvent() {
        guard let event = profile.lastGardenEvent else { return }
        switch event {
        case .died(let species, let salvaged):
            toast = salvaged
                ? "\(species.title) wilted. A seed was salvaged."
                : "\(species.title) wilted away. The bed is empty."
            Haptics.error()
        }
        profile.clearGardenEvent()
    }
}

private struct IdentifiedSlot: Identifiable {
    var value: Int
    var id: Int { value }
}
