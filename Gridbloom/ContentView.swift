import SwiftUI

enum AppRoute: Equatable {
    case menu
    case play(GameMode)
}

struct ContentView: View {
    @State private var route: AppRoute = .menu
    private let scoreStore = UserDefaultsScoreStore()

    var body: some View {
        ZStack {
            switch route {
            case .menu:
                MainMenuView(
                    classicBest: scoreStore.best(for: .classic, utcDay: nil),
                    dailyBest: scoreStore.best(for: .daily, utcDay: DailySeed.utcDayString()),
                    utcDay: DailySeed.utcDayString(),
                    onPlayClassic: { route = .play(.classic) },
                    onPlayDaily: { route = .play(.daily) }
                )
                .transition(.opacity)
            case .play(let mode):
                GameView(mode: mode, onExit: { route = .menu })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: route)
        .preferredColorScheme(.light)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
