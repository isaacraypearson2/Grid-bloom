import SwiftUI

struct OnboardingView: View {
    var theme: BoardTheme
    var onFinished: () -> Void
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("leaf.fill", "Drag a flower onto the garden", "Tiles snap when the ghost is clear. If it can’t land, it shakes home."),
        ("square.grid.3x3.fill", "Fill a row or a column", "Complete lines bloom away together. Intersections count once."),
        ("sparkles", "Chain Bloom combos", "Clear on consecutive drops for Bloom x2, x3… Petals burst, the board punches."),
        ("book.fill", "Collect flowers & maps", "Album, daily goals, and side gardens unlock new species and playfield skins. Classic Garden is always free to play.")
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()
            GardenCard(theme: theme) {
                VStack(spacing: 18) {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            onFinished()
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(theme.inkSoft)
                    }

                    let item = pages[page]
                    Image(systemName: item.0)
                        .font(.system(size: 36))
                        .foregroundColor(theme.accent)
                        .padding(.top, 4)
                    Text(item.1)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(theme.ink)
                        .multilineTextAlignment(.center)
                    Text(item.2)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(theme.inkSoft)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == page ? theme.accent : theme.inkSoft.opacity(0.25))
                                .frame(width: index == page ? 18 : 8, height: 8)
                        }
                    }
                    .padding(.top, 4)

                    PrimaryGardenButton(
                        title: page == pages.count - 1 ? "Let’s plant" : "Next",
                        fill: theme.accent
                    ) {
                        if page == pages.count - 1 {
                            onFinished()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                                page += 1
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
