import SpriteKit
import UIKit

/// Timed falling-petal tapper. First win unlocks Orchid.
final class PetalCatchScene: SKScene {
    var onFinished: ((Int, Bool) -> Void)?
    var reducedMotion = false

    private var caught = 0
    private var elapsed: TimeInterval = 0
    private var spawnAcc: TimeInterval = 0
    private var running = false
    private var hud: SKLabelNode?
    private var lastUpdate: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        removeAllChildren()
        caught = 0
        elapsed = 0
        spawnAcc = 0
        lastUpdate = 0
        running = true

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.fontSize = 18
        label.fontColor = UIColor(red: 0.2, green: 0.36, blue: 0.28, alpha: 1)
        label.position = CGPoint(x: size.width / 2, y: size.height - 36)
        label.zPosition = 20
        addChild(label)
        hud = label
        refreshHUD()
        spawnPetal()
    }

    override func update(_ currentTime: TimeInterval) {
        guard running else { return }
        if lastUpdate == 0 { lastUpdate = currentTime }
        let dt = min(0.05, currentTime - lastUpdate)
        lastUpdate = currentTime
        elapsed += dt
        spawnAcc += dt
        if spawnAcc >= PetalCatchRules.spawnEvery {
            spawnAcc = 0
            spawnPetal()
        }
        if elapsed >= PetalCatchRules.duration {
            finish()
        }
        refreshHUD()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard running, let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location).filter { $0.name == "petal" }
        guard let petal = nodes.first else { return }
        caught += 1
        Haptics.light()
        SoundPlayer.shared.click()
        Juice.burstPetals(
            at: petal.position,
            color: UIColor(red: 0.93, green: 0.62, blue: 0.70, alpha: 1),
            in: self,
            count: reducedMotion ? 0 : 8,
            style: .sakura,
            reduced: reducedMotion
        )
        Juice.sparkles(at: petal.position, in: self, count: reducedMotion ? 0 : 5, reduced: reducedMotion)
        petal.removeAllActions()
        petal.removeFromParent()
        refreshHUD()
        if caught >= PetalCatchRules.winCatches {
            finish()
        }
    }

    private func spawnPetal() {
        let petal = SKShapeNode(ellipseOf: CGSize(width: 28, height: 40))
        petal.fillColor = [
            UIColor(red: 0.93, green: 0.55, blue: 0.64, alpha: 1),
            UIColor(red: 0.86, green: 0.62, blue: 0.82, alpha: 1),
            UIColor(red: 0.98, green: 0.82, blue: 0.55, alpha: 1),
            UIColor(red: 0.72, green: 0.78, blue: 0.92, alpha: 1)
        ].randomElement() ?? .white
        petal.strokeColor = UIColor.white.withAlphaComponent(0.45)
        petal.lineWidth = 1
        petal.name = "petal"
        petal.zPosition = 5
        let x = CGFloat.random(in: 36...(max(37, size.width - 36)))
        petal.position = CGPoint(x: x, y: size.height + 20)
        petal.zRotation = CGFloat.random(in: -0.4...0.4)
        addChild(petal)
        let dest = CGPoint(x: x + CGFloat.random(in: -30...30), y: -30)
        let fall = reducedMotion
            ? SKAction.move(to: dest, duration: PetalCatchRules.fallDuration * 0.7)
            : SKAction.group([
                SKAction.move(to: dest, duration: PetalCatchRules.fallDuration),
                SKAction.rotate(byAngle: CGFloat.random(in: -1.2...1.2), duration: PetalCatchRules.fallDuration)
            ])
        petal.run(.sequence([fall, .fadeOut(withDuration: 0.1), .removeFromParent()]))
    }

    private func refreshHUD() {
        let left = max(0, Int((PetalCatchRules.duration - elapsed).rounded(.up)))
        hud?.text = "Caught \(caught)/\(PetalCatchRules.winCatches)  ·  \(left)s"
    }

    private func finish() {
        guard running else { return }
        running = false
        let won = caught >= PetalCatchRules.winCatches
        onFinished?(caught, won)
    }
}
