import SpriteKit

class PetNode: SKSpriteNode {
    private var spriteSheetTexture: SKTexture?
    private var spriteSheetData: AsepriteSpriteSheet?
    private var animationCache: [PetAnimation: [SKTexture]] = [:]
    private var currentAnimation: PetAnimation = .idle
    private var accessoryNodes: [AccessoryType: SKSpriteNode] = [:]

    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        setupPet()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPet()
    }

    private func setupPet() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        loadSpriteResources()
        playAnimation(.idle)
    }

    private func loadSpriteResources() {
        spriteSheetTexture = SKTexture(imageNamed: "MotiPet_Cat_v2")
        spriteSheetTexture?.filteringMode = .nearest
        spriteSheetData = AnimationLoader.loadAnimationData()

        if let frames = textures(for: .idle), let firstFrame = frames.first {
            texture = firstFrame
        } else if let texture = spriteSheetTexture {
            self.texture = texture
        }
    }

    private func textures(for animation: PetAnimation) -> [SKTexture]? {
        if let cached = animationCache[animation] {
            return cached
        }

        guard
            let spriteSheet = spriteSheetTexture,
            let sheetData = spriteSheetData,
            let frameTag = sheetData.meta.frameTags.first(where: { $0.name.caseInsensitiveCompare(animation.rawValue) == .orderedSame })
        else {
            return nil
        }

        let sortedFrames = sheetData.frames.sorted { lhs, rhs in
            intIndex(from: lhs.key) < intIndex(from: rhs.key)
        }

        var textures: [SKTexture] = []
        for index in frameTag.from...frameTag.to {
            guard index < sortedFrames.count else { continue }
            let frameData = sortedFrames[index].value.frame
            let sheetHeight = CGFloat(sheetData.meta.size.h)
            let sheetWidth = CGFloat(sheetData.meta.size.w)

            let rect = CGRect(
                x: CGFloat(frameData.x) / sheetWidth,
                y: CGFloat(sheetHeight - CGFloat(frameData.y) - CGFloat(frameData.h)) / sheetHeight,
                width: CGFloat(frameData.w) / sheetWidth,
                height: CGFloat(frameData.h) / sheetHeight
            )

            let texture = SKTexture(rect: rect, in: spriteSheet)
            texture.filteringMode = .nearest
            textures.append(texture)
        }

        animationCache[animation] = textures
        return textures
    }

    func playAnimation(_ animation: PetAnimation) {
        currentAnimation = animation
        removeAction(forKey: "pet_animation")

        guard let frames = textures(for: animation), !frames.isEmpty else {
            return
        }

        texture = frames.first
        let timePerFrame = animation == .idle ? 0.35 : 0.25
        let animateAction = SKAction.animate(with: frames, timePerFrame: timePerFrame)

        if animation.isLoop {
            run(SKAction.repeatForever(animateAction), withKey: "pet_animation")
        } else {
            let completion = SKAction.run { [weak self] in
                self?.playAnimation(.idle)
            }
            run(SKAction.sequence([animateAction, completion]), withKey: "pet_animation")
        }
    }

    func addAccessory(_ accessory: AccessoryType) {
        guard accessoryNodes[accessory] == nil else { return }

        let accessoryNode = SKSpriteNode(imageNamed: accessory.rawValue)
        accessoryNode.size = CGSize(width: size.width * 0.7, height: size.height * 0.28)
        accessoryNode.position = CGPoint(x: 0, y: size.height * 0.15)
        accessoryNode.zPosition = 5
        accessoryNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        addChild(accessoryNode)
        accessoryNodes[accessory] = accessoryNode
    }

    func removeAccessory(_ accessory: AccessoryType) {
        accessoryNodes[accessory]?.removeFromParent()
        accessoryNodes[accessory] = nil
    }

    func updateAccessories(_ accessories: [AccessoryType]) {
        for (type, _) in accessoryNodes where !accessories.contains(type) {
            removeAccessory(type)
        }

        for accessory in accessories where accessoryNodes[accessory] == nil {
            addAccessory(accessory)
        }
    }

    private func intIndex(from key: String) -> Int {
        let components = key.split(separator: " ")
        guard let last = components.last else { return 0 }
        return Int(last.replacingOccurrences(of: ".jpg", with: "")) ?? 0
    }
}