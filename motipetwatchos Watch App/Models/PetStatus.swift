import Foundation

struct PetStatus: Codable {
    var energy: Double = 100.0
    var happiness: Double = 100.0
    var xp: Int = 0
    var level: Int = 1
    var accessories: [AccessoryType] = []
    
    var xpForNextLevel: Int {
        switch level {
        case 1: return 100
        case 2: return 250
        case 3: return 500
        default: return level * 200
        }
    }
    
    var xpProgress: Double {
        return Double(xp) / Double(xpForNextLevel)
    }
    
    mutating func addXP(_ points: Int) {
        xp += points
        checkLevelUp()
    }
    
    private mutating func checkLevelUp() {
        if xp >= xpForNextLevel {
            level += 1
            xp = 0
        }
    }
}

enum AccessoryType: String, CaseIterable, Codable {
    case sunglasses = "Accessory_Sunglasses"
    
    var displayName: String {
        switch self {
        case .sunglasses:
            return "墨镜"
        }
    }
}

enum PetAnimation: String, CaseIterable {
    case idle = "idle"
    case happy = "Happy" 
    case tired = "tired"
    case sleep = "sleep"
    
    var isLoop: Bool {
        switch self {
        case .idle, .tired, .sleep:
            return true
        case .happy:
            return false
        }
    }
}