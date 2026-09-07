import SwiftUI

struct GameOverView: View {
    var score: Int
    var best: Int
    var onRestart: () -> Void
    var onContinue: () -> Void
    var onMenu: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            BloomMark(size: 64)
            Text("Garden’s full")
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundColor(GardenPalette.ink)
            Text("No remaining piece fits the board.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(GardenPalette.inkSoft)
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                VStack {
                    Text("Score").font(.caption).foregroundColor(GardenPalette.inkSoft)
                    Text("\(score)").font(.title.bold())
                }
                VStack {
                    Text("Best").font(.caption).foregroundColor(GardenPalette.inkSoft)
                    Text("\(best)").font(.title.bold())
                }
            }
            .foregroundColor(GardenPalette.ink)

            Button(action: onRestart) {
                Text("Restart")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(GardenButtonStyle(fill: GardenPalette.buttonFill))

            Button(action: onContinue) {
                Text("Continue  ·  bloom revive")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(GardenButtonStyle(fill: GardenPalette.dailyFill))

            Button("Menu", action: onMenu)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(GardenPalette.inkSoft)
                .padding(.top, 4)
        }
        .padding(28)
        .background(GardenPalette.cream.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: GardenPalette.soil.opacity(0.35), radius: 24, y: 10)
        .padding(.horizontal, 28)
    }
}
