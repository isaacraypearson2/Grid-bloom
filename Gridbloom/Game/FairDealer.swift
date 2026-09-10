import Foundation

/// Deals trays of three pieces. High occupancy down-weights bulky pentominoes;
/// opening trays bias smaller shapes so early games feel fair.
struct FairDealer {
    var rng: SplitMix64
    var catalog: [Piece]
    var maxRegenerateAttempts = 40
    /// Trays already dealt this run. Opening grace uses this, not occupancy alone.
    var traysDealt = 0
    var openingGraceTrays = 5
    /// Flowers the dealer may stamp onto pieces. Daily Bloom should pass starters only.
    var flowerRoster: Set<FlowerSpecies> = Set(FlowerSpecies.starters)
    /// Classic-only scanned blooms. Empty for Today’s Bloom so UTC deals stay stable.
    var customBlooms: [CustomBloom] = []

    init(rng: SplitMix64, catalog: [Piece] = PieceCatalog.all) {
        self.rng = rng
        self.catalog = catalog
    }

    mutating func dealTray(on board: Board) -> [Piece] {
        defer { traysDealt += 1 }
        let desiredFits = traysDealt < openingGraceTrays ? 2 : 1

        if !board.canPlaceAny(from: catalog) {
            return randomTray(on: board)
        }

        var best: [Piece] = []
        var bestFits = -1
        for _ in 0..<maxRegenerateAttempts {
            let tray = randomTray(on: board)
            if traysDealt < openingGraceTrays, tray.allSatisfy({ $0.cellCount >= 5 }) {
                continue
            }
            let fits = tray.filter { board.canPlaceAnywhere($0) }.count
            if fits > bestFits {
                best = tray
                bestFits = fits
            }
            if fits >= desiredFits {
                return tray
            }
        }

        if bestFits > 0 {
            return best
        }
        return guaranteedFitTray(on: board)
    }

    mutating func randomTray(on board: Board) -> [Piece] {
        (0..<3).map { _ in stamp(pickWeighted(occupancy: board.occupancy)) }
    }

    mutating func pickWeighted(occupancy: Double) -> Piece {
        guard !catalog.isEmpty else {
            return Piece(
                id: UUID(),
                catalogID: "empty",
                cells: [GridPoint(x: 0, y: 0)],
                colorIndex: 0,
                flower: .tulip,
                customBloomID: nil,
                customStorageSlot: nil
            )
        }
        let weights = catalog.map { weight(for: $0, occupancy: occupancy) }
        let index = weightedIndex(weights: weights)
        guard catalog.indices.contains(index) else { return catalog[0] }
        return catalog[index]
    }

    func occupancyWeight(for piece: Piece, occupancy: Double) -> Double {
        let bulkFactor = (Double(piece.cellCount) - 3.0) / 2.0
        let clampedBulk = min(1.0, max(0.0, bulkFactor))
        return max(0.05, 1.0 - occupancy * 0.85 * clampedBulk)
    }

    /// Occupancy curve plus an opening-game nudge toward trominoes.
    func weight(for piece: Piece, occupancy: Double) -> Double {
        occupancyWeight(for: piece, occupancy: occupancy) * openingMultiplier(for: piece)
    }

    func openingMultiplier(for piece: Piece) -> Double {
        let early = max(0, 1.0 - Double(traysDealt) / Double(openingGraceTrays))
        if piece.cellCount <= 3 {
            return 1.0 + early * 0.85
        }
        if piece.cellCount >= 5 {
            return 1.0 - early * 0.65
        }
        return 1.0 + early * 0.12
    }

    private mutating func guaranteedFitTray(on board: Board) -> [Piece] {
        let fitting = catalog.filter { board.canPlaceAnywhere($0) }
        guard let first = fitting.randomElement(using: &rng) else {
            return randomTray(on: board)
        }
        let second = pickWeighted(occupancy: board.occupancy)
        let third = pickWeighted(occupancy: board.occupancy)
        return [stamp(first), stamp(second), stamp(third)]
    }

    private func stamp(_ piece: Piece) -> Piece {
        let flower = FlowerSpecies.playable(at: piece.colorIndex, unlocked: flowerRoster)
        return overlayCustom(overlayUltra(piece.spawned(flower: flower)))
    }

    /// Classic-only ultras, derived from colorIndex — no extra RNG.
    func overlayUltra(_ piece: Piece) -> Piece {
        guard piece.customBloomID == nil, piece.flower.rarity != .ultra else { return piece }
        let ultras = flowerRoster.filter { $0.rarity == .ultra }.sorted { $0.rawValue < $1.rawValue }
        guard !ultras.isEmpty, piece.colorIndex % 4 == 1 else { return piece }
        return piece.spawned(flower: ultras[abs(piece.colorIndex) % ultras.count])
    }

    /// Applies a scanned stamp from `colorIndex` with no extra RNG.
    /// Used to restamp an already-dealt opening tray after the profile attaches.
    func overlayCustom(_ piece: Piece) -> Piece {
        guard piece.customBloomID == nil, !customBlooms.isEmpty, piece.colorIndex % 3 == 0 else {
            return piece
        }
        let bloom = customBlooms[abs(piece.colorIndex) % customBlooms.count]
        return piece.spawned(
            flower: bloom.guessedSpecies ?? piece.flower,
            customBloomID: bloom.id,
            customStorageSlot: bloom.slot
        )
    }

    private mutating func weightedIndex(weights: [Double]) -> Int {
        guard !weights.isEmpty else { return 0 }
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
