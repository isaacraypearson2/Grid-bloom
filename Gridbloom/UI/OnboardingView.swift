import SwiftUI

/// First-run and Help pages. Keep this list at five — tests enforce the cap.
enum OnboardingPage: Int, CaseIterable, Identifiable {
    case classic
    case garden
    case packs
    case album
    case miniGames

    var id: Int { rawValue }

    var symbol: String {
        switch self {
        case .classic: return "leaf.fill"
        case .garden: return "drop.fill"
        case .packs: return "shippingbox.fill"
        case .album: return "book.fill"
        case .miniGames: return "sparkles"
        }
    }

    var title: String {
        switch self {
        case .classic: return "Bloom a line"
        case .garden: return "Water your beds"
        case .packs: return "Open seed packs"
        case .album: return "Collect every bloom"
        case .miniGames: return "Play a side garden"
        }
    }

    var message: String {
        switch self {
        case .classic:
            return "Drag a flower onto the garden. Fill a row or column and it blooms away. Chain clears for Bloom ×2, ×3…"
        case .garden:
            return "My Garden grows in real time. Water about every 3 hours so plants don’t wilt. Classic Garden stays free."
        case .packs:
            return "Score, play, or spend petals for Common → Ultra packs. Each pack only drops seeds of that rarity."
        case .album:
            return "Species, colors, and rarities land in the Album. Scan a real flower on this iPhone to plant it as a tile."
        case .miniGames:
            return "Petal Catch, Pattern Bloom, Bee Trail, and Bloom Match earn packs, petals, and new flowers."
        }
    }
}

enum OnboardingOutcome: Equatable {
    case completed
    case skipped
}

/// First-launch routing: show the intro once, then plant the player in Classic Garden.
enum IntroFlow {
    static let maxPages = 5

    static func shouldShow(seenIntro: Bool, completedOnboarding: Bool) -> Bool {
        !seenIntro && !completedOnboarding
    }

    static func initialRoute(seenIntro: Bool, completedOnboarding: Bool) -> AppRoute {
        shouldShow(seenIntro: seenIntro, completedOnboarding: completedOnboarding) ? .intro : .menu
    }

    static func route(after outcome: OnboardingOutcome) -> AppRoute {
        switch outcome {
        case .completed: return .play(.classic)
        case .skipped: return .menu
        }
    }
}

struct OnboardingView: View {
    var theme: BoardTheme
    /// Settings → How to play reuses the same pages without launching a game.
    var isReplay: Bool = false
    var onFinished: (OnboardingOutcome) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = OnboardingPage.classic

    private var isLastPage: Bool {
        page == OnboardingPage.allCases.last
    }

    private var primaryTitle: String {
        if isReplay {
            return isLastPage ? "Done" : "Next"
        }
        return isLastPage ? "Let’s plant" : "Next"
    }

    var body: some View {
        ZStack {
            GardenBackground(theme: theme)
            decorativeBlooms

            VStack(spacing: 18) {
                header
                TabView(selection: $page) {
                    ForEach(OnboardingPage.allCases) { item in
                        pageCard(item)
                            .tag(item)
                            .padding(.horizontal, 4)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                pageDots

                PrimaryGardenButton(title: primaryTitle, fill: theme.accent) {
                    advanceOrFinish()
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gridbloom")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                Text(isReplay ? "How to play" : "A quiet garden puzzle")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(theme.inkSoft)
            }
            Spacer()
            Button("Skip") {
                onFinished(.skipped)
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundColor(theme.inkSoft)
            .accessibilityHint(isReplay ? "Close how to play" : "Skip the intro and go to the menu")
        }
    }

    private func pageCard(_ item: OnboardingPage) -> some View {
        GardenCard(theme: theme) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.14))
                        .frame(width: 92, height: 92)
                    BloomMark(size: 36, petal: theme.accent)
                        .offset(x: 28, y: -26)
                        .opacity(0.55)
                    Image(systemName: item.symbol)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(theme.accent)
                        .accessibilityHidden(true)
                }
                .padding(.top, 6)

                Text(item.title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(theme.ink)
                    .multilineTextAlignment(.center)
                Text(item.message)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.message)")
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingPage.allCases) { item in
                Capsule()
                    .fill(item == page ? theme.accent : theme.inkSoft.opacity(0.25))
                    .frame(width: item == page ? 18 : 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel("Page \(page.rawValue + 1) of \(OnboardingPage.allCases.count)")
    }

    private var decorativeBlooms: some View {
        ZStack {
            BloomMark(size: 88, petal: theme.accent)
                .opacity(0.18)
                .offset(x: -130, y: -280)
            BloomMark(size: 56, petal: GardenPalette.blossom)
                .opacity(0.22)
                .offset(x: 140, y: -220)
            BloomMark(size: 44, petal: GardenPalette.leaf)
                .opacity(0.18)
                .offset(x: 150, y: 260)
        }
        .allowsHitTesting(false)
    }

    private func advanceOrFinish() {
        if isLastPage {
            onFinished(.completed)
            return
        }
        guard let next = OnboardingPage(rawValue: page.rawValue + 1) else {
            onFinished(.completed)
            return
        }
        if reduceMotion {
            page = next
        } else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                page = next
            }
        }
    }
}
