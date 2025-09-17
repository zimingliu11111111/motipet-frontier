import SpriteKit

class PetNode: SKSpriteNode {
    private var spriteSheet: SKTexture?
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
        // 加载精灵图集
        if let spriteImage = UIImage(named: "MotiPet_Cat_v2") {
            spriteSheet = SKTexture(image: spriteImage)
            // 立即设置纹理，这样即使动画失败也能看到图片
            texture = spriteSheet
            print("✅ 成功加载宠物精灵图集")
        } else {
            print("❌ 无法加载MotiPet_Cat_v2图片")
        }
        
        // 大小由父级设置，这里不需要重新设置
        // size = CGSize(width: 64, height: 64)
        
        // 开始待机动画
        playAnimation(.idle)
    }
    
    func playAnimation(_ animation: PetAnimation) {
        // 确保有精灵图集
        guard let spriteSheet = spriteSheet else {
            print("❌ 没有精灵图集")
            return
        }
        
        // 尝试加载动画数据
        guard let spriteSheetData = AnimationLoader.loadAnimationData() else {
            print("⚠️ 未找到动画数据文件，显示静态图片")
            texture = spriteSheet
            return
        }
        
        guard let frameTag = AnimationLoader.getFrameTag(for: animation) else {
            print("⚠️ 未找到动画: \(animation.rawValue)，显示静态图片")
            texture = spriteSheet
            return
        }
        
        currentAnimation = animation
        
        // 停止当前动画
        removeAllActions()
        
        // 创建动画帧 - 使用JSON中的精确坐标
        var frames: [SKTexture] = []
        let sortedFrames = spriteSheetData.frames.sorted { first, second in
            let firstIndex = Int(first.key.split(separator: " ").last ?? "0") ?? 0
            let secondIndex = Int(second.key.split(separator: " ").last ?? "0") ?? 0
            return firstIndex < secondIndex
        }
        
        for frameIndex in frameTag.from...frameTag.to {
            if frameIndex < sortedFrames.count {
                let frameData = sortedFrames[frameIndex].value
                let frame = frameData.frame
                
                // 计算归一化的纹理坐标
                let rect = CGRect(
                    x: CGFloat(frame.x) / spriteSheet.size().width,
                    y: CGFloat(spriteSheetData.meta.size.h - frame.y - frame.h) / spriteSheet.size().height, // 翻转Y轴
                    width: CGFloat(frame.w) / spriteSheet.size().width,
                    height: CGFloat(frame.h) / spriteSheet.size().height
                )
                
                let frameTexture = SKTexture(rect: rect, in: spriteSheet)
                frameTexture.filteringMode = .nearest // 像素艺术设置
                frames.append(frameTexture)
            }
        }
        
        if !frames.isEmpty {
            // 根据帧数据中的duration来设置时间
            let timePerFrame = 0.3 // 可以后续根据JSON中的duration字段调整
            let animationAction = SKAction.animate(with: frames, timePerFrame: timePerFrame)
            
            if animation.isLoop {
                let repeatAction = SKAction.repeatForever(animationAction)
                run(repeatAction, withKey: "pet_animation")
            } else {
                let completionAction = SKAction.run {
                    // 非循环动画结束后回到待机状态
                    self.playAnimation(.idle)
                }
                let sequence = SKAction.sequence([animationAction, completionAction])
                run(sequence, withKey: "pet_animation")
            }
        }
    }
    
    func addAccessory(_ accessory: AccessoryType) {
        guard accessoryNodes[accessory] == nil else { return }
        
        let accessoryNode = SKSpriteNode(imageNamed: accessory.rawValue)
        accessoryNode.size = self.size // 使用宠物的实际大小
        accessoryNode.zPosition = 1
        
        // 根据装饰品类型调整位置（根据宠物大小缩放）
        switch accessory {
        case .sunglasses:
            let offsetY = self.size.height * 0.125 // 按比例调整位置
            accessoryNode.position = CGPoint(x: 0, y: offsetY)
        }
        
        addChild(accessoryNode)
        accessoryNodes[accessory] = accessoryNode
    }
    
    func removeAccessory(_ accessory: AccessoryType) {
        accessoryNodes[accessory]?.removeFromParent()
        accessoryNodes[accessory] = nil
    }
    
    func updateAccessories(_ accessories: [AccessoryType]) {
        // 移除不需要的装饰品
        for (type, _) in accessoryNodes {
            if !accessories.contains(type) {
                removeAccessory(type)
            }
        }
        
        // 添加新的装饰品
        for accessory in accessories {
            if accessoryNodes[accessory] == nil {
                addAccessory(accessory)
            }
        }
    }
}