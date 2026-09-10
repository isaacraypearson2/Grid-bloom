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

    var id: String { rawValue.description }

    static let starters: [FlowerSpecies] = [.tulip, .daisy, .rose, .lily, .lavender, .hydrangea]

    var isStarter: Bool { Self.starters.contains(self) }

    var title: String {
        switch self {
        case .tulip: return "Tulip"
        case .daisy: return "Daisy"
        case .rose: return "Rose"
        case .lily: return "Lily"
        case .lavender: return "Lavender"
        case .hydrangea: return "Hydrangea"
        case .orchid: return "Orchid"
        case .peony: return "Peony"
        case .lotus: return "Lotus"
        case .cactusBloom: return "Cactus bloom"
        case .moonflower: return "Moonflower"
        case .cherryBlossom: return "Cherry blossom"
        }
    }

    var blurb: String {
        switch self {
        case .tulip: return "Cupped spring bloom. Always in the tray."
        case .daisy: return "Sunny ring of petals."
        case .rose: return "Layered classic."
        case .lily: return "Starry garden lily."
        case .lavender: return "Soft purple spires."
        case .hydrangea: return "A clustered cloud."
        case .orchid: return "Catch falling petals to invite her in."
        case .peony: return "Repeat the bloom pattern to unlock."
        case .lotus: return "A quiet sink for spare petals."
        case .cactusBloom: return "Blooms once Desert Bloom is yours."
        case .moonflower: return "Opens with Moonlight Garden."
        case .cherryBlossom: return "Travels with Sakura Petals."
        }
    }

    var unlock: FlowerUnlock {
        switch self {
        case .tulip, .daisy, .rose, .lily, .lavender, .hydrangea:
            return .starter
        case .orchid:
            return .miniGame(.petalCatch)
        case .peony:
            return .miniGame(.patternBloom)
        case .lotus:
            return .petals(30)
        case .cactusBloom:
            return .mapSkin(.desertBloom)
        case .moonflower:
            return .mapSkin(.moonlight)
        case .cherryBlossom:
            return .mapSkin(.sakura)
        }
    }

    var petalTint: UIColor {
        switch self {
        case .tulip: return UIColor(red: 0.90, green: 0.42, blue: 0.48, alpha: 1)
        case .daisy: return UIColor(red: 0.98, green: 0.92, blue: 0.55, alpha: 1)
        case .rose: return UIColor(red: 0.86, green: 0.32, blue: 0.42, alpha: 1)
        case .lily: return UIColor(red: 0.96, green: 0.86, blue: 0.92, alpha: 1)
        case .lavender: return UIColor(red: 0.70, green: 0.58, blue: 0.86, alpha: 1)
        case .hydrangea: return UIColor(red: 0.62, green: 0.72, blue: 0.90, alpha: 1)
        case .orchid: return UIColor(red: 0.78, green: 0.48, blue: 0.82, alpha: 1)
        case .peony: return UIColor(red: 0.94, green: 0.62, blue: 0.74, alpha: 1)
        case .lotus: return UIColor(red: 0.95, green: 0.72, blue: 0.78, alpha: 1)
        case .cactusBloom: return UIColor(red: 0.92, green: 0.48, blue: 0.62, alpha: 1)
        case .moonflower: return UIColor(red: 0.82, green: 0.86, blue: 0.96, alpha: 1)
        case .cherryBlossom: return UIColor(red: 0.96, green: 0.70, blue: 0.78, alpha: 1)
        }
    }

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
        case .petalCatch: return "Tap falling petals before they wilt. First win unlocks Orchid."
        case .patternBloom: return "Watch the bloom, repeat the pattern. First win unlocks Peony and Glasshouse."
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
