import SwiftUI
import UIKit

/// Flower identity for tiles. Color remains a secondary fill; the glyph is the primary read.
enum FlowerSpecies: Int, CaseIterable, Codable, Identifiable, Equatable, Hashable, Sendable {
    case tulip = 1
    case daisy = 2
    case rose = 3
    case lily = 4
    case lavender = 5
    case hydrangea = 6
    case orchid = 7
    case peony = 8
    case lotus = 9
    case cactusBloom = 10
    case moonflower = 11
    case cherryBlossom = 12
    case starfire = 13
    case nightOrchid = 14
    case sunburst = 15

    var id: String { rawValue.description }

    static let starters: [FlowerSpecies] = [.tulip, .daisy, .rose, .lily, .lavender, .hydrangea]

    var isStarter: Bool { Self.starters.contains(self) }

    var profile: SpeciesProfile { BloomCatalog.profile(self) }

    var title: String { profile.title }
    var blurb: String { profile.blurb }
    var unlock: FlowerUnlock { profile.unlock }
    /// Historical species rarity (signature variant). Tile power uses `BloomVariant.rarity`.
    var rarity: SeedRarity { profile.signatureRarity }
    var ability: FlowerAbility? { rarity == .ultra ? .gridWipe : nil }
    var petalTint: UIColor { profile.baseTint }
    var colors: [BloomColor] { profile.colors }

    var swiftTint: Color { Color(petalTint) }

    /// Catalog color indexes 0...8 map onto the nine tray species.
    static func from(colorIndex: Int) -> FlowerSpecies {
        let tray: [FlowerSpecies] = [.tulip, .daisy, .rose, .lily, .lavender, .hydrangea, .orchid, .peony, .lotus]
        return tray[abs(colorIndex) % tray.count]
    }

    /// Daily Bloom always uses starters so unlocks cannot change the UTC deal.
    static func playable(at colorIndex: Int, unlocked: Set<FlowerSpecies>) -> FlowerSpecies {
        let pool = allCases
            .filter { unlocked.contains($0) }
            .sorted { $0.rawValue < $1.rawValue }
        if pool.isEmpty { return .tulip }
        let candidate = from(colorIndex: colorIndex)
        if pool.contains(candidate) { return candidate }
        return pool[abs(colorIndex) % pool.count]
    }
}

enum MiniGameKind: String, Codable, Equatable, Sendable {
    case petalCatch
    case patternBloom

    var title: String {
        switch self {
        case .petalCatch: return "Petal Catch"
        case .patternBloom: return "Pattern Bloom"
        }
    }

    var blurb: String {
        switch self {
        case .petalCatch: return "Tap falling petals before they wilt. Wins grant a seed pack (Rare first, then Common) and invite Orchid."
        case .patternBloom: return "Watch the bloom, repeat the pattern. First win: Peony, Glasshouse, and an Epic pack. Repeats: a Rare pack."
        }
    }

    var winPack: SeedRarity {
        switch self {
        case .petalCatch: return .rare
        case .patternBloom: return .epic
        }
    }

    var repeatPack: SeedRarity {
        switch self {
        case .petalCatch: return .common
        case .patternBloom: return .rare
        }
    }

    var rewardFlower: FlowerSpecies {
        switch self {
        case .petalCatch: return .orchid
        case .patternBloom: return .peony
        }
    }

    var rewardPack: CosmeticPack? {
        switch self {
        case .petalCatch: return nil
        case .patternBloom: return .greenhouse
        }
    }

    var winPetals: Int {
        switch self {
        case .petalCatch: return 12
        case .patternBloom: return 16
        }
    }

    var repeatPetals: Int { 6 }
}

enum FlowerUnlock: Equatable, Sendable {
    case starter
    case miniGame(MiniGameKind)
    case petals(Int)
    case mapSkin(CosmeticPack)
    case seedPack(SeedRarity)
}

enum GardenRank: String, Equatable, Sendable {
    case sprout
    case gardener
    case bloomkeeper
    case florist

    var title: String {
        switch self {
        case .sprout: return "Sprout"
        case .gardener: return "Gardener"
        case .bloomkeeper: return "Bloomkeeper"
        case .florist: return "Master florist"
        }
    }

    static func from(collectedCount: Int) -> GardenRank {
        switch collectedCount {
        case 0..<4: return .sprout
        case 4..<8: return .gardener
        case 8..<11: return .bloomkeeper
        default: return .florist
        }
    }
}

enum AlbumStatus: Equatable, Sendable {
    case locked
    case unlocked
    case collected
}
