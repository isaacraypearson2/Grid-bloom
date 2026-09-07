import SpriteKit
import UIKit

enum Juice {
    static func shake(amplitude: CGFloat = 9) -> SKAction {
        let offsets: [CGFloat] = [-amplitude, amplitude, -amplitude * 0.7, amplitude * 0.7, -amplitude * 0.35, amplitude * 0.35, 0]
        return .sequence(offsets.map { .moveBy(x: $0, y: 0, duration: 0.028) })
    }

    static func squashPop() -> SKAction {
        .sequence([
            .scale(to: 1.14, duration: 0.06),
            .scale(to: 0.94, duration: 0.07),
            .scale(to: 1.0, duration: 0.08)
        ])
    }

    static func screenShake(on node: SKNode, combo: Int, reduced: Bool) {
        guard !reduced else { return }
        let amp: CGFloat = combo >= 4 ? 7 : (combo >= 3 ? 4 : 2.2)
        let original = node.position
        node.run(.sequence([
            shake(amplitude: amp),
            .move(to: original, duration: 0.02)
        ]))
    }

    static func burstPetals(
        at position: CGPoint,
        color: UIColor,
        in parent: SKNode,
        count: Int = 10,
        style: CosmeticPack = .garden,
        reduced: Bool = false
    ) {
        guard !reduced else { return }
        for _ in 0..<count {
            let size: CGSize
            switch style {
            case .sakura:
                size = CGSize(width: 8, height: 14)
            case .moonlight:
                size = CGSize(width: 6, height: 6)
            case .sunflower:
                size = CGSize(width: 9, height: 9)
            case .garden:
                size = CGSize(width: 7, height: 12)
            }
            let petal = SKShapeNode(ellipseOf: size)
            petal.fillColor = color.withAlphaComponent(0.92)
            petal.strokeColor = UIColor.white.withAlphaComponent(0.25)
            petal.lineWidth = 0.4
            petal.position = position
            petal.zPosition = 40
            petal.zRotation = CGFloat.random(in: 0...(2 * .pi))
            parent.addChild(petal)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 26...78)
            let dest = CGPoint(x: position.x + cos(angle) * distance, y: position.y + sin(angle) * distance)
            petal.run(.sequence([
                .group([
                    .move(to: dest, duration: 0.48),
                    .fadeOut(withDuration: 0.48),
                    .scale(to: 0.25, duration: 0.48),
                    .rotate(byAngle: CGFloat.random(in: -2.2...2.2), duration: 0.48)
                ]),
                .removeFromParent()
            ]))
        }
    }

    static func roundedRectPath(size: CGSize, corner: CGFloat) -> CGPath {
        CGPath(
            roundedRect: CGRect(origin: CGPoint(x: -size.width / 2, y: -size.height / 2), size: size),
            cornerWidth: corner,
            cornerHeight: corner,
            transform: nil
        )
    }

    static func ceramicTile(size: CGFloat, fill: UIColor, stroke: UIColor, theme: CosmeticPack) -> SKNode {
        let root = SKNode()
        let corner = size * 0.22
        let body = SKShapeNode(path: roundedRectPath(size: CGSize(width: size, height: size), corner: corner))
        body.fillColor = fill
        body.strokeColor = stroke
        body.lineWidth = 1.15
        root.addChild(body)

        let highlight = SKShapeNode(ellipseOf: CGSize(width: size * 0.55, height: size * 0.28))
        highlight.fillColor = UIColor.white.withAlphaComponent(theme == .moonlight ? 0.28 : 0.22)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -size * 0.08, y: size * 0.16)
        highlight.zPosition = 1
        root.addChild(highlight)

        let sheen = SKShapeNode(ellipseOf: CGSize(width: size * 0.16, height: size * 0.1))
        sheen.fillColor = UIColor.white.withAlphaComponent(0.35)
        sheen.strokeColor = .clear
        sheen.position = CGPoint(x: -size * 0.16, y: size * 0.18)
        sheen.zPosition = 2
        root.addChild(sheen)
        return root
    }
}

final class PieceSprite: SKNode {
    let piece: Piece
    private let blockSize: CGFloat
    private let gap: CGFloat
    var theme: BoardTheme

    init(piece: Piece, blockSize: CGFloat, gap: CGFloat = 2.4, ghost: Bool = false, valid: Bool = true, theme: BoardTheme) {
        self.piece = piece
        self.blockSize = blockSize
        self.gap = gap
        self.theme = theme
        super.init()
        name = "piece-\(piece.id.uuidString)"
        redraw(ghost: ghost, valid: valid)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redraw(ghost: Bool, valid: Bool) {
        removeAllChildren()
        let size = blockSize - gap
        for cell in piece.cells {
            let node: SKNode
            if ghost {
                let shape = SKShapeNode(path: Juice.roundedRectPath(size: CGSize(width: size, height: size), corner: size * 0.22))
                shape.fillColor = valid ? theme.validGhost : theme.invalidGhost
                shape.strokeColor = valid
                    ? UIColor.white.withAlphaComponent(0.85)
                    : UIColor(white: 0.2, alpha: 0.55)
                shape.lineWidth = valid ? 1.4 : 2.0
                if !valid {
                    let dash = SKShapeNode(circleOfRadius: size * 0.12)
                    dash.fillColor = UIColor(white: 0.15, alpha: 0.55)
                    dash.strokeColor = .clear
                    shape.addChild(dash)
                }
                node = shape
            } else {
                node = Juice.ceramicTile(
                    size: size,
                    fill: theme.pieceFill(index: piece.colorIndex),
                    stroke: theme.pieceStroke(index: piece.colorIndex),
                    theme: theme.pack
                )
            }
            node.position = CGPoint(
                x: (CGFloat(cell.x) + 0.5) * blockSize,
                y: -(CGFloat(cell.y) + 0.5) * blockSize
            )
            addChild(node)
        }
    }
}
