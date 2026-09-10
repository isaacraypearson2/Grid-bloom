import SwiftUI
import UIKit

enum GardenPalette {
    static let backgroundTop = Color(red: 0.90, green: 0.95, blue: 0.88)
    static let backgroundBottom = Color(red: 0.78, green: 0.88, blue: 0.80)
    static let soil = Color(red: 0.72, green: 0.82, blue: 0.70)
    static let boardWell = Color(red: 0.76, green: 0.86, blue: 0.74)
    static let emptyCell = Color(red: 0.96, green: 0.98, blue: 0.94)
    static let emptyStroke = Color(red: 0.82, green: 0.90, blue: 0.80)
    static let ink = Color(red: 0.22, green: 0.38, blue: 0.30)
    static let inkSoft = Color(red: 0.35, green: 0.50, blue: 0.42)
    static let blossom = Color(red: 0.95, green: 0.70, blue: 0.76)
    static let petal = Color(red: 0.91, green: 0.62, blue: 0.70)
    static let butter = Color(red: 0.96, green: 0.90, blue: 0.62)
    static let leaf = Color(red: 0.48, green: 0.76, blue: 0.50)
    static let validGhost = Color(red: 0.45, green: 0.78, blue: 0.52).opacity(0.72)
    static let invalidGhost = Color(red: 0.92, green: 0.42, blue: 0.45).opacity(0.72)
    static let cream = Color(red: 0.98, green: 0.97, blue: 0.93)
    static let buttonFill = Color(red: 0.42, green: 0.68, blue: 0.50)
    static let dailyFill = Color(red: 0.86, green: 0.55, blue: 0.66)

    private static let pieceFills: [UIColor] = [
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

    static func pieceFill(index: Int) -> UIColor {
        pieceFills[abs(index) % pieceFills.count]
    }

    static func pieceStroke(index: Int) -> UIColor {
        pieceFill(index: index).darker(by: 0.14)
    }

    static var emptyCellUI: UIColor {
        UIColor(red: 0.96, green: 0.98, blue: 0.94, alpha: 1)
    }

    static var emptyStrokeUI: UIColor {
        UIColor(red: 0.82, green: 0.90, blue: 0.80, alpha: 1)
    }

    static var boardWellUI: UIColor {
        UIColor(red: 0.74, green: 0.85, blue: 0.72, alpha: 1)
    }

    static var backgroundUI: UIColor {
        UIColor(red: 0.86, green: 0.92, blue: 0.84, alpha: 1)
    }
}

extension UIColor {
    func darker(by amount: CGFloat) -> UIColor {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        if getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha) {
            return UIColor(hue: hue, saturation: sat, brightness: max(0, bri - amount), alpha: alpha)
        }
        return self
    }
}

struct GardenBackground: View {
    var theme: BoardTheme = BoardTheme.theme(for: .garden, colorblind: false)

    var body: some View {
        LinearGradient(
            colors: [theme.backgroundTop, theme.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            BloomMark(size: 64, petal: theme.accent)
                .opacity(0.26)
                .padding(28)
        }
        .overlay(alignment: .bottomLeading) {
            BloomMark(size: 48, petal: theme.accent)
                .opacity(0.16)
                .padding(36)
        }
        .overlay {
            switch theme.pack {
            case .moonlight:
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 72, height: 72)
                            .padding(36)
                    }
                    Spacer()
                }
            case .desertBloom:
                VStack {
                    Spacer()
                    Capsule()
                        .fill(Color(red: 0.86, green: 0.62, blue: 0.32).opacity(0.22))
                        .frame(height: 70)
                        .offset(y: 20)
                }
            case .greenhouse:
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    .padding(28)
            case .sakura, .garden, .sunflower:
                EmptyView()
            }
        }
    }
}

struct BloomMark: View {
    var size: CGFloat = 44
    var petal: Color = GardenPalette.blossom

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Capsule()
                    .fill(petal.opacity(0.9))
                    .frame(width: size * 0.22, height: size * 0.48)
                    .offset(y: -size * 0.18)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
            Circle()
                .fill(GardenPalette.butter)
                .frame(width: size * 0.28, height: size * 0.28)
        }
        .frame(width: size, height: size)
    }
}
