import Foundation

/// Tromino / tetromino / pentomino mix. Each orientation is listed separately (no in-game rotation).
enum PieceCatalog {
    static let all: [Piece] = trominoes + tetrominoes + pentominoes

    static let trominoes: [Piece] = [
        make("I3_h", [(0, 0), (1, 0), (2, 0)], 0),
        make("I3_v", [(0, 0), (0, 1), (0, 2)], 0),
        make("L3_0", [(0, 0), (0, 1), (1, 0)], 1),
        make("L3_1", [(0, 0), (1, 0), (1, 1)], 1),
        make("L3_2", [(1, 0), (0, 1), (1, 1)], 1),
        make("L3_3", [(0, 0), (0, 1), (1, 1)], 1)
    ]

    static let tetrominoes: [Piece] = [
        make("I4_h", [(0, 0), (1, 0), (2, 0), (3, 0)], 2),
        make("I4_v", [(0, 0), (0, 1), (0, 2), (0, 3)], 2),
        make("O4", [(0, 0), (1, 0), (0, 1), (1, 1)], 3),
        make("T4_0", [(0, 0), (1, 0), (2, 0), (1, 1)], 4),
        make("T4_1", [(1, 0), (0, 1), (1, 1), (1, 2)], 4),
        make("T4_2", [(1, 0), (0, 1), (1, 1), (2, 1)], 4),
        make("T4_3", [(0, 0), (0, 1), (1, 1), (0, 2)], 4),
        make("L4_0", [(0, 0), (0, 1), (0, 2), (1, 2)], 5),
        make("L4_1", [(0, 0), (1, 0), (2, 0), (0, 1)], 5),
        make("L4_2", [(0, 0), (1, 0), (1, 1), (1, 2)], 5),
        make("L4_3", [(2, 0), (0, 1), (1, 1), (2, 1)], 5),
        make("J4_0", [(1, 0), (1, 1), (0, 2), (1, 2)], 6),
        make("J4_1", [(0, 0), (0, 1), (1, 1), (2, 1)], 6),
        make("J4_2", [(0, 0), (1, 0), (0, 1), (0, 2)], 6),
        make("J4_3", [(0, 0), (1, 0), (2, 0), (2, 1)], 6),
        make("S4_0", [(1, 0), (2, 0), (0, 1), (1, 1)], 7),
        make("S4_1", [(0, 0), (0, 1), (1, 1), (1, 2)], 7),
        make("Z4_0", [(0, 0), (1, 0), (1, 1), (2, 1)], 8),
        make("Z4_1", [(1, 0), (0, 1), (1, 1), (0, 2)], 8)
    ]

    static let pentominoes: [Piece] = [
        make("I5_h", [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)], 0),
        make("I5_v", [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)], 0),
        make("X5", [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)], 1),
        make("U5_0", [(0, 0), (2, 0), (0, 1), (1, 1), (2, 1)], 2),
        make("U5_1", [(0, 0), (1, 0), (1, 1), (0, 2), (1, 2)], 2),
        make("V5_0", [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)], 3),
        make("V5_1", [(2, 0), (2, 1), (0, 2), (1, 2), (2, 2)], 3),
        make("W5_0", [(0, 0), (0, 1), (1, 1), (1, 2), (2, 2)], 4),
        make("W5_1", [(2, 0), (1, 1), (2, 1), (0, 2), (1, 2)], 4),
        make("P5_0", [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2)], 5),
        make("P5_1", [(0, 0), (1, 0), (2, 0), (1, 1), (2, 1)], 5),
        make("T5_0", [(0, 0), (1, 0), (2, 0), (1, 1), (1, 2)], 6),
        make("T5_1", [(2, 0), (0, 1), (1, 1), (2, 1), (2, 2)], 6),
        make("L5_0", [(0, 0), (0, 1), (0, 2), (0, 3), (1, 3)], 7),
        make("L5_1", [(0, 0), (1, 0), (2, 0), (3, 0), (0, 1)], 7),
        make("Y5_0", [(0, 1), (1, 0), (1, 1), (1, 2), (1, 3)], 8),
        make("Y5_1", [(0, 0), (1, 0), (2, 0), (3, 0), (2, 1)], 8),
        make("N5_0", [(1, 0), (0, 1), (1, 1), (0, 2), (0, 3)], 0),
        make("F5_0", [(1, 0), (2, 0), (0, 1), (1, 1), (1, 2)], 1)
    ]

    /// Stable placeholder so catalog templates are comparable; each deal clones via `spawned()`.
    private static let templateID = UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID()

    private static func make(_ id: String, _ cells: [(Int, Int)], _ color: Int) -> Piece {
        let points = cells.map { GridPoint(x: $0.0, y: $0.1) }
        return Piece(id: templateID, catalogID: id, cells: points, colorIndex: color)
    }

    static func piece(catalogID: String) -> Piece? {
        all.first { $0.catalogID == catalogID }
    }
}
