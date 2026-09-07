import SwiftUI

struct GardenCard<Content: View>: View {
    var theme: BoardTheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(24)
            .background(theme.cream.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 22, y: 10)
    }
}

struct IconCircleButton: View {
    var systemName: String
    var label: String
    var theme: BoardTheme
    var action: () -> Void

    var body: some View {
        Button(action: {
            SoundPlayer.shared.uiTap()
            Haptics.light()
            action()
        }) {
            Image(systemName: systemName)
                .font(.headline.weight(.bold))
                .foregroundColor(theme.ink)
                .frame(width: 40, height: 40)
                .background(theme.cream.opacity(0.88))
                .clipShape(Circle())
        }
        .accessibilityLabel(label)
        .buttonStyle(.plain)
    }
}

struct PrimaryGardenButton: View {
    var title: String
    var fill: Color
    var action: () -> Void

    var body: some View {
        Button(action: {
            SoundPlayer.shared.uiTap()
            Haptics.light()
            action()
        }) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(GardenButtonStyle(fill: fill))
    }
}

struct AdInterludeView: View {
    var theme: BoardTheme
    var title: String

    var body: some View {
        VStack(spacing: 16) {
            BloomMark(size: 56, petal: theme.accent)
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(theme.ink)
            Text("A short thank-you bloom.\nNo mid-game interruptions — you asked for this.")
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(theme.inkSoft)
                .multilineTextAlignment(.center)
            ProgressView()
                .tint(theme.accent)
        }
        .padding(28)
        .frame(maxWidth: 320)
        .background(theme.cream.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 24, y: 10)
    }
}

struct GardenButtonStyle: ButtonStyle {
    var fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(fill.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: fill.opacity(0.32), radius: configuration.isPressed ? 2 : 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
