import SpriteKit
import UIKit

/// SpriteKit board + tray. Drag pieces from the tray, snap with a green/red ghost,
/// shake invalid drops back, and play clear / petal juice.
final class GameScene: SKScene {
    unowned var game: GameState

    var onNeedsHUD: (() -> Void)?

    private var cellSize: CGFloat = 40
    private var boardRect = CGRect.zero
    private var traySlots: [CGPoint] = []
    private var trayScale: CGFloat = 0.72

    private var boardRoot = SKNode()
    private var trayRoot = SKNode()
    private var traySprites: [PieceSprite?] = [nil, nil, nil]
    private var ghostNode: PieceSprite?

    private var drag: DragState?
    private var inputLocked = false

    private struct DragState {
        var index: Int
        var sprite: PieceSprite
        var home: CGPoint
        var grabOffset: CGPoint
        var fingerLift: CGFloat
    }

    init(game: GameState, size: CGSize) {
        self.game = game
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        isUserInteractionEnabled = true
        if boardRoot.parent == nil {
            addChild(boardRoot)
            addChild(trayRoot)
        }
        layout()
        rebuildBoard()
        rebuildTray()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard oldSize != size, size.width > 1, size.height > 1 else { return }
        layout()
        rebuildBoard()
        rebuildTray()
    }

    func reloadFromState() {
        rebuildBoard()
        rebuildTray()
        clearGhost()
        drag = nil
        inputLocked = false
    }

    // MARK: Layout

    private func layout() {
        let margin: CGFloat = 18
        let topPad: CGFloat = 10
        let trayReserve: CGFloat = 158
        let availableWidth = max(120, size.width - margin * 2)
        let availableHeight = max(120, size.height - topPad - trayReserve)
        cellSize = floor(min(availableWidth, availableHeight) / CGFloat(Board.size))
        let boardSide = cellSize * CGFloat(Board.size)
        let originX = (size.width - boardSide) / 2
        let originY = size.height - topPad - boardSide
        boardRect = CGRect(x: originX, y: originY, width: boardSide, height: boardSide)

        let slotY = originY / 2
        let spacing = size.width / 4
        traySlots = (0..<3).map { CGPoint(x: spacing * CGFloat($0 + 1), y: max(52, slotY)) }
        trayScale = min(0.78, (spacing - 16) / (cellSize * 5))
    }

    // MARK: Board drawing

    private func rebuildBoard() {
        boardRoot.removeAllChildren()

        let well = SKShapeNode(rectOf: CGSize(width: boardRect.width + 16, height: boardRect.height + 16),
                               cornerRadius: 18)
        well.fillColor = GardenPalette.boardWellUI
        well.strokeColor = UIColor.white.withAlphaComponent(0.35)
        well.lineWidth = 1.5
        well.position = CGPoint(x: boardRect.midX, y: boardRect.midY)
        well.zPosition = 0
        boardRoot.addChild(well)

        for y in 0..<Board.size {
            for x in 0..<Board.size {
                let empty = makeCellNode(fill: GardenPalette.emptyCellUI, stroke: GardenPalette.emptyStrokeUI)
                empty.position = scenePoint(cell: GridPoint(x: x, y: y))
                empty.zPosition = 1
                boardRoot.addChild(empty)

                let value = game.board[GridPoint(x: x, y: y)]
                if value != 0 {
                    let filled = makeCellNode(
                        fill: GardenPalette.pieceFill(index: value - 1),
                        stroke: GardenPalette.pieceStroke(index: value - 1)
                    )
                    filled.position = empty.position
                    filled.zPosition = 2
                    boardRoot.addChild(filled)
                }
            }
        }
    }

    private func makeCellNode(fill: UIColor, stroke: UIColor) -> SKShapeNode {
        let inset = cellSize * 0.08
        let size = cellSize - inset
        let node = SKShapeNode(path: Juice.roundedRectPath(size: CGSize(width: size, height: size), corner: size * 0.22))
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = 1
        return node
    }

    private func scenePoint(cell: GridPoint) -> CGPoint {
        CGPoint(
            x: boardRect.minX + (CGFloat(cell.x) + 0.5) * cellSize,
            y: boardRect.maxY - (CGFloat(cell.y) + 0.5) * cellSize
        )
    }

    /// Origin (top-left cell) under the piece root, which is drawn with y downward.
    private func origin(for piece: Piece, rootPosition: CGPoint) -> GridPoint {
        let firstCenter = CGPoint(x: rootPosition.x + cellSize * 0.5, y: rootPosition.y - cellSize * 0.5)
        let col = Int(floor((firstCenter.x - boardRect.minX) / cellSize))
        let row = Int(floor((boardRect.maxY - firstCenter.y) / cellSize))
        return GridPoint(x: col, y: row)
    }

    // MARK: Tray

    private func rebuildTray() {
        trayRoot.removeAllChildren()
        traySprites = [nil, nil, nil]
        for index in 0..<3 {
            guard drag?.index != index, let piece = game.tray[index] else { continue }
            let sprite = PieceSprite(piece: piece, blockSize: cellSize)
            sprite.setScale(trayScale * 0.82)
            sprite.position = trayHome(for: piece, slot: traySlots[index])
            sprite.zPosition = 10
            trayRoot.addChild(sprite)
            traySprites[index] = sprite
            sprite.run(.sequence([
                .scale(to: trayScale * 1.06, duration: 0.12),
                .scale(to: trayScale, duration: 0.1)
            ]))
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
            let ghost = PieceSprite(piece: piece, blockSize: cellSize, ghost: true, valid: valid)
            ghost.zPosition = 8
            ghost.alpha = 0.95
            addChild(ghost)
            ghostNode = ghost
        } else {
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
        guard !inputLocked, !game.isGameOver, drag == nil, let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard let index = hitTrayIndex(at: location), let sprite = traySprites[index] else { return }

        Haptics.light()
        SoundPlayer.shared.click()
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
        guard let drag else { return }
        finishDrag()
        self.drag = nil
        _ = drag
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
        sprite.run(.sequence([
            Juice.shake(),
            .group([
                .move(to: drag.home, duration: 0.18),
                .scale(to: trayScale, duration: 0.18)
            ]),
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
            if let drag {
                invalidDrop(drag)
            }
            return
        }
        Haptics.medium()
        SoundPlayer.shared.place()
        sprite.removeFromParent()
        traySprites[index] = nil

        if result.clear.isEmpty {
            rebuildBoard()
            rebuildTray()
            onNeedsHUD?()
        } else {
            animateClear(result)
        }
    }

    private func animateClear(_ result: PlaceResult) {
        inputLocked = true
        Haptics.success()
        SoundPlayer.shared.bloom()
        rebuildBoard()

        for point in result.clear.clearedCells {
            let flash = makeCellNode(
                fill: GardenPalette.pieceFill(index: 2),
                stroke: UIColor.white.withAlphaComponent(0.85)
            )
            flash.position = scenePoint(cell: point)
            flash.zPosition = 25
            addChild(flash)
            Juice.burstPetals(
                at: scenePoint(cell: point),
                color: GardenPalette.pieceFill(index: 2),
                in: self
            )
            flash.run(.sequence([
                .group([
                    .scale(to: 1.32, duration: 0.1),
                    .fadeOut(withDuration: 0.28)
                ]),
                .removeFromParent()
            ]))
        }

        run(.sequence([
            .wait(forDuration: 0.32),
            .run { [weak self] in
                guard let self else { return }
                self.rebuildTray()
                self.inputLocked = false
                self.onNeedsHUD?()
            }
        ]))
    }

    private func hitTrayIndex(at location: CGPoint) -> Int? {
        var best: (Int, CGFloat)?
        for (index, sprite) in traySprites.enumerated() {
            guard let sprite else { continue }
            let box = sprite.calculateAccumulatedFrame().insetBy(dx: -18, dy: -18)
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
