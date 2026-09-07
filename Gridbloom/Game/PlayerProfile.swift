import Foundation
import Combine

/// Local profile: lifetime stats plus a UTC daily streak.
final class PlayerProfile: ObservableObject {
    static let shared = PlayerProfile()

    @Published private(set) var gamesPlayed: Int
    @Published private(set) var linesCleared: Int
    @Published private(set) var bestCombo: Int
    @Published private(set) var dailyStreak: Int
    @Published private(set) var longestDailyStreak: Int
    @Published private(set) var lastDailyPlayDay: String?

    private let defaults: UserDefaults

    private enum Keys {
        static let games = "gridbloom.profile.games"
        static let lines = "gridbloom.profile.lines"
        static let combo = "gridbloom.profile.combo"
        static let streak = "gridbloom.profile.streak"
        static let longest = "gridbloom.profile.longestStreak"
        static let lastDaily = "gridbloom.profile.lastDaily"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        gamesPlayed = defaults.integer(forKey: Keys.games)
        linesCleared = defaults.integer(forKey: Keys.lines)
        bestCombo = defaults.integer(forKey: Keys.combo)
        dailyStreak = defaults.integer(forKey: Keys.streak)
        longestDailyStreak = defaults.integer(forKey: Keys.longest)
        lastDailyPlayDay = defaults.string(forKey: Keys.lastDaily)
    }

    var playedDailyToday: Bool {
        lastDailyPlayDay == DailySeed.utcDayString()
    }

    func recordGameStarted() {
        gamesPlayed += 1
        defaults.set(gamesPlayed, forKey: Keys.games)
    }

    func record(lines: Int, combo: Int) {
        if lines > 0 {
            linesCleared += lines
            defaults.set(linesCleared, forKey: Keys.lines)
        }
        if combo > bestCombo {
            bestCombo = combo
            defaults.set(bestCombo, forKey: Keys.combo)
        }
    }

    func recordDailyPlay(utcDay: String) {
        let next = Self.streakAfterPlay(
            lastDay: lastDailyPlayDay,
            streak: dailyStreak,
            today: utcDay
        )
        lastDailyPlayDay = utcDay
        dailyStreak = next
        longestDailyStreak = max(longestDailyStreak, next)
        defaults.set(utcDay, forKey: Keys.lastDaily)
        defaults.set(dailyStreak, forKey: Keys.streak)
        defaults.set(longestDailyStreak, forKey: Keys.longest)
    }

    /// Pure streak rules: same day keeps the count; consecutive UTC day increments; a gap resets to 1.
    static func streakAfterPlay(lastDay: String?, streak: Int, today: String) -> Int {
        guard let lastDay else { return 1 }
        if lastDay == today { return max(1, streak) }
        if isNextUTCDay(after: lastDay, today: today) {
            return streak + 1
        }
        return 1
    }

    static func isNextUTCDay(after previous: String, today: String) -> Bool {
        guard let prev = parseUTC(previous), let now = parseUTC(today) else { return false }
        let next = prev.addingTimeInterval(24 * 60 * 60)
        return DailySeed.utcDayString(from: next) == DailySeed.utcDayString(from: now)
    }

    private static func parseUTC(_ day: String) -> Date? {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "GMT") ?? .current
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
