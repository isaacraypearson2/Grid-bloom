import SpriteKit
import UIKit

/// SpriteKit board + tray with ceramic tiles, tuned juice, and Reduce Motion support.
final class GameScene: SKScene {
    unowned var game: GameState
    var theme: BoardTheme
    weak var settings: AppSettings?

    var onNeedsHUD: (() -> Void)?
    var isPausedOverlay = false

    private var cellSize: CGFloat = 40
    private var boardRect = CGRect.zero
    private var traySlots: [CGPoint] = []
    private var trayScale: CGFloat = 0.72

    private var boardRoot = SKNode()
    private var trayRoot = SKNode()
    private var juiceRoot = SKNode()
    private var traySprites: [PieceSprite?] = [nil, nil, nil]
    private var ghostNode: PieceSprite?

    private var drag: DragState?
    private var inputLocked = false

    private var reducedMotion: Bool {
        settings?.prefersReducedMotion ?? UIAccessibility.isReduceMotionEnabled
    }

    private struct DragState {
        var index: Int
        var sprite: PieceSprite
        var home: CGPoint
        var grabOffset: CGPoint
        var fingerLift: CGFloat
    }

    init(game: GameState, size: CGSize, theme: BoardTheme) {
        self.game = game
        self.theme = theme
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = .zero
        // SpriteView may call apply(theme:) from SwiftUI onAppear *before* didMove(to:).
        applyLayout(GameBoardLayout(sceneSize: size))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        isUserInteractionEnabled = true
        if boardRoot.parent == nil {
            addChild(boardRoot)
            addChild(trayRoot)
            addChild(juiceRoot)
        }
        relayoutAndRedraw(animatedTray: false)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 1, size.height > 1 else { return }
        relayoutAndRedraw(animatedTray: false)
    }

    func apply(theme: BoardTheme) {
        self.theme = theme
        relayoutAndRedraw(animatedTray: false)
    }

    func reloadFromState() {
        relayoutAndRedraw(animatedTray: !reducedMotion)
        clearGhost()
        drag = nil
        inputLocked = false
        isPausedOverlay = false
    }

    // MARK: Layout

    /// Always runs layout before drawing so traySlots/boardRect exist even if
    /// SwiftUI presents the scene (onAppear → apply) before didMove(to:).
    private func relayoutAndRedraw(animatedTray: Bool) {
        applyLayout(GameBoardLayout(sceneSize: size))
        rebuildBoard()
        rebuildTray(animated: animatedTray)
    }

    private func applyLayout(_ layout: GameBoardLayout) {
        cellSize = layout.cellSize
        boardRect = layout.boardRect
        traySlots = layout.traySlots
        trayScale = layout.trayScale
    }

    // MARK: Board drawing

    private func rebuildBoard() {
        boardRoot.removeAllChildren()

        let well = SKShapeNode(rectOf: CGSize(width: boardRect.width + 18, height: boardRect.height + 18),
                               cornerRadius: 22)
        well.fillColor = theme.well
        well.strokeColor = UIColor.white.withAlphaComponent(0.42)
        well.lineWidth = 1.6
        well.position = CGPoint(x: boardRect.midX, y: boardRect.midY)
        well.zPosition = 0
        boardRoot.addChild(well)

        for y in 0..<Board.size {
            for x in 0..<Board.size {
                let empty = makeEmptyCell()
                empty.position = scenePoint(cell: GridPoint(x: x, y: y))
                empty.zPosition = 1
                boardRoot.addChild(empty)

                let value = game.board[GridPoint(x: x, y: y)]
                if value != 0 {
                    let filled = Juice.ceramicTile(
                        size: cellSize * 0.9,
                        fill: theme.pieceFill(index: value - 1),
                        stroke: theme.pieceStroke(index: value - 1),
                        theme: theme.pack
                    )
                    filled.position = empty.position
                    filled.zPosition = 2
                    filled.name = "tile-\(x)-\(y)"
                    boardRoot.addChild(filled)
                }
            }
        }
    }

    private func makeEmptyCell() -> SKShapeNode {
        let inset = cellSize * 0.1
        let size = cellSize - inset
        let node = SKShapeNode(path: Juice.roundedRectPath(size: CGSize(width: size, height: size), corner: size * 0.24))
        node.fillColor = theme.empty
        node.strokeColor = theme.emptyStroke
        node.lineWidth = 1
        return node
    }

    private func scenePoint(cell: GridPoint) -> CGPoint {
        CGPoint(
            x: boardRect.minX + (CGFloat(cell.x) + 0.5) * cellSize,
            y: boardRect.maxY - (CGFloat(cell.y) + 0.5) * cellSize
        )
    }

    private func origin(for piece: Piece, rootPosition: CGPoint) -> GridPoint {
        let firstCenter = CGPoint(x: rootPosition.x + cellSize * 0.5, y: rootPosition.y - cellSize * 0.5)
        let col = Int(floor((firstCenter.x - boardRect.minX) / cellSize))
        let row = Int(floor((boardRect.maxY - firstCenter.y) / cellSize))
        return GridPoint(x: col, y: row)
    }

    // MARK: Tray

    private func rebuildTray(animated: Bool) {
        if traySlots.count < 3 {
            applyLayout(GameBoardLayout(sceneSize: size))
        }
        guard traySlots.count >= 3 else { return }
        trayRoot.removeAllChildren()
        traySprites = [nil, nil, nil]
        for index in 0..<3 {
            guard drag?.index != index, let piece = game.tray[index] else { continue }
            let sprite = PieceSprite(piece: piece, blockSize: cellSize, theme: theme)
            sprite.position = trayHome(for: piece, slot: traySlots[index])
            sprite.zPosition = 10
            trayRoot.addChild(sprite)
            traySprites[index] = sprite
            if animated, !reducedMotion {
                sprite.setScale(trayScale * 0.78)
                sprite.alpha = 0
                sprite.run(.group([
                    .fadeIn(withDuration: 0.16),
                    .sequence([
                        .scale(to: trayScale * 1.06, duration: 0.14),
                        .scale(to: trayScale, duration: 0.1)
                    ])
                ]))
            } else {
                sprite.setScale(trayScale)
            }
        }
    }

    private func trayHome(for piece: Piece, slot: CGPoint) -> CGPoint {
        let footprint = CGSize(width: CGFloat(piece.width) * cellSize * trayScale,
                               height: CGFloat(piece.height) * cellSize * trayScale)
        return CGPoint(x: slot.x - footprint.width / 2, y: slot.y + footprint.height / 2)
    }

    // MARK: Ghost

    private func updateGhost(for piece: Piece, root: CGPoint) {
        let snap = origin(for: piece, rootPosition: root)
        let valid = game.canPlace(piece, at: snap)
        if ghostNode == nil {
            let ghost = PieceSprite(piece: piece, blockSize: cellSize, ghost: true, valid: valid, theme: theme)
            ghost.zPosition = 8
            ghost.alpha = 0.95
            addChild(ghost)
            ghostNode = ghost
        } else {
            ghostNode?.theme = theme
            ghostNode?.redraw(ghost: true, valid: valid)
        }
        ghostNode?.position = rootPoint(for: snap)
        ghostNode?.isHidden = !overlapsBoard(snap, piece: piece)
    }

    private func overlapsBoard(_ origin: GridPoint, piece: Piece) -> Bool {
        piece.occupying(at: origin).contains { game.board.isInBounds($0) }
    }

    private func rootPoint(for origin: GridPoint) -> CGPoint {
        let topLeft = scenePoint(cell: origin)
        return CGPoint(x: topLeft.x - cellSize * 0.5, y: topLeft.y + cellSize * 0.5)
    }

    private func clearGhost() {
        ghostNode?.removeFromParent()
        ghostNode = nil
    }

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !inputLocked, !isPausedOverlay, !game.isGameOver, drag == nil, let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard let index = hitTrayIndex(at: location), let sprite = traySprites[index] else { return }

        Haptics.light()
        SoundPlayer.shared.click()
        sprite.removeAllActions()
        sprite.setScale(1)
        sprite.zPosition = 30
        let grabOffset = CGPoint(x: sprite.position.x - location.x, y: sprite.position.y - location.y)
        drag = DragState(
            index: index,
            sprite: sprite,
            home: sprite.position,
            grabOffset: grabOffset,
            fingerLift: cellSize * 1.35
        )
        moveDrag(to: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let drag, let touch = touches.first else { return }
        moveDrag(to: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard drag != nil else { return }
        finishDrag()
        self.drag = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let drag else { return }
        returnHome(drag)
        self.drag = nil
        clearGhost()
    }

    private func moveDrag(to location: CGPoint) {
        guard let drag else { return }
        let lifted = CGPoint(
            x: location.x + drag.grabOffset.x,
            y: location.y + drag.grabOffset.y + drag.fingerLift
        )
        drag.sprite.position = lifted
        updateGhost(for: drag.sprite.piece, root: lifted)
    }

    private func finishDrag() {
        guard let drag else { return }
        let piece = drag.sprite.piece
        let snap = origin(for: piece, rootPosition: drag.sprite.position)
        if game.canPlace(piece, at: snap) {
            commitPlacement(index: drag.index, origin: snap, sprite: drag.sprite)
        } else {
            Haptics.error()
            invalidDrop(drag)
        }
        clearGhost()
    }

    private func invalidDrop(_ drag: DragState) {
        let sprite = drag.sprite
        inputLocked = true
        let motion: SKAction = reducedMotion
            ? .group([.move(to: drag.home, duration: 0.12), .scale(to: trayScale, duration: 0.12)])
            : .sequence([
                Juice.shake(),
                .group([
                    .move(to: drag.home, duration: 0.18),
                    .scale(to: trayScale, duration: 0.18)
                ])
            ])
        sprite.run(.sequence([
            motion,
            .run { [weak self] in
                sprite.zPosition = 10
                self?.inputLocked = false
            }
        ]))
    }

    private func returnHome(_ drag: DragState) {
        drag.sprite.position = drag.home
        drag.sprite.setScale(trayScale)
        drag.sprite.zPosition = 10
    }

    private func commitPlacement(index: Int, origin: GridPoint, sprite: PieceSprite) {
        guard let result = game.place(trayIndex: index, at: origin) else {
            if let drag { invalidDrop(drag) }
            return
        }
        if result.combo >= 3 {
            Haptics.heavy()
        } else {
            Haptics.medium()
        }
        SoundPlayer.shared.place()
        sprite.removeFromParent()
        traySprites[index] = nil

        if result.clear.isEmpty {
            rebuildBoard()
            popNewTiles(result.placedCells)
            rebuildTray(animated: result.trayRefilled)
            onNeedsHUD?()
        } else {
            animateClear(result)
        }
    }

    private func popNewTiles(_ cells: [GridPoint]) {
        guard !reducedMotion else { return }
        for point in cells where game.board[point] != 0 {
            if let node = boardRoot.childNode(withName: "tile-\(point.x)-\(point.y)") {
                node.setScale(0.86)
                node.run(Juice.squashPop())
            }
        }
    }

    private func animateClear(_ result: PlaceResult) {
        inputLocked = true
        if result.combo >= 2 {
            Haptics.success()
            SoundPlayer.shared.bloom(combo: result.combo)
        } else {
            Haptics.medium()
            SoundPlayer.shared.bloom(combo: 1)
        }
        rebuildBoard()
        popNewTiles(result.placedCells.filter { cell in
            !result.clear.clearedCells.contains(cell)
        })

        let petalCount = reducedMotion ? 0 : min(18, 8 + result.combo * 3)
        for point in result.clear.clearedCells {
            let flash = Juice.ceramicTile(
                size: cellSize * 0.92,
                fill: theme.petal,
                stroke: UIColor.white.withAlphaComponent(0.85),
                theme: theme.pack
            )
            flash.position = scenePoint(cell: point)
            flash.zPosition = 25
            juiceRoot.addChild(flash)
            Juice.burstPetals(
                at: scenePoint(cell: point),
                color: theme.petal,
                in: juiceRoot,
                count: max(4, petalCount / max(1, result.clear.clearedCells.count / 2)),
                style: theme.pack,
                reduced: reducedMotion
            )
            let fade: SKAction = reducedMotion
                ? .sequence([.fadeOut(withDuration: 0.12), .removeFromParent()])
                : .sequence([
                    .group([.scale(to: 1.28, duration: 0.1), .fadeOut(withDuration: 0.28)]),
                    .removeFromParent()
                ])
            flash.run(fade)
        }

        Juice.screenShake(on: boardRoot, combo: result.combo, reduced: reducedMotion)

        let wait = reducedMotion ? 0.14 : 0.34
        run(.sequence([
            .wait(forDuration: wait),
            .run { [weak self] in
                guard let self else { return }
                self.rebuildTray(animated: result.trayRefilled)
                self.inputLocked = false
                self.onNeedsHUD?()
            }
        ]))
    }

    private func hitTrayIndex(at location: CGPoint) -> Int? {
        var best: (Int, CGFloat)?
        for (index, sprite) in traySprites.enumerated() {
            guard let sprite else { continue }
            let box = sprite.calculateAccumulatedFrame().insetBy(dx: -22, dy: -22)
            if box.contains(location) {
                let dx = location.x - sprite.position.x
                let dy = location.y - sprite.position.y
                let d = dx * dx + dy * dy
                if best == nil || d < best!.1 {
                    best = (index, d)
                }
            }
        }
        return best?.0
    }
}

/// Pure layout for the 8×8 board and 3 tray slots. Always yields three slots,
/// even when SpriteKit reports a zero size before the view is in the hierarchy.
struct GameBoardLayout {
    static let slotCount = 3

    let cellSize: CGFloat
    let boardRect: CGRect
    let traySlots: [CGPoint]
    let trayScale: CGFloat

    init(sceneSize: CGSize) {
        let width = max(sceneSize.width, 320)
        let height = max(sceneSize.height, 568)
        let margin: CGFloat = width < 360 ? 12 : 18
        let topPad: CGFloat = 8
        let trayReserve = max(118, min(170, height * 0.21))
        let availableWidth = max(120, width - margin * 2)
        let availableHeight = max(120, height - topPad - trayReserve)
        let cell = max(8, floor(min(availableWidth, availableHeight) / CGFloat(Board.size)))
        let boardSide = cell * CGFloat(Board.size)
        let originX = (width - boardSide) / 2
        let originY = height - topPad - boardSide
        cellSize = cell
        boardRect = CGRect(x: originX, y: originY, width: boardSide, height: boardSide)

        let slotY = max(48, originY * 0.48)
        let spacing = width / 4
        traySlots = (0..<Self.slotCount).map { CGPoint(x: spacing * CGFloat($0 + 1), y: slotY) }
        trayScale = min(0.78, max(0.52, (spacing - 14) / (cell * 5)))
    }
}
