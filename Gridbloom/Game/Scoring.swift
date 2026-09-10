import Foundation

/// Placement + line-clear scoring with a consecutive-clear combo ("Bloom xN").
enum Scoring {
    static let pointsPerCell = 1
    static let pointsPerLine = 10

    static func placementScore(cellCount: Int) -> Int {
        cellCount * pointsPerCell
    }

    /// Uses the combo value *after* the current clear (1 for the first clear in a chain).
    static func clearScore(lineCount: Int, combo: Int) -> Int {
        guard lineCount > 0, combo > 0 else { return 0 }
        return lineCount * pointsPerLine * combo
    }

    static func totalScore(cellCount: Int, lineCount: Int, comboAfterMove: Int) -> Int {
        placementScore(cellCount: cellCount) + clearScore(lineCount: lineCount, combo: comboAfterMove)
    }

    /// Consecutive placements that clear at least one line increment combo.
    /// A placement with no clear resets combo to 0.
    static func nextCombo(current: Int, didClear: Bool) -> Int {
        didClear ? current + 1 : 0
    }

    /// Soft currency: 1 petal per line, plus a small combo bonus. Never the only path to fun.
    static func petals(lineCount: Int, combo: Int) -> Int {
        guard lineCount > 0 else { return 0 }
        return lineCount + max(0, combo - 1)
    }

    /// Ultra grid-wipe bonus. Extra cells that were not part of a completed line.
    static func ultraWipeBonus(combo: Int, extraCells: Int) -> Int {
        40 * max(1, combo) + max(0, extraCells)
    }
}
