import Foundation
import Combine

enum GameMode: Equatable, Hashable, Sendable {
    case classic
    case daily
    case stage(String)
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
    var didUltraWipe: Bool
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
    @Published private(set) var continuesUsed: Int = 0
    @Published private(set) var linesClearedThisRun: Int = 0
    @Published private(set) var lastRunRewards: RunScoreRewards?

    static let maxContinuesPerRun = 1

    private var dealer: FairDealer
    private let scoreStore: ScorePersisting
    private var profile: PlayerProfile?
    private var didRecordSessionStart = false
    private var resolvedScoreRungs: Set<Int> = []
    private var didGrantOrganicThisRun = false

    init(
        mode: GameMode,
        utcDay: String? = nil,
        now: Date = Date(),
        scoreStore: ScorePersisting? = nil,
        profile: PlayerProfile? = nil,
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
        self.profile = profile
        let seed: UInt64
        if let rng {
            self.dealer = FairDealer(rng: rng)
        } else {
            switch mode {
            case .daily:
                seed = DailySeed.seed(fromUTCDay: day ?? DailySeed.utcDayString(from: now))
            case .classic, .stage:
                seed = DailySeed.classicLaunchSeed(from: now)
            }
            self.dealer = FairDealer(rng: SplitMix64(seed: seed))
        }
        self.dealer.flowerRoster = profile?.playableFlowers(for: mode) ?? Self.fallbackFlowers(for: mode)
        self.dealer.bloomRoster = profile?.playableBlooms(for: mode) ?? Self.fallbackBlooms(for: mode)
        self.dealer.customBlooms = mode.allowsCustomBlooms ? (profile?.customBlooms ?? []) : []
        self.bestScore = self.scoreStore.best(for: mode, utcDay: day)
        if dealOnStart, tray == nil {
            dealTray()
            refreshGameOver()
        }
        // Do not touch PlayerProfile here. View.init / body evaluation must not
        // publish environment objects or SwiftUI re-enters ContentView.body.
    }

    func attachProfile(_ profile: PlayerProfile) {
        self.profile = profile
        applyRoster()
        restampOpeningTrayIfNeeded()
    }

    private func applyRoster() {
        dealer.flowerRoster = profile?.playableFlowers(for: mode) ?? Self.fallbackFlowers(for: mode)
        dealer.bloomRoster = profile?.playableBlooms(for: mode) ?? Self.fallbackBlooms(for: mode)
        dealer.customBlooms = mode.allowsCustomBlooms ? (profile?.customBlooms ?? []) : []
    }

    private static func fallbackFlowers(for mode: GameMode) -> Set<FlowerSpecies> {
        switch mode {
        case .classic, .daily:
            return Set(FlowerSpecies.starters)
        case .stage(let id):
            return Set(GardenStageCatalog.stage(id: id)?.species ?? FlowerSpecies.starters)
        }
    }

    private static func fallbackBlooms(for mode: GameMode) -> Set<BloomVariant> {
        Set(fallbackFlowers(for: mode).map(BloomCatalog.signature))
    }

    /// Classic deals the first tray in `init` before SwiftUI can attach the profile.
    /// Overlay scanned stamps and unlocked variants in place (no extra RNG).
    func restampOpeningTrayIfNeeded() {
        guard board.occupiedCount == 0, score == 0 else { return }
        let next = tray.map { piece in
            piece.map { dealer.restampBloom($0) }
        }
        let changed = zip(tray, next).contains { lhs, rhs in
            lhs?.customBloomID != rhs?.customBloomID || lhs?.bloom != rhs?.bloom
        }
        guard changed else { return }
        tray = next
    }

    /// Call from `onAppear` (after the view is mounted), never from `View.init`.
    /// Does nothing until a profile is attached so tests (and first-frame setup)
    /// can construct `GameState` without publisher side effects.
    func recordSessionStartIfNeeded() {
        guard !didRecordSessionStart, let profile else { return }
        didRecordSessionStart = true
        profile.recordGameStarted()
        if mode == .daily, let utcDay {
            profile.recordDailyPlay(utcDay: utcDay)
        }
    }

    var remainingPieces: [Piece] {
        tray.compactMap { $0 }
    }

    var traySignatures: [String] {
        tray.map { $0?.catalogID ?? "-" }
    }

    private var scoreLane: String {
        switch mode {
        case .classic: return "classic"
        case .daily: return "daily"
        case .stage(let id): return "stage.\(id)"
        }
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

        var clear = board.clearCompletedLines()
        var didUltraWipe = false
        if mode.allowsUltraWipe, clear.bloomVariant?.ability == .gridWipe {
            let extra = board.occupiedPoints()
            if !extra.isEmpty {
                board.clearCells(extra)
                clear.clearedCells.append(contentsOf: extra)
            }
            didUltraWipe = !clear.isEmpty
        }

        combo = Scoring.nextCombo(current: combo, didClear: !clear.isEmpty)
        var delta = Scoring.totalScore(
            cellCount: piece.cellCount,
            lineCount: clear.lineCount,
            comboAfterMove: combo
        )
        if didUltraWipe {
            let extra = max(0, clear.cellsCleared - clear.lineCount * Board.size)
            delta += Scoring.ultraWipeBonus(combo: combo, extraCells: extra)
        }
        score += delta
        bestScore = scoreStore.updateBest(for: mode, utcDay: utcDay, score: score)

        if combo >= 2 {
            lastBloomCombo = combo
            bloomPulse += 1
        }
        if !clear.isEmpty {
            linesClearedThisRun += clear.lineCount
            profile?.record(lines: clear.lineCount, combo: combo, blooms: [piece.bloom], score: score)
        } else {
            profile?.record(lines: 0, combo: combo, blooms: [piece.bloom], score: score)
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
            isGameOver: isGameOver,
            didUltraWipe: didUltraWipe
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
        continuesUsed = 0
        linesClearedThisRun = 0
        resolvedScoreRungs = []
        didGrantOrganicThisRun = false
        lastRunRewards = nil
        // Keep the daily seed so Today's Bloom is a fresh run of the same deal sequence.
        if mode == .daily, let utcDay {
            dealer = FairDealer(rng: SplitMix64(seed: DailySeed.seed(fromUTCDay: utcDay)))
        } else {
            dealer = FairDealer(rng: SplitMix64(seed: DailySeed.classicLaunchSeed()))
        }
        applyRoster()
        bestScore = scoreStore.best(for: mode, utcDay: utcDay)
        dealTray()
        refreshGameOver()
        if profile != nil {
            didRecordSessionStart = true
            profile?.recordGameStarted()
            if mode == .daily, let utcDay {
                profile?.recordDailyPlay(utcDay: utcDay)
            }
        }
    }

    var canContinue: Bool {
        continuesUsed < Self.maxContinuesPerRun
    }

    /// Rewarded-continue payload: clear a handful of occupied cells and refill the tray.
    @discardableResult
    func applyRewardedContinue(clearedCellCount: Int = 8) -> Bool {
        guard canContinue else { return false }
        continuesUsed += 1
        var rng = dealer.rng
        let occupied = board.occupiedPoints().shuffled(using: &rng)
        dealer.rng = rng
        let toClear = Array(occupied.prefix(clearedCellCount))
        board.clearCells(toClear)
        combo = 0
        isGameOver = false
        dealTray()
        refreshGameOver()
        return true
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
        var next = dealer.dealTray(on: board).map { Optional($0) }
        while next.count < 3 { next.append(nil) }
        if next.count > 3 { next = Array(next.prefix(3)) }
        tray = next
    }

    func refreshGameOver() {
        let remaining = remainingPieces
        isGameOver = remaining.isEmpty || remaining.allSatisfy { !board.canPlaceAnywhere($0) }
        if isGameOver {
            grantPendingScoreRewards()
        }
    }

    private func grantPendingScoreRewards() {
        guard let profile else { return }
        var rng = SplitMix64(seed: DailySeed.fnv1a64("score-pack|\(scoreLane)|\(utcDay ?? "")|\(score)"))
        let result = ScorePackTable.awards(score: score, alreadyResolved: resolvedScoreRungs, rng: &rng)
        resolvedScoreRungs = result.resolved
        var organic = false
        if !didGrantOrganicThisRun {
            let day = utcDay ?? DailySeed.utcDayString()
            organic = profile.shouldGrantOrganicForScore(score: score, utcDay: day)
            if organic { didGrantOrganicThisRun = true }
        }
        guard !result.packs.isEmpty || organic else { return }
        let rewards = profile.grantScoreRewards(RunScoreRewards(packs: result.packs, organicFertilizer: organic))
        lastRunRewards = rewards
    }

    // MARK: - Test helpers

    func replaceBoard(_ newBoard: Board) {
        board = newBoard
    }

    func replaceTray(_ pieces: [Piece?]) {
        var next = pieces
        while next.count < 3 { next.append(nil) }
        if next.count > 3 { next = Array(next.prefix(3)) }
        tray = next
    }

    func setCombo(_ value: Int) {
        combo = value
    }
}
