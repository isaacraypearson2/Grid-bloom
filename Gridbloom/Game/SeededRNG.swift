import Foundation

/// Deterministic RNG used for classic seeds and UTC daily deals.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }

    mutating func int(in range: Range<Int>) -> Int {
        Int.random(in: range, using: &self)
    }

    mutating func unitDouble() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}

enum DailySeed {
    /// `yyyy-MM-dd` in UTC.
    static func utcDayString(from date: Date = Date()) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(identifier: "GMT") ?? .current
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func seed(fromUTCDay day: String) -> UInt64 {
        fnv1a64(day + "|gridbloom.daily.v1")
    }

    static func classicLaunchSeed(from date: Date = Date()) -> UInt64 {
        UInt64(date.timeIntervalSinceReferenceDate * 1000)
    }

    static func fnv1a64(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
