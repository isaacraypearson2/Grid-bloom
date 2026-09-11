import Foundation
import SwiftUI

/// Cosmetic pot tints bought with petals. Data-driven so new colors are content, not new shop code.
enum PotTint: String, CaseIterable, Codable, Identifiable, Sendable {
    case terracotta
    case sage
    case blush
    case midnight
    case cream

    var id: String { rawValue }

    var title: String {
        switch self {
        case .terracotta: return "Terracotta"
        case .sage: return "Sage glaze"
        case .blush: return "Blush clay"
        case .midnight: return "Midnight pot"
        case .cream: return "Creamware"
        }
    }

    var petalCost: Int {
        switch self {
        case .terracotta: return 0
        case .sage: return 14
        case .blush: return 16
        case .midnight: return 20
        case .cream: return 12
        }
    }

    var isFree: Bool { petalCost == 0 }

    var fill: Color {
        switch self {
        case .terracotta: return Color(red: 0.78, green: 0.48, blue: 0.36)
        case .sage: return Color(red: 0.52, green: 0.64, blue: 0.50)
        case .blush: return Color(red: 0.86, green: 0.62, blue: 0.66)
        case .midnight: return Color(red: 0.28, green: 0.32, blue: 0.46)
        case .cream: return Color(red: 0.93, green: 0.88, blue: 0.76)
        }
    }
}

/// Spendable petal sinks beyond catching. Keep new offers in this table.
enum PetalOffer: String, CaseIterable, Identifiable, Sendable {
    case mistAll
    case dewBurst
    case organicPouch
    case beeHint
    case potSage
    case potBlush
    case potMidnight
    case potCream

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mistAll: return "Garden mist"
        case .dewBurst: return "Dew burst"
        case .organicPouch: return "Organic pouch"
        case .beeHint: return "Bee lantern"
        case .potSage: return PotTint.sage.title
        case .potBlush: return PotTint.blush.title
        case .potMidnight: return PotTint.midnight.title
        case .potCream: return PotTint.cream.title
        }
    }

    var blurb: String {
        switch self {
        case .mistAll: return "Water every living bed at once."
        case .dewBurst: return "1.5× growth on all growing plants for 15 minutes."
        case .organicPouch: return "One Organic fertilizer charge — 3× for 4 hours, 12h cooldown."
        case .beeHint: return "Next Bee Trail highlights the next bloom. Consumed when you start a flight."
        case .potSage, .potBlush, .potMidnight, .potCream:
            return "Tint the garden pots. Purely cosmetic."
        }
    }

    var cost: Int {
        switch self {
        case .mistAll: return 10
        case .dewBurst: return 22
        case .organicPouch: return 90
        case .beeHint: return 8
        case .potSage: return PotTint.sage.petalCost
        case .potBlush: return PotTint.blush.petalCost
        case .potMidnight: return PotTint.midnight.petalCost
        case .potCream: return PotTint.cream.petalCost
        }
    }

    var potTint: PotTint? {
        switch self {
        case .potSage: return .sage
        case .potBlush: return .blush
        case .potMidnight: return .midnight
        case .potCream: return .cream
        default: return nil
        }
    }

    var systemImage: String {
        switch self {
        case .mistAll: return "drop.fill"
        case .dewBurst: return "sparkles"
        case .organicPouch: return "leaf.fill"
        case .beeHint: return "lightbulb.fill"
        case .potSage, .potBlush, .potMidnight, .potCream: return "cup.and.saucer.fill"
        }
    }
}

enum FertilizerKind: String, Codable, Equatable, Sendable {
    case regular
    case organic

    var title: String {
        switch self {
        case .regular: return "Fertilizer"
        case .organic: return "Organic"
        }
    }

    var multiplier: Double {
        switch self {
        case .regular: return 2
        case .organic: return 3
        }
    }

    var duration: TimeInterval {
        switch self {
        case .regular: return SeedGardenRules.fertilizerDuration
        case .organic: return SeedGardenRules.organicDuration
        }
    }

    var cooldown: TimeInterval {
        switch self {
        case .regular: return SeedGardenRules.fertilizerCooldown
        case .organic: return SeedGardenRules.organicCooldown
        }
    }

    var fill: Color {
        switch self {
        case .regular: return Color(red: 0.46, green: 0.62, blue: 0.28)
        case .organic: return Color(red: 0.28, green: 0.52, blue: 0.36)
        }
    }
}
