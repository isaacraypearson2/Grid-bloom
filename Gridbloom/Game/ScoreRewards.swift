import Foundation

/// Score → seed-pack rungs for Classic Garden and Today’s Bloom (and flower-map stages).
/// Higher rarities sit behind steeper scores; Ultra also rolls a low drop chance at 2000.
enum ScorePackTable {
    struct Rung: Equatable, Sendable {
        var score: Int
        var rarity: SeedRarity
        /// 1.0 always grants. Ultra’s first rung is a rare roll so 2000 is not a free Ultra.
        var chance: Double
    }

    /// Common 100 → Rare 500 → Epic 1000 → Ultra 2000 (22%) → Ultra 4000 (guaranteed).
    static let rungs: [Rung] = [
        Rung(score: 100, rarity: .common, chance: 1),
        Rung(score: 500, rarity: .rare, chance: 1),
        Rung(score: 1000, rarity: .epic, chance: 1),
        Rung(score: 2000, rarity: .ultra, chance: 0.22),
        Rung(score: 4000, rarity: .ultra, chance: 1)
    ]

    /// High-score Organic fertilizer (once per UTC day per mode family).
    static let organicScore = 2500

    static func rungs(reaching score: Int) -> [Rung] {
        rungs.filter { score >= $0.score }
    }

    /// Grants each crossed rung at most once per run. Failed Ultra rolls still consume the rung.
    static func awards(
        score: Int,
        alreadyResolved: Set<Int>,
        rng: inout SplitMix64
    ) -> (packs: [SeedRarity], resolved: Set<Int>) {
        var packs: [SeedRarity] = []
        var resolved = alreadyResolved
        for rung in rungs(reaching: score) where !resolved.contains(rung.score) {
            resolved.insert(rung.score)
            if rung.chance >= 1 || rng.unitDouble() < rung.chance {
                packs.append(rung.rarity)
            }
        }
        return (packs, resolved)
    }

    static func preview(score: Int) -> [Rung] {
        rungs(reaching: score)
    }
}

struct RunScoreRewards: Equatable {
    var packs: [SeedRarity]
    var organicFertilizer: Bool
}

/// Short botanical notes for album / garden detail. Color lanes add a one-line variant fact.
enum BloomFacts {
    static func speciesFact(_ species: FlowerSpecies) -> String {
        switch species {
        case .tulip:
            return "Tulips can rest as bulbs for years and still bloom when the soil warms."
        case .daisy:
            return "A daisy “flower” is really a bouquet: hundreds of tiny florets in one head."
        case .rose:
            return "Garden roses have been bred for scent and form for more than two thousand years."
        case .lily:
            return "True lilies grow from scaly bulbs; each scale can start a whole new plant."
        case .lavender:
            return "Lavender’s oils sit in tiny glandular hairs — that’s why brushing it perfumes the air."
        case .hydrangea:
            return "Hydrangea color can shift with soil pH: more acid leans blue, more alkaline leans pink."
        case .orchid:
            return "Many orchids bloom on the same spike for months, sipping light instead of rich soil."
        case .peony:
            return "Peonies can outlive the gardener — some clumps flower for fifty years or more."
        case .lotus:
            return "Lotus leaves are famously water-repellent; rain beads up and rolls the dust away."
        case .cactusBloom:
            return "Desert cactus flowers often open for a single intense day, then fold at dusk."
        case .moonflower:
            return "Moonflowers unfurl at evening and pour out scent for moths, not bees."
        case .cherryBlossom:
            return "Cherry blossoms peak for only a week or two — a whole festival around a brief bloom."
        case .starfire:
            return "Starfire is Gridbloom’s amber Ultra: a board-clearing blaze when it dominates a line."
        case .nightOrchid:
            return "Night orchid is an Ultra dusk bloom — matching it wipes the rest of the garden grid."
        case .sunburst:
            return "Sunburst is the Ultra meadow flare: gold tiles that can empty the board in one bloom."
        }
    }

    static func variantFact(species: FlowerSpecies, color: BloomColor) -> String {
        let hue: String
        switch color {
        case .red: hue = "Red forms often signal nectar-rich blooms to birds as well as bees."
        case .white: hue = "White petals bounce moonlight and tend to show best after dusk."
        case .yellow: hue = "Yellow reads loudly to bees — many pollinators see it as a landing light."
        case .pink: hue = "Pink often comes from a soft mix of red pigments, not a separate dye."
        case .peach: hue = "Peach tones usually blend coral carotenoids with a wash of pink."
        case .lavender: hue = "Lavender hues sit between rose and violet — cool in shade, warmer in sun."
        case .blue: hue = "True blue in petals is rare; most “blue” blooms lean violet up close."
        case .coral: hue = "Coral mixes warmth and blush — a desert-sunset lane in the catalog."
        case .ivory: hue = "Ivory is cream with a hint of green-gold, like new moonlight on petals."
        case .amber: hue = "Amber carries the honeyed look of late-summer pollen."
        case .violet: hue = "Violet sits at the edge of what many insects see as ultraviolet guides."
        case .cream: hue = "Cream petals hide a little yellow so they never read as stark white."
        }
        return "\(BloomFacts.speciesFact(species)) \(hue)"
    }
}

/// Album XP and named collector tiers. XP is derived from collected variants + scans (no separate save).
enum CollectorProgress {
    static func xp(for rarity: SeedRarity) -> Int {
        switch rarity {
        case .common: return 8
        case .rare: return 14
        case .epic: return 24
        case .ultra: return 40
        }
    }

    static let scanXP = 6
    static let newSpeciesBonus = 12

    static func totalXP(variants: Set<String>, species: Set<FlowerSpecies>, scans: Int) -> Int {
        var xp = 0
        var countedSpecies = Set<FlowerSpecies>()
        for key in variants {
            guard let bloom = BloomVariant.parse(catalogKey: key) else { continue }
            xp += xp(for: bloom.rarity)
            if countedSpecies.insert(bloom.species).inserted, species.contains(bloom.species) {
                xp += newSpeciesBonus
            }
        }
        xp += max(0, scans) * scanXP
        return xp
    }
}
