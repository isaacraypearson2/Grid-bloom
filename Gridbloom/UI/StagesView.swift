import SwiftUI

struct StagesView: View {
    @ObservedObject var profile: PlayerProfile
    var theme: BoardTheme
    var classicBest: Int
    var bestForStage: (String) -> Int
    var onPlayClassic: () -> Void
    var onPlayStage: (GardenStage) -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Flower maps")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundColor(theme.ink)
                        Text("Themed boards for each plant family. Classic Garden stays the mixed meadow.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(theme.inkSoft)
                    }
                    Spacer()
                    IconCircleButton(systemName: "xmark", label: "Close", theme: theme, action: onClose)
                }

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(GardenStageCatalog.all) { stage in
                            stageCard(stage)
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
            .padding(22)
        }
    }

    private func stageCard(_ stage: GardenStage) -> some View {
        let unlocked = profile.isStageUnlocked(stage)
        let packTheme = BoardTheme.theme(for: stage.themePack, colorblind: false)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                BloomMark(
                    size: 32,
                    petal: unlocked
                        ? Color((stage.species.first ?? .tulip).petalTint)
                        : theme.inkSoft.opacity(0.35)
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(unlocked ? stage.title : "???")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(theme.ink)
                    Text(unlocked ? stage.blurb : lockHint(stage))
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            HStack {
                Text(stage.isClassic ? "Best \(classicBest)" : "Best \(bestForStage(stage.id))")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.inkSoft)
                Spacer()
                if unlocked {
                    Button(stage.isClassic ? "Play mixed" : "Play") {
                        if stage.isClassic {
                            onPlayClassic()
                        } else {
                            onPlayStage(stage)
                        }
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(packTheme.accent)
                    .clipShape(Capsule())
                } else {
                    Text("Locked")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.inkSoft)
                }
            }
        }
        .padding(14)
        .background(packTheme.cream.opacity(unlocked ? 0.92 : 0.62))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(unlocked ? packTheme.accent.opacity(0.45) : Color.clear, lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func lockHint(_ stage: GardenStage) -> String {
        switch stage.unlock {
        case .always:
            return "Always open."
        case .collectSpecies(let species):
            return "Collect \(species.title) — play Classic, harvest a seed, or unlock its map."
        }
    }
}
