import SwiftUI

struct PauseView: View {
    var theme: BoardTheme
    var onResume: () -> Void
    var onShuffle: () -> Void
    var onSettings: () -> Void
    var onMenu: () -> Void

    var body: some View {
        GardenCard(theme: theme) {
            VStack(spacing: 16) {
                Text("Paused")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                Text("Your garden is waiting.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(theme.inkSoft)

                PrimaryGardenButton(title: "Resume", fill: theme.accent, action: onResume)
                PrimaryGardenButton(title: "New tray  ·  short bloom", fill: GardenPalette.dailyFill, action: onShuffle)
                Button("Settings", action: onSettings)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(theme.ink)
                Button("Menu", action: onMenu)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(theme.inkSoft)
            }
        }
        .padding(.horizontal, 28)
    }
}
