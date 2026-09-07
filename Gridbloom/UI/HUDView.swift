import SwiftUI

struct HUDView: View {
    var score: Int
    var best: Int
    var combo: Int
    var modeTitle: String
    var onBack: () -> Void
    var onShuffle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundColor(GardenPalette.ink)
                    .frame(width: 36, height: 36)
                    .background(GardenPalette.cream.opacity(0.8))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Back to menu")

            VStack(alignment: .leading, spacing: 2) {
                Text(modeTitle)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(GardenPalette.inkSoft)
                Text("\(score)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(GardenPalette.ink)
            }

            Spacer()

            if combo >= 2 {
                Text("Bloom x\(combo)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(GardenPalette.dailyFill)
                    .clipShape(Capsule())
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("Best")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(GardenPalette.inkSoft)
                Text("\(best)")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(GardenPalette.ink)
            }

            Button(action: onShuffle) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.headline)
                    .foregroundColor(GardenPalette.ink)
                    .frame(width: 36, height: 36)
                    .background(GardenPalette.cream.opacity(0.8))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Shuffle tray")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct ComboBanner: View {
    var combo: Int

    var body: some View {
        Text("Bloom x\(combo)")
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(GardenPalette.dailyFill.opacity(0.95))
                    .shadow(color: GardenPalette.petal.opacity(0.5), radius: 16, y: 6)
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
    }
}
