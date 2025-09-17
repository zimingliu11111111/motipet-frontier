import Foundation

enum PetMood: String, Codable {
    case energetic
    case normal
    case tired
}

enum HappinessState: String, Codable {
    case happy
    case content
    case low

    var displayName: String {
        switch self {
        case .happy: return "开心"
        case .content: return "平静"
        case .low: return "低落"
        }
    }
}

struct PetStatus: Codable {
    var level: Int = 1
    var totalXP: Int = 0
    var xpIntoLevel: Int = 0
    var xpToNextLevel: Int = 100
    var readinessScore: Int = 75
    var readinessDiagnosis: String = "正常"
    var stateReason: String = ""
    var petMood: PetMood = .normal
    var happinessScore: Int = 80
    var happinessState: HappinessState = .content
    var leveledUp: Bool = false
    var forceHappySeconds: Int = 0
    var accessories: [AccessoryType] = []

    var xpForNextLevel: Int { xpIntoLevel + xpToNextLevel }

    var xpProgress: Double {
        let total = xpForNextLevel
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, Double(xpIntoLevel) / Double(total)))
    }

    var xpDisplayText: String {
        "\(xpIntoLevel)/\(xpForNextLevel)"
    }

    mutating func updateProgress(totalXP: Int) {
        let progress = LevelSystem.progress(for: totalXP)
        level = progress.level
        self.totalXP = totalXP
        xpIntoLevel = progress.xpIntoLevel
        xpToNextLevel = progress.xpToNextLevel
    }

    mutating func apply(apiResponse: MotipetDailyStateResponse, accessories: [AccessoryType]) {
        level = apiResponse.level
        totalXP = apiResponse.totalXP
        xpIntoLevel = apiResponse.xpIntoLevel
        xpToNextLevel = apiResponse.xpToNextLevel
        readinessScore = apiResponse.readinessScore
        readinessDiagnosis = apiResponse.readinessDiagnosis
        stateReason = apiResponse.stateReason
        petMood = PetMood(rawValue: apiResponse.petState) ?? .normal
        happinessScore = apiResponse.happinessScore
        happinessState = HappinessState(rawValue: apiResponse.happinessState) ?? .content
        leveledUp = apiResponse.leveledUp
        forceHappySeconds = apiResponse.forceHappySeconds
        self.accessories = accessories
    }

    mutating func mergeAccessories(_ accessories: [AccessoryType]) {
        self.accessories = accessories
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

    static func animation(for mood: PetMood) -> PetAnimation {
        switch mood {
        case .energetic: return .idle
        case .normal: return .idle
        case .tired: return .tired
        }
    }
}