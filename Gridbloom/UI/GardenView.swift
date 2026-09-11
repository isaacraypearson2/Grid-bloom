import SwiftUI
import Combine

struct GardenView: View {
    @ObservedObject var profile: PlayerProfile
    var theme: BoardTheme
    var onClose: () -> Void

    @State private var plantSlot: Int?
    @State private var adMessage: String?
    @State private var toast: String?
    @State private var wateringSlot: Int?
    @State private var fertilizeKind: FertilizerKind = .regular

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My garden")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Text("Water about every 3 hours so they don’t wilt. Regular fertilizer is an ad (2× for 2 hours). Organic is stronger (3× for 4 hours, 12h cooldown). Classic Garden never waits on this.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        fertilizerBar
                        organicBar
                        packsRow
                        shopRow
                        petalOffers
                        potTintRow

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

                        Text("\(profile.petals) petals  ·  \(profile.inventorySeeds.reduce(0) { $0 + $1.1 }) seeds  ·  \(profile.fertilizerCharges) fertilizer  ·  \(profile.organicFertilizerCharges) organic")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundColor(theme.inkSoft)

                        if let toast {
                            Text(toast)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundColor(theme.accent)
                        }
                    }
                }
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
        .onChange(of: profile.lastWateredPlotID) { id in
            guard let id, let plot = profile.gardenPlots.first(where: { $0.id == id }) else { return }
            wateringSlot = plot.slot
            Haptics.light()
            SoundPlayer.shared.place()
            let hold = AppSettings.shared.prefersReducedMotion ? 0.35 : 1.05
            DispatchQueue.main.asyncAfter(deadline: .now() + hold) {
                if wateringSlot == plot.slot {
                    wateringSlot = nil
                    profile.clearWateredPlot()
                }
            }
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
                fertilizeKind = .regular
                watchForFertilizer()
            } label: {
                Text(profile.fertilizerCharges >= SeedGardenRules.fertilizerChargeCap ? "Full" : (fertilizeKind == .regular ? "Watch · selected" : "Watch for fertilizer"))
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

    private var organicBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Organic fertilizer")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.inkSoft)
                Text("\(profile.organicFertilizerCharges) charge\(profile.organicFertilizerCharges == 1 ? "" : "s")")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                Text("3× for 4 hours · 12h cooldown. Earn from Bee Trail or a 2500+ run.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(theme.inkSoft)
            }
            Spacer()
            Button {
                fertilizeKind = .organic
                toast = "Organic selected — tap Fertilize on a bed"
            } label: {
                Text(fertilizeKind == .organic ? "Selected" : "Use Organic")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(profile.organicFertilizerCharges == 0 ? theme.inkSoft : FertilizerKind.organic.fill)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(profile.organicFertilizerCharges == 0)
        }
        .padding(12)
        .background(theme.cream.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var petalOffers: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spend petals")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(theme.ink)
            Text("Mists, dew, pot tints, Bee lanterns, Organic pouches.")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(theme.inkSoft)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PetalOffer.allCases) { offer in
                        Button {
                            if profile.redeem(offer) {
                                toast = profile.lastPetalOfferMessage ?? offer.title
                                Haptics.success()
                            } else {
                                toast = profile.lastPetalOfferMessage ?? "Need \(offer.cost) petals"
                                Haptics.error()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Image(systemName: offer.systemImage)
                                Text(offer.title)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                Text("\(offer.cost) petals")
                                    .font(.system(size: 11, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(10)
                            .frame(width: 118, alignment: .leading)
                            .background(theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var potTintRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pot tint")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundColor(theme.inkSoft)
            HStack(spacing: 8) {
                ForEach(PotTint.allCases) { tint in
                    Button {
                        if profile.ownsPot(tint) {
                            profile.selectPotTint(tint)
                            toast = "\(tint.title) pots"
                        } else {
                            toast = "Buy \(tint.title) with petals"
                            Haptics.error()
                        }
                    } label: {
                        Circle()
                            .fill(tint.fill)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().stroke(profile.selectedPotTint == tint ? theme.ink : Color.clear, lineWidth: 2)
                            )
                            .opacity(profile.ownsPot(tint) ? 1 : 0.35)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tint.title)
                }
            }
        }
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
                ZStack {
                    BloomMark(size: 26, petal: plot.careStage(now: now) == .wilted ? theme.inkSoft : plot.bloom.swiftTint)
                        .opacity(plot.careStage(now: now) == .wilted ? 0.55 : 1)
                    if wateringSlot == slot {
                        WateringFX(accent: theme.accent, reduced: AppSettings.shared.prefersReducedMotion)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .frame(height: 40)
                Text(plot.bloom.title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(BloomFacts.speciesFact(plot.species))
                    .font(.system(size: 9, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                if let warning = plot.warningCopy(now: now) {
                    Text(warning)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(plot.careStage(now: now) == .wilted ? Color(red: 0.72, green: 0.38, blue: 0.18) : Color(red: 0.78, green: 0.55, blue: 0.12))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else if plot.isFertilizerActive(now: now) {
                    Text("\(plot.fertilizerKind.multiplier, specifier: "%g")× \(plot.fertilizerKind.title.lowercased())")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(plot.fertilizerKind.fill)
                } else if plot.isDewActive(now: now) {
                    Text("Dew burst")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.36, green: 0.58, blue: 0.72))
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
                            toast = "Watered — next drink in about 3 hours"
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
        .frame(maxWidth: .infinity, minHeight: 196)
        .padding(10)
        .background(plotBackground(live: plot, now: now))
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(profile.selectedPotTint.fill)
                .frame(height: 6)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
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
        let charges = fertilizeKind == .organic ? profile.organicFertilizerCharges : profile.fertilizerCharges
        return charges > 0 && plot.canAcceptFertilizer(now: now)
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
        let charges = fertilizeKind == .organic ? profile.organicFertilizerCharges : profile.fertilizerCharges
        if charges <= 0 {
            toast = fertilizeKind == .organic ? "Win Bee Trail or score 2500+ for Organic" : "Watch an ad for a fertilizer charge"
            Haptics.error()
            return
        }
        if profile.applyFertilizer(plot.id, kind: fertilizeKind, now: now) {
            toast = fertilizeKind == .organic ? "Organic 3× for 4 hours" : "2× growth for 2 hours"
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
                Text("\(bloom.rarity.title)  ·  \(SeedGardenRules.formatRemaining(bloom.rarity.growDuration))  ·  water every 3h")
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
