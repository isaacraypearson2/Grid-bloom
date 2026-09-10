import Foundation

/// One rotating daily chore. Progress is UTC-day scoped and auto-claimed.
struct DailyGoal: Equatable, Identifiable, Sendable {
    enum Kind: String, Equatable, Sendable {
        case lines
        case combo
        case score
        case petalCatch
    }

    let id: String
    let title: String
    let detail: String
    let target: Int
    let rewardPetals: Int
    let kind: Kind
}

enum DailyGoalCatalog {
    private static let pool: [DailyGoal] = [
        DailyGoal(id: "lines-6", title: "Trim the beds", detail: "Clear 6 lines", target: 6, rewardPetals: 8, kind: .lines),
        DailyGoal(id: "lines-10", title: "Full sweep", detail: "Clear 10 lines", target: 10, rewardPetals: 12, kind: .lines),
        DailyGoal(id: "combo-3", title: "Bloom chain", detail: "Hit Bloom x3", target: 3, rewardPetals: 10, kind: .combo),
        DailyGoal(id: "combo-4", title: "Garden rush", detail: "Hit Bloom x4", target: 4, rewardPetals: 14, kind: .combo),
        DailyGoal(id: "score-50", title: "Morning score", detail: "Score 50 in a run", target: 50, rewardPetals: 8, kind: .score),
        DailyGoal(id: "score-90", title: "Show bloom", detail: "Score 90 in a run", target: 90, rewardPetals: 12, kind: .score),
        DailyGoal(id: "catch-8", title: "Petal practice", detail: "Catch 8 petals", target: 8, rewardPetals: 8, kind: .petalCatch)
    ]

    /// Three goals, stable for a UTC day.
    static func goals(utcDay: String) -> [DailyGoal] {
        var rng = SplitMix64(seed: DailySeed.fnv1a64(utcDay + "|gridbloom.goals.v1"))
        var remaining = pool
        var picked: [DailyGoal] = []
        for _ in 0..<3 where !remaining.isEmpty {
            let index = rng.int(in: 0..<remaining.count)
            picked.append(remaining.remove(at: index))
        }
        return picked
    }
}

struct DailyGoalProgress: Equatable, Codable, Sendable {
    var utcDay: String
    var values: [String: Int]
    var claimed: [String]

    init(utcDay: String, values: [String: Int] = [:], claimed: [String] = []) {
        self.utcDay = utcDay
        self.values = values
        self.claimed = claimed
    }

    func value(for goal: DailyGoal) -> Int {
        min(goal.target, values[goal.id] ?? 0)
    }

    func isClaimed(_ goal: DailyGoal) -> Bool {
        claimed.contains(goal.id)
    }

    func isComplete(_ goal: DailyGoal) -> Bool {
        value(for: goal) >= goal.target
    }
}
