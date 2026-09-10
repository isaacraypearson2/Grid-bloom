import Foundation
import SwiftUI
import UIKit

/// Petal color lane. Each species lists a few of these; adding a hue is content, not new tile code.
enum BloomColor: Int, Codable, CaseIterable, Identifiable, Hashable, Sendable, Comparable {
    case red = 0
    case white = 1
    case yellow = 2
    case pink = 3
    case peach = 4
    case lavender = 5
    case blue = 6
    case coral = 7
    case ivory = 8
    case amber = 9
    case violet = 10
    case cream = 11

    var id: Int { rawValue }

    static func < (lhs: BloomColor, rhs: BloomColor) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .red: return "Red"
        case .white: return "White"
        case .yellow: return "Yellow"
        case .pink: return "Pink"
        case .peach: return "Peach"
        case .lavender: return "Lavender"
        case .blue: return "Blue"
        case .coral: return "Coral"
        case .ivory: return "Ivory"
        case .amber: return "Amber"
        case .violet: return "Violet"
        case .cream: return "Cream"
        }
    }

    /// Shift a species' signature tint toward this color lane.
    func applied(to base: UIColor) -> UIColor {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        guard base.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha) else { return base }
        switch self {
        case .red:
            return UIColor(hue: 0.00, saturation: max(0.55, sat), brightness: min(1, bri + 0.02), alpha: 1)
        case .white:
            return UIColor(hue: hue, saturation: min(sat, 0.10), brightness: max(0.92, bri), alpha: 1)
        case .yellow:
            return UIColor(hue: 0.13, saturation: max(0.55, sat), brightness: max(0.86, bri), alpha: 1)
        case .pink:
            return UIColor(hue: 0.96, saturation: max(0.42, sat * 0.9), brightness: min(1, bri + 0.04), alpha: 1)
        case .peach:
            return UIColor(hue: 0.06, saturation: max(0.38, sat * 0.85), brightness: max(0.88, bri), alpha: 1)
        case .lavender:
            return UIColor(hue: 0.75, saturation: max(0.35, sat * 0.85), brightness: min(1, bri + 0.02), alpha: 1)
        case .blue:
            return UIColor(hue: 0.60, saturation: max(0.40, sat * 0.9), brightness: min(1, bri + 0.04), alpha: 1)
        case .coral:
            return UIColor(hue: 0.03, saturation: max(0.52, sat), brightness: min(1, bri + 0.02), alpha: 1)
        case .ivory:
            return UIColor(hue: 0.58, saturation: min(0.18, sat), brightness: max(0.90, bri), alpha: 1)
        case .amber:
            return UIColor(hue: 0.10, saturation: max(0.62, sat), brightness: max(0.82, bri), alpha: 1)
        case .violet:
            return UIColor(hue: 0.78, saturation: max(0.48, sat), brightness: min(0.92, bri), alpha: 1)
        case .cream:
            return UIColor(hue: 0.12, saturation: min(0.28, sat), brightness: max(0.90, bri), alpha: 1)
        }
    }
}

/// One collectible tile: species × color × rarity. Ultra grants the board wipe.
struct BloomVariant: Hashable, Codable, Identifiable, Sendable, Comparable {
    var species: FlowerSpecies
    var color: BloomColor
    var rarity: SeedRarity

    var id: String { catalogKey }

    var catalogKey: String {
        "\(species.rawValue).\(color.rawValue).\(rarity.rawValue)"
    }

    var storageID: Int {
        BloomCatalog.storageID(species: species, color: color, rarity: rarity)
    }

    var title: String { "\(color.title) \(species.title)" }

    var fullTitle: String { "\(rarity.title) \(title)" }

    var ability: FlowerAbility? {
        rarity == .ultra ? .gridWipe : nil
    }

    var petalTint: UIColor {
        let base = species.profile.tint(for: color)
        guard rarity == .ultra || rarity == .epic else { return base }
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        guard base.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha) else { return base }
        let bump: CGFloat = rarity == .ultra ? 0.12 : 0.05
        return UIColor(hue: hue, saturation: min(1, sat + bump), brightness: min(1, bri + 0.03), alpha: 1)
    }

    var swiftTint: Color { Color(petalTint) }

    static func < (lhs: BloomVariant, rhs: BloomVariant) -> Bool {
        lhs.storageID < rhs.storageID
    }

    static func parse(catalogKey: String) -> BloomVariant? {
        let parts = catalogKey.split(separator: ".").map(String.init)
        guard parts.count == 3,
              let speciesRaw = Int(parts[0]),
              let species = FlowerSpecies(rawValue: speciesRaw),
              let colorRaw = Int(parts[1]),
              let color = BloomColor(rawValue: colorRaw),
              let rarity = SeedRarity(rawValue: parts[2]) else {
            return nil
        }
        return BloomVariant(species: species, color: color, rarity: rarity)
    }
}

/// Content row for one plant family. Add a species by appending an enum case and one of these.
struct SpeciesProfile {
    var species: FlowerSpecies
    var slug: String
    var title: String
    var blurb: String
    var stageTitle: String
    var stageBlurb: String
    var colors: [BloomColor]
    var signatureColor: BloomColor
    var signatureRarity: SeedRarity
    var unlock: FlowerUnlock
    var stageTheme: CosmeticPack
    var baseTint: UIColor

    func tint(for color: BloomColor) -> UIColor {
        color == signatureColor ? baseTint : color.applied(to: baseTint)
    }

    var stage: GardenStage {
        GardenStage(
            id: slug,
            title: stageTitle,
            blurb: stageBlurb,
            species: [species],
            themePack: stageTheme,
            unlock: .collectSpecies(species)
        )
    }
}

struct GardenStage: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var blurb: String
    var species: [FlowerSpecies]
    var themePack: CosmeticPack
    var unlock: StageUnlock

    var isClassic: Bool { id == GardenStageCatalog.classicID }

    var allowsCustomBlooms: Bool { isClassic }

    var allowsUltraWipe: Bool { true }
}

enum StageUnlock: Equatable, Sendable {
    case always
    case collectSpecies(FlowerSpecies)
}

/// Data-driven flower matrix and themed stages. Board storage: legacy 1...15, custom 100...199, variants 1000+.
enum BloomCatalog {
    static let variantStorageBase = 1000
    static let customStorageEnd = 1000

    static func profile(_ species: FlowerSpecies) -> SpeciesProfile {
        profiles[species] ?? profiles[.tulip]!
    }

    static func signature(_ species: FlowerSpecies) -> BloomVariant {
        let row = profile(species)
        return BloomVariant(species: species, color: row.signatureColor, rarity: row.signatureRarity)
    }

    static func variants(for species: FlowerSpecies) -> [BloomVariant] {
        let row = profile(species)
        return row.colors.flatMap { color in
            SeedRarity.allCases.map { BloomVariant(species: species, color: color, rarity: $0) }
        }
    }

    static func variants(rarity: SeedRarity) -> [BloomVariant] {
        FlowerSpecies.allCases.flatMap { species in
            profile(species).colors.map { BloomVariant(species: species, color: $0, rarity: rarity) }
        }
    }

    static var allVariants: [BloomVariant] {
        FlowerSpecies.allCases.flatMap { variants(for: $0) }
    }

    static func storageID(species: FlowerSpecies, color: BloomColor, rarity: SeedRarity) -> Int {
        variantStorageBase + species.rawValue * 64 + color.rawValue * 4 + rarity.ladderIndex
    }

    static func variant(fromStorage value: Int) -> BloomVariant? {
        if value <= 0 { return nil }
        if CustomBloom.isCustomStorage(value) { return nil }
        if let legacy = FlowerSpecies(rawValue: value), value < 100 {
            return signature(legacy)
        }
        guard value >= variantStorageBase else { return nil }
        let offset = value - variantStorageBase
        let speciesRaw = offset / 64
        let rem = offset % 64
        let colorRaw = rem / 4
        let rarityIndex = rem % 4
        guard let species = FlowerSpecies(rawValue: speciesRaw),
              let color = BloomColor(rawValue: colorRaw) else {
            return nil
        }
        let rarity = SeedRarity.from(ladderIndex: rarityIndex)
        let row = profile(species)
        guard row.colors.contains(color) else { return nil }
        return BloomVariant(species: species, color: color, rarity: rarity)
    }

    static func playableBloom(at colorIndex: Int, roster: [BloomVariant]) -> BloomVariant {
        let sorted = roster.sorted()
        guard !sorted.isEmpty else { return signature(.tulip) }
        return sorted[abs(colorIndex) % sorted.count]
    }

    private static let profiles: [FlowerSpecies: SpeciesProfile] = [
        .tulip: SpeciesProfile(
            species: .tulip, slug: "tulip", title: "Tulip",
            blurb: "Cupped spring bloom. Always in the tray.",
            stageTitle: "Tulip Walk", stageBlurb: "A whole board of tulips — every color and rarity you’ve grown.",
            colors: [.pink, .yellow, .white], signatureColor: .pink, signatureRarity: .common,
            unlock: .starter, stageTheme: .garden,
            baseTint: UIColor(red: 0.90, green: 0.42, blue: 0.48, alpha: 1)
        ),
        .daisy: SpeciesProfile(
            species: .daisy, slug: "daisy", title: "Daisy",
            blurb: "Sunny ring of petals.",
            stageTitle: "Daisy Field", stageBlurb: "Yellow, white, and peach daisies under a honey sky.",
            colors: [.yellow, .white, .peach], signatureColor: .yellow, signatureRarity: .common,
            unlock: .starter, stageTheme: .sunflower,
            baseTint: UIColor(red: 0.98, green: 0.92, blue: 0.55, alpha: 1)
        ),
        .rose: SpeciesProfile(
            species: .rose, slug: "rose", title: "Rose",
            blurb: "Layered classic.",
            stageTitle: "Rose Garden", stageBlurb: "Red, white, and yellow roses on a blush playfield.",
            colors: [.red, .white, .yellow], signatureColor: .red, signatureRarity: .common,
            unlock: .starter, stageTheme: .sakura,
            baseTint: UIColor(red: 0.86, green: 0.32, blue: 0.42, alpha: 1)
        ),
        .lily: SpeciesProfile(
            species: .lily, slug: "lily", title: "Lily",
            blurb: "Starry garden lily.",
            stageTitle: "Lily Pond", stageBlurb: "Ivory lilies with pink and peach sisters.",
            colors: [.white, .pink, .peach], signatureColor: .white, signatureRarity: .common,
            unlock: .starter, stageTheme: .garden,
            baseTint: UIColor(red: 0.96, green: 0.86, blue: 0.92, alpha: 1)
        ),
        .lavender: SpeciesProfile(
            species: .lavender, slug: "lavender", title: "Lavender",
            blurb: "Soft purple spires.",
            stageTitle: "Lavender Lane", stageBlurb: "Cool spires on a porcelain evening board.",
            colors: [.lavender, .violet, .white], signatureColor: .lavender, signatureRarity: .common,
            unlock: .starter, stageTheme: .moonlight,
            baseTint: UIColor(red: 0.70, green: 0.58, blue: 0.86, alpha: 1)
        ),
        .hydrangea: SpeciesProfile(
            species: .hydrangea, slug: "hydrangea", title: "Hydrangea",
            blurb: "A clustered cloud.",
            stageTitle: "Hydrangea House", stageBlurb: "Blue, pink, and white clusters in the mist.",
            colors: [.blue, .pink, .white], signatureColor: .blue, signatureRarity: .common,
            unlock: .starter, stageTheme: .moonlight,
            baseTint: UIColor(red: 0.62, green: 0.72, blue: 0.90, alpha: 1)
        ),
        .orchid: SpeciesProfile(
            species: .orchid, slug: "orchid", title: "Orchid",
            blurb: "Catch falling petals to invite her in.",
            stageTitle: "Orchid House", stageBlurb: "Violet, white, and pink orchids after Petal Catch.",
            colors: [.violet, .white, .pink], signatureColor: .violet, signatureRarity: .rare,
            unlock: .miniGame(.petalCatch), stageTheme: .moonlight,
            baseTint: UIColor(red: 0.78, green: 0.48, blue: 0.82, alpha: 1)
        ),
        .peony: SpeciesProfile(
            species: .peony, slug: "peony", title: "Peony",
            blurb: "Repeat the bloom pattern to unlock.",
            stageTitle: "Peony Court", stageBlurb: "Blush peonies on a sakura board. Pattern Bloom first.",
            colors: [.pink, .white, .coral], signatureColor: .pink, signatureRarity: .rare,
            unlock: .miniGame(.patternBloom), stageTheme: .sakura,
            baseTint: UIColor(red: 0.94, green: 0.62, blue: 0.74, alpha: 1)
        ),
        .lotus: SpeciesProfile(
            species: .lotus, slug: "lotus", title: "Lotus",
            blurb: "A quiet sink for spare petals.",
            stageTitle: "Lotus Pool", stageBlurb: "Glasshouse water and lotus colors. Invite her with petals.",
            colors: [.pink, .white, .cream], signatureColor: .pink, signatureRarity: .epic,
            unlock: .petals(30), stageTheme: .greenhouse,
            baseTint: UIColor(red: 0.95, green: 0.72, blue: 0.78, alpha: 1)
        ),
        .cactusBloom: SpeciesProfile(
            species: .cactusBloom, slug: "succulent", title: "Cactus bloom",
            blurb: "Blooms once Desert Bloom is yours.",
            stageTitle: "Succulent Dunes", stageBlurb: "A desert map of cactus blooms — coral, yellow, pink.",
            colors: [.coral, .yellow, .pink], signatureColor: .coral, signatureRarity: .epic,
            unlock: .mapSkin(.desertBloom), stageTheme: .desertBloom,
            baseTint: UIColor(red: 0.92, green: 0.48, blue: 0.62, alpha: 1)
        ),
        .moonflower: SpeciesProfile(
            species: .moonflower, slug: "moonflower", title: "Moonflower",
            blurb: "Opens with Moonlight Garden.",
            stageTitle: "Moon Terrace", stageBlurb: "Ivory night blooms on the moonlight board.",
            colors: [.ivory, .violet, .white], signatureColor: .ivory, signatureRarity: .epic,
            unlock: .mapSkin(.moonlight), stageTheme: .moonlight,
            baseTint: UIColor(red: 0.82, green: 0.86, blue: 0.96, alpha: 1)
        ),
        .cherryBlossom: SpeciesProfile(
            species: .cherryBlossom, slug: "sakura", title: "Cherry blossom",
            blurb: "Travels with Sakura Petals.",
            stageTitle: "Sakura Path", stageBlurb: "Cherry blossom tiles on the sakura grove board.",
            colors: [.pink, .white, .coral], signatureColor: .pink, signatureRarity: .epic,
            unlock: .mapSkin(.sakura), stageTheme: .sakura,
            baseTint: UIColor(red: 0.96, green: 0.70, blue: 0.78, alpha: 1)
        ),
        .starfire: SpeciesProfile(
            species: .starfire, slug: "starfire", title: "Starfire",
            blurb: "Ultra. Matching a set wipes the whole board.",
            stageTitle: "Starfire Grove", stageBlurb: "Amber fire tiles. Ultra variants still clear the grid.",
            colors: [.amber, .red, .yellow], signatureColor: .amber, signatureRarity: .ultra,
            unlock: .seedPack(.ultra), stageTheme: .sunflower,
            baseTint: UIColor(red: 0.98, green: 0.62, blue: 0.22, alpha: 1)
        ),
        .nightOrchid: SpeciesProfile(
            species: .nightOrchid, slug: "night-orchid", title: "Night orchid",
            blurb: "Ultra. A night bloom that clears the grid.",
            stageTitle: "Night Orchid Court", stageBlurb: "Violet night orchids. Ultra still wipes the board.",
            colors: [.violet, .blue, .ivory], signatureColor: .violet, signatureRarity: .ultra,
            unlock: .seedPack(.ultra), stageTheme: .moonlight,
            baseTint: UIColor(red: 0.42, green: 0.28, blue: 0.72, alpha: 1)
        ),
        .sunburst: SpeciesProfile(
            species: .sunburst, slug: "sunburst", title: "Sunburst",
            blurb: "Ultra. Matching it blooms the entire garden.",
            stageTitle: "Sunburst Meadow", stageBlurb: "Golden sunburst tiles on a honey board.",
            colors: [.yellow, .amber, .cream], signatureColor: .yellow, signatureRarity: .ultra,
            unlock: .seedPack(.ultra), stageTheme: .sunflower,
            baseTint: UIColor(red: 0.98, green: 0.84, blue: 0.28, alpha: 1)
        )
    ]
}

enum GardenStageCatalog {
    static let classicID = "classic"

    static let classic = GardenStage(
        id: classicID,
        title: "Classic Garden",
        blurb: "Mixed meadow. Every flower you’ve unlocked can show up. Pick a map skin in Greenhouse.",
        species: FlowerSpecies.allCases,
        themePack: .garden,
        unlock: .always
    )

    static var all: [GardenStage] {
        [classic] + FlowerSpecies.allCases.map { BloomCatalog.profile($0).stage }
    }

    static func stage(id: String) -> GardenStage? {
        all.first { $0.id == id }
    }
}

extension GameMode {
    var stage: GardenStage? {
        switch self {
        case .classic:
            return GardenStageCatalog.classic
        case .daily:
            return nil
        case .stage(let id):
            return GardenStageCatalog.stage(id: id)
        }
    }

    var allowsCustomBlooms: Bool {
        switch self {
        case .classic: return true
        case .daily, .stage: return false
        }
    }

    var allowsUltraWipe: Bool {
        self != .daily
    }

    var usesPlayerMapSkin: Bool {
        switch self {
        case .classic, .daily: return true
        case .stage: return false
        }
    }
}
