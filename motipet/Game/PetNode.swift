import SpriteKit

class PetNode: SKSpriteNode {
    private struct AnimationClip {
        let textures: [SKTexture]
        let timePerFrame: Double
    }

    private var spriteSheetTexture: SKTexture?
    private var spriteSheetData: AsepriteSpriteSheet?
    private var animationCache: [String: AnimationClip] = [:]
    private var accessoryNodes: [AccessoryType: SKSpriteNode] = [:]
    private let timePerFrameOverrides: [String: Double] = [
        "sleep": 0.28,
        "lookleft": 0.18,
        "lookright": 0.18,
        "petjaw": 0.45,
        "chasetail": 0.20,
        "turn": 0.16
    ]
    private let minimumFrameDuration: Double = 0.05

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

        if let clip = clip(forTag: "idle"), let first = clip.textures.first {
            texture = first
        } else if let texture = spriteSheetTexture {
            self.texture = texture
        }
    }

    func playAnimation(_ animation: PetAnimation) {
        let shouldRestore = animation == .idle ? false : true
        playAnimation(named: animation.rawValue, loop: animation.isLoop, restoreToIdle: shouldRestore)
    }

    func playAnimation(named tag: String, loop: Bool, restoreToIdle: Bool) {
        guard let clip = clip(forTag: tag) else { return }
        removeAction(forKey: "pet_animation")

        let animate = SKAction.animate(with: clip.textures, timePerFrame: clip.timePerFrame)
        if loop {
            run(SKAction.repeatForever(animate), withKey: "pet_animation")
        } else if restoreToIdle {
            let sequence = SKAction.sequence([animate, SKAction.run { [weak self] in
                self?.playAnimation(.idle)
            }])
            run(sequence, withKey: "pet_animation")
        } else {
            run(animate, withKey: "pet_animation")
        }
    }

    func playAnimationSequence(_ names: [String], loopLast: Bool, restoreToIdle: Bool) {
        guard !names.isEmpty else { return }
        removeAction(forKey: "pet_animation")

        var actions: [SKAction] = []

        for (index, name) in names.enumerated() {
            guard let clip = clip(forTag: name) else { continue }
            var action = SKAction.animate(with: clip.textures, timePerFrame: clip.timePerFrame)
            if loopLast && index == names.count - 1 {
                action = SKAction.repeatForever(action)
            }
            actions.append(action)
        }

        guard !actions.isEmpty else { return }

        let combined: SKAction
        if actions.count == 1 {
            combined = actions[0]
        } else {
            combined = SKAction.sequence(actions)
        }

        if loopLast {
            run(combined, withKey: "pet_animation")
        } else if restoreToIdle {
            run(SKAction.sequence([combined, SKAction.run { [weak self] in
                self?.playAnimation(.idle)
            }]), withKey: "pet_animation")
        } else {
            run(combined, withKey: "pet_animation")
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

    private func clip(forTag tag: String) -> AnimationClip? {
        let key = tag.lowercased()
        if let cached = animationCache[key] {
            return cached
        }

        guard
            let spriteSheet = spriteSheetTexture,
            let sheetData = spriteSheetData,
            let frameTag = sheetData.meta.frameTags.first(where: { $0.name.lowercased() == key })
        else {
            return nil
        }

        let sortedFrames = sheetData.frames.sorted { lhs, rhs in
            intIndex(from: lhs.key) < intIndex(from: rhs.key)
        }

        var textures: [SKTexture] = []
        var frameDurations: [Double] = []

        for index in frameTag.from...frameTag.to {
            guard index < sortedFrames.count else { continue }
            let frameEntry = sortedFrames[index].value
            let frame = frameEntry.frame
            let sheetHeight = CGFloat(sheetData.meta.size.h)
            let sheetWidth = CGFloat(sheetData.meta.size.w)

            let rect = CGRect(
                x: CGFloat(frame.x) / sheetWidth,
                y: CGFloat(sheetHeight - CGFloat(frame.y) - CGFloat(frame.h)) / sheetHeight,
                width: CGFloat(frame.w) / sheetWidth,
                height: CGFloat(frame.h) / sheetHeight
            )

            let texture = SKTexture(rect: rect, in: spriteSheet)
            texture.filteringMode = .nearest
            textures.append(texture)
            frameDurations.append(max(minimumFrameDuration, Double(frameEntry.duration) / 1000.0))
        }

        guard !textures.isEmpty else { return nil }
        let average = frameDurations.reduce(0, +) / Double(frameDurations.count)
        let clip = AnimationClip(textures: textures, timePerFrame: timePerFrameOverrides[key] ?? average)
        animationCache[key] = clip
        return clip
    }

    private func intIndex(from key: String) -> Int {
        let components = key.split(separator: " ")
        guard let last = components.last else { return 0 }
        return Int(last.replacingOccurrences(of: ".jpg", with: "")) ?? 0
    }
}