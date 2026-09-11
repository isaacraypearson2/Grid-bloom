import Foundation

/// Pure rules for Petal Catch so the SpriteKit scene stays thin.
enum PetalCatchRules {
    static let duration: TimeInterval = 22
    static let winCatches = 10
    static let spawnEvery: TimeInterval = 0.62
    static let fallDuration: TimeInterval = 2.4
}

/// Simon-style bloom memory. Sequences are seeded so tests can replay them.
struct PatternBloomGame {
    static let roundsToWin = 3
    static let palette: [FlowerSpecies] = [.tulip, .daisy, .rose, .lily]

    private(set) var roundIndex: Int
    private(set) var sequence: [FlowerSpecies]
    private(set) var input: [FlowerSpecies]
    private(set) var isWon: Bool
    private(set) var isFailed: Bool
    private var rng: SplitMix64

    init(seed: UInt64, roundIndex: Int = 0) {
        self.rng = SplitMix64(seed: seed)
        self.roundIndex = roundIndex
        self.sequence = []
        self.input = []
        self.isWon = false
        self.isFailed = false
        dealRound()
    }

    var length: Int { 3 + roundIndex }

    mutating func tap(_ species: FlowerSpecies) -> PatternBloomTapResult {
        guard !isWon, !isFailed else { return .ignored }
        input.append(species)
        let idx = input.count - 1
        guard sequence.indices.contains(idx), sequence[idx] == species else {
            isFailed = true
            return .wrong
        }
        if input.count == sequence.count {
            if roundIndex + 1 >= Self.roundsToWin {
                isWon = true
                return .won
            }
            roundIndex += 1
            dealRound()
            return .roundClear
        }
        return .correct
    }

    mutating func retry() {
        isFailed = false
        input = []
        // Keep the same round sequence so a miss is fair to retry.
    }

    private mutating func dealRound() {
        input = []
        sequence = (0..<length).map { _ in
            Self.palette[rng.int(in: 0..<Self.palette.count)]
        }
    }
}

enum PatternBloomTapResult: Equatable {
    case ignored
    case correct
    case roundClear
    case won
    case wrong
}

/// Faster sequence game: a bee visits blooms; tap them in order before the timer wilts.
struct BeeTrailGame {
    static let roundsToWin = 3
    static let palette: [FlowerSpecies] = [.tulip, .daisy, .rose, .lily, .lavender, .hydrangea]
    static let secondsPerTap: TimeInterval = 1.15

    private(set) var roundIndex: Int
    private(set) var sequence: [FlowerSpecies]
    private(set) var inputCount: Int
    private(set) var isWon: Bool
    private(set) var isFailed: Bool
    private var rng: SplitMix64

    init(seed: UInt64, roundIndex: Int = 0) {
        self.rng = SplitMix64(seed: seed)
        self.roundIndex = roundIndex
        self.sequence = []
        self.inputCount = 0
        self.isWon = false
        self.isFailed = false
        dealRound()
    }

    var length: Int { 4 + roundIndex }
    var timeLimit: TimeInterval { Double(length) * Self.secondsPerTap }
    var nextSpecies: FlowerSpecies? {
        guard sequence.indices.contains(inputCount) else { return nil }
        return sequence[inputCount]
    }

    mutating func tap(_ species: FlowerSpecies) -> PatternBloomTapResult {
        guard !isWon, !isFailed else { return .ignored }
        guard let expected = nextSpecies else { return .ignored }
        if species != expected {
            isFailed = true
            return .wrong
        }
        inputCount += 1
        if inputCount == sequence.count {
            if roundIndex + 1 >= Self.roundsToWin {
                isWon = true
                return .won
            }
            roundIndex += 1
            dealRound()
            return .roundClear
        }
        return .correct
    }

    mutating func timeout() {
        guard !isWon, !isFailed else { return }
        isFailed = true
    }

    mutating func retry() {
        isFailed = false
        inputCount = 0
    }

    private mutating func dealRound() {
        inputCount = 0
        sequence = (0..<length).map { _ in
            Self.palette[rng.int(in: 0..<Self.palette.count)]
        }
    }
}

/// Memory pairs of species × color. Win by matching every pair under the mismatch cap.
struct BloomMatchGame {
    static let pairCount = 6
    static let mismatchLimit = 8
    struct Card: Equatable, Identifiable {
        var id: Int
        var species: FlowerSpecies
        var color: BloomColor
    }

    private(set) var cards: [Card]
    private(set) var revealed: [Int]
    private(set) var matched: Set<Int>
    private(set) var mismatches: Int
    private(set) var isWon: Bool
    private(set) var isFailed: Bool
    private var rng: SplitMix64

    init(seed: UInt64) {
        self.rng = SplitMix64(seed: seed)
        self.cards = []
        self.revealed = []
        self.matched = []
        self.mismatches = 0
        self.isWon = false
        self.isFailed = false
        deal()
    }

    var remainingMismatches: Int { max(0, Self.mismatchLimit - mismatches) }

    mutating func flip(_ index: Int) -> BloomMatchFlip {
        guard !isWon, !isFailed else { return .ignored }
        guard cards.indices.contains(index) else { return .ignored }
        guard !matched.contains(index), !revealed.contains(index) else { return .ignored }
        if revealed.count == 2 { revealed = [] }
        revealed.append(index)
        if revealed.count < 2 { return .revealed }
        let a = cards[revealed[0]]
        let b = cards[revealed[1]]
        if a.species == b.species, a.color == b.color {
            matched.insert(revealed[0])
            matched.insert(revealed[1])
            revealed = []
            if matched.count == cards.count {
                isWon = true
                return .matchedWon
            }
            return .matched
        }
        mismatches += 1
        if mismatches >= Self.mismatchLimit {
            isFailed = true
            return .mismatchFailed
        }
        return .mismatch
    }

    mutating func hideMismatch() {
        guard revealed.count == 2 else { return }
        let a = cards[revealed[0]]
        let b = cards[revealed[1]]
        if a.species != b.species || a.color != b.color {
            revealed = []
        }
    }

    mutating func retry() {
        isFailed = false
        isWon = false
        mismatches = 0
        revealed = []
        matched = []
        deal()
    }

    private mutating func deal() {
        let pairs: [(FlowerSpecies, BloomColor)] = [
            (.tulip, .pink), (.daisy, .yellow), (.rose, .red),
            (.lily, .white), (.lavender, .lavender), (.hydrangea, .blue)
        ]
        var deck: [Card] = []
        for (i, pair) in pairs.enumerated() {
            deck.append(Card(id: i * 2, species: pair.0, color: pair.1))
            deck.append(Card(id: i * 2 + 1, species: pair.0, color: pair.1))
        }
        for i in stride(from: deck.count - 1, through: 1, by: -1) {
            let j = rng.int(in: 0..<i + 1)
            deck.swapAt(i, j)
        }
        cards = deck
    }
}

enum BloomMatchFlip: Equatable {
    case ignored
    case revealed
    case matched
    case matchedWon
    case mismatch
    case mismatchFailed
}
