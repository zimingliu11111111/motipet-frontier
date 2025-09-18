import SpriteKit

class GameScene: SKScene {
    private var petNode: PetNode?

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        configurePetNode()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        resizePetIfNeeded()
    }

    private func configurePetNode() {
        guard petNode == nil else { return }
        let size = idealPetSize()
        let node = PetNode(texture: nil, color: .clear, size: size)
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(node)
        petNode = node
    }

    private func idealPetSize() -> CGSize {
        let edge = min(frame.width, frame.height) * 0.75
        return CGSize(width: edge, height: edge)
    }

    private func resizePetIfNeeded() {
        guard let petNode = petNode else { return }
        let newSize = idealPetSize()
        if petNode.size != newSize {
            petNode.size = newSize
        }
        petNode.position = CGPoint(x: frame.midX, y: frame.midY)
    }

    func updatePetAnimation(_ animation: PetAnimation) {
        petNode?.playAnimation(animation)
    }

    func updatePetAccessories(_ accessories: [AccessoryType]) {
        petNode?.updateAccessories(accessories)
    }

    func playAnimation(named name: String, loop: Bool = false, restoreToIdle: Bool = true) {
        petNode?.playAnimation(named: name, loop: loop, restoreToIdle: restoreToIdle)
    }

    func playAnimationSequence(_ names: [String], loopLast: Bool = false, restoreToIdle: Bool = true) {
        if names.count <= 1, let first = names.first {
            playAnimation(named: first, loop: loopLast, restoreToIdle: restoreToIdle)
        } else {
            petNode?.playAnimationSequence(names, loopLast: loopLast, restoreToIdle: restoreToIdle)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        petNode?.playAnimation(named: "Happy", loop: false, restoreToIdle: true)
    }
}