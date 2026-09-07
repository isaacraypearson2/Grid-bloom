import SwiftUI

struct MainMenuView: View {
    var classicBest: Int
    var dailyBest: Int
    var utcDay: String
    var onPlayClassic: () -> Void
    var onPlayDaily: () -> Void

    var body: some View {
        ZStack {
            GardenBackground()
            VStack(spacing: 28) {
                Spacer()
                BloomMark(size: 92)
                VStack(spacing: 8) {
                    Text("Gridbloom")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(GardenPalette.ink)
                    Text("Plant pieces. Bloom the grid.")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(GardenPalette.inkSoft)
                }

                VStack(spacing: 14) {
                    Button(action: onPlayClassic) {
                        menuLabel(title: "Play", subtitle: "Classic garden", systemImage: "leaf.fill")
                    }
                    .buttonStyle(GardenButtonStyle(fill: GardenPalette.buttonFill))

                    Button(action: onPlayDaily) {
                        menuLabel(title: "Today’s Bloom", subtitle: utcDay + " · UTC seed", systemImage: "sun.max.fill")
                    }
                    .buttonStyle(GardenButtonStyle(fill: GardenPalette.dailyFill))
                }
                .padding(.horizontal, 32)

                HStack(spacing: 28) {
                    scoreChip(title: "Best", value: classicBest)
                    scoreChip(title: "Today", value: dailyBest)
                }
                .padding(.top, 8)

                Spacer()
                Text("Clear rows & columns · chain Bloom combos")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(GardenPalette.inkSoft.opacity(0.85))
                    .padding(.bottom, 24)
            }
        }
    }

    private func menuLabel(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(subtitle)
                    .font(.system(.caption, design: .rounded))
                    .opacity(0.85)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .opacity(0.7)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func scoreChip(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(GardenPalette.inkSoft)
            Text("\(value)")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(GardenPalette.ink)
        }
        .frame(width: 110)
        .padding(.vertical, 10)
        .background(GardenPalette.cream.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GardenButtonStyle: ButtonStyle {
    var fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(fill.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: fill.opacity(0.35), radius: configuration.isPressed ? 2 : 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
