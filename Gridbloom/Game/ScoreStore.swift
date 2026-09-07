import Foundation

protocol ScorePersisting {
    func best(for mode: GameMode, utcDay: String?) -> Int
    @discardableResult
    func updateBest(for mode: GameMode, utcDay: String?, score: Int) -> Int
}

final class UserDefaultsScoreStore: ScorePersisting {
    private let defaults: UserDefaults
    private let classicKey = "gridbloom.best.classic"
    private let dailyPrefix = "gridbloom.best.daily."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func best(for mode: GameMode, utcDay: String?) -> Int {
        switch mode {
        case .classic:
            return defaults.integer(forKey: classicKey)
        case .daily:
            guard let utcDay else { return 0 }
            return defaults.integer(forKey: dailyPrefix + utcDay)
        }
    }

    @discardableResult
    func updateBest(for mode: GameMode, utcDay: String?, score: Int) -> Int {
        let current = best(for: mode, utcDay: utcDay)
        let next = max(current, score)
        switch mode {
        case .classic:
            defaults.set(next, forKey: classicKey)
        case .daily:
            if let utcDay {
                defaults.set(next, forKey: dailyPrefix + utcDay)
            }
        }
        return next
    }
}

final class InMemoryScoreStore: ScorePersisting {
    private var classic = 0
    private var daily: [String: Int] = [:]

    func best(for mode: GameMode, utcDay: String?) -> Int {
        switch mode {
        case .classic: return classic
        case .daily: return utcDay.flatMap { daily[$0] } ?? 0
        }
    }

    @discardableResult
    func updateBest(for mode: GameMode, utcDay: String?, score: Int) -> Int {
        switch mode {
        case .classic:
            classic = max(classic, score)
            return classic
        case .daily:
            let day = utcDay ?? ""
            daily[day] = max(daily[day] ?? 0, score)
            return daily[day] ?? score
        }
    }
}
