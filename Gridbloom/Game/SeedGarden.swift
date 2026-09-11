import Foundation
import SwiftUI
import UIKit

/// Pack and flower rarity. Common–Epic are collection/score; Ultra adds a board power.
enum SeedRarity: String, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case common
    case rare
    case epic
    case ultra

    var id: String { rawValue }

    var ladderIndex: Int {
        switch self {
        case .common: return 0
        case .rare: return 1
        case .epic: return 2
        case .ultra: return 3
        }
    }

    static func < (lhs: SeedRarity, rhs: SeedRarity) -> Bool {
        lhs.ladderIndex < rhs.ladderIndex
    }

    static func from(ladderIndex: Int) -> SeedRarity {
        switch max(0, min(3, ladderIndex)) {
        case 1: return .rare
        case 2: return .epic
        case 3: return .ultra
        default: return .common
        }
    }

    var title: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .ultra: return "Ultra"
        }
    }

    var packTitle: String { "\(title) seed pack" }

    var seedCount: Int {
        switch self {
        case .common: return 3
        case .rare: return 2
        case .epic: return 1
        case .ultra: return 1
        }
    }

    var petalCost: Int {
        switch self {
        case .common: return 18
        case .rare: return 40
        case .epic: return 70
        case .ultra: return 120
        }
    }

    /// Real-time grow duration. Baseline ~12–15 min; rarer seeds take longer. No instant grows.
    var growDuration: TimeInterval {
        switch self {
        case .common: return 12 * 60
        case .rare: return 18 * 60
        case .epic: return 30 * 60
        case .ultra: return 48 * 60
        }
    }

    var ink: Color {
        switch self {
        case .common: return Color(red: 0.42, green: 0.58, blue: 0.40)
        case .rare: return Color(red: 0.28, green: 0.48, blue: 0.78)
        case .epic: return Color(red: 0.58, green: 0.36, blue: 0.78)
        case .ultra: return Color(red: 0.86, green: 0.52, blue: 0.16)
        }
    }

    var fill: Color {
        switch self {
        case .common: return Color(red: 0.62, green: 0.78, blue: 0.48)
        case .rare: return Color(red: 0.42, green: 0.62, blue: 0.92)
        case .epic: return Color(red: 0.72, green: 0.48, blue: 0.90)
        case .ultra: return Color(red: 0.96, green: 0.72, blue: 0.28)
        }
    }
}

enum FlowerAbility: String, Codable, Equatable, Sendable {
    case gridWipe

    var title: String {
        switch self {
        case .gridWipe: return "Clears the whole board"
        }
    }
}

struct OwnedSeedPack: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var rarity: SeedRarity
    var source: String
}

struct GardenPlot: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var slot: Int
    var speciesRaw: Int
    var colorRaw: Int
    var rarityRaw: String
    var plantedAt: Date
    var lastWateredAt: Date
    var lastTickAt: Date
    var baseDuration: TimeInterval
    var workRemaining: TimeInterval
    /// Growth boost until this instant.
    var fertilizerUntil: Date?
    /// Next time this plot may accept fertilizer.
    var fertilizerAvailableAt: Date?
    /// `regular` (ad, 2×/2h) or `organic` (3×/4h).
    var fertilizerKindRaw: String?
    /// Petal dew burst 1.5× until this instant.
    var dewUntil: Date?

    var species: FlowerSpecies {
        FlowerSpecies(rawValue: speciesRaw) ?? .tulip
    }

    var bloom: BloomVariant {
        BloomVariant(
            species: species,
            color: BloomColor(rawValue: colorRaw) ?? species.profile.signatureColor,
            rarity: SeedRarity(rawValue: rarityRaw) ?? species.rarity
        )
    }

    var rarity: SeedRarity { bloom.rarity }

    func thirstyAt() -> Date {
        lastWateredAt.addingTimeInterval(SeedGardenRules.waterEvery(for: rarity))
    }

    func wiltAt() -> Date {
        thirstyAt().addingTimeInterval(SeedGardenRules.thirstyGrace(for: rarity))
    }

    func deathAt() -> Date {
        wiltAt().addingTimeInterval(SeedGardenRules.wiltGrace(for: rarity))
    }

    func isDead(now: Date) -> Bool {
        now >= deathAt()
    }

    func isReady(now: Date) -> Bool {
        !isDead(now: now) && workRemaining <= 0.01
    }

    func careStage(now: Date) -> GardenCareStage {
        if isDead(now: now) { return .dead }
        if isReady(now: now) {
            if now >= wiltAt() { return .wilted }
            if now >= thirstyAt() { return .thirsty }
            return .ready
        }
        if now >= wiltAt() { return .wilted }
        if now >= thirstyAt() { return .thirsty }
        return .growing
    }

    var fertilizerKind: FertilizerKind {
        FertilizerKind(rawValue: fertilizerKindRaw ?? "") ?? .regular
    }

    func isFertilizerActive(now: Date) -> Bool {
        guard let until = fertilizerUntil else { return false }
        return now < until
    }

    func isDewActive(now: Date) -> Bool {
        guard let until = dewUntil else { return false }
        return now < until
    }

    func canAcceptFertilizer(now: Date) -> Bool {
        guard !isDead(now: now), workRemaining > 0.01 else { return false }
        if now >= wiltAt() { return false }
        if let available = fertilizerAvailableAt, now < available { return false }
        return true
    }

    func fertilizerCooldownRemaining(now: Date) -> TimeInterval {
        guard let available = fertilizerAvailableAt else { return 0 }
        return max(0, available.timeIntervalSince(now))
    }

    func growthRate(at date: Date) -> Double {
        if date >= deathAt() { return 0 }
        if date >= wiltAt() { return 0 }
        var rate = 1.0
        if date >= thirstyAt() { rate *= 0.5 }
        if let until = fertilizerUntil, date < until {
            rate *= fertilizerKind.multiplier
        }
        if let dew = dewUntil, date < dew {
            rate *= SeedGardenRules.dewMultiplier
        }
        return rate
    }

    mutating func tick(now: Date) {
        guard now > lastTickAt else { return }
        var cursor = lastTickAt
        while cursor < now {
            if cursor >= deathAt() {
                workRemaining = max(workRemaining, 0)
                break
            }
            let next = min(now, nextRateChange(after: cursor) ?? now)
            let dt = next.timeIntervalSince(cursor)
            if dt <= 0 { break }
            let rate = growthRate(at: cursor)
            workRemaining = max(0, workRemaining - dt * rate)
            cursor = next
        }
        lastTickAt = now
    }

    func progress(now: Date) -> Double {
        guard baseDuration > 0 else { return 1 }
        return min(1, max(0, 1 - workRemaining / baseDuration))
    }

    func remaining(now: Date) -> TimeInterval {
        let rate = growthRate(at: now)
        if rate <= 0 { return workRemaining }
        return max(0, workRemaining / rate)
    }

    func warningCopy(now: Date) -> String? {
        switch careStage(now: now) {
        case .thirsty:
            let untilWilt = max(0, wiltAt().timeIntervalSince(now))
            return isReady(now: now)
                ? "Needs water — harvest soon"
                : "Needs water (\(SeedGardenRules.formatRemaining(untilWilt)) to wilt)"
        case .wilted:
            let untilDeath = max(0, deathAt().timeIntervalSince(now))
            return isReady(now: now)
                ? "Wilting — harvest or water to save"
                : "Wilting — water within \(SeedGardenRules.formatRemaining(untilDeath))"
        case .dead:
            return "This bloom didn’t make it"
        case .growing, .ready:
            return nil
        }
    }

    private func nextRateChange(after date: Date) -> Date? {
        var marks: [Date] = [thirstyAt(), wiltAt(), deathAt()]
        if let until = fertilizerUntil { marks.append(until) }
        if let dew = dewUntil { marks.append(dew) }
        return marks.filter { $0 > date }.min()
    }

    enum CodingKeys: String, CodingKey {
        case id, slot, speciesRaw, colorRaw, rarityRaw, plantedAt, lastWateredAt, lastTickAt
        case baseDuration, workRemaining, fertilizerUntil, fertilizerAvailableAt
        case fertilizerKindRaw, dewUntil
        case finishesAt, boosted
    }

    init(
        id: UUID,
        slot: Int,
        speciesRaw: Int,
        colorRaw: Int,
        rarityRaw: String,
        plantedAt: Date,
        lastWateredAt: Date,
        lastTickAt: Date,
        baseDuration: TimeInterval,
        workRemaining: TimeInterval,
        fertilizerUntil: Date? = nil,
        fertilizerAvailableAt: Date? = nil,
        fertilizerKindRaw: String? = nil,
        dewUntil: Date? = nil
    ) {
        self.id = id
        self.slot = slot
        self.speciesRaw = speciesRaw
        self.colorRaw = colorRaw
        self.rarityRaw = rarityRaw
        self.plantedAt = plantedAt
        self.lastWateredAt = lastWateredAt
        self.lastTickAt = lastTickAt
        self.baseDuration = baseDuration
        self.workRemaining = workRemaining
        self.fertilizerUntil = fertilizerUntil
        self.fertilizerAvailableAt = fertilizerAvailableAt
        self.fertilizerKindRaw = fertilizerKindRaw
        self.dewUntil = dewUntil
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        slot = try c.decode(Int.self, forKey: .slot)
        speciesRaw = try c.decode(Int.self, forKey: .speciesRaw)
        let species = FlowerSpecies(rawValue: speciesRaw) ?? .tulip
        let signature = BloomCatalog.signature(species)
        colorRaw = try c.decodeIfPresent(Int.self, forKey: .colorRaw) ?? signature.color.rawValue
        rarityRaw = try c.decodeIfPresent(String.self, forKey: .rarityRaw) ?? signature.rarity.rawValue
        plantedAt = try c.decode(Date.self, forKey: .plantedAt)
        let decodedNow = Date()
        // Legacy plots had no care clock. Reset watering at load so they don't instantly wilt.
        lastWateredAt = try c.decodeIfPresent(Date.self, forKey: .lastWateredAt) ?? decodedNow
        lastTickAt = try c.decodeIfPresent(Date.self, forKey: .lastTickAt) ?? decodedNow
        let fallbackDuration = BloomVariant(
            species: species,
            color: BloomColor(rawValue: colorRaw) ?? signature.color,
            rarity: SeedRarity(rawValue: rarityRaw) ?? signature.rarity
        ).rarity.growDuration
        baseDuration = try c.decodeIfPresent(TimeInterval.self, forKey: .baseDuration) ?? fallbackDuration
        if let remaining = try c.decodeIfPresent(TimeInterval.self, forKey: .workRemaining) {
            workRemaining = remaining
        } else if let finishes = try c.decodeIfPresent(Date.self, forKey: .finishesAt) {
            workRemaining = max(0, finishes.timeIntervalSince(decodedNow))
        } else {
            workRemaining = fallbackDuration
        }
        fertilizerUntil = try c.decodeIfPresent(Date.self, forKey: .fertilizerUntil)
        fertilizerAvailableAt = try c.decodeIfPresent(Date.self, forKey: .fertilizerAvailableAt)
        fertilizerKindRaw = try c.decodeIfPresent(String.self, forKey: .fertilizerKindRaw)
        dewUntil = try c.decodeIfPresent(Date.self, forKey: .dewUntil)
        if (try c.decodeIfPresent(Bool.self, forKey: .boosted)) == true {
            workRemaining = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(slot, forKey: .slot)
        try c.encode(speciesRaw, forKey: .speciesRaw)
        try c.encode(colorRaw, forKey: .colorRaw)
        try c.encode(rarityRaw, forKey: .rarityRaw)
        try c.encode(plantedAt, forKey: .plantedAt)
        try c.encode(lastWateredAt, forKey: .lastWateredAt)
        try c.encode(lastTickAt, forKey: .lastTickAt)
        try c.encode(baseDuration, forKey: .baseDuration)
        try c.encode(workRemaining, forKey: .workRemaining)
        try c.encodeIfPresent(fertilizerUntil, forKey: .fertilizerUntil)
        try c.encodeIfPresent(fertilizerAvailableAt, forKey: .fertilizerAvailableAt)
        try c.encodeIfPresent(fertilizerKindRaw, forKey: .fertilizerKindRaw)
        try c.encodeIfPresent(dewUntil, forKey: .dewUntil)
    }
}

enum GardenCareStage: String, Equatable, Sendable {
    case growing
    case thirsty
    case wilted
    case ready
    case dead
}

struct PackReveal: Equatable {
    var rarity: SeedRarity
    var seeds: [BloomVariant]
}

enum GardenEvent: Equatable {
    case died(species: FlowerSpecies, salvaged: Bool)
}

enum SeedGardenRules {
    static let plotCount = 6
    static let harvestPetals = 4
    static let fertilizerDuration: TimeInterval = 2 * 60 * 60
    static let fertilizerCooldown: TimeInterval = 24 * 60 * 60
    static let fertilizerChargeCap = 5
    static let organicDuration: TimeInterval = 4 * 60 * 60
    static let organicCooldown: TimeInterval = 12 * 60 * 60
    static let organicChargeCap = 3
    static let dewDuration: TimeInterval = 15 * 60
    static let dewMultiplier = 1.5
    static let salvageChance = 0.22
    /// Care clock is about 3 hours for every rarity.
    static let waterInterval: TimeInterval = 3 * 60 * 60
    static let thirstyGraceInterval: TimeInterval = 20 * 60
    static let wiltGraceInterval: TimeInterval = 40 * 60

    static func waterEvery(for rarity: SeedRarity) -> TimeInterval {
        _ = rarity
        return waterInterval
    }

    /// Yellow warning window after water is due, before wilt.
    static func thirstyGrace(for rarity: SeedRarity) -> TimeInterval {
        _ = rarity
        return thirstyGraceInterval
    }

    /// Orange wilt window; water still saves. After this the plot dies.
    static func wiltGrace(for rarity: SeedRarity) -> TimeInterval {
        _ = rarity
        return wiltGraceInterval
    }

    static func salvagesSeed(plotID: UUID) -> Bool {
        let hash = DailySeed.fnv1a64(plotID.uuidString + "|salvage")
        let unit = Double(hash % 1000) / 1000.0
        return unit < salvageChance
    }

    static func pool(for rarity: SeedRarity) -> [FlowerSpecies] {
        FlowerSpecies.allCases.filter { $0.rarity == rarity }
    }

    /// Fair gacha: a pack of rarity X only rolls variants of that tier (species × color).
    static func roll(rarity: SeedRarity, rng: inout SplitMix64) -> [BloomVariant] {
        let pool = BloomCatalog.variants(rarity: rarity)
        guard !pool.isEmpty else { return [] }
        return (0..<rarity.seedCount).map { _ in
            pool[rng.int(in: 0..<pool.count)]
        }
    }

    static func formatRemaining(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded(.up)))
        let minutes = seconds / 60
        let rem = seconds % 60
        if minutes >= 60 {
            return String(format: "%dh %02dm", minutes / 60, minutes % 60)
        }
        return String(format: "%d:%02d", minutes, rem)
    }
}
