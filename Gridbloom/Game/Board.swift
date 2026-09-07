import Foundation

struct ClearResult: Equatable, Sendable {
    var rows: [Int]
    var columns: [Int]
    var clearedCells: [GridPoint]

    var lineCount: Int { rows.count + columns.count }
    var cellsCleared: Int { clearedCells.count }
    var isEmpty: Bool { lineCount == 0 }

    static let empty = ClearResult(rows: [], columns: [], clearedCells: [])
}

/// Occupancy grid for the 8×8 puzzle. Row 0 is the top of the board.
struct Board: Equatable, Sendable {
    static let size = 8

    /// `cells[row][column]`. `0` is empty; positive values are piece color indexes + 1.
    private(set) var cells: [[Int]]

    init(filled: [[Int]]? = nil) {
        if let filled {
            precondition(filled.count == Board.size && filled.allSatisfy { $0.count == Board.size })
            cells = filled
        } else {
            cells = Array(repeating: Array(repeating: 0, count: Board.size), count: Board.size)
        }
    }

    var occupiedCount: Int {
        cells.reduce(0) { $0 + $1.filter { $0 != 0 }.count }
    }

    /// Fraction of cells that are occupied, 0...1.
    var occupancy: Double {
        Double(occupiedCount) / Double(Board.size * Board.size)
    }

    subscript(point: GridPoint) -> Int {
        cells[point.y][point.x]
    }

    func isInBounds(_ point: GridPoint) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < Board.size && point.y < Board.size
    }

    func isEmpty(at point: GridPoint) -> Bool {
        isInBounds(point) && cells[point.y][point.x] == 0
    }

    func canPlace(_ piece: Piece, at origin: GridPoint) -> Bool {
        piece.occupying(at: origin).allSatisfy { isEmpty(at: $0) }
    }

    func canPlaceAnywhere(_ piece: Piece) -> Bool {
        !possibleOrigins(for: piece).isEmpty
    }

    func possibleOrigins(for piece: Piece) -> [GridPoint] {
        var origins: [GridPoint] = []
        let maxX = Board.size - piece.width
        let maxY = Board.size - piece.height
        guard maxX >= 0, maxY >= 0 else { return [] }
        for y in 0...maxY {
            for x in 0...maxX {
                let origin = GridPoint(x: x, y: y)
                if canPlace(piece, at: origin) {
                    origins.append(origin)
                }
            }
        }
        return origins
    }

    /// True if at least one catalog piece can still be placed.
    func canPlaceAny(from catalog: [Piece]) -> Bool {
        catalog.contains { canPlaceAnywhere($0) }
    }

    mutating func place(_ piece: Piece, at origin: GridPoint) {
        precondition(canPlace(piece, at: origin), "Invalid placement")
        let value = piece.colorIndex + 1
        for point in piece.occupying(at: origin) {
            cells[point.y][point.x] = value
        }
    }

    /// Completes rows and columns in one pass. Intersection cells are counted once.
    mutating func clearCompletedLines() -> ClearResult {
        var rows: [Int] = []
        var columns: [Int] = []
        for y in 0..<Board.size where rowFilled(y) {
            rows.append(y)
        }
        for x in 0..<Board.size where columnFilled(x) {
            columns.append(x)
        }

        var cleared: [GridPoint] = []
        var seen = Set<GridPoint>()
        for y in rows {
            for x in 0..<Board.size {
                let point = GridPoint(x: x, y: y)
                if seen.insert(point).inserted {
                    cleared.append(point)
                }
                cells[y][x] = 0
            }
        }
        for x in columns {
            for y in 0..<Board.size {
                let point = GridPoint(x: x, y: y)
                if seen.insert(point).inserted {
                    cleared.append(point)
                }
                cells[y][x] = 0
            }
        }
        return ClearResult(rows: rows, columns: columns, clearedCells: cleared)
    }

    mutating func clearCells(_ points: [GridPoint]) {
        for point in points where isInBounds(point) {
            cells[point.y][point.x] = 0
        }
    }

    mutating func fill(_ point: GridPoint, value: Int) {
        precondition(isInBounds(point))
        cells[point.y][point.x] = value
    }

    mutating func fillRow(_ y: Int, value: Int = 1) {
        for x in 0..<Board.size {
            cells[y][x] = value
        }
    }

    mutating func fillColumn(_ x: Int, value: Int = 1) {
        for y in 0..<Board.size {
            cells[y][x] = value
        }
    }

    func occupiedPoints() -> [GridPoint] {
        var points: [GridPoint] = []
        for y in 0..<Board.size {
            for x in 0..<Board.size where cells[y][x] != 0 {
                points.append(GridPoint(x: x, y: y))
            }
        }
        return points
    }

    private func rowFilled(_ y: Int) -> Bool {
        cells[y].allSatisfy { $0 != 0 }
    }

    private func columnFilled(_ x: Int) -> Bool {
        (0..<Board.size).allSatisfy { cells[$0][x] != 0 }
    }
}
