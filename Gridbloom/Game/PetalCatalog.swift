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

    /// Lighter lip on the pot mesh.
    var rim: Color {
        switch self {
        case .terracotta: return Color(red: 0.88, green: 0.60, blue: 0.48)
        case .sage: return Color(red: 0.66, green: 0.76, blue: 0.62)
        case .blush: return Color(red: 0.94, green: 0.74, blue: 0.76)
        case .midnight: return Color(red: 0.40, green: 0.44, blue: 0.58)
        case .cream: return Color(red: 0.98, green: 0.94, blue: 0.86)
        }
    }

    /// Darker saucer / pot foot.
    var saucer: Color {
        switch self {
        case .terracotta: return Color(red: 0.58, green: 0.32, blue: 0.24)
        case .sage: return Color(red: 0.34, green: 0.46, blue: 0.34)
        case .blush: return Color(red: 0.64, green: 0.40, blue: 0.46)
        case .midnight: return Color(red: 0.16, green: 0.18, blue: 0.30)
        case .cream: return Color(red: 0.72, green: 0.64, blue: 0.50)
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
        case .mistAll: return "Water every living bed at once — plays a mist spray over the garden."
        case .dewBurst: return "1.5× growth on all growing plants for 15 minutes, with a dew sparkle."
        case .organicPouch: return "One Organic fertilizer charge — 3× for 4 hours, 12h cooldown."
        case .beeHint: return "A lantern bee visits planted flowers — 1.5× growth for about a minute."
        case .potSage, .potBlush, .potMidnight, .potCream:
            return "Glaze the pot mesh. Purely cosmetic."
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
        case .beeHint: return "hexagon.fill"
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
