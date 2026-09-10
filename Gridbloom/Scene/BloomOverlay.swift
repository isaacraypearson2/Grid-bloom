import SpriteKit
import UIKit

/// Full-screen species bloom on a line clear. Does not steal touches; fades fast.
enum BloomOverlay {
    static func play(
        in scene: SKScene,
        species: FlowerSpecies,
        title: String,
        tint: UIColor,
        stamp: UIImage?,
        combo: Int,
        reduced: Bool
    ) {
        scene.childNode(withName: "fullscreen-bloom")?.removeFromParent()
        let overlay = SKNode()
        overlay.name = "fullscreen-bloom"
        overlay.zPosition = 220
        overlay.isUserInteractionEnabled = false
        scene.addChild(overlay)

        let wash = SKSpriteNode(color: tint.withAlphaComponent(reduced ? 0.16 : min(0.34, 0.16 + CGFloat(combo) * 0.04)),
                                size: scene.size)
        wash.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        wash.zPosition = 0
        overlay.addChild(wash)

        let center = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.56)
        let span = min(scene.size.width, scene.size.height)
        let scale = 0.42 + min(0.38, CGFloat(max(1, combo)) * 0.07)
        let bloomSize = span * scale

        let hero: SKNode
        if let stamp {
            let sprite = SKSpriteNode(texture: SKTexture(image: stamp), size: CGSize(width: bloomSize, height: bloomSize))
            sprite.position = center
            hero = sprite
        } else {
            let glyph = FlowerGlyph.node(species: species, size: bloomSize * 0.72, fill: tint)
            glyph.position = center
            hero = glyph
        }
        hero.zPosition = 2
        hero.setScale(reduced ? 1 : 0.55)
        hero.alpha = 0
        overlay.addChild(hero)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = combo >= 3 ? "\(title)  x\(combo)" : title
        label.fontSize = combo >= 4 ? 28 : 22
        label.fontColor = .white
        label.position = CGPoint(x: center.x, y: center.y - bloomSize * 0.42)
        label.zPosition = 3
        label.alpha = 0
        overlay.addChild(label)

        let lifetime = reduced ? 0.2 : min(0.7, 0.36 + Double(combo) * 0.07)
        if reduced {
            hero.alpha = 1
            hero.setScale(1)
            overlay.run(.sequence([.fadeOut(withDuration: lifetime), .removeFromParent()]))
            return
        }

        let petalCopies = min(18, 8 + combo * 3)
        for index in 0..<petalCopies {
            let chip: SKNode
            if let stamp, index % 3 == 0 {
                let size = CGFloat.random(in: 28...44)
                chip = SKSpriteNode(texture: SKTexture(image: stamp), size: CGSize(width: size, height: size))
            } else {
                chip = FlowerGlyph.node(species: species, size: CGFloat.random(in: 22...38), fill: tint)
            }
            chip.position = center
            chip.zPosition = 1
            chip.alpha = 0.95
            overlay.addChild(chip)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = bloomSize * CGFloat.random(in: 0.45...0.95)
            let dest = CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
            chip.run(.sequence([
                .group([
                    .move(to: dest, duration: lifetime),
                    .rotate(byAngle: CGFloat.random(in: -1.6...1.6), duration: lifetime),
                    .fadeOut(withDuration: lifetime),
                    .scale(to: 0.35, duration: lifetime)
                ]),
                .removeFromParent()
            ]))
        }

        Juice.burstPetals(
            at: center,
            color: tint,
            in: overlay,
            count: min(28, 12 + combo * 4),
            style: .garden,
            reduced: false
        )

        hero.run(.group([
            .fadeIn(withDuration: 0.08),
            .sequence([
                .scale(to: 1.08, duration: 0.14),
                .scale(to: 1.0, duration: 0.12)
            ])
        ]))
        label.run(.sequence([
            .wait(forDuration: 0.06),
            .fadeIn(withDuration: 0.1)
        ]))
        overlay.run(.sequence([
            .wait(forDuration: lifetime * 0.55),
            .group([
                .fadeOut(withDuration: lifetime * 0.45),
                .scale(to: 1.08, duration: lifetime * 0.45)
            ]),
            .removeFromParent()
        ]))
    }
}
