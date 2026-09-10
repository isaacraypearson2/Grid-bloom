import Foundation

/// Integer board coordinate. `x` is column (0 is left), `y` is row (0 is top).
struct GridPoint: Hashable, Equatable, Sendable {
    var x: Int
    var y: Int

    static func + (lhs: GridPoint, rhs: GridPoint) -> GridPoint {
        GridPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}

/// A single polyomino. Pieces never rotate at play time; each orientation is a distinct catalog entry.
struct Piece: Identifiable, Equatable, Sendable {
    let id: UUID
    /// Stable shape key, e.g. `T4_0`, used for daily-run comparisons.
    let catalogID: String
    /// Cell offsets, normalized so the bounding box origin is (0, 0).
    let cells: [GridPoint]
    /// Palette slot; flower identity is the primary tile read.
    let colorIndex: Int
    let flower: FlowerSpecies
    /// Scanned bloom, if this piece is a photo stamp instead of a catalog glyph.
    let customBloomID: UUID?
    let customStorageSlot: Int?

    var cellCount: Int { cells.count }

    var storageValue: Int {
        if let customStorageSlot {
            return CustomBloom.storageBase + customStorageSlot
        }
        return flower.rawValue
    }

    var width: Int {
        (cells.map(\.x).max() ?? 0) + 1
    }

    var height: Int {
        (cells.map(\.y).max() ?? 0) + 1
    }

    func occupying(at origin: GridPoint) -> [GridPoint] {
        cells.map { origin + $0 }
    }

    /// New instance with a unique id (used when dealing from the catalog).
    func spawned(
        id: UUID = UUID(),
        flower: FlowerSpecies? = nil,
        customBloomID: UUID? = nil,
        customStorageSlot: Int? = nil
    ) -> Piece {
        Piece(
            id: id,
            catalogID: catalogID,
            cells: cells,
            colorIndex: colorIndex,
            flower: flower ?? self.flower,
            customBloomID: customBloomID ?? self.customBloomID,
            customStorageSlot: customStorageSlot ?? self.customStorageSlot
        )
    }

    static func == (lhs: Piece, rhs: Piece) -> Bool {
        lhs.id == rhs.id
    }
}
