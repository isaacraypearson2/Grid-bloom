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

    private var rank: Int {
        switch self {
        case .common: return 0
        case .rare: return 1
        case .epic: return 2
        case .ultra: return 3
        }
    }

    static func < (lhs: SeedRarity, rhs: SeedRarity) -> Bool {
        lhs.rank < rhs.rank
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

    /// Real-time grow duration. Ads can skip the rest of a plot; Classic Garden never waits on this.
    var growDuration: TimeInterval {
        switch self {
        case .common: return 60
        case .rare: return 180
        case .epic: return 480
        case .ultra: return 900
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
    var plantedAt: Date
    var finishesAt: Date
    var boosted: Bool

    var species: FlowerSpecies {
        FlowerSpecies(rawValue: speciesRaw) ?? .tulip
    }

    func isReady(now: Date = Date()) -> Bool {
        now >= finishesAt
    }

    func progress(now: Date = Date()) -> Double {
        let total = finishesAt.timeIntervalSince(plantedAt)
        guard total > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(plantedAt) / total))
    }

    func remaining(now: Date = Date()) -> TimeInterval {
        max(0, finishesAt.timeIntervalSince(now))
    }
}

struct PackReveal: Equatable {
    var rarity: SeedRarity
    var seeds: [FlowerSpecies]
}

enum SeedGardenRules {
    static let plotCount = 6
    static let harvestPetals = 4

    static func pool(for rarity: SeedRarity) -> [FlowerSpecies] {
        FlowerSpecies.allCases.filter { $0.rarity == rarity }
    }

    /// Fair gacha: a pack of rarity X only rolls seeds of that tier.
    static func roll(rarity: SeedRarity, rng: inout SplitMix64) -> [FlowerSpecies] {
        let pool = Self.pool(for: rarity)
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
