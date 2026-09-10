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
