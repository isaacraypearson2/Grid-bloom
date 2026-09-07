import SwiftUI
import UIKit

enum CosmeticPack: String, CaseIterable, Identifiable, Equatable {
    case garden
    case sakura
    case moonlight
    case sunflower

    var id: String { rawValue }

    var productID: String? {
        switch self {
        case .garden: return nil
        case .sakura: return "com.gridbloom.cosmetics.sakura"
        case .moonlight: return "com.gridbloom.cosmetics.moonlight"
        case .sunflower: return "com.gridbloom.cosmetics.sunflower"
        }
    }

    var title: String {
        switch self {
        case .garden: return "Garden Clay"
        case .sakura: return "Sakura Petals"
        case .moonlight: return "Moonlight Garden"
        case .sunflower: return "Golden Sunflower"
        }
    }

    var blurb: String {
        switch self {
        case .garden: return "Soft celadon tiles. Always yours."
        case .sakura: return "Blush glaze and cherry petal bursts."
        case .moonlight: return "Cool porcelain under a night garden."
        case .sunflower: return "Warm honey tiles and golden petals."
        }
    }

    var isFree: Bool { self == .garden }
}

struct BoardTheme {
    var pack: CosmeticPack
    var backgroundTop: Color
    var backgroundBottom: Color
    var ink: Color
    var inkSoft: Color
    var cream: Color
    var accent: Color
    var well: UIColor
    var empty: UIColor
    var emptyStroke: UIColor
    var pieceFills: [UIColor]
    var petal: UIColor
    var validGhost: UIColor
    var invalidGhost: UIColor

    static func theme(for pack: CosmeticPack, colorblind: Bool) -> BoardTheme {
        let base: BoardTheme
        switch pack {
        case .garden:
            base = BoardTheme(
                pack: pack,
                backgroundTop: Color(red: 0.91, green: 0.96, blue: 0.90),
                backgroundBottom: Color(red: 0.76, green: 0.87, blue: 0.78),
                ink: Color(red: 0.20, green: 0.36, blue: 0.28),
                inkSoft: Color(red: 0.34, green: 0.48, blue: 0.40),
                cream: Color(red: 0.99, green: 0.98, blue: 0.94),
                accent: Color(red: 0.42, green: 0.68, blue: 0.50),
                well: UIColor(red: 0.73, green: 0.84, blue: 0.71, alpha: 1),
                empty: UIColor(red: 0.97, green: 0.98, blue: 0.95, alpha: 1),
                emptyStroke: UIColor(red: 0.80, green: 0.88, blue: 0.78, alpha: 1),
                pieceFills: GardenPalette.defaultPieceFills,
                petal: UIColor(red: 0.93, green: 0.62, blue: 0.70, alpha: 1),
                validGhost: UIColor(red: 0.32, green: 0.62, blue: 0.78, alpha: 0.55),
                invalidGhost: UIColor(red: 0.55, green: 0.40, blue: 0.22, alpha: 0.55)
            )
        case .sakura:
            base = BoardTheme(
                pack: pack,
                backgroundTop: Color(red: 0.99, green: 0.93, blue: 0.94),
                backgroundBottom: Color(red: 0.92, green: 0.80, blue: 0.84),
                ink: Color(red: 0.38, green: 0.22, blue: 0.28),
                inkSoft: Color(red: 0.52, green: 0.36, blue: 0.42),
                cream: Color(red: 1.0, green: 0.97, blue: 0.96),
                accent: Color(red: 0.86, green: 0.52, blue: 0.62),
                well: UIColor(red: 0.90, green: 0.78, blue: 0.82, alpha: 1),
                empty: UIColor(red: 1.0, green: 0.97, blue: 0.97, alpha: 1),
                emptyStroke: UIColor(red: 0.92, green: 0.82, blue: 0.84, alpha: 1),
                pieceFills: [
                    UIColor(red: 0.93, green: 0.55, blue: 0.64, alpha: 1),
                    UIColor(red: 0.95, green: 0.72, blue: 0.78, alpha: 1),
                    UIColor(red: 0.86, green: 0.62, blue: 0.74, alpha: 1),
                    UIColor(red: 0.72, green: 0.78, blue: 0.62, alpha: 1),
                    UIColor(red: 0.98, green: 0.84, blue: 0.70, alpha: 1),
                    UIColor(red: 0.78, green: 0.70, blue: 0.86, alpha: 1),
                    UIColor(red: 0.96, green: 0.78, blue: 0.82, alpha: 1),
                    UIColor(red: 0.62, green: 0.72, blue: 0.58, alpha: 1),
                    UIColor(red: 0.90, green: 0.50, blue: 0.58, alpha: 1)
                ],
                petal: UIColor(red: 0.96, green: 0.58, blue: 0.68, alpha: 1),
                validGhost: UIColor(red: 0.40, green: 0.62, blue: 0.78, alpha: 0.55),
                invalidGhost: UIColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 0.55)
            )
        case .moonlight:
            base = BoardTheme(
                pack: pack,
                backgroundTop: Color(red: 0.86, green: 0.90, blue: 0.96),
                backgroundBottom: Color(red: 0.62, green: 0.70, blue: 0.82),
                ink: Color(red: 0.18, green: 0.24, blue: 0.38),
                inkSoft: Color(red: 0.32, green: 0.40, blue: 0.52),
                cream: Color(red: 0.94, green: 0.96, blue: 0.99),
                accent: Color(red: 0.42, green: 0.52, blue: 0.72),
                well: UIColor(red: 0.68, green: 0.74, blue: 0.84, alpha: 1),
                empty: UIColor(red: 0.93, green: 0.95, blue: 0.98, alpha: 1),
                emptyStroke: UIColor(red: 0.76, green: 0.82, blue: 0.90, alpha: 1),
                pieceFills: [
                    UIColor(red: 0.55, green: 0.66, blue: 0.86, alpha: 1),
                    UIColor(red: 0.70, green: 0.78, blue: 0.92, alpha: 1),
                    UIColor(red: 0.78, green: 0.70, blue: 0.90, alpha: 1),
                    UIColor(red: 0.58, green: 0.78, blue: 0.80, alpha: 1),
                    UIColor(red: 0.92, green: 0.88, blue: 0.72, alpha: 1),
                    UIColor(red: 0.48, green: 0.58, blue: 0.78, alpha: 1),
                    UIColor(red: 0.84, green: 0.80, blue: 0.92, alpha: 1),
                    UIColor(red: 0.62, green: 0.72, blue: 0.78, alpha: 1),
                    UIColor(red: 0.40, green: 0.50, blue: 0.70, alpha: 1)
                ],
                petal: UIColor(red: 0.78, green: 0.82, blue: 0.96, alpha: 1),
                validGhost: UIColor(red: 0.45, green: 0.72, blue: 0.88, alpha: 0.55),
                invalidGhost: UIColor(red: 0.72, green: 0.55, blue: 0.32, alpha: 0.55)
            )
        case .sunflower:
            base = BoardTheme(
                pack: pack,
                backgroundTop: Color(red: 0.99, green: 0.96, blue: 0.86),
                backgroundBottom: Color(red: 0.90, green: 0.82, blue: 0.58),
                ink: Color(red: 0.36, green: 0.28, blue: 0.12),
                inkSoft: Color(red: 0.50, green: 0.42, blue: 0.24),
                cream: Color(red: 1.0, green: 0.98, blue: 0.92),
                accent: Color(red: 0.86, green: 0.62, blue: 0.22),
                well: UIColor(red: 0.86, green: 0.78, blue: 0.52, alpha: 1),
                empty: UIColor(red: 1.0, green: 0.98, blue: 0.90, alpha: 1),
                emptyStroke: UIColor(red: 0.90, green: 0.82, blue: 0.58, alpha: 1),
                pieceFills: [
                    UIColor(red: 0.92, green: 0.70, blue: 0.22, alpha: 1),
                    UIColor(red: 0.96, green: 0.82, blue: 0.40, alpha: 1),
                    UIColor(red: 0.62, green: 0.72, blue: 0.38, alpha: 1),
                    UIColor(red: 0.90, green: 0.52, blue: 0.28, alpha: 1),
                    UIColor(red: 0.78, green: 0.64, blue: 0.32, alpha: 1),
                    UIColor(red: 0.55, green: 0.68, blue: 0.42, alpha: 1),
                    UIColor(red: 0.98, green: 0.86, blue: 0.50, alpha: 1),
                    UIColor(red: 0.72, green: 0.48, blue: 0.22, alpha: 1),
                    UIColor(red: 0.86, green: 0.74, blue: 0.36, alpha: 1)
                ],
                petal: UIColor(red: 0.96, green: 0.78, blue: 0.28, alpha: 1),
                validGhost: UIColor(red: 0.28, green: 0.58, blue: 0.48, alpha: 0.55),
                invalidGhost: UIColor(red: 0.55, green: 0.32, blue: 0.16, alpha: 0.55)
            )
        }
        guard colorblind else { return base }
        var themed = base
        themed.pieceFills = GardenPalette.colorblindPieceFills
        themed.validGhost = UIColor(red: 0.00, green: 0.45, blue: 0.70, alpha: 0.58)
        themed.invalidGhost = UIColor(red: 0.80, green: 0.47, blue: 0.00, alpha: 0.58)
        return themed
    }

    func pieceFill(index: Int) -> UIColor {
        pieceFills[abs(index) % pieceFills.count]
    }

    func pieceStroke(index: Int) -> UIColor {
        pieceFill(index: index).darker(by: 0.16)
    }
}

extension GardenPalette {
    static let defaultPieceFills: [UIColor] = [
        UIColor(red: 0.48, green: 0.77, blue: 0.52, alpha: 1),
        UIColor(red: 0.62, green: 0.80, blue: 0.58, alpha: 1),
        UIColor(red: 0.93, green: 0.70, blue: 0.76, alpha: 1),
        UIColor(red: 0.77, green: 0.70, blue: 0.89, alpha: 1),
        UIColor(red: 0.96, green: 0.78, blue: 0.58, alpha: 1),
        UIColor(red: 0.58, green: 0.78, blue: 0.86, alpha: 1),
        UIColor(red: 0.95, green: 0.88, blue: 0.55, alpha: 1),
        UIColor(red: 0.55, green: 0.72, blue: 0.62, alpha: 1),
        UIColor(red: 0.90, green: 0.62, blue: 0.68, alpha: 1)
    ]

    /// Okabe–Ito inspired set so pieces stay distinct without relying on green vs red.
    static let colorblindPieceFills: [UIColor] = [
        UIColor(red: 0.90, green: 0.62, blue: 0.00, alpha: 1),
        UIColor(red: 0.34, green: 0.71, blue: 0.91, alpha: 1),
        UIColor(red: 0.00, green: 0.62, blue: 0.45, alpha: 1),
        UIColor(red: 0.94, green: 0.89, blue: 0.26, alpha: 1),
        UIColor(red: 0.00, green: 0.45, blue: 0.70, alpha: 1),
        UIColor(red: 0.84, green: 0.37, blue: 0.00, alpha: 1),
        UIColor(red: 0.80, green: 0.47, blue: 0.65, alpha: 1),
        UIColor(red: 0.40, green: 0.40, blue: 0.40, alpha: 1),
        UIColor(red: 0.27, green: 0.67, blue: 0.60, alpha: 1)
    ]
}
