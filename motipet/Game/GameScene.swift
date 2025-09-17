import SpriteKit

class GameScene: SKScene {
    private var petNode: PetNode!
    
    override func didMove(to view: SKView) {
        setupScene()
        setupPet()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // 当场景大小改变时，重新调整宠物大小
        if let petNode = petNode {
            let petSize = min(frame.width, frame.height) * 0.7
            petNode.size = CGSize(width: petSize, height: petSize)
            petNode.position = CGPoint(x: frame.midX, y: frame.midY)
        }
    }
    
    private func setupScene() {
        backgroundColor = .clear
        scaleMode = .resizeFill
    }
    
    private func setupPet() {
        // 计算合适的宠物大小 - 使用场景的较小维度的70%
        let petSize = min(frame.width, frame.height) * 0.7
        petNode = PetNode(texture: nil, color: .clear, size: CGSize(width: petSize, height: petSize))
        petNode.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(petNode)
    }
    
    func updatePetAnimation(_ animation: PetAnimation) {
        petNode?.playAnimation(animation)
    }
    
    func updatePetAccessories(_ accessories: [AccessoryType]) {
        petNode?.updateAccessories(accessories)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 点击宠物触发简单的愉悦动画
        petNode?.playAnimation(.happy)
    }
}