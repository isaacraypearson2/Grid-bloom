import Foundation
import Combine
import GameKit

/// Local high scores plus optional Game Center. Classic and Daily never share a board.
@MainActor
final class LeaderboardService: NSObject, ObservableObject {
    static let shared = LeaderboardService()

    static let classicID = "gridbloom.classic.highscore"
    static let dailyID = "gridbloom.daily.highscore"

    @Published private(set) var isAuthenticated = false
    @Published private(set) var authMessage: String?
    /// Game Center friends lists need App Store Connect boards; until then we show local bests.
    @Published private(set) var friendsAvailable = false

    private let defaults: UserDefaults
    private var didStartAuth = false

    private enum Keys {
        static let classic = "gridbloom.leaderboard.classic"
        static let daily = "gridbloom.leaderboard.daily"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
    }

    func localBest(classic: Bool) -> Int {
        defaults.integer(forKey: classic ? Keys.classic : Keys.daily)
    }

    @discardableResult
    func recordLocal(score: Int, classic: Bool) -> Int {
        let key = classic ? Keys.classic : Keys.daily
        let next = max(defaults.integer(forKey: key), score)
        defaults.set(next, forKey: key)
        return next
    }

    func start() {
        guard !didStartAuth else { return }
        didStartAuth = true
        authenticate()
    }

    func submit(score: Int, mode: GameMode) {
        guard score > 0 else { return }
        switch mode {
        case .classic:
            recordLocal(score: score, classic: true)
            submitToGameCenter(score: score, leaderboardID: Self.classicID)
        case .daily:
            recordLocal(score: score, classic: false)
            submitToGameCenter(score: score, leaderboardID: Self.dailyID)
        case .stage:
            break
        }
    }

    private func authenticate() {
        let local = GKLocalPlayer.local
        local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if viewController != nil {
                    // Cloud / unit tests have no window to present the GC sign-in sheet.
                    self.authMessage = "Sign in to Game Center in Settings to share scores."
                    self.isAuthenticated = false
                    return
                }
                if let error {
                    self.authMessage = error.localizedDescription
                    self.isAuthenticated = false
                    return
                }
                self.isAuthenticated = local.isAuthenticated
                self.friendsAvailable = local.isAuthenticated
                if local.isAuthenticated {
                    self.authMessage = nil
                } else {
                    self.authMessage = "Game Center is optional. Local bests still save on this iPhone."
                }
            }
        }
    }

    private func submitToGameCenter(score: Int, leaderboardID: String) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { _ in }
    }
}
