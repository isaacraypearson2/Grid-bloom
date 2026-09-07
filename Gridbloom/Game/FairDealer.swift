import Foundation

/// Deals trays of three pieces. High occupancy down-weights bulky pentominoes;
/// trays are regenerated until at least one piece fits whenever that is possible.
struct FairDealer {
    var rng: SplitMix64
    var catalog: [Piece]
    var maxRegenerateAttempts = 80

    init(rng: SplitMix64, catalog: [Piece] = PieceCatalog.all) {
        self.rng = rng
        self.catalog = catalog
    }

    mutating func dealTray(on board: Board) -> [Piece] {
        if !board.canPlaceAny(from: catalog) {
            return randomTray(on: board)
        }

        for _ in 0..<maxRegenerateAttempts {
            let tray = randomTray(on: board)
            if tray.contains(where: { board.canPlaceAnywhere($0) }) {
                return tray
            }
        }

        return guaranteedFitTray(on: board)
    }

    mutating func randomTray(on board: Board) -> [Piece] {
        (0..<3).map { _ in pickWeighted(occupancy: board.occupancy).spawned() }
    }

    mutating func pickWeighted(occupancy: Double) -> Piece {
        let weights = catalog.map { weight(for: $0, occupancy: occupancy) }
        let index = weightedIndex(weights: weights)
        return catalog[index]
    }

    /// Trominoes keep full weight; tetrominoes and pentominoes fall off as the board fills.
    func weight(for piece: Piece, occupancy: Double) -> Double {
        let bulkFactor = (Double(piece.cellCount) - 3.0) / 2.0
        let clampedBulk = min(1.0, max(0.0, bulkFactor))
        return max(0.05, 1.0 - occupancy * 0.85 * clampedBulk)
    }

    private mutating func guaranteedFitTray(on board: Board) -> [Piece] {
        let fitting = catalog.filter { board.canPlaceAnywhere($0) }
        guard let first = fitting.randomElement(using: &rng) else {
            return randomTray(on: board)
        }
        let second = pickWeighted(occupancy: board.occupancy)
        let third = pickWeighted(occupancy: board.occupancy)
        return [first.spawned(), second.spawned(), third.spawned()]
    }

    private mutating func weightedIndex(weights: [Double]) -> Int {
        let total = weights.reduce(0, +)
        guard total > 0 else { return rng.int(in: 0..<weights.count) }
        var ticket = rng.unitDouble() * total
        for (index, weight) in weights.enumerated() {
            ticket -= weight
            if ticket <= 0 {
                return index
            }
        }
        return weights.count - 1
    }
}
