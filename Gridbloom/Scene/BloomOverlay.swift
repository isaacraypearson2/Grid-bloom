import SpriteKit
import SwiftUI
import UIKit

struct MatchBloomFlash: Equatable, Identifiable {
    var id = UUID()
    var species: FlowerSpecies
    var title: String
    var tint: Color
    var stamp: UIImage?
    var combo: Int
}

/// Full-screen species bloom on a line clear. Does not steal touches.
enum BloomOverlay {
    static func heroSize(sceneSize: CGSize, combo: Int) -> CGFloat {
        let span = min(sceneSize.width, sceneSize.height)
        return span * (0.82 + min(0.12, CGFloat(max(1, combo)) * 0.03))
    }

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

        let wash = SKSpriteNode(
            color: tint.withAlphaComponent(reduced ? 0.28 : min(0.55, 0.38 + CGFloat(combo) * 0.05)),
            size: scene.size
        )
        wash.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        overlay.addChild(wash)

        let center = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.52)
        let bloomSize = heroSize(sceneSize: scene.size, combo: combo)

        let hero: SKNode
        if let stamp {
            let sprite = SKSpriteNode(texture: SKTexture(image: stamp), size: CGSize(width: bloomSize, height: bloomSize))
            sprite.position = center
            hero = sprite
        } else {
            let glyph = FlowerGlyph.node(species: species, size: bloomSize, fill: tint)
            glyph.position = center
            hero = glyph
        }
        hero.zPosition = 2
        hero.setScale(reduced ? 1 : 0.55)
        hero.alpha = 0
        overlay.addChild(hero)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = combo >= 3 ? "\(title)  x\(combo)" : title
        label.fontSize = combo >= 4 ? 36 : 30
        label.fontColor = .white
        label.position = CGPoint(x: center.x, y: max(24, center.y - bloomSize * 0.52))
        label.zPosition = 3
        label.alpha = 0
        overlay.addChild(label)

        let lifetime = reduced ? 0.35 : min(1.05, 0.7 + Double(combo) * 0.08)
        if reduced {
            hero.alpha = 1
            hero.setScale(1)
            label.alpha = 1
            overlay.run(.sequence([.fadeOut(withDuration: lifetime), .removeFromParent()]))
            return
        }

        for index in 0..<(min(22, 10 + combo * 3)) {
            let chip: SKNode
            if let stamp, index % 3 == 0 {
                let size = CGFloat.random(in: 36...56)
                chip = SKSpriteNode(texture: SKTexture(image: stamp), size: CGSize(width: size, height: size))
            } else {
                chip = FlowerGlyph.node(species: species, size: CGFloat.random(in: 28...48), fill: tint)
            }
            chip.position = center
            chip.zPosition = 1
            overlay.addChild(chip)
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = bloomSize * CGFloat.random(in: 0.4...0.95)
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
            count: min(32, 14 + combo * 4),
            style: .garden,
            reduced: false
        )

        hero.run(.group([
            .fadeIn(withDuration: 0.08),
            .sequence([
                .scale(to: 1.08, duration: 0.16),
                .scale(to: 1.0, duration: 0.14)
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
                .scale(to: 1.06, duration: lifetime * 0.45)
            ]),
            .removeFromParent()
        ]))
    }
}

/// Covers the whole phone — HUD included — so a match bloom is unmistakable.
struct FullScreenMatchBloom: View {
    var flash: MatchBloomFlash
    var reduced: Bool

    var body: some View {
        ZStack {
            flash.tint.opacity(reduced ? 0.32 : 0.52)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                if let stamp = flash.stamp {
                    Image(uiImage: stamp)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                } else {
                    FlowerGlyphView(species: flash.species, fill: flash.tint, size: 280)
                }
                Text(flash.combo >= 3 ? "\(flash.title)  x\(flash.combo)" : flash.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(flash.title) bloom")
    }
}

struct FlowerGlyphView: View {
    var species: FlowerSpecies
    var fill: Color
    var size: CGFloat

    private var petals: Int {
        switch species {
        case .tulip: return 3
        case .daisy, .lotus: return 8
        case .rose, .lily, .cactusBloom: return 6
        case .lavender: return 3
        case .hydrangea: return 5
        case .orchid, .moonflower, .cherryBlossom, .nightOrchid: return 5
        case .peony: return 10
        case .starfire: return 12
        case .sunburst: return 16
        }
    }

    var body: some View {
        ZStack {
            ForEach(0..<petals, id: \.self) { index in
                Capsule()
                    .fill(Color(red: 1, green: 0.98, blue: 0.94))
                    .overlay(Capsule().stroke(fill.opacity(0.85), lineWidth: max(2, size * 0.018)))
                    .frame(width: size * 0.18, height: size * 0.46)
                    .offset(y: -size * 0.16)
                    .rotationEffect(.degrees(Double(index) * 360 / Double(max(petals, 1))))
            }
            Circle()
                .fill(Color(red: 0.96, green: 0.86, blue: 0.38))
                .overlay(Circle().stroke(fill.opacity(0.9), lineWidth: 2))
                .frame(width: size * 0.22, height: size * 0.22)
        }
        .frame(width: size, height: size)
    }
}
