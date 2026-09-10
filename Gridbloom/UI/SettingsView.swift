import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    var theme: BoardTheme
    var onClose: () -> Void
    @State private var showHelp = false

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Settings")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundColor(theme.ink)
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                VStack(spacing: 0) {
                    toggleRow("Sound", isOn: $settings.soundEnabled, footnote: "Respects the silent switch.")
                    Divider().opacity(0.3)
                    toggleRow("Haptics", isOn: $settings.hapticsEnabled, footnote: nil)
                    Divider().opacity(0.3)
                    toggleRow("Color-distinct pieces", isOn: $settings.colorblindPalette, footnote: "Okabe–Ito inspired palette.")
                    Divider().opacity(0.3)
                    toggleRow("Reduce motion", isOn: $settings.reduceMotion, footnote: "Also honors the system setting.")
                }
                .padding(16)
                .background(theme.cream.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                PrimaryGardenButton(title: "How to play", fill: theme.accent) {
                    showHelp = true
                }

                Text("Ads never start themselves. Continue, New tray, Greenhouse unlocks, and optional garden speed-ups only run when you tap them.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                    .padding(.top, 8)

                Spacer()
            }
            .padding(24)
        }
        .sheet(isPresented: $showHelp) {
            ZStack {
                GardenBackground(theme: theme)
                OnboardingView(theme: theme) {
                    settings.hasCompletedOnboarding = true
                    showHelp = false
                }
            }
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>, footnote: String?) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.ink)
                if let footnote {
                    Text(footnote)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                }
            }
        }
        .tint(theme.accent)
        .padding(.vertical, 10)
    }
}
