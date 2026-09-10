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
        if let data = defaults.data(forKey: Keys.goals),
           let decoded = try? JSONDecoder().decode(DailyGoalProgress.self, from: data) {
            goalState = decoded
        } else {
            goalState = DailyGoalProgress(utcDay: DailySeed.utcDayString())
        }
        refreshGoalsIfNeeded(utcDay: DailySeed.utcDayString())
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
