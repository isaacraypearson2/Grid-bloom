import SwiftUI

struct OnboardingView: View {
    var theme: BoardTheme
    var onFinished: () -> Void
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("leaf.fill", "Drag a flower onto the garden", "Tiles snap when the ghost is clear. If it can’t land, it shakes home."),
        ("square.grid.3x3.fill", "Fill a row or a column", "Complete lines bloom away together. Intersections count once."),
        ("sparkles", "Chain Bloom combos", "Clear on consecutive drops for Bloom x2, x3… That flower blooms across the screen."),
        ("camera.fill", "Scan a real flower", "Point the camera at a bloom. We read it on this iPhone and plant it as a playable tile — no photo library."),
        ("leaf.circle.fill", "Grow a real-time garden", "Water about every 3 hours so plants don’t wilt. Ads grant regular fertilizer; Organic is stronger and rarer. Classic Garden stays free."),
        ("map.fill", "Flower maps", "Unlock Tulip Walk, Rose Garden, Succulent Dunes, and more by collecting that flower. Classic Garden stays the mixed meadow."),
        ("book.fill", "Collect colors & rarities", "Each species has color variants and a Common → Rare → Epic → Ultra ladder. Ultra still wipes the board. Classic Garden is always free to play.")
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
