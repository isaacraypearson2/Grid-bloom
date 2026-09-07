import Foundation
import Combine

enum GameMode: String, Equatable, Sendable {
    case classic
    case daily
}

struct PlaceResult: Equatable {
    var trayIndex: Int
    var origin: GridPoint
    var placedCells: [GridPoint]
    var clear: ClearResult
    var scoreDelta: Int
    var combo: Int
    var trayRefilled: Bool
    var isGameOver: Bool
}

/// Mutable match: board, tray of three, score, combo, and game-over.
final class GameState: ObservableObject {
    let mode: GameMode
    let utcDay: String?

    @Published private(set) var board: Board
    @Published private(set) var tray: [Piece?]
    @Published private(set) var score: Int = 0
    @Published private(set) var combo: Int = 0
    @Published private(set) var bestScore: Int = 0
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var lastPlace: PlaceResult?
    /// Increments whenever a combo ≥ 2 lands, so SwiftUI can play a banner.
    @Published private(set) var bloomPulse: Int = 0
    @Published private(set) var lastBloomCombo: Int = 0

    private var dealer: FairDealer
    private let scoreStore: ScorePersisting

    init(
        mode: GameMode,
        utcDay: String? = nil,
        now: Date = Date(),
        scoreStore: ScorePersisting? = nil,
        rng: SplitMix64? = nil,
        board: Board = Board(),
        tray: [Piece?]? = nil,
        dealOnStart: Bool = true
    ) {
        self.mode = mode
        let day = utcDay ?? (mode == .daily ? DailySeed.utcDayString(from: now) : nil)
        self.utcDay = day
        self.board = board
        self.tray = tray ?? [nil, nil, nil]
        self.scoreStore = scoreStore ?? UserDefaultsScoreStore()
        let seed: UInt64
        if let rng {
            self.dealer = FairDealer(rng: rng)
        } else {
            switch mode {
            case .daily:
                seed = DailySeed.seed(fromUTCDay: day ?? DailySeed.utcDayString(from: now))
            case .classic:
                seed = DailySeed.classicLaunchSeed(from: now)
            }
            self.dealer = FairDealer(rng: SplitMix64(seed: seed))
        }
        self.bestScore = self.scoreStore.best(for: mode, utcDay: day)
        if dealOnStart, tray == nil {
            dealTray()
            refreshGameOver()
        }
    }

    var remainingPieces: [Piece] {
        tray.compactMap { $0 }
    }

    var traySignatures: [String] {
        tray.map { $0?.catalogID ?? "-" }
    }

    func canPlace(_ piece: Piece, at origin: GridPoint) -> Bool {
        board.canPlace(piece, at: origin)
    }

    func canPlaceAnywhere(_ piece: Piece) -> Bool {
        board.canPlaceAnywhere(piece)
    }

    @discardableResult
    func place(trayIndex: Int, at origin: GridPoint) -> PlaceResult? {
        guard !isGameOver else { return nil }
        guard tray.indices.contains(trayIndex), let piece = tray[trayIndex] else { return nil }
        guard board.canPlace(piece, at: origin) else { return nil }

        let placedCells = piece.occupying(at: origin)
        board.place(piece, at: origin)
        tray[trayIndex] = nil

        let clear = board.clearCompletedLines()
        combo = Scoring.nextCombo(current: combo, didClear: !clear.isEmpty)
        let delta = Scoring.totalScore(
            cellCount: piece.cellCount,
            lineCount: clear.lineCount,
            comboAfterMove: combo
        )
        score += delta
        bestScore = scoreStore.updateBest(for: mode, utcDay: utcDay, score: score)

        if combo >= 2 {
            lastBloomCombo = combo
            bloomPulse += 1
        }

        var refilled = false
        if tray.allSatisfy({ $0 == nil }) {
            dealTray()
            refilled = true
        }

        refreshGameOver()

        let result = PlaceResult(
            trayIndex: trayIndex,
            origin: origin,
            placedCells: placedCells,
            clear: clear,
            scoreDelta: delta,
            combo: combo,
            trayRefilled: refilled,
            isGameOver: isGameOver
        )
        lastPlace = result
        return result
    }

    func restart() {
        board = Board()
        tray = [nil, nil, nil]
        score = 0
        combo = 0
        isGameOver = false
        lastPlace = nil
        lastBloomCombo = 0
        // Keep the daily seed so Today's Bloom is a fresh run of the same deal sequence.
        if mode == .daily, let utcDay {
            dealer = FairDealer(rng: SplitMix64(seed: DailySeed.seed(fromUTCDay: utcDay)))
        } else {
            dealer = FairDealer(rng: SplitMix64(seed: DailySeed.classicLaunchSeed()))
        }
        bestScore = scoreStore.best(for: mode, utcDay: utcDay)
        dealTray()
        refreshGameOver()
    }

    /// Rewarded-continue payload: clear a handful of occupied cells and refill the tray.
    func applyRewardedContinue(clearedCellCount: Int = 8) {
        var rng = dealer.rng
        let occupied = board.occupiedPoints().shuffled(using: &rng)
        dealer.rng = rng
        let toClear = Array(occupied.prefix(clearedCellCount))
        board.clearCells(toClear)
        combo = 0
        isGameOver = false
        dealTray()
        refreshGameOver()
    }

    /// Rewarded tray shuffle: replace remaining pieces with a freshly dealt tray.
    func applyRewardedShuffle() {
        dealTray()
        if remainingPieces.contains(where: { board.canPlaceAnywhere($0) }) {
            isGameOver = false
        } else {
            refreshGameOver()
        }
    }

    func dealTray() {
        tray = dealer.dealTray(on: board).map { Optional($0) }
    }

    func refreshGameOver() {
        let remaining = remainingPieces
        isGameOver = remaining.isEmpty || remaining.allSatisfy { !board.canPlaceAnywhere($0) }
    }

    // MARK: - Test helpers

    func replaceBoard(_ newBoard: Board) {
        board = newBoard
    }

    func replaceTray(_ pieces: [Piece?]) {
        precondition(pieces.count == 3)
        tray = pieces
    }

    func setCombo(_ value: Int) {
        combo = value
    }
}
