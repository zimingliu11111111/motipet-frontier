import Foundation

struct AsepriteSpriteSheet: Codable {
    let frames: [String: FrameData]
    let meta: MetaData
}

struct FrameData: Codable {
    let frame: Frame
    let rotated: Bool
    let trimmed: Bool
    let spriteSourceSize: Frame
    let sourceSize: Size
    let duration: Int
}

struct Frame: Codable {
    let x: Int
    let y: Int
    let w: Int
    let h: Int
}

struct Size: Codable {
    let w: Int
    let h: Int
}

struct MetaData: Codable {
    let app: String
    let version: String
    let image: String
    let format: String
    let size: Size
    let scale: String
    let frameTags: [FrameTag]
    let layers: [Layer]
    let slices: [String]
}

struct FrameTag: Codable {
    let name: String
    let from: Int
    let to: Int
    let direction: String
    let color: String
    
    var frameCount: Int {
        return to - from + 1
    }
}

struct Layer: Codable {
    let name: String
    let opacity: Int
    let blendMode: String
}

class AnimationLoader {
    static func loadAnimationData() -> AsepriteSpriteSheet? {
        guard let url = Bundle.main.url(forResource: "MotiPet_Cat_v2", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("无法加载动画数据文件")
            return nil
        }
        
        do {
            let spriteSheet = try JSONDecoder().decode(AsepriteSpriteSheet.self, from: data)
            return spriteSheet
        } catch {
            print("解析动画数据失败: \(error)")
            return nil
        }
    }
    
    static func getFrameTag(for animation: PetAnimation) -> FrameTag? {
        guard let spriteSheet = loadAnimationData() else { return nil }
        
        // 处理大小写不敏感的匹配
        let targetName = animation.rawValue.lowercased()
        return spriteSheet.meta.frameTags.first { $0.name.lowercased() == targetName }
    }
}