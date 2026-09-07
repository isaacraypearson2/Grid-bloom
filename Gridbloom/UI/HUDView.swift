import SwiftUI

struct HUDView: View {
    var theme: BoardTheme
    var score: Int
    var best: Int
    var combo: Int
    var modeTitle: String
    var onPause: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            IconCircleButton(systemName: "pause.fill", label: "Pause", theme: theme, action: onPause)

            VStack(alignment: .leading, spacing: 2) {
                Text(modeTitle)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.inkSoft)
                Text("\(score)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                    .monospacedDigit()
            }

            Spacer()

            if combo >= 2 {
                Text("Bloom x\(combo)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.accent)
                    .clipShape(Capsule())
                    .accessibilityLabel("Bloom combo \(combo)")
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text("Best")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                Text("\(best)")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.ink)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

struct ComboBanner: View {
    var combo: Int
    var theme: BoardTheme

    var body: some View {
        Text(combo >= 4 ? "Garden rush  x\(combo)" : "Bloom x\(combo)")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(theme.accent.opacity(0.95))
                    .shadow(color: theme.accent.opacity(0.4), radius: 16, y: 6)
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
    }
}
