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

    /// Quick scale punch so a clear feels like the garden inhaled.
    static func screenPunch(on node: SKNode, combo: Int, reduced: Bool) {
        guard !reduced else { return }
        let up: CGFloat = combo >= 4 ? 1.05 : (combo >= 2 ? 1.03 : 1.018)
        node.run(.sequence([
            .scale(to: up, duration: 0.055),
            .scale(to: 1.0, duration: 0.14)
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
            case .sunflower, .desertBloom:
                size = CGSize(width: 9, height: 9)
            case .greenhouse:
                size = CGSize(width: 8, height: 8)
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
            let distance = CGFloat.random(in: 28...92)
            let dest = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance - CGFloat.random(in: 6...22)
            )
            petal.run(.sequence([
                .group([
                    .move(to: dest, duration: 0.52),
                    .fadeOut(withDuration: 0.52),
                    .scale(to: 0.22, duration: 0.52),
                    .rotate(byAngle: CGFloat.random(in: -2.4...2.4), duration: 0.52)
                ]),
                .removeFromParent()
            ]))
        }
    }

    static func sparkles(at position: CGPoint, in parent: SKNode, count: Int, reduced: Bool) {
        guard !reduced else { return }
        for _ in 0..<count {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.6...3.4))
            star.fillColor = UIColor.white.withAlphaComponent(0.95)
            star.strokeColor = UIColor(red: 1, green: 0.92, blue: 0.65, alpha: 0.7)
            star.lineWidth = 0.6
            star.position = position
            star.zPosition = 42
            parent.addChild(star)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 14...48)
            let dest = CGPoint(x: position.x + cos(angle) * distance, y: position.y + sin(angle) * distance)
            star.run(.sequence([
                .group([
                    .move(to: dest, duration: 0.38),
                    .sequence([
                        .scale(to: 1.35, duration: 0.12),
                        .fadeOut(withDuration: 0.28)
                    ])
                ]),
                .removeFromParent()
            ]))
        }
    }

    static func flashRing(at position: CGPoint, color: UIColor, in parent: SKNode, reduced: Bool) {
        guard !reduced else { return }
        let ring = SKShapeNode(circleOfRadius: 10)
        ring.strokeColor = color.withAlphaComponent(0.9)
        ring.fillColor = color.withAlphaComponent(0.18)
        ring.lineWidth = 2.2
        ring.position = position
        ring.zPosition = 24
        parent.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 2.4, duration: 0.28),
                .fadeOut(withDuration: 0.28)
            ]),
            .removeFromParent()
        ]))
    }

    static func floatingLabel(
        _ text: String,
        at position: CGPoint,
        color: UIColor,
        in parent: SKNode,
        fontSize: CGFloat = 18,
        reduced: Bool
    ) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = position
        label.zPosition = 50
        parent.addChild(label)
        let motion: SKAction = reduced
            ? .sequence([.fadeOut(withDuration: 0.2), .removeFromParent()])
            : .sequence([
                .group([
                    .moveBy(x: 0, y: 28, duration: 0.55),
                    .sequence([.wait(forDuration: 0.18), .fadeOut(withDuration: 0.38)])
                ]),
                .removeFromParent()
            ])
        label.run(motion)
    }

    static func comboBanner(combo: Int, color: UIColor, in parent: SKNode, at position: CGPoint, reduced: Bool) {
        let copy: String
        if combo >= 5 {
            copy = "Garden rush  x\(combo)"
        } else if combo >= 3 {
            copy = "Bloom x\(combo)"
        } else {
            copy = "Bloom x\(combo)"
        }
        floatingLabel(copy, at: position, color: color, in: parent, fontSize: combo >= 3 ? 22 : 18, reduced: reduced)
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
        flowerTile(size: size, fill: fill, stroke: stroke, theme: theme, flower: nil)
    }

    static func flowerTile(
        size: CGFloat,
        fill: UIColor,
        stroke: UIColor,
        theme: CosmeticPack,
        flower: FlowerSpecies?,
        stamp: UIImage? = nil
    ) -> SKNode {
        let root = SKNode()
        let corner = size * 0.22
        let body = SKShapeNode(path: roundedRectPath(size: CGSize(width: size, height: size), corner: corner))
        body.fillColor = fill
        body.strokeColor = stroke
        body.lineWidth = 1.15
        root.addChild(body)

        let highlight = SKShapeNode(ellipseOf: CGSize(width: size * 0.55, height: size * 0.28))
        highlight.fillColor = UIColor.white.withAlphaComponent(theme == .moonlight ? 0.16 : 0.12)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -size * 0.08, y: size * 0.16)
        highlight.zPosition = 1
        root.addChild(highlight)

        if let stamp {
            let sprite = SKSpriteNode(
                texture: SKTexture(image: stamp),
                size: CGSize(width: size * 0.78, height: size * 0.78)
            )
            sprite.name = "flower-glyph"
            sprite.zPosition = 3
            root.addChild(sprite)
        } else if let flower {
            let glyph = FlowerGlyph.node(species: flower, size: size * 0.86, fill: fill)
            glyph.name = "flower-glyph"
            glyph.zPosition = 3
            root.addChild(glyph)
        }
        return root
    }

    static func mapDecor(pack: CosmeticPack, boardRect: CGRect, in parent: SKNode) {
        let decor = SKNode()
        decor.name = "map-decor"
        decor.zPosition = 0.5
        switch pack {
        case .greenhouse:
            let pane = SKShapeNode(rectOf: CGSize(width: boardRect.width + 8, height: boardRect.height + 8), cornerRadius: 18)
            pane.fillColor = UIColor.white.withAlphaComponent(0.08)
            pane.strokeColor = UIColor.white.withAlphaComponent(0.28)
            pane.lineWidth = 1.2
            pane.position = CGPoint(x: boardRect.midX, y: boardRect.midY)
            decor.addChild(pane)
            for i in 1...3 {
                let line = SKShapeNode(rectOf: CGSize(width: 1.1, height: boardRect.height * 0.92))
                line.fillColor = UIColor.white.withAlphaComponent(0.16)
                line.strokeColor = .clear
                line.position = CGPoint(x: boardRect.minX + boardRect.width * CGFloat(i) / 4, y: boardRect.midY)
                decor.addChild(line)
            }
        case .desertBloom:
            for i in 0..<3 {
                let dune = SKShapeNode(ellipseOf: CGSize(width: boardRect.width * 0.42, height: 18))
                dune.fillColor = UIColor(red: 0.92, green: 0.72, blue: 0.42, alpha: 0.22)
                dune.strokeColor = .clear
                dune.position = CGPoint(
                    x: boardRect.minX + boardRect.width * (0.22 + 0.28 * CGFloat(i)),
                    y: boardRect.minY + 10
                )
                decor.addChild(dune)
            }
        case .moonlight:
            let moon = SKShapeNode(circleOfRadius: 10)
            moon.fillColor = UIColor.white.withAlphaComponent(0.28)
            moon.strokeColor = .clear
            moon.position = CGPoint(x: boardRect.maxX - 18, y: boardRect.maxY - 16)
            decor.addChild(moon)
        case .sakura, .garden, .sunflower:
            break
        }
        parent.addChild(decor)
    }
}

enum FlowerGlyph {
    static func node(species: FlowerSpecies, size: CGFloat, fill: UIColor) -> SKNode {
        let root = SKNode()
        root.name = "flower-glyph"
        let petal = UIColor(red: 1, green: 0.98, blue: 0.94, alpha: 1)
        let ink = fill.darker(by: 0.42)
        let butter = UIColor(red: 0.96, green: 0.86, blue: 0.38, alpha: 1)
        let stroke = max(1.15, size * 0.045)

        switch species {
        case .tulip:
            addPetals(to: root, count: 3, length: size * 0.48, width: size * 0.26, color: petal, ink: ink, stroke: stroke, start: -0.5, span: 1.0)
            addCenter(to: root, radius: size * 0.12, color: butter, ink: ink, stroke: stroke)
        case .daisy:
            addPetals(to: root, count: 8, length: size * 0.44, width: size * 0.14, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.15, color: butter, ink: ink, stroke: stroke)
        case .rose:
            addPetals(to: root, count: 6, length: size * 0.38, width: size * 0.22, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.13, color: butter, ink: ink, stroke: stroke)
        case .lily:
            addPetals(to: root, count: 6, length: size * 0.46, width: size * 0.16, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.1, color: butter, ink: ink, stroke: stroke)
        case .lavender:
            for i in 0..<3 {
                let bud = SKShapeNode(circleOfRadius: size * 0.11)
                bud.fillColor = petal
                bud.strokeColor = ink
                bud.lineWidth = stroke
                bud.position = CGPoint(x: CGFloat(i - 1) * size * 0.16, y: CGFloat(i % 2) * size * 0.1)
                root.addChild(bud)
            }
        case .hydrangea:
            for p in [CGPoint(x: -0.14, y: 0.1), CGPoint(x: 0.14, y: 0.1), CGPoint(x: -0.1, y: -0.12), CGPoint(x: 0.12, y: -0.1), .zero] {
                let bud = SKShapeNode(circleOfRadius: size * 0.11)
                bud.fillColor = petal
                bud.strokeColor = ink
                bud.lineWidth = stroke
                bud.position = CGPoint(x: p.x * size, y: p.y * size)
                root.addChild(bud)
            }
        case .orchid:
            addPetals(to: root, count: 5, length: size * 0.46, width: size * 0.18, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.12, color: butter, ink: ink, stroke: stroke)
        case .peony:
            addPetals(to: root, count: 10, length: size * 0.4, width: size * 0.14, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.13, color: butter, ink: ink, stroke: stroke)
        case .lotus:
            addPetals(to: root, count: 8, length: size * 0.42, width: size * 0.18, color: petal, ink: ink, stroke: stroke, start: 0, span: .pi)
            addCenter(to: root, radius: size * 0.12, color: butter, ink: ink, stroke: stroke)
        case .cactusBloom:
            addPetals(to: root, count: 6, length: size * 0.4, width: size * 0.12, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.12, color: butter, ink: ink, stroke: stroke)
        case .moonflower:
            addPetals(to: root, count: 5, length: size * 0.44, width: size * 0.18, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.12, color: butter, ink: ink, stroke: stroke)
        case .cherryBlossom:
            addPetals(to: root, count: 5, length: size * 0.42, width: size * 0.2, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.1, color: butter, ink: ink, stroke: stroke)
        case .starfire:
            addPetals(to: root, count: 12, length: size * 0.46, width: size * 0.1, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.13, color: butter, ink: ink, stroke: stroke)
        case .nightOrchid:
            addPetals(to: root, count: 5, length: size * 0.48, width: size * 0.16, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.11, color: butter, ink: ink, stroke: stroke)
        case .sunburst:
            addPetals(to: root, count: 16, length: size * 0.44, width: size * 0.09, color: petal, ink: ink, stroke: stroke)
            addCenter(to: root, radius: size * 0.14, color: butter, ink: ink, stroke: stroke)
        }
        return root
    }

    private static func addPetals(
        to root: SKNode,
        count: Int,
        length: CGFloat,
        width: CGFloat,
        color: UIColor,
        ink: UIColor,
        stroke: CGFloat,
        start: CGFloat = 0,
        span: CGFloat = 2 * .pi
    ) {
        for i in 0..<count {
            let angle = start + span * CGFloat(i) / CGFloat(max(count, 1)) - .pi / 2
            let petal = SKShapeNode(ellipseOf: CGSize(width: width, height: length))
            petal.fillColor = color
            petal.strokeColor = ink
            petal.lineWidth = stroke
            petal.zRotation = angle
            petal.position = CGPoint(x: sin(angle) * length * 0.28, y: cos(angle) * length * 0.28)
            root.addChild(petal)
        }
    }

    private static func addCenter(to root: SKNode, radius: CGFloat, color: UIColor, ink: UIColor, stroke: CGFloat) {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color
        node.strokeColor = ink
        node.lineWidth = stroke
        node.zPosition = 2
        root.addChild(node)
    }
}

final class PieceSprite: SKNode {
    let piece: Piece
    private let blockSize: CGFloat
    private let gap: CGFloat
    var theme: BoardTheme
    var stamp: UIImage?

    init(
        piece: Piece,
        blockSize: CGFloat,
        gap: CGFloat = 2.4,
        ghost: Bool = false,
        valid: Bool = true,
        theme: BoardTheme,
        stamp: UIImage? = nil
    ) {
        self.piece = piece
        self.blockSize = blockSize
        self.gap = gap
        self.theme = theme
        self.stamp = stamp
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
                let fill = piece.bloom.rarity == .ultra
                    ? piece.bloom.petalTint
                    : theme.pieceFill(index: piece.colorIndex)
                node = Juice.flowerTile(
                    size: size,
                    fill: fill,
                    stroke: fill.darker(by: 0.16),
                    theme: theme.pack,
                    flower: piece.flower,
                    stamp: stamp
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
