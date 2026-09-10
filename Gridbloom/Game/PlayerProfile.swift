import Foundation
import Combine
import UIKit

/// Local profile: lifetime stats, UTC daily streak, petals, album, and daily goals.
final class PlayerProfile: ObservableObject {
    static let shared = PlayerProfile()

    @Published private(set) var gamesPlayed: Int
    @Published private(set) var linesCleared: Int
    @Published private(set) var bestCombo: Int
    @Published private(set) var dailyStreak: Int
    @Published private(set) var longestDailyStreak: Int
    @Published private(set) var lastDailyPlayDay: String?
    @Published private(set) var petals: Int
    @Published private(set) var lifetimePetals: Int
    @Published private(set) var extraFlowerIDs: Set<String>
    @Published private(set) var collectedFlowerIDs: Set<String>
    @Published private(set) var goalState: DailyGoalProgress
    @Published private(set) var lastClaimedGoalIDs: [String] = []
    @Published private(set) var lastPetalsAwarded: Int = 0
    @Published private(set) var customBlooms: [CustomBloom]
    @Published private(set) var gardenPlots: [GardenPlot]
    @Published private(set) var seedCounts: [String: Int]
    @Published private(set) var seedPacks: [OwnedSeedPack]
    @Published private(set) var lastPackReveal: PackReveal?
    @Published private(set) var lastHarvested: FlowerSpecies?
    @Published private(set) var fertilizerCharges: Int
    @Published private(set) var lastGardenEvent: GardenEvent?

    private let defaults: UserDefaults

    private enum Keys {
        static let games = "gridbloom.profile.games"
        static let lines = "gridbloom.profile.lines"
        static let combo = "gridbloom.profile.combo"
        static let streak = "gridbloom.profile.streak"
        static let longest = "gridbloom.profile.longestStreak"
        static let lastDaily = "gridbloom.profile.lastDaily"
        static let petals = "gridbloom.profile.petals"
        static let lifetimePetals = "gridbloom.profile.lifetimePetals"
        static let extraFlowers = "gridbloom.profile.extraFlowers"
        static let collected = "gridbloom.profile.collectedFlowers"
        static let goals = "gridbloom.profile.dailyGoals"
        static let blooms = "gridbloom.profile.customBlooms"
        static let plots = "gridbloom.profile.gardenPlots"
        static let seeds = "gridbloom.profile.seedCounts"
        static let packs = "gridbloom.profile.seedPacks"
        static let starterSeeds = "gridbloom.profile.starterSeeds"
        static let ultraMilestone = "gridbloom.profile.ultraMilestone"
        static let fertilizer = "gridbloom.profile.fertilizerCharges"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        gamesPlayed = defaults.integer(forKey: Keys.games)
        linesCleared = defaults.integer(forKey: Keys.lines)
        bestCombo = defaults.integer(forKey: Keys.combo)
        dailyStreak = defaults.integer(forKey: Keys.streak)
        longestDailyStreak = defaults.integer(forKey: Keys.longest)
        lastDailyPlayDay = defaults.string(forKey: Keys.lastDaily)
        petals = defaults.integer(forKey: Keys.petals)
        lifetimePetals = defaults.integer(forKey: Keys.lifetimePetals)
        extraFlowerIDs = Set(defaults.stringArray(forKey: Keys.extraFlowers) ?? [])
        collectedFlowerIDs = Set(defaults.stringArray(forKey: Keys.collected) ?? [])
        if let bloomData = defaults.data(forKey: Keys.blooms),
           let blooms = try? JSONDecoder().decode([CustomBloom].self, from: bloomData) {
            customBlooms = blooms
        } else {
            customBlooms = []
        }
        if let plotData = defaults.data(forKey: Keys.plots),
           let plots = try? JSONDecoder().decode([GardenPlot].self, from: plotData) {
            gardenPlots = plots
        } else {
            gardenPlots = []
        }
        if let seedData = defaults.data(forKey: Keys.seeds),
           let counts = try? JSONDecoder().decode([String: Int].self, from: seedData) {
            seedCounts = counts
        } else {
            seedCounts = [:]
        }
        if let packData = defaults.data(forKey: Keys.packs),
           let packs = try? JSONDecoder().decode([OwnedSeedPack].self, from: packData) {
            seedPacks = packs
        } else {
            seedPacks = []
        }
        lastPackReveal = nil
        lastHarvested = nil
        lastGardenEvent = nil
        fertilizerCharges = defaults.integer(forKey: Keys.fertilizer)
        if !defaults.bool(forKey: Keys.starterSeeds) {
            defaults.set(true, forKey: Keys.starterSeeds)
            addSeed(.tulip)
            addSeed(.daisy)
            addSeed(.rose)
        }
        if let data = defaults.data(forKey: Keys.goals),
           let decoded = try? JSONDecoder().decode(DailyGoalProgress.self, from: data) {
            goalState = decoded
        } else {
            goalState = DailyGoalProgress(utcDay: DailySeed.utcDayString())
        }
        refreshGoalsIfNeeded(utcDay: DailySeed.utcDayString())
        tickGarden(now: Date())
    }

    var playedDailyToday: Bool {
        lastDailyPlayDay == DailySeed.utcDayString()
    }

    var unlockedFlowers: Set<FlowerSpecies> {
        var set = Set(FlowerSpecies.starters)
        for id in extraFlowerIDs {
            if let value = Int(id), let species = FlowerSpecies(rawValue: value) {
                set.insert(species)
            }
        }
        return set
    }

    var collectedFlowers: Set<FlowerSpecies> {
        var set = Set<FlowerSpecies>()
        for id in collectedFlowerIDs {
            if let value = Int(id), let species = FlowerSpecies(rawValue: value) {
                set.insert(species)
            }
        }
        return set
    }

    var gardenRank: GardenRank {
        GardenRank.from(collectedCount: collectedFlowers.count + customBlooms.count)
    }

    var todayGoals: [DailyGoal] {
        DailyGoalCatalog.goals(utcDay: goalState.utcDay)
    }

    var completedGoalCount: Int {
        todayGoals.filter { goalState.isComplete($0) }.count
    }

    func playableFlowers(for mode: GameMode) -> Set<FlowerSpecies> {
        switch mode {
        case .daily:
            return Set(FlowerSpecies.starters)
        case .classic:
            return unlockedFlowers
        }
    }

    func albumStatus(for species: FlowerSpecies) -> AlbumStatus {
        if collectedFlowers.contains(species) { return .collected }
        if unlockedFlowers.contains(species) { return .unlocked }
        return .locked
    }

    func recordGameStarted() {
        gamesPlayed += 1
        defaults.set(gamesPlayed, forKey: Keys.games)
    }

    func record(lines: Int, combo: Int, flowers: [FlowerSpecies] = [], score: Int = 0) {
        if lines > 0 {
            linesCleared += lines
            defaults.set(linesCleared, forKey: Keys.lines)
            addPetals(Scoring.petals(lineCount: lines, combo: combo))
        }
        if combo > bestCombo {
            bestCombo = combo
            defaults.set(bestCombo, forKey: Keys.combo)
        }
        for flower in flowers {
            collect(flower)
        }
        noteGoals(lines: lines, combo: combo, score: score)
    }

    func recordDailyPlay(utcDay: String) {
        let next = Self.streakAfterPlay(
            lastDay: lastDailyPlayDay,
            streak: dailyStreak,
            today: utcDay
        )
        lastDailyPlayDay = utcDay
        dailyStreak = next
        longestDailyStreak = max(longestDailyStreak, next)
        defaults.set(utcDay, forKey: Keys.lastDaily)
        defaults.set(dailyStreak, forKey: Keys.streak)
        defaults.set(longestDailyStreak, forKey: Keys.longest)
        refreshGoalsIfNeeded(utcDay: utcDay)
    }

    @discardableResult
    func unlockFlower(_ species: FlowerSpecies, collectImmediately: Bool = true) -> Bool {
        if species.isStarter {
            if collectImmediately { collect(species) }
            return false
        }
        let id = String(species.rawValue)
        let inserted = extraFlowerIDs.insert(id).inserted
        if inserted {
            defaults.set(Array(extraFlowerIDs).sorted(), forKey: Keys.extraFlowers)
        }
        if collectImmediately {
            collect(species)
        }
        return inserted
    }

    func collect(_ species: FlowerSpecies) {
        guard unlockedFlowers.contains(species) else { return }
        let id = String(species.rawValue)
        guard collectedFlowerIDs.insert(id).inserted else { return }
        defaults.set(Array(collectedFlowerIDs).sorted(), forKey: Keys.collected)
    }

    func addPetals(_ amount: Int) {
        guard amount > 0 else { return }
        petals += amount
        lifetimePetals += amount
        lastPetalsAwarded = amount
        persistPetals()
    }

    @discardableResult
    func spendPetals(_ amount: Int) -> Bool {
        guard amount > 0, petals >= amount else { return false }
        petals -= amount
        persistPetals()
        return true
    }

    @discardableResult
    func buyLotus() -> Bool {
        guard albumStatus(for: .lotus) == .locked else { return false }
        guard spendPetals(30) else { return false }
        unlockFlower(.lotus)
        return true
    }

    /// Map-tied flowers stamp into the album when the matching pack is owned.
    func syncMapFlowers(ownedPacks: [CosmeticPack]) {
        let owned = Set(ownedPacks)
        if owned.contains(.sakura) { unlockFlower(.cherryBlossom) }
        if owned.contains(.moonlight) { unlockFlower(.moonflower) }
        if owned.contains(.desertBloom) { unlockFlower(.cactusBloom) }
        if owned.contains(.sunflower) { collect(.daisy) }
    }

    func refreshGoalsIfNeeded(utcDay: String = DailySeed.utcDayString()) {
        if goalState.utcDay != utcDay {
            goalState = DailyGoalProgress(utcDay: utcDay)
            persistGoals()
        }
    }

    func recordPetalCatches(_ count: Int) {
        guard count > 0 else { return }
        applyGoalProgress(kind: .petalCatch, value: count, additive: true)
    }

    func customBloom(storage: Int) -> CustomBloom? {
        customBlooms.first { $0.storageValue == storage }
    }

    func customBloom(id: UUID) -> CustomBloom? {
        customBlooms.first { $0.id == id }
    }

    @discardableResult
    func addCustomBloom(name: String, stamp: UIImage, draft: FlowerScanDraft) -> CustomBloom? {
        var blooms = customBlooms
        if blooms.count >= CustomBloom.maxCount {
            let oldest = blooms.removeFirst()
            CustomBloomDisk.remove(id: oldest.id)
        }
        let used = Set(blooms.map(\.slot))
        let slot = (0..<CustomBloom.maxCount).first { !used.contains($0) } ?? blooms.count
        let bloom = CustomBloom(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom bloom" : name,
            slot: slot,
            guessedSpeciesRaw: draft.speciesHint?.rawValue,
            hue: draft.hue,
            saturation: draft.saturation,
            brightness: draft.brightness,
            identifiedOnDevice: draft.usedVision
        )
        CustomBloomDisk.save(stamp: stamp, id: bloom.id)
        blooms.append(bloom)
        customBlooms = blooms
        persistCustomBlooms()
        addPetals(8)
        return bloom
    }

    func removeCustomBloom(_ id: UUID) {
        CustomBloomDisk.remove(id: id)
        customBlooms.removeAll { $0.id == id }
        persistCustomBlooms()
    }

    func seedCount(for species: FlowerSpecies) -> Int {
        max(0, seedCounts[String(species.rawValue)] ?? 0)
    }

    var inventorySeeds: [(FlowerSpecies, Int)] {
        FlowerSpecies.allCases.compactMap { species in
            let count = seedCount(for: species)
            return count > 0 ? (species, count) : nil
        }
    }

    var emptyGardenSlots: [Int] {
        let used = Set(gardenPlots.map(\.slot))
        return (0..<SeedGardenRules.plotCount).filter { !used.contains($0) }
    }

    func addSeed(_ species: FlowerSpecies, count: Int = 1) {
        guard count > 0 else { return }
        let key = String(species.rawValue)
        seedCounts[key] = seedCount(for: species) + count
        persistSeeds()
    }

    @discardableResult
    func grantPack(_ rarity: SeedRarity, source: String) -> OwnedSeedPack {
        let pack = OwnedSeedPack(id: UUID(), rarity: rarity, source: source)
        seedPacks.append(pack)
        persistPacks()
        return pack
    }

    /// First time both side gardens are won, grant one Ultra pack. Classic Garden stays free.
    @discardableResult
    func grantMilestoneUltraIfEligible() -> Bool {
        guard unlockedFlowers.contains(.orchid), unlockedFlowers.contains(.peony) else { return false }
        guard !defaults.bool(forKey: Keys.ultraMilestone) else { return false }
        defaults.set(true, forKey: Keys.ultraMilestone)
        grantPack(.ultra, source: "side-gardens")
        return true
    }

    @discardableResult
    func buyPack(_ rarity: SeedRarity) -> OwnedSeedPack? {
        guard spendPetals(rarity.petalCost) else { return nil }
        return grantPack(rarity, source: "petals")
    }

    @discardableResult
    func openPack(_ id: UUID) -> PackReveal? {
        guard let index = seedPacks.firstIndex(where: { $0.id == id }) else { return nil }
        let pack = seedPacks.remove(at: index)
        persistPacks()
        var rng = SplitMix64(seed: DailySeed.fnv1a64(id.uuidString))
        let seeds = SeedGardenRules.roll(rarity: pack.rarity, rng: &rng)
        for species in seeds {
            addSeed(species)
        }
        let reveal = PackReveal(rarity: pack.rarity, seeds: seeds)
        lastPackReveal = reveal
        return reveal
    }

    func clearPackReveal() {
        lastPackReveal = nil
    }

    @discardableResult
    func plantSeed(_ species: FlowerSpecies, slot: Int, now: Date = Date()) -> GardenPlot? {
        guard emptyGardenSlots.contains(slot) else { return nil }
        guard consumeSeed(species) else { return nil }
        let duration = species.rarity.growDuration
        let plot = GardenPlot(
            id: UUID(),
            slot: slot,
            speciesRaw: species.rawValue,
            plantedAt: now,
            lastWateredAt: now,
            lastTickAt: now,
            baseDuration: duration,
            workRemaining: duration
        )
        gardenPlots.append(plot)
        persistPlots()
        return plot
    }

    @discardableResult
    func waterPlot(_ id: UUID, now: Date = Date()) -> Bool {
        tickGarden(now: now)
        guard let index = gardenPlots.firstIndex(where: { $0.id == id }) else { return false }
        var plot = gardenPlots[index]
        plot.tick(now: now)
        guard !plot.isDead(now: now) else { return false }
        plot.lastWateredAt = now
        gardenPlots[index] = plot
        persistPlots()
        return true
    }

    @discardableResult
    func grantFertilizerCharge(count: Int = 1) -> Int {
        guard count > 0 else { return fertilizerCharges }
        fertilizerCharges = min(SeedGardenRules.fertilizerChargeCap, fertilizerCharges + count)
        defaults.set(fertilizerCharges, forKey: Keys.fertilizer)
        return fertilizerCharges
    }

    @discardableResult
    func applyFertilizer(_ id: UUID, now: Date = Date()) -> Bool {
        tickGarden(now: now)
        guard fertilizerCharges > 0 else { return false }
        guard let index = gardenPlots.firstIndex(where: { $0.id == id }) else { return false }
        var plot = gardenPlots[index]
        plot.tick(now: now)
        guard plot.canAcceptFertilizer(now: now) else { return false }
        fertilizerCharges -= 1
        defaults.set(fertilizerCharges, forKey: Keys.fertilizer)
        plot.fertilizerUntil = now.addingTimeInterval(SeedGardenRules.fertilizerDuration)
        plot.fertilizerAvailableAt = now.addingTimeInterval(SeedGardenRules.fertilizerCooldown)
        gardenPlots[index] = plot
        persistPlots()
        return true
    }

    @discardableResult
    func harvestPlot(_ id: UUID, now: Date = Date()) -> FlowerSpecies? {
        tickGarden(now: now)
        guard let index = gardenPlots.firstIndex(where: { $0.id == id }) else { return nil }
        var plot = gardenPlots[index]
        plot.tick(now: now)
        guard plot.isReady(now: now) else { return nil }
        gardenPlots.remove(at: index)
        persistPlots()
        let species = plot.species
        unlockFlower(species)
        lastHarvested = species
        addPetals(SeedGardenRules.harvestPetals)
        return species
    }

    /// Apply elapsed growth, wilt, and deaths. Dead plots empty; low-chance wilted seed salvage.
    func tickGarden(now: Date = Date()) {
        var next: [GardenPlot] = []
        var event: GardenEvent?
        for var plot in gardenPlots {
            plot.tick(now: now)
            if plot.isDead(now: now) {
                let salvaged = SeedGardenRules.salvagesSeed(plotID: plot.id)
                if salvaged {
                    addSeed(plot.species)
                }
                event = .died(species: plot.species, salvaged: salvaged)
                continue
            }
            next.append(plot)
        }
        if next != gardenPlots {
            gardenPlots = next
            persistPlots()
        }
        if let event {
            lastGardenEvent = event
        }
    }

    func clearGardenEvent() {
        lastGardenEvent = nil
    }

    private func consumeSeed(_ species: FlowerSpecies) -> Bool {
        let key = String(species.rawValue)
        let count = seedCount(for: species)
        guard count > 0 else { return false }
        if count == 1 {
            seedCounts.removeValue(forKey: key)
        } else {
            seedCounts[key] = count - 1
        }
        persistSeeds()
        return true
    }

    private func persistPlots() {
        if let data = try? JSONEncoder().encode(gardenPlots) {
            defaults.set(data, forKey: Keys.plots)
        }
    }

    private func persistSeeds() {
        if let data = try? JSONEncoder().encode(seedCounts) {
            defaults.set(data, forKey: Keys.seeds)
        }
    }

    private func persistPacks() {
        if let data = try? JSONEncoder().encode(seedPacks) {
            defaults.set(data, forKey: Keys.packs)
        }
    }

    private func persistCustomBlooms() {
        if let data = try? JSONEncoder().encode(customBlooms) {
            defaults.set(data, forKey: Keys.blooms)
        }
    }

    /// Pure streak rules: same day keeps the count; consecutive UTC day increments; a gap resets to 1.
    static func streakAfterPlay(lastDay: String?, streak: Int, today: String) -> Int {
        guard let lastDay else { return 1 }
        if lastDay == today { return max(1, streak) }
        if isNextUTCDay(after: lastDay, today: today) {
            return streak + 1
        }
        return 1
    }

    static func isNextUTCDay(after previous: String, today: String) -> Bool {
        guard let prev = parseUTC(previous), let now = parseUTC(today) else { return false }
        let next = prev.addingTimeInterval(24 * 60 * 60)
        return DailySeed.utcDayString(from: next) == DailySeed.utcDayString(from: now)
    }

    private func noteGoals(lines: Int, combo: Int, score: Int) {
        refreshGoalsIfNeeded()
        if lines > 0 {
            applyGoalProgress(kind: .lines, value: lines, additive: true)
        }
        if combo > 0 {
            applyGoalProgress(kind: .combo, value: combo, additive: false)
        }
        if score > 0 {
            applyGoalProgress(kind: .score, value: score, additive: false)
        }
    }

    private func applyGoalProgress(kind: DailyGoal.Kind, value: Int, additive: Bool) {
        refreshGoalsIfNeeded()
        var claimedNow: [String] = []
        var next = goalState
        for goal in todayGoals where goal.kind == kind {
            let current = next.values[goal.id] ?? 0
            let updated = additive ? current + value : max(current, value)
            next.values[goal.id] = updated
            if updated >= goal.target, !next.claimed.contains(goal.id) {
                next.claimed.append(goal.id)
                claimedNow.append(goal.id)
            }
        }
        goalState = next
        persistGoals()
        if !claimedNow.isEmpty {
            let reward = todayGoals.filter { claimedNow.contains($0.id) }.reduce(0) { $0 + $1.rewardPetals }
            lastClaimedGoalIDs = claimedNow
            addPetals(reward)
        }
    }

    private func persistPetals() {
        defaults.set(petals, forKey: Keys.petals)
        defaults.set(lifetimePetals, forKey: Keys.lifetimePetals)
    }

    private func persistGoals() {
        if let data = try? JSONEncoder().encode(goalState) {
            defaults.set(data, forKey: Keys.goals)
        }
    }

    private static func parseUTC(_ day: String) -> Date? {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "GMT") ?? .current
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
