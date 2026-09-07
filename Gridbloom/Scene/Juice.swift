import SpriteKit
import UIKit

enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

enum Juice {
    static func shake(amplitude: CGFloat = 9) -> SKAction {
        let offsets: [CGFloat] = [-amplitude, amplitude, -amplitude * 0.7, amplitude * 0.7, -amplitude * 0.35, amplitude * 0.35, 0]
        return .sequence(offsets.map { .moveBy(x: $0, y: 0, duration: 0.028) })
    }

    static func popIn() -> SKAction {
        .sequence([
            .scale(to: 1.08, duration: 0.08),
            .scale(to: 1.0, duration: 0.1)
        ])
    }

    static func burstPetals(at position: CGPoint, color: UIColor, in parent: SKNode) {
        for _ in 0..<10 {
            let petal = SKShapeNode(ellipseOf: CGSize(width: 7, height: 12))
            petal.fillColor = color.withAlphaComponent(0.9)
            petal.strokeColor = .clear
            petal.position = position
            petal.zPosition = 40
            petal.zRotation = CGFloat.random(in: 0...(2 * .pi))
            parent.addChild(petal)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 28...72)
            let dest = CGPoint(x: position.x + cos(angle) * distance, y: position.y + sin(angle) * distance)
            petal.run(.sequence([
                .group([
                    .move(to: dest, duration: 0.45),
                    .fadeOut(withDuration: 0.45),
                    .scale(to: 0.3, duration: 0.45),
                    .rotate(byAngle: CGFloat.random(in: -2...2), duration: 0.45)
                ]),
                .removeFromParent()
            ]))
        }
    }

    static func roundedRectPath(size: CGSize, corner: CGFloat) -> CGPath {
        CGPath(roundedRect: CGRect(origin: CGPoint(x: -size.width / 2, y: -size.height / 2), size: size),
               cornerWidth: corner,
               cornerHeight: corner,
               transform: nil)
    }
}

final class PieceSprite: SKNode {
    let piece: Piece
    private let blockSize: CGFloat
    private let gap: CGFloat

    init(piece: Piece, blockSize: CGFloat, gap: CGFloat = 2, ghost: Bool = false, valid: Bool = true) {
        self.piece = piece
        self.blockSize = blockSize
        self.gap = gap
        super.init()
        name = "piece-\(piece.id.uuidString)"
        redraw(ghost: ghost, valid: valid)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func redraw(ghost: Bool, valid: Bool) {
        removeAllChildren()
        let fill: UIColor
        let stroke: UIColor
        if ghost {
            fill = valid
                ? UIColor(red: 0.42, green: 0.76, blue: 0.48, alpha: 0.55)
                : UIColor(red: 0.90, green: 0.38, blue: 0.40, alpha: 0.55)
            stroke = valid
                ? UIColor(red: 0.28, green: 0.62, blue: 0.34, alpha: 0.9)
                : UIColor(red: 0.78, green: 0.22, blue: 0.26, alpha: 0.9)
        } else {
            fill = GardenPalette.pieceFill(index: piece.colorIndex)
            stroke = GardenPalette.pieceStroke(index: piece.colorIndex)
        }

        let size = blockSize - gap
        for cell in piece.cells {
            let node = SKShapeNode(path: Juice.roundedRectPath(size: CGSize(width: size, height: size), corner: size * 0.22))
            node.fillColor = fill
            node.strokeColor = stroke
            node.lineWidth = ghost ? 1.5 : 1.2
            node.position = CGPoint(
                x: (CGFloat(cell.x) + 0.5) * blockSize,
                y: -(CGFloat(cell.y) + 0.5) * blockSize
            )
            addChild(node)
        }
    }

    /// Scene-space size of the bounding box, origin at the top-left cell center offset.
    var footprint: CGSize {
        CGSize(width: CGFloat(piece.width) * blockSize, height: CGFloat(piece.height) * blockSize)
    }
}
